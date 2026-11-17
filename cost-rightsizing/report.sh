#!/usr/bin/env bash
# Requests vs actual usage, per deployment, plus what the node has left to schedule.
kubectl config use-context kind-cost-lab >/dev/null
python3 - <<'PY'
import json, subprocess, re
def q(s):  # quantity -> millicores or MiB
    if s.endswith('m'): return int(s[:-1])
    if s.endswith('Ki'): return int(s[:-2])/1024
    if s.endswith('Mi'): return int(s[:-2])
    if s.endswith('Gi'): return int(s[:-2])*1024
    return int(float(s)*1000)
pods = json.loads(subprocess.check_output(["kubectl","get","pods","-n","shop","-o","json"]))["items"]
top = subprocess.run(["kubectl","top","pods","-n","shop","--no-headers"],capture_output=True,text=True).stdout.split("\n")
use = {l.split()[0]:(q(l.split()[1]), q(l.split()[2])) for l in top if l.strip()}
rows = {}
for p in pods:
    app = p["metadata"]["labels"]["app"]; r = p["spec"]["containers"][0]["resources"]["requests"]
    d = rows.setdefault(app, dict(pods=0, running=0, cpu_req=0, mem_req=0, cpu_use=0, mem_use=0))
    d["pods"] += 1
    if p["status"]["phase"] != "Running": continue   # Pending pods hold no node capacity
    d["running"] += 1
    d["cpu_req"] += q(r["cpu"]); d["mem_req"] += q(r["memory"])
    u = use.get(p["metadata"]["name"], (0, 0)); d["cpu_use"] += u[0]; d["mem_use"] += u[1]
print('(requests counted for Running pods only)')
print(f"{'deploy':8s} {'run/pods':>8s} {'cpu req':>8s} {'cpu used':>8s} {'mem req':>8s} {'mem used':>8s}")
t = dict(cr=0, cu=0, mr=0, mu=0)
for a, d in sorted(rows.items()):
    print(f"{a:8s} {str(d['running'])+'/'+str(d['pods']):>8s} {d['cpu_req']:>7d}m {d['cpu_use']:>7d}m {d['mem_req']:>6.0f}Mi {d['mem_use']:>6.0f}Mi")
    t["cr"] += d["cpu_req"]; t["cu"] += d["cpu_use"]; t["mr"] += d["mem_req"]; t["mu"] += d["mem_use"]
print(f"{'total':8s} {'':>8s} {t['cr']:>7d}m {t['cu']:>7d}m {t['mr']:>6.0f}Mi {t['mu']:>6.0f}Mi")
PY
echo "--- node: requested vs allocatable, and real usage ---"
kubectl describe node cost-lab-control-plane | grep -A5 'Allocated resources' | tail -2
kubectl top node --no-headers | awk '{print "real usage: cpu "$2" ("$3"), memory "$4" ("$5")"}'
