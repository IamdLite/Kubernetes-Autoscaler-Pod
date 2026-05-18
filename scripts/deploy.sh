#!/usr/bin/env bash
#
# One-shot deploy script. Brings up everything needed for the HPA demo.
#
# Usage:
#   ./scripts/deploy.sh                   # assume metrics-server already installed
#   ./scripts/deploy.sh --with-metrics    # also install the patched metrics-server
#   ./scripts/deploy.sh --minikube        # build the image into minikube's docker

set -euo pipefail

WITH_METRICS=false
MINIKUBE_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --with-metrics) WITH_METRICS=true ;;
    --minikube)     MINIKUBE_BUILD=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Step 1: Build the app image"
if $MINIKUBE_BUILD; then
  echo "    Pointing docker CLI at minikube's daemon..."
  eval "$(minikube docker-env)"
fi
docker build -t hpa-demo-app:1.0.0 ./app

if $WITH_METRICS; then
  echo "==> Step 2: Install metrics-server (patched for local clusters)"
  kubectl apply -f k8s/metrics-server/components-patched.yaml
  echo "    Waiting for metrics-server to be ready..."
  kubectl -n kube-system rollout status deploy/metrics-server --timeout=120s
fi

echo "==> Step 3: Deploy app + service + HPA"
kubectl apply -k k8s/base

echo "==> Step 4: Wait for the deployment to be ready"
kubectl -n hpa-demo rollout status deploy/hpa-demo-app --timeout=120s

echo ""
echo "==> Done. Current state:"
kubectl -n hpa-demo get all
echo ""
kubectl -n hpa-demo get hpa
echo ""
echo "Next steps:"
echo "  - watch HPA:   watch -n 2 'kubectl -n hpa-demo get hpa,pods'"
echo "  - run load:    ./load-test/load-test-simple.sh"
echo "  - or k6 load:  kubectl apply -f load-test/k6-load-test.yaml"
