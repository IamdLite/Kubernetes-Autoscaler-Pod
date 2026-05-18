#!/usr/bin/env bash
#
# Capture HPA scaling activity into a timestamped log file.
# Run this in a second terminal during your load test, then attach
# the resulting log to your report as proof of scaling behavior.
#
# Usage:
#   ./load-test/capture-scaling-events.sh           # 10 min default
#   ./load-test/capture-scaling-events.sh 1200      # 20 min capture

set -euo pipefail

DURATION="${1:-600}"      # seconds
NAMESPACE="hpa-demo"
OUTDIR="results"
mkdir -p "$OUTDIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${OUTDIR}/scaling-events-${TIMESTAMP}.log"

echo ">> Capturing HPA scaling for ${DURATION}s into: $LOG_FILE"
echo "===== HPA Scaling Capture =====" > "$LOG_FILE"
echo "Started:   $(date -Iseconds)" >> "$LOG_FILE"
echo "Namespace: $NAMESPACE"        >> "$LOG_FILE"
echo "Duration:  ${DURATION}s"      >> "$LOG_FILE"
echo ""                              >> "$LOG_FILE"

START=$(date +%s)
END=$((START + DURATION))

while [[ $(date +%s) -lt $END ]]; do
  {
    echo "---------- $(date -Iseconds) ----------"
    echo ">> HPA state:"
    kubectl -n "$NAMESPACE" get hpa 2>/dev/null || true
    echo ""
    echo ">> Pods:"
    kubectl -n "$NAMESPACE" get pods -o wide 2>/dev/null || true
    echo ""
    echo ">> Resource usage:"
    kubectl -n "$NAMESPACE" top pods 2>/dev/null || echo "  metrics-server not ready"
    echo ""
  } >> "$LOG_FILE"
  sleep 15
done

# Final summary
{
  echo "===== FINAL EVENTS ====="
  kubectl -n "$NAMESPACE" describe hpa hpa-demo-app
  echo ""
  echo "===== KUBERNETES EVENTS ====="
  kubectl -n "$NAMESPACE" get events \
    --sort-by='.lastTimestamp' \
    --field-selector reason=SuccessfulRescale 2>/dev/null || true
} >> "$LOG_FILE"

echo ">> Capture complete: $LOG_FILE"
