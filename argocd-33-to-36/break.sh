#!/usr/bin/env bash
# The tempting shortcut: upgrade to 3.4 with a plain (client-side) kubectl apply.
set -uo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-argocd-lab >/dev/null
echo "--- kubectl apply -n argocd -f .../v3.4.13/manifests/install.yaml (no --server-side) ---"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.4.13/manifests/install.yaml 2>&1 \
  | grep -vE ' (configured|unchanged|created)$' | cut -c1-220
echo "exit code: ${PIPESTATUS[0]}"
sleep 20
echo "--- what is running now? ---"
kubectl -n argocd get deploy,sts -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image
kubectl get crd applicationsets.argoproj.io -o jsonpath='{.metadata.annotations}' | head -c 120; echo
./status.sh
