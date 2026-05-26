#!/usr/bin/env bash
#
# Tear everything down.
#
# Removes:
#   - load-test jobs
#   - the hpa-demo namespace (which removes the app, service, HPA, pods)
# Does NOT remove metrics-server (you'll usually want to keep that).
#
# Usage:
#   ./scripts/cleanup.sh
#   ./scripts/cleanup.sh --all     # also removes metrics-server

set -euo pipefail
REMOVE_METRICS=false

for arg in "$@"; do
  case "$arg" in
    --all) REMOVE_METRICS=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

echo "==> Removing load-test jobs (if any)"
kubectl -n hpa-demo delete job --all --ignore-not-found
kubectl -n hpa-demo delete pod load-generator --ignore-not-found

echo "==> Removing the hpa-demo namespace"
kubectl delete namespace hpa-demo --ignore-not-found

if $REMOVE_METRICS; then
  echo "==> Removing patched metrics-server"
  kubectl delete -f k8s/metrics-server/components-patched.yaml --ignore-not-found
fi

echo "==> Done"
