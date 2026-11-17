#!/usr/bin/env bash
# The documented way: server-side apply of the full manifest, one minor at a time, check after each hop.
set -uo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-argocd-lab >/dev/null
mkdir -p run
for v in v3.4.13 v3.5.7 v3.6.1; do
  echo "=== hop to $v ==="
  kubectl -n argocd get cm argocd-cm argocd-cmd-params-cm argocd-rbac-cm -o yaml > run/backup-before-$v.yaml
  start=$(date +%s)
  kubectl apply -n argocd --server-side --force-conflicts \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/$v/manifests/install.yaml 2>&1 | grep -viE 'serverside-applied|unchanged' || true
  kubectl -n argocd rollout status deploy/argocd-server --timeout=300s >/dev/null
  kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s >/dev/null
  kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s >/dev/null
  echo "rollout took $(( $(date +%s) - start ))s"
  kubectl -n argocd annotate application guestbook argocd.argoproj.io/refresh=hard --overwrite >/dev/null
  sleep 30
  ./status.sh
  echo "errors in the last 3m (controller, repo-server, server):"
  for c in statefulset/argocd-application-controller deploy/argocd-repo-server deploy/argocd-server; do
    kubectl -n argocd logs $c --since=3m 2>/dev/null | grep -iE 'level=(error|fatal)|"level":"error"' | cut -c1-200 | sort -u | head -3
  done
  kubectl -n argocd get pods --no-headers | awk '$3!="Running" || $4!="0" {print "  pod:", $1, $3, "restarts="$4}'
done
echo "=== final ==="
kubectl -n argocd get deploy,sts -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image
argocd version --client --short
