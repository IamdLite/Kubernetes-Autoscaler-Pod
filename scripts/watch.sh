#!/usr/bin/env bash
#
# Convenience wrapper around `watch` to monitor HPA + pods live.
# Run this in a side terminal during the load test for screenshots.

set -euo pipefail
NAMESPACE="hpa-demo"

if ! command -v watch >/dev/null; then
  echo "ERROR: 'watch' not found. Install procps-ng (Linux) or watch via brew (macOS)."
  exit 1
fi

watch -n 2 "
  echo '=== HPA ==='
  kubectl -n $NAMESPACE get hpa
  echo
  echo '=== PODS ==='
  kubectl -n $NAMESPACE get pods -o wide
  echo
  echo '=== TOP PODS ==='
  kubectl -n $NAMESPACE top pods 2>/dev/null || echo '(metrics not ready)'
"
