# Requests vs real usage: right-sizing on kind (lab)

**This is an analogy for an EKS node group.** One kind node with 8 CPUs plays the part of the
capacity you pay for. Nothing here touches AWS or prices; the point is the gap between what pods
*request* (what you pay for on a node) and what they *use*.

## Requirements
Docker, kind, kubectl, python3. Internet access for metrics-server and VPA manifests.
About 10 minutes, most of it waiting for the VPA recommender to collect samples.

## Run
```bash
./setup.sh     # kind 1.37 (kube-proxy nftables), metrics-server v0.9.1, VPA recommender 1.8.1
./break.sh     # 3 services at 1 CPU / 1Gi each, then a new service that can't schedule
./fix.sh       # waits VPA_WAIT seconds (default 300), prints recommendations, applies smaller requests
./report.sh    # requests vs usage, any time
./cleanup.sh
```

## Tested on
Linux 6.12.113 x86_64, Docker 26.1.5, kind v0.33.0, kindest/node v1.37.0, metrics-server v0.9.1,
vertical-pod-autoscaler 1.8.1. Run on 17 Nov 2026 (IST). In that run fix.sh was started with
`VPA_WAIT=0` about six minutes after the VPAs were created, and it was interrupted in its final
`sleep 60`; the last two report steps were run by hand (noted in `output/03-fix.txt`).

## What running it taught
- After ~6 minutes the VPA targets sat on the recommender's floors (25m CPU, 250Mi memory) and the
  upper bounds were huge (up to 27 CPUs and 53.8Gi). Upper bounds shrink as history grows; don't
  size from them on day one.
- The new `search` service, the one that couldn't schedule, was itself the most over-requested
  thing after the fix (1000m requested, 2m used).
