#!/usr/bin/env bash
# Create a 2-node kind cluster on Kubernetes 1.31 and deploy the "old" manifests.
set -euo pipefail
cd "$(dirname "$0")"
kind create cluster --config kind.yaml --wait 120s
kubectl config use-context kind-eks131-lab >/dev/null
echo "--- deploy the app and the APF objects (watch for warnings) ---"
kubectl apply -f manifests/
kubectl rollout status deploy/orders-api --timeout=120s
echo "--- versions ---"
kubectl get --raw /version | grep gitVersion
kubectl get nodes -o custom-columns=NAME:.metadata.name,KUBELET:.status.nodeInfo.kubeletVersion
