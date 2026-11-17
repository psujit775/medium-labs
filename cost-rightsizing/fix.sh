#!/usr/bin/env bash
# Read the VPA recommendations, apply right-sized requests, and measure what came back.
set -euo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-cost-lab >/dev/null
WAIT=${VPA_WAIT:-300}
echo "--- waiting ${WAIT}s so the VPA recommender has some history ---"
sleep "$WAIT"
echo "--- VPA recommendations (target / upper bound) ---"
./vpa-recs.py
echo "--- apply new requests: VPA target, CPU roughly doubled for headroom, memory rounded to 256Mi ---"
# In a real repo, change these in the manifests or Helm values, not with kubectl (see README).
kubectl -n shop set resources deploy/web     --requests=cpu=50m,memory=256Mi  --limits=memory=256Mi
kubectl -n shop set resources deploy/worker  --requests=cpu=150m,memory=256Mi --limits=memory=256Mi
kubectl -n shop set resources deploy/reports --requests=cpu=25m,memory=256Mi  --limits=memory=256Mi
kubectl -n shop rollout status deploy/web --timeout=180s
kubectl -n shop rollout status deploy/worker --timeout=180s
kubectl -n shop rollout status deploy/reports --timeout=180s
kubectl -n shop rollout status deploy/search --timeout=180s
sleep 60
echo "--- pods ---"
kubectl get pods -n shop --no-headers | awk '{print $1, $3, "restarts="$4}' | sort
echo "--- requests vs usage after right-sizing ---"
./report.sh
