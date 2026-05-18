#!/usr/bin/env bash
#
# Simple in-cluster load generator.
#
# Spawns a busybox pod that hammers the demo app's /cpu endpoint in
# a tight loop. This is the classic Kubernetes HPA demo pattern.
#
# Usage:
#   ./load-test/load-test-simple.sh           # run forever (Ctrl-C to stop)
#   ./load-test/load-test-simple.sh 300       # run for 300 seconds
#
# In another terminal, watch the HPA react:
#   watch -n 2 'kubectl -n hpa-demo get hpa,pods'

set -euo pipefail

DURATION="${1:-0}"   # 0 = forever
TARGET="http://hpa-demo-app.hpa-demo.svc.cluster.local/cpu"
NAMESPACE="hpa-demo"

echo ">> Starting load generator pod"
echo ">> Target: $TARGET"

if [[ "$DURATION" -gt 0 ]]; then
  echo ">> Duration: ${DURATION}s"
  CMD="timeout ${DURATION} sh -c 'while true; do wget -q -O- ${TARGET} >/dev/null; done'"
else
  echo ">> Duration: forever (Ctrl-C to stop)"
  CMD="while true; do wget -q -O- ${TARGET} >/dev/null; done"
fi

kubectl run -i --tty load-generator \
  --rm \
  --image=busybox:1.36 \
  --restart=Never \
  --namespace="$NAMESPACE" \
  -- /bin/sh -c "$CMD"
