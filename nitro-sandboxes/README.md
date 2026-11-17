# Sandboxed pods with a RuntimeClass, on kind with gVisor (lab)

**This is an analogy, not AWS Nitro Sandboxes.** Nitro Sandboxes run each pod in a Firecracker
microVM on EC2. This lab uses [gVisor](https://gvisor.dev) (`runsc`), a user-space kernel, because
it runs inside a kind node with no extra hardware. The Kubernetes side is the same idea: a
RuntimeClass, and one `runtimeClassName` line on the pods you don't trust.

## Requirements
Docker, kind, kubectl, curl, python3 (to unpack the gVisor tarball). Linux x86_64 or arm64 host
(gVisor needs Linux 5.6+). Runs in about 2 minutes.

## Run
```bash
./setup.sh     # kind 1.37, installs runsc into the node, RuntimeClass "gvisor", pre-pulls the image
./break.sh     # the "untrusted" Job on the default runtime: same kernel as the node
./fix.sh       # same Job with runtimeClassName: gvisor; then oci-seccomp on; startup and memory compared
./cleanup.sh
```
`manifests/probe.py` prints the kernel the container sees and tries ten kernel-level syscalls with
harmless or invalid arguments, reporting the errno for each.

## Tested on
Linux 6.12.113 x86_64, Docker 26.1.5, kind v0.33.0, kindest/node v1.37.0 (containerd 2.3.4),
gVisor release-20261109.0 (systrap platform). Run on 17 Nov 2026 (IST).

## What running it taught
With gVisor's defaults, the pod's `seccompProfile: RuntimeDefault` was not applied inside the
sandbox: `unshare(CLONE_NEWUSER)` and `syslog` succeeded (against gVisor's kernel, not the host's).
runsc only loads OCI seccomp filters with `--oci-seccomp`; fix.sh step 2 turns it on.
