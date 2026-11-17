#!/usr/bin/env bash
# Two ways scale-to-zero does not work.
set -uo pipefail
cd "$(dirname "$0")"; . ./lib.sh
kubectl config use-context kind-hpa-zero-lab >/dev/null
echo "--- 1. minReplicas: 0 with only a CPU metric ---"
kubectl apply -f manifests/hpa-cpu-only.yaml
echo "--- 2. scale the worker to 0 by hand, then create the queue HPA and add work ---"
kubectl scale deploy/queue-worker --replicas=0
kubectl apply -f manifests/hpa.yaml
setq 90
sleep 60
echo "$(ts) queue=90 for 60s: $(hpa)"
kubectl get deploy queue-worker
cond
