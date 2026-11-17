#!/usr/bin/env bash
cd "$(dirname "$0")"
kind delete cluster --name sandbox-lab
rm -rf run
echo "[cleanup] cluster deleted, ./run removed"
