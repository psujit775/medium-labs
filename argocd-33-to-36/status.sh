#!/usr/bin/env bash
# One-line health check after each hop.
kubectl config use-context kind-argocd-lab >/dev/null
img=$(kubectl -n argocd get deploy argocd-server -o jsonpath='{.spec.template.spec.containers[0].image}')
app=$(kubectl -n argocd get application guestbook -o jsonpath='{.status.sync.status}/{.status.health.status}')
pod=$(kubectl -n guestbook get pod -l app=guestbook-ui -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
echo "server image: $img | guestbook: $app | guestbook pod: $pod"
