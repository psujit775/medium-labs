"""Every few seconds: run the feature query on a random DB node, write a feature
file, and copy it to every edge. No validation at all (the starting state)."""
import json, os, random, sqlite3, time, shutil
RUN = os.environ.get("LAB_RUN", "run")
INTERVAL = float(os.environ.get("PUBLISH_EVERY", "5"))
NODES = ["a", "b"]
EDGES = ["edge1", "edge2", "edge3"]

# Same shape as the query quoted in the report: note there is no filter on database.
QUERY = """SELECT name, type FROM columns
           WHERE table_name = 'http_requests_features' AND visible = 1
           ORDER BY name"""

def generate(node):
    con = sqlite3.connect(os.path.join(RUN, f"db-{node}.sqlite"))
    rows = con.execute(QUERY).fetchall()
    return [{"name": n, "type": t} for n, t in rows]

def publish(features, node, gen):
    blob = json.dumps({"generation": gen, "source_node": node, "features": features})
    for e in EDGES:
        d = os.path.join(RUN, e); os.makedirs(d, exist_ok=True)
        tmp = os.path.join(d, "features.json.tmp")
        with open(tmp, "w") as f: f.write(blob)
        os.replace(tmp, os.path.join(d, "features.json"))

gen = 0
while True:
    gen += 1
    node = random.choice(NODES)
    feats = generate(node)
    publish(feats, node, gen)
    print(f"{time.strftime('%H:%M:%S')} [publisher] gen={gen} node-{node} features={len(feats)} -> {len(EDGES)} edges", flush=True)
    time.sleep(INTERVAL)
