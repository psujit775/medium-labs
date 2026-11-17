#!/usr/bin/env bash
# Wait for the API server to be ready (not just reachable), then check the end state.
set -uo pipefail
kubectl config use-context kind-eks131-lab >/dev/null
for i in $(seq 1 90); do [ "$(kubectl get --raw /readyz 2>/dev/null)" = "ok" ] && break; sleep 2; done
echo "readyz: $(kubectl get --raw /readyz 2>&1)"
kubectl get --raw /version | grep gitVersion
kubectl get nodes -o custom-columns=NAME:.metadata.name,READY:.status.conditions[-1].status,KUBELET:.status.nodeInfo.kubeletVersion
kubectl get pods -l app=orders-api -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase
pluto detect-api-resources --target-versions k8s=v1.32.0 -o wide 2>&1 | tail -2
