"""Two tiny 'database nodes' (SQLite files) that mimic a metadata table.

Each node has a `columns` table, like a system catalog: (database, table_name, name, type).
The real feature table lives in database 'r0'; users normally only *see* the
'default' copy. A 'grant' makes the r0 rows visible too, which is the analogy
for the permissions change in the Cloudflare report.
"""
import sqlite3, sys, os

RUN = os.environ.get("LAB_RUN", "run")
N_FEATURES = 60

def node_path(node):
    return os.path.join(RUN, f"db-{node}.sqlite")

def init(node):
    con = sqlite3.connect(node_path(node))
    con.executescript("""
      DROP TABLE IF EXISTS columns;
      CREATE TABLE columns (database TEXT, table_name TEXT, name TEXT, type TEXT, visible INTEGER);
    """)
    rows = []
    for i in range(N_FEATURES):
        name, typ = f"feature_{i:03d}", "Float64"
        rows.append(("default", "http_requests_features", name, typ, 1))
        rows.append(("r0", "http_requests_features", name, typ, 0))  # hidden until granted
    con.executemany("INSERT INTO columns VALUES (?,?,?,?,?)", rows)
    con.commit()

def grant(node):
    con = sqlite3.connect(node_path(node))
    con.execute("UPDATE columns SET visible=1 WHERE database='r0'")
    con.commit()

if __name__ == "__main__":
    cmd, *nodes = sys.argv[1:]
    for n in nodes:
        {"init": init, "grant": grant}[cmd](n)
        print(f"[db] {cmd} node-{n}")
