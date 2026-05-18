# Testing Playbook

This is the script for your live demo. Three terminals, one load test,
clear evidence of scaling.

## Terminal layout

| Terminal | Purpose |
|---|---|
| 1 | Watch HPA + pods live (`./scripts/watch.sh`) |
| 2 | Capture scaling events to a log file |
| 3 | Run the load generator |

## Step 1 — Baseline screenshot (terminal 1)

Before any load, run the watch script and capture the baseline:

```bash
./scripts/watch.sh
```

Expected output:

```
=== HPA ===
NAME           REFERENCE                 TARGETS                MINPODS  MAXPODS  REPLICAS
hpa-demo-app   Deployment/hpa-demo-app   cpu: 1%/50%, mem: 8%/70%   2       10       2

=== PODS ===
NAME                            READY  STATUS    RESTARTS  AGE
hpa-demo-app-7d8f5b6f9c-abc12   1/1    Running   0         2m
hpa-demo-app-7d8f5b6f9c-def34   1/1    Running   0         2m
```

**Screenshot this.** It's your "before" picture.

## Step 2 — Start capturing events (terminal 2)

This logs HPA state every 15 seconds for 10 minutes into a file:

```bash
./load-test/capture-scaling-events.sh 600
```

You'll attach the resulting log (in `results/`) to your report.

## Step 3 — Launch the load test (terminal 3)

Pick ONE of these:

### Option A — Simple busybox loop (quickest)

```bash
./load-test/load-test-simple.sh
```

### Option B — k6 (more rigorous, recommended for the report)

```bash
kubectl apply -f load-test/k6-load-test.yaml

# Follow output:
kubectl -n hpa-demo logs -f job/k6-load-test
```

### Option C — hey (middle ground)

```bash
kubectl apply -f load-test/hey-load-test.yaml
kubectl -n hpa-demo logs -f job/hey-load-test
```

## Step 4 — Watch the magic (terminal 1)

Within **30 to 60 seconds** of load starting, you should see:

```
=== HPA ===
NAME           TARGETS                       REPLICAS
hpa-demo-app   cpu: 187%/50%, mem: 12%/70%   2  ->  ramping up

=== PODS ===
NAME                            READY  STATUS              AGE
hpa-demo-app-7d8f5b6f9c-abc12   1/1    Running             3m
hpa-demo-app-7d8f5b6f9c-def34   1/1    Running             3m
hpa-demo-app-7d8f5b6f9c-ghi56   0/1    ContainerCreating   2s
hpa-demo-app-7d8f5b6f9c-jkl78   0/1    Pending             1s
```

**Screenshot at peak scale-up.** This is your "during" picture.

Within 2 to 3 minutes, replicas should hit `maxReplicas: 10` (or whatever
number balances out the load). HPA recalculates every ~15 seconds.

## Step 5 — Stop the load

```bash
# Option A — Ctrl-C in terminal 3
# Option B/C — delete the job
kubectl -n hpa-demo delete job k6-load-test    # or hey-load-test
```

## Step 6 — Watch scale-down (terminal 1)

The HPA `behavior.scaleDown.stabilizationWindowSeconds` is **300s** by
design, so nothing happens for 5 minutes. This avoids flapping.

After ~5 minutes of low CPU, replicas will drop back to the `minReplicas: 2`
floor. Capture this in the log too.

**Screenshot when back to baseline.** That's your "after" picture.

## Step 7 — Pull the evidence

```bash
# HPA history
kubectl -n hpa-demo describe hpa hpa-demo-app > results/hpa-describe.txt

# All scale events
kubectl -n hpa-demo get events --sort-by='.lastTimestamp' \
  --field-selector reason=SuccessfulRescale > results/scale-events.txt

# Pod history (showing pods created/destroyed)
kubectl -n hpa-demo get events --sort-by='.lastTimestamp' > results/all-events.txt
```

You now have:

- `results/scaling-events-<timestamp>.log` — minute-by-minute HPA state
- `results/hpa-describe.txt` — HPA's own event log
- `results/scale-events.txt` — every scale-up/down event
- Screenshots: before, during, after

That's plenty of evidence for your report.

## Troubleshooting during the demo

| Problem | Quick fix |
|---|---|
| HPA TARGETS shows `<unknown>/50%` | metrics-server not ready: `kubectl -n kube-system get pods` |
| Pods stuck in `Pending` | Node is out of capacity. Reduce `maxReplicas` to 6 or `cpu.limits` to 200m. |
| Load generator pod won't start | Service DNS may not be resolving: `kubectl -n hpa-demo get svc` |
| Scale-up too slow | Lower the `stabilizationWindowSeconds` in the HPA manifest |
| Scale-down never happens | The 5-min stabilization window hasn't elapsed yet. Be patient. |
