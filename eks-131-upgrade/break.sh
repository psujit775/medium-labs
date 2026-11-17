#!/usr/bin/env bash
# Upgrade without fixing anything: control plane 1.31 -> 1.32 with kubeadm inside the
# kind node, then re-apply the same manifests (what CI or GitOps does), then try to drain.
set -uo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-eks131-lab >/dev/null
CP=eks131-lab-control-plane; V=${TARGET:-v1.32.11}
echo "--- upgrade control plane to $V (takes ~2 minutes) ---"
docker exec $CP bash -c "curl -sSLo /usr/local/bin/kubeadm-new https://dl.k8s.io/release/$V/bin/linux/amd64/kubeadm && chmod +x /usr/local/bin/kubeadm-new"
start=$(date +%s)
docker exec $CP kubeadm-new upgrade apply $V -y --ignore-preflight-errors=all 2>&1 | grep -E 'SUCCESS|ERROR|error' || true
echo "control plane upgrade took $(( $(date +%s) - start ))s"
kubectl get --raw /version | grep gitVersion
kubectl get nodes -o custom-columns=NAME:.metadata.name,KUBELET:.status.nodeInfo.kubeletVersion
echo "--- the objects already in the cluster survived (stored as v1) ---"
kubectl get flowschema/batch-jobs prioritylevelconfiguration/batch-jobs
echo "--- but re-applying the manifests from Git fails ---"
kubectl apply -f manifests/
NODE=$(kubectl get pod -l app=orders-api -o jsonpath='{.items[0].spec.nodeName}')
echo "--- drain $NODE (where orders-api runs) so its kubelet can be upgraded ---"
kubectl drain "$NODE" --ignore-daemonsets --timeout=40s 2>&1 | grep -E "cordoned|violate|unable" | sort -u | head -4
