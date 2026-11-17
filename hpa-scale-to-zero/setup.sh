#!/usr/bin/env bash
# kind 1.37 + a fake queue + Prometheus + Prometheus Adapter (External Metrics API) + the worker.
set -euo pipefail
cd "$(dirname "$0")"
kind create cluster --config kind.yaml --wait 120s
kubectl config use-context kind-hpa-zero-lab >/dev/null
docker exec hpa-zero-lab-control-plane crictl pull python:3.13-alpine >/dev/null
kubectl apply -f manifests/queue.yaml -f manifests/prometheus.yaml
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community >/dev/null
helm install prometheus-adapter prometheus-community/prometheus-adapter --version 5.4.2 \
  -n monitoring -f manifests/adapter-values.yaml --wait --timeout 5m >/dev/null
kubectl -n monitoring rollout status deploy/prometheus --timeout=180s
kubectl rollout status deploy/fake-queue --timeout=180s
kubectl apply -f manifests/worker.yaml
kubectl rollout status deploy/queue-worker --timeout=180s
for i in $(seq 1 30); do
  kubectl get --raw '/apis/external.metrics.k8s.io/v1beta1/namespaces/default/queue_consumer_lag?labelSelector=name%3Dworker_tasks' 2>/dev/null | grep -q '"value"' && break; sleep 5
done
kubectl get apiservice v1beta1.external.metrics.k8s.io
kubectl get --raw '/apis/external.metrics.k8s.io/v1beta1/namespaces/default/queue_consumer_lag?labelSelector=name%3Dworker_tasks' | python3 -m json.tool | grep -E 'metricName|value'
