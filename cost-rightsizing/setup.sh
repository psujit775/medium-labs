#!/usr/bin/env bash
# kind cluster + metrics-server + the VPA recommender (recommendation only).
set -euo pipefail
cd "$(dirname "$0")"
kind create cluster --config kind.yaml --wait 120s
kubectl config use-context kind-cost-lab >/dev/null
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.1/components.yaml
# kind's kubelets use self-signed serving certs, so metrics-server must skip verification (lab only).
kubectl -n kube-system patch deploy metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
V=https://raw.githubusercontent.com/kubernetes/autoscaler/vertical-pod-autoscaler-1.8.1/vertical-pod-autoscaler/deploy
kubectl apply -f $V/vpa-v1-crd-gen.yaml -f $V/vpa-rbac.yaml -f $V/recommender-deployment.yaml
docker exec cost-lab-control-plane crictl pull python:3.13-alpine >/dev/null && echo "image pre-pulled"
kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s
kubectl -n kube-system rollout status deploy/vpa-recommender --timeout=180s
kubectl get node cost-lab-control-plane -o jsonpath='allocatable: cpu={.status.allocatable.cpu} memory={.status.allocatable.memory}{"\n"}'
