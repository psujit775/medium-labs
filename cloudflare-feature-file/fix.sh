#!/usr/bin/env bash
# The fix: restart the edges with a loader that validates each new file and keeps
# the last-known-good one when validation fails. We seed a known-good file first
# (the rollback step), then leave the publisher pushing bad files on purpose.
set -euo pipefail
cd "$(dirname "$0")"
export LAB_RUN=run
for i in 1 2 3; do kill "$(cat run/edge$i.pid)" 2>/dev/null || true; done
python3 bin/seed_lkg.py
for i in 1 2 3; do
  nohup python3 bin/edge.py --name edge$i --port 808$i --loader safe >> run/logs/edge$i.log 2>&1 &
  echo $! > run/edge$i.pid
done
sleep 2
echo "--- after fix (publisher is still pushing bad files) ---"
python3 bin/probe.py ${FIX_SECS:-15}
echo "--- edge1 log tail ---"
tail -n 4 run/logs/edge1.log
