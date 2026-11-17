# Argo CD 3.3.19 -> 3.4.13 -> 3.5.7 -> 3.6.1 on kind (lab)

**This is a replay.** The versions and manifests are the real upstream ones
(`manifests/install.yaml` at each tag), installed on a kind cluster running Kubernetes 1.35,
which is inside the tested range of both 3.3 and 3.6. The workload is the upstream guestbook example.
It is a stock, non-HA install with no SSO, Helm/OCI repos, tracing or custom health checks,
so it can't show breakage in those areas.

## Requirements
Docker, kind, kubectl, internet access (GitHub raw, quay.io, ghcr.io). About 6 minutes, ~1.5 GB RAM.

## Run
```bash
./setup.sh     # kind 1.35 + Argo CD v3.3.19 + guestbook (auto-sync)
./break.sh     # the shortcut: client-side `kubectl apply` of v3.4.13 -> fails half-way
./fix.sh       # server-side apply, one minor at a time, with a backup and a check after each hop
./status.sh    # one-line status any time
./cleanup.sh
```

## Tested on
Linux 6.12.113 x86_64, Docker 26.1.5, kind v0.33.0, kindest/node v1.35.8 (kube-proxy nftables),
kubectl v1.37.2, argocd CLI v3.6.1. Run on 17 Nov 2026 (IST).

## What running it taught
The client-side apply exited 1 on the ApplicationSet CRD (`metadata.annotations: Too long`) but had
already rolled every Argo CD workload to v3.4.13. It also left a full copy of each object in a
`last-applied-configuration` annotation (`output/04-extra-checks.txt`).
