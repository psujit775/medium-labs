#!/usr/bin/env bash
# The problem: the "untrusted" job runs on the default runtime (runc) and shares the node's kernel.
set -euo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-sandbox-lab >/dev/null
sed 's/RUNTIME/runc/' manifests/untrusted-job.yaml | kubectl apply -f -
kubectl wait --for=condition=complete job/untrusted-runc --timeout=120s >/dev/null
echo "--- job on runc (default runtime), node kernel is $(docker exec sandbox-lab-control-plane uname -r) ---"
kubectl logs job/untrusted-runc
