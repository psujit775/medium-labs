#!/usr/bin/env bash
# kind cluster on Kubernetes 1.37 with gVisor (runsc) added to containerd as a second runtime.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p run
kind create cluster --name sandbox-lab --image kindest/node:v1.37.0 --wait 120s
kubectl config use-context kind-sandbox-lab >/dev/null
N=sandbox-lab-control-plane
if [ ! -x run/gvisor/runsc ]; then
  U=https://storage.googleapis.com/gvisor/releases/release/latest/$(uname -m)
  curl -sSLo run/gvisor.tar.bz2 $U/gvisor.tar.bz2
  curl -sSLo run/gvisor.tar.bz2.sha512 $U/gvisor.tar.bz2.sha512
  (cd run && sha512sum -c gvisor.tar.bz2.sha512)
  mkdir -p run/gvisor
  python3 -c "import tarfile; tarfile.open('run/gvisor.tar.bz2','r:bz2').extractall('run/gvisor', filter='data')"
  chmod +x run/gvisor/runsc run/gvisor/containerd-shim-runsc-v1 run/gvisor/gvisor-bin/*
fi
docker cp run/gvisor/. $N:/usr/local/bin/
docker exec $N bash -c 'cat >> /etc/containerd/config.toml <<EOT

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOT
systemctl restart containerd'
sleep 5
docker exec $N runsc --version | sed -n 1p
kubectl apply -f manifests/runtimeclass.yaml
kubectl create configmap probe --from-file=manifests/probe.py
docker exec $N crictl pull python:3.13-alpine >/dev/null && echo "image pre-pulled"
kubectl get runtimeclass
echo "host kernel: $(uname -r)"
