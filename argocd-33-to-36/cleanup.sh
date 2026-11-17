#!/usr/bin/env bash
cd "$(dirname "$0")"
kind delete cluster --name argocd-lab
rm -rf run
echo "[cleanup] cluster deleted"
