#!/usr/bin/env bash
cd "$(dirname "$0")"
for f in run/*.pid; do [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null; done
rm -rf run
echo "[cleanup] stopped all lab processes and removed ./run"
