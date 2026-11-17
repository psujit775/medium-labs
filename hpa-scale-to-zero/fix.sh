#!/usr/bin/env bash
# Start the worker at 1, let the HPA take it to zero itself, then wake it and time the cold start.
set -uo pipefail
cd "$(dirname "$0")"; . ./lib.sh
kubectl config use-context kind-hpa-zero-lab >/dev/null
echo "--- 1. give the HPA a running workload (1 replica) ---"
kubectl delete hpa queue-worker >/dev/null
kubectl scale deploy/queue-worker --replicas=1
kubectl rollout status deploy/queue-worker --timeout=120s >/dev/null
kubectl apply -f manifests/hpa.yaml
echo "--- 2. queue drains to 0, wait for the HPA to scale to zero ---"
setq 0; t0=$(date +%s)
for i in $(seq 1 60); do
  [ "$(kubectl get deploy queue-worker -o jsonpath='{.spec.replicas}')" = "0" ] && break; sleep 5
done
echo "$(ts) scaled to zero $(( $(date +%s) - t0 ))s after the queue emptied: $(hpa)"
cond
echo "--- 3. work arrives: queue=45, time until a worker pod is Ready (cold start) ---"
setq 45; t0=$(date +%s.%N)
until [ "$(kubectl get deploy queue-worker -o jsonpath='{.status.readyReplicas}')" -ge 1 ] 2>/dev/null; do sleep 0.5; done
t1=$(date +%s.%N)
echo "$(ts) first worker Ready after $(python3 -c "print(f'{$t1-$t0:.1f}')")s"
sleep 20
echo "$(ts) $(hpa)"
kubectl get hpa queue-worker -o jsonpath='{range .status.conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}' | grep ScaledToZero || true
echo "--- 4. a burst: queue=200 ---"
setq 200; sleep 30
echo "$(ts) $(hpa)"
echo "--- 5. queue empties again ---"
setq 0; t0=$(date +%s)
for i in $(seq 1 60); do
  [ "$(kubectl get deploy queue-worker -o jsonpath='{.spec.replicas}')" = "0" ] && break; sleep 5
done
echo "$(ts) back at zero after $(( $(date +%s) - t0 ))s: $(hpa)"
echo "--- HPA events ---"
kubectl get events --field-selector involvedObject.kind=HorizontalPodAutoscaler -o custom-columns=REASON:.reason,MSG:.message --no-headers | tail -8
