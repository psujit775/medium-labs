#!/usr/bin/env bash
# Start the lab: 2 DB nodes, 1 publisher, 3 edges (naive loader). Python 3 stdlib only.
set -euo pipefail
cd "$(dirname "$0")"
export LAB_RUN=run PUBLISH_EVERY=${PUBLISH_EVERY:-5}
rm -rf run && mkdir -p run/logs
python3 bin/db.py init a b
nohup python3 bin/publisher.py > run/logs/publisher.log 2>&1 & echo $! > run/publisher.pid
for i in 1 2 3; do
  nohup python3 bin/edge.py --name edge$i --port 808$i --loader naive > run/logs/edge$i.log 2>&1 &
  echo $! > run/edge$i.pid
done
sleep 2
echo "--- healthy baseline ---"
python3 bin/probe.py 5
