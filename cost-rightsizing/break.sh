#!/usr/bin/env bash
# Deploy the over-requested services, then try to ship one more small service.
set -euo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-cost-lab >/dev/null
kubectl apply -f manifests/shop.yaml
sleep 30
kubectl apply -f manifests/new-feature.yaml -f manifests/vpa.yaml
sleep 60   # let metrics-server collect a couple of samples
echo "--- pods ---"
kubectl get pods -n shop -o wide --no-headers | awk '{print $1, $3}' | sort -k2
echo "--- why is search Pending? ---"
kubectl get events -n shop --field-selector reason=FailedScheduling -o custom-columns=MSG:.message --no-headers | sort -u | head -2
echo "--- requests vs usage ---"
./report.sh
