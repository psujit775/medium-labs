# Outage, Explained: a bad feature file vs. a fixed-size limit (lab)

**This is an analogy, not a replay.** It copies the *failure pattern* from Cloudflare's
18 November 2025 post-mortem (https://blog.cloudflare.com/18-november-2025-outage/):
a metadata query without a database filter starts returning duplicate rows after a
permissions change, the generated feature file doubles, it is pushed to every edge,
and every edge fails on a fixed-size limit. Nothing here is Cloudflare code.
SQLite stands in for ClickHouse; small Python HTTP servers stand in for the proxy.

Lab numbers are scaled: 60 features, a limit of 100, so the doubled file (120) crosses it.
Cloudflare's report gives ~60 features in use and a limit of 200.

## Requirements
- Linux or macOS, Python 3.9+ (standard library only), `bash`, free ports 8081-8083.
- No Docker, no cloud account. Runs in about 70 seconds; reading along takes ~10 minutes.

## Run
```bash
./setup.sh     # 2 DB nodes, a publisher (every 5 s), 3 edges with a naive loader; healthy probe
./break.sh     # grant on node-b only (flapping), then on both nodes (steady 500s)
./fix.sh       # restart edges with a validating loader + on-disk last-known-good
./cleanup.sh   # stop everything, remove ./run
```
Env knobs: `PUBLISH_EVERY` (default 5), `STAGE1_SECS` (30), `STAGE2_SECS` (10), `FIX_SECS` (15).

The publisher picks a DB node at random each cycle, so the flapping in stage 1
looks different each run. That randomness is the point: it mirrors the report's
"sometimes good, sometimes bad" files during a gradual rollout.

## Files
- `bin/db.py` – creates/grants the fake metadata table on node `a`/`b`
- `bin/publisher.py` – runs the unfiltered query, writes `features.json` to each edge
- `bin/edge.py` – toy proxy; `--loader naive` (fails on >100) or `--loader safe`
- `bin/seed_lkg.py` – writes a known-good file as `features.lkg.json` (the rollback step)
- `bin/probe.py` – hits all 3 edges once a second, prints status codes
- `output/` – real output from the run on 17 Nov 2026 (IST), plus `attempt1-lkg-in-memory-only/`,
  a first fix attempt that failed (see below)

## Tested on
Linux 6.12.113 x86_64, Python 3.13.5, SQLite 3.46.1 (Python's bundled `sqlite3`).
Docker/kind were not installed on the test machine and are not needed.

## What the first fix attempt taught
The first version of the safe loader kept the last-known-good config in memory only.
Restarting the edges to deploy the fix wiped that memory, the publisher had already
overwritten the seeded file, and all three edges answered 500 "no valid config" for the
whole run (`output/attempt1-lkg-in-memory-only/03-fix.txt`). Persisting the last-known-good
file to disk (`features.lkg.json`) and loading it at startup fixed it.
