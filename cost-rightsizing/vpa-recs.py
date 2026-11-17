#!/usr/bin/env python3
# Print VPA recommendations (target and upper bound) for namespace shop.
import json, subprocess
def mem(s):
    s = str(s)
    if s.isdigit(): return f"{int(s)/2**30:.1f}Gi"
    return s
vpas = json.loads(subprocess.check_output(["kubectl", "get", "vpa", "-n", "shop", "-o", "json"]))["items"]
for v in vpas:
    r = v.get("status", {}).get("recommendation", {}).get("containerRecommendations", [{}])[0]
    t, u = r.get("target", {}), r.get("upperBound", {})
    print(f"{v['metadata']['name']:8s} target cpu={t.get('cpu')} mem={mem(t.get('memory'))}   upperBound cpu={u.get('cpu')} mem={mem(u.get('memory'))}")
