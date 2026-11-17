# medium-labs

Small local labs that go with my Medium posts. Each folder has one problem and one fix, runs on a
laptop with no cloud account, and keeps the real output from the run the post is based on in `output/`.

Every lab says what it is:
- **Replay**: the real software and versions, doing the real thing (on a local cluster).
- **Analogy**: the same failure pattern in miniature, with stand-ins for the real system.

| Folder | Post | Type | Needs |
| --- | --- | --- | --- |
| [eks-131-upgrade](eks-131-upgrade/) | Getting Off EKS 1.31: A Step-by-Step Upgrade, Rehearsed on kind | Analogy (kind + kubeadm stand in for EKS) | Docker, kind, kubectl, pluto, kubent |
| [nitro-sandboxes](nitro-sandboxes/) | Running Untrusted Code on EKS with Nitro Sandboxes | Analogy (gVisor stands in for Nitro) | Docker, kind, kubectl |
| [cost-rightsizing](cost-rightsizing/) | Right-Sizing Kubernetes Requests: The Step That Cuts Your AWS Bill | Analogy (one kind node stands in for a node group) | Docker, kind, kubectl |
| [argocd-33-to-36](argocd-33-to-36/) | Upgrading Argo CD from 3.3 to 3.6, One Minor Version at a Time | Replay | Docker, kind, kubectl |
| [hpa-scale-to-zero](hpa-scale-to-zero/) | Scaling Queue Workers to Zero with the HPA in Kubernetes 1.37 | Replay (fake queue) | Docker, kind, kubectl, helm |
| [cloudflare-feature-file](cloudflare-feature-file/) | Outage, Explained: Cloudflare's Oversized Feature File | Analogy | Python 3 only |

Each folder has the same scripts:

```bash
./setup.sh    # build the starting point
./break.sh    # show the problem
./fix.sh      # apply the fix and show the result
./cleanup.sh  # delete the cluster / processes
```

## Notes from the test machine

All labs were run on 17 Nov 2026 (IST) on Linux 6.12.113 x86_64 with Docker 26.1.5 and kind v0.33.0.
Two things were specific to that machine and may not apply to yours:

- Its kernel had no `xt_statistic` module, so kube-proxy's default iptables mode failed to program
  Service rules (`RULE_APPEND failed`). The kind configs set `kubeProxyMode: nftables`, which works
  on any recent kernel.
- Docker's user-defined networks had no outbound access until legacy-iptables FORWARD rules were
  added for `br-+` interfaces, because of pre-existing rules on the host. If `kind` nodes can't
  pull images or reach dl.k8s.io, check your host firewall before anything else.

## License

MIT, see [LICENSE](LICENSE).
