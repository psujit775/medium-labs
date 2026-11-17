"""A toy 'edge proxy'. Each request runs a bot-scoring module that copies the
features into a preallocated buffer of fixed size (MAX_FEATURES).

--loader=naive : load whatever file arrives; over the limit -> unhandled error -> 500
--loader=safe  : validate a new file before swapping it in; if bad, keep last-known-good
"""
import argparse, json, os, sys, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MAX_FEATURES = 100   # lab number; Cloudflare's real limit was 200 (see post)

p = argparse.ArgumentParser()
p.add_argument("--name"); p.add_argument("--port", type=int)
p.add_argument("--loader", choices=["naive", "safe"], default="naive")
a = p.parse_args()
RUN = os.environ.get("LAB_RUN", "run")
PATH = os.path.join(RUN, a.name, "features.json")
LKG = os.path.join(RUN, a.name, "features.lkg.json")   # last-known-good, kept on disk

state = {"mtime": None, "cfg": None, "gen": None}

def log(msg): print(f"{time.strftime('%H:%M:%S')} [{a.name}] {msg}", flush=True)

def validate(cfg):
    feats = cfg["features"]
    names = [f["name"] for f in feats]
    if len(feats) > MAX_FEATURES:
        return f"{len(feats)} features > limit {MAX_FEATURES}"
    if len(names) != len(set(names)):
        return f"duplicate feature names ({len(names) - len(set(names))} dups)"
    return None

def maybe_reload():
    try: m = os.stat(PATH).st_mtime_ns
    except FileNotFoundError: return
    if m == state["mtime"]: return
    state["mtime"] = m
    with open(PATH) as f: cfg = json.load(f)
    if a.loader == "safe":
        err = validate(cfg)
        if err:
            log(f"REJECTED gen={cfg['generation']} ({err}); keeping last-known-good gen={state['cfg']['generation'] if state['cfg'] else None}")
            return
        with open(LKG + ".tmp", "w") as f: json.dump(cfg, f)
        os.replace(LKG + ".tmp", LKG)
    if state["cfg"] is None or state["cfg"]["generation"] != cfg["generation"]:
        log(f"loaded gen={cfg['generation']} features={len(cfg['features'])}")
    state["cfg"] = cfg

def bot_score(cfg):
    buf = [0.0] * MAX_FEATURES          # preallocated, fixed size
    for i, f in enumerate(cfg["features"]):
        if i >= MAX_FEATURES:
            # Mirrors the shape of the reported bug: the error is not handled here.
            raise RuntimeError(f"feature count {len(cfg['features'])} exceeds preallocated {MAX_FEATURES}")
        buf[i] = 1.0
    return 42  # pretend score

class H(BaseHTTPRequestHandler):
    def log_message(self, *x): pass
    def do_GET(self):
        maybe_reload()
        try:
            if state["cfg"] is None: raise RuntimeError("no valid config loaded")
            score = bot_score(state["cfg"])
            body, code = f"200 OK {a.name} gen={state['cfg']['generation']} bot_score={score}\n", 200
        except Exception as e:
            body, code = f"500 {a.name} worker panicked: {e}\n", 500
        self.send_response(code); self.end_headers(); self.wfile.write(body.encode())

if a.loader == "safe" and os.path.exists(LKG):
    with open(LKG) as f: state["cfg"] = json.load(f)
    log(f"started from last-known-good gen={state['cfg']['generation']} features={len(state['cfg']['features'])}")

log(f"listening on :{a.port} loader={a.loader} max_features={MAX_FEATURES}")
ThreadingHTTPServer(("127.0.0.1", a.port), H).serve_forever()
