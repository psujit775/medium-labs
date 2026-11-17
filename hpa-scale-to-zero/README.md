# HPA scale-to-zero on Kubernetes 1.37 with a queue metric (lab)

**This is a replay of the Kubernetes feature, with a fake queue.** The cluster is real Kubernetes
1.37 (kind), where the `HPAScaleToZero` feature gate is beta and on by default. The HPA, the
External Metrics API, Prometheus and the Prometheus Adapter are real. The queue is a 20-line
Python server whose `queue_consumer_lag` value you set by hand. Nothing here runs on EKS.

## Requirements
Docker, kind, kubectl, helm, python3, internet access. About 5 minutes, ~1.5 GB RAM.

## Run
```bash
./setup.sh     # kind 1.37, fake queue, Prometheus (5s scrape), Prometheus Adapter, worker at 1 replica
./break.sh     # minReplicas 0 with a CPU-only HPA (rejected); a worker scaled to 0 by hand (never wakes)
./fix.sh       # HPA takes the worker to 0 itself; queue=45 wakes it (cold start timed); burst; back to 0
./cleanup.sh
```
`lib.sh` has the helpers (`setq 42` sets the queue length from inside the cluster).

## Tested on
Linux 6.12.113 x86_64, Docker 26.1.5, kind v0.33.0, kindest/node v1.37.0 (kube-proxy nftables),
Prometheus v3.16.0, prometheus-adapter chart 5.4.2 (v0.12.0), Helm v4.3.2. Run on 17 Nov 2026 (IST).

## What running it taught
- Prometheus 3 marked the first version of the fake exporter `down` because it sent no
  Content-Type header, while the adapter's APIService still said `Available: True`
  (`output/earlier-run-notes.txt`). Check the metric itself, not just the APIService.
- A Deployment scaled to 0 by hand stays at 0 even with work queued: the HPA reports
  `ScalingActive=False (ScalingDisabled)`.
- Cold start from the queue filling to the first Ready worker was 10.4 s with the image cached.
