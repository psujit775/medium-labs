#!/usr/bin/env bash
# The "permissions change": make hidden r0 metadata visible.
# Stage 1 rolls it to node-b only (gradual rollout -> flapping), stage 2 to both nodes.
set -euo pipefail
cd "$(dirname "$0")"
export LAB_RUN=run
echo "--- stage 1: grant on node-b only (half the cluster) ---"
python3 bin/db.py grant b
python3 bin/probe.py ${STAGE1_SECS:-30}
echo "--- stage 2: grant on every node ---"
python3 bin/db.py grant a
sleep 6
python3 bin/probe.py ${STAGE2_SECS:-10}
