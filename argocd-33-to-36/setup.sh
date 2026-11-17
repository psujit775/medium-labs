#!/usr/bin/env bash
# kind on 1.35, Argo CD v3.3.19 (the last 3.3 release), and the guestbook app.
set -euo pipefail
cd "$(dirname "$0")"
kind create cluster --config kind.yaml --wait 120s
kubectl config use-context kind-argocd-lab >/dev/null
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.3.19/manifests/install.yaml >/dev/null
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
kubectl apply -f manifests/guestbook.yaml
for i in $(seq 1 60); do
  [ "$(kubectl -n argocd get application guestbook -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null)" = "Synced/Healthy" ] && break; sleep 5
done
./status.sh
