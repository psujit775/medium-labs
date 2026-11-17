# Upgrading off Kubernetes 1.31, rehearsed on kind (lab)

**This is an analogy, not a replay of EKS.** EKS manages the control plane for you; here
`kubeadm upgrade` inside a kind node stands in for `aws eks update-cluster-version`, and
replacing the kubelet binary stands in for a managed node group update. What *is* real:
the Kubernetes versions (1.31.14 -> 1.32.11), the removed API (`flowcontrol.apiserver.k8s.io/v1beta3`,
no longer served from 1.32), the API server warnings and metric, pluto/kubent output, and the
PodDisruptionBudget blocking a drain. None of the AWS-specific steps in the post were run here.

## Requirements
Docker, kind (tested with v0.33.0), kubectl, [pluto](https://github.com/FairwindsOps/pluto),
[kubent](https://github.com/doitintl/kube-no-trouble), internet access from the kind nodes
(they download `kubeadm`/`kubelet` from dl.k8s.io). About 6 minutes of run time, 3 nodes, ~2 GB RAM.

## Run
```bash
./setup.sh     # 3-node kind cluster on v1.31.14; deploys orders-api (1 replica + PDB) and v1beta3 APF objects
./check.sh     # what you should run first: pluto (files), kubent (cluster), deprecated-API metric, PDBs
./break.sh     # upgrade the control plane to v1.32.11 anyway, re-apply manifests, try to drain
./fix.sh       # move manifests to flowcontrol v1, replicas 2 in the manifest, drain + upgrade each kubelet
./cleanup.sh   # delete the cluster and reset the manifests
```
`TARGET=v1.32.11` can be overridden in break.sh and fix.sh.

## Tested on
Linux 6.12.113 x86_64, Docker 26.1.5, kind v0.33.0, kindest/node v1.31.14, kubeadm/kubelet v1.32.11,
kubectl v1.37.2, pluto 5.24.5, kubent 0.7.3. Run on 17 Nov 2026 (IST). Real output is in `output/`.

## What running it taught
See `output/earlier-run-notes.txt`: a `kubectl scale` that the next `kubectl apply` undid, a few
seconds of `Forbidden` for the admin user while the upgraded API server warmed up, and a second
replica with nowhere to go on a 2-node cluster.
