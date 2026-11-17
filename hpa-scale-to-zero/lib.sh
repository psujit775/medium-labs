# helpers
setq() { kubectl run setq-$RANDOM --rm -i --restart=Never --image=curlimages/curl:8.17.0 --quiet -- \
  -s -X POST "http://fake-queue.default.svc:8000/set?n=$1" 2>/dev/null; }
hpa() { kubectl get hpa queue-worker -o jsonpath='{"replicas="}{.status.currentReplicas}{" desired="}{.status.desiredReplicas}{" metric="}{.status.currentMetrics[0].external.current.value}{"\n"}'; }
cond() { kubectl get hpa queue-worker -o jsonpath='{range .status.conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'; }
ts() { date +%H:%M:%S; }
