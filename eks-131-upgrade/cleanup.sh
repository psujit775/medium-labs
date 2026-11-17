#!/usr/bin/env bash
# Delete the cluster and put the manifests back to their "before" state.
cd "$(dirname "$0")"
kind delete cluster --name eks131-lab
sed -i 's#flowcontrol.apiserver.k8s.io/v1$#flowcontrol.apiserver.k8s.io/v1beta3#' manifests/apf.yaml
sed -i 's#replicas: 2#replicas: 1#' manifests/app.yaml
echo "[cleanup] cluster deleted, manifests reset"
