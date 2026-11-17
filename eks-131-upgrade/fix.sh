#!/usr/bin/env bash
# Fix the manifests in Git, give the PDB room, then drain and upgrade each node's kubelet.
set -uo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-eks131-lab >/dev/null
V=${TARGET:-v1.32.11}

wait_api() { for i in $(seq 1 60); do kubectl get nodes >/dev/null 2>&1 && return 0; sleep 2; done; }

upgrade_node() {  # drain -> kubeadm upgrade node -> new kubelet -> uncordon
  local n=$1
  kubectl drain "$n" --ignore-daemonsets --delete-emptydir-data --timeout=120s 2>&1 | grep -E 'drained|error|violate' | sort -u
  docker exec "$n" bash -c "curl -sSLo /usr/local/bin/kubeadm-new https://dl.k8s.io/release/$V/bin/linux/amd64/kubeadm && chmod +x /usr/local/bin/kubeadm-new && kubeadm-new upgrade node >/dev/null 2>&1; curl -sSLo /tmp/kubelet https://dl.k8s.io/release/$V/bin/linux/amd64/kubelet && install -m 0755 /tmp/kubelet /usr/bin/kubelet && systemctl restart kubelet"
  wait_api
  kubectl uncordon "$n"
}

echo "--- 1. move the APF manifests to flowcontrol.apiserver.k8s.io/v1 ---"
sed -i 's#flowcontrol.apiserver.k8s.io/v1beta3#flowcontrol.apiserver.k8s.io/v1#' manifests/apf.yaml
pluto detect-files -d manifests/ --target-versions k8s=v1.32.0 -o wide
kubectl apply -f manifests/apf.yaml

echo "--- 2. give the PDB room: replicas 2, changed in the manifest, not with kubectl scale ---"
sed -i 's#replicas: 1#replicas: 2#' manifests/app.yaml
kubectl apply -f manifests/app.yaml
kubectl rollout status deploy/orders-api --timeout=120s
kubectl get pdb orders-api -o custom-columns=NAME:.metadata.name,ALLOWED:.status.disruptionsAllowed

echo "--- 3. upgrade kubelets one node at a time ---"
start=$(date +%s)
for n in eks131-lab-worker eks131-lab-worker2 eks131-lab-control-plane; do  # workers first, then the control-plane node
  echo "== $n"; upgrade_node "$n"
done
echo "node upgrades took $(( $(date +%s) - start ))s"

echo "--- 4. verify: re-apply from Git, then wait for /readyz and check ---"
kubectl apply -f manifests/ 2>&1 || true
./verify.sh
