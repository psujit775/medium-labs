"""Write a last-known-good feature file (features.lkg.json) (from a node with no grant) to every edge."""
import json, sqlite3, os
import importlib.util
spec = importlib.util.spec_from_file_location("db", os.path.join(os.path.dirname(__file__), "db.py"))
db = importlib.util.module_from_spec(spec); spec.loader.exec_module(db)
db.init("lkg")
rows = sqlite3.connect(db.node_path("lkg")).execute(
    "SELECT name, type FROM columns WHERE table_name='http_requests_features' AND visible=1 ORDER BY name").fetchall()
blob = json.dumps({"generation": 0, "source_node": "lkg", "features": [{"name": n, "type": t} for n, t in rows]})
for e in ("edge1", "edge2", "edge3"):
    with open(os.path.join(db.RUN, e, "features.lkg.json"), "w") as f: f.write(blob)
print(f"[fix] seeded last-known-good file (gen=0) with {len(rows)} features on 3 edges")
