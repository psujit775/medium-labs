#!/usr/bin/env bash
# The pre-upgrade checks you should run first: files, live cluster, API server metric, PDBs.
set -uo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-eks131-lab >/dev/null
echo "--- pluto: scan the manifests in Git for APIs removed by 1.32 ---"
pluto detect-files -d manifests/ --target-versions k8s=v1.32.0 -o wide
echo "--- kubent: scan the live cluster ---"
kubent --target-version 1.32.0 2>/dev/null
echo "--- API server: which deprecated APIs have clients actually called? ---"
kubectl get --raw /metrics | grep '^apiserver_requested_deprecated_apis'
echo "--- PDBs that allow zero disruptions (these block a node drain) ---"
kubectl get pdb -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,ALLOWED:.status.disruptionsAllowed
