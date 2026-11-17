#!/usr/bin/env bash
# The fix: same job, one extra line (runtimeClassName: gvisor).
# Step 2 turns on gVisor's OCI seccomp support, which is off by default (see README).
# Step 3 compares startup time and memory.
set -euo pipefail
cd "$(dirname "$0")"
kubectl config use-context kind-sandbox-lab >/dev/null
N=sandbox-lab-control-plane
run_job() {  # $1 = job suffix
  sed -e "s/RUNTIME/$1/" -e 's/# runtimeClassName: gvisor/runtimeClassName: gvisor/' manifests/untrusted-job.yaml | kubectl apply -f - >/dev/null
  kubectl wait --for=condition=complete job/untrusted-$1 --timeout=120s >/dev/null
  kubectl logs job/untrusted-$1
}
echo "--- 1. job on gVisor (runtimeClassName: gvisor) ---"
run_job gvisor

echo "--- 2. enable oci-seccomp in runsc so the pod's RuntimeDefault profile is applied inside the sandbox ---"
docker exec $N bash -c 'printf "[runsc_config]\n  oci-seccomp = \"true\"\n" > /etc/containerd/runsc.toml
cat >> /etc/containerd/config.toml <<EOT
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc.options]
  TypeUrl = "io.containerd.runsc.v1.options"
  ConfigPath = "/etc/containerd/runsc.toml"
EOT
systemctl restart containerd'
sleep 5
run_job gvisor-seccomp

echo "--- 3. startup: kubectl run -> pod Ready, 5 pods per runtime, image already on the node ---"
for rt in runc gvisor; do
  t=()
  for i in 1 2 3 4 5; do
    rc=""; [ $rt = gvisor ] && rc='"runtimeClassName":"gvisor",'
    s=$(date +%s.%N)
    kubectl run start-$rt-$i --image=python:3.13-alpine --restart=Never \
      --overrides="{\"spec\":{${rc}\"containers\":[{\"name\":\"c\",\"image\":\"python:3.13-alpine\",\"command\":[\"sleep\",\"300\"]}]}}" >/dev/null
    kubectl wait --for=condition=Ready pod/start-$rt-$i --timeout=120s >/dev/null
    t+=("$(python3 -c "print(f'{$(date +%s.%N)-$s:.2f}')")")
  done
  echo "$rt: ${t[*]} seconds"
done
echo "--- 4. memory: what each sleeping pod costs on the node (RSS, KiB) ---"
docker exec $N sh -c 'echo "runc pods   : $(ps -eo rss,args | grep "[s]leep 300" | grep -v runsc | awk "{print \$1}" | xargs)"; echo "gVisor Sentry per pod: $(ps -eo rss,comm | grep gvisor_sentry | awk "{print \$1}" | xargs)"'
