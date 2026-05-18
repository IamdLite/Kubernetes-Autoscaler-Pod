# Load Test Results

> **Fill this in after running the demo. Replace the bracketed placeholders.**

## Test environment

| Item | Value |
|---|---|
| Date | [YYYY-MM-DD] |
| Cluster | minikube vX.Y.Z / EKS / GKE / etc. |
| Kubernetes version | [output of `kubectl version --short`] |
| Node count | [number of nodes] |
| Node specs | [CPU / RAM per node] |
| metrics-server version | v0.7.2 (or whatever you used) |

## App configuration

| Item | Value |
|---|---|
| Image | hpa-demo-app:1.0.0 |
| Initial replicas | 2 |
| CPU request / limit | 100m / 500m |
| Memory request / limit | 128Mi / 256Mi |

## HPA configuration

| Item | Value |
|---|---|
| minReplicas | 2 |
| maxReplicas | 10 |
| CPU target | 50% utilization |
| Memory target | 70% utilization |
| scaleUp stabilization | 30 seconds |
| scaleDown stabilization | 300 seconds |

## Load profile

| Item | Value |
|---|---|
| Tool used | k6 / hey / busybox loop |
| Concurrency / VUs | [e.g. 100 VUs] |
| Duration | [e.g. 7 minutes total] |
| Target endpoint | /cpu (CPU-bound) |

## Observed behavior

### Phase 1 — Baseline (t = 0)

- Replicas: **2**
- Avg CPU utilization: **[X]%** of request
- Avg memory utilization: **[X]%** of request
- (attach `screenshot-baseline.png`)

### Phase 2 — Load applied (t = 0 to t = 7m)

- Time to first scale-up: **[X] seconds** after load applied
- Peak replicas reached: **[X]** (out of max 10)
- Time to reach peak: **[X] minutes / seconds**
- Peak avg CPU utilization: **[X]%**
- (attach `screenshot-during-load.png`)

### Phase 3 — Load stopped (t = 7m to t = 15m)

- Time scale-down started: **[X] minutes** after load stopped (expected: ~5min stabilization)
- Time to return to minReplicas: **[X] minutes**
- (attach `screenshot-scaled-down.png`)

## Scale events captured

Reference `scaling-events-<timestamp>.log` and `scale-events.txt`.
Summary of `SuccessfulRescale` events:

| Time | From | To | Reason |
|---|---|---|---|
| [HH:MM:SS] | 2 | 4 | cpu resource utilization above target |
| [HH:MM:SS] | 4 | 8 | cpu resource utilization above target |
| [HH:MM:SS] | 8 | 10 | cpu resource utilization above target |
| [HH:MM:SS] | 10 | 5 | All metrics below target |
| [HH:MM:SS] | 5 | 2 | All metrics below target |

## Conclusion

The Horizontal Pod Autoscaler successfully scaled the `hpa-demo-app`
deployment in response to load:

- Scale-up was triggered within **[X] seconds** of CPU utilization
  exceeding the 50% target threshold.
- The deployment scaled from 2 to **[X]** replicas at peak load.
- The 5-minute scale-down stabilization window prevented thrashing
  and the deployment correctly returned to its 2-replica baseline
  after sustained low load.

### About the Cluster Autoscaler

Cluster Autoscaler is included as a configuration deliverable
(`k8s/cluster-autoscaler/cluster-autoscaler-aws.yaml`) for AWS EKS.
Because this lab uses a [minikube / kind] cluster — which does not
have an elastic node pool — the live Cluster Autoscaler behavior
was not exercised. The HPA exhausted in-cluster resources at
**[X] replicas** before any pods would have been left in `Pending`
state requiring node-level scaling.

## Attached files

- `scaling-events-<timestamp>.log`
- `hpa-describe.txt`
- `scale-events.txt`
- `all-events.txt`
- `screenshot-baseline.png`
- `screenshot-during-load.png`
- `screenshot-scaled-down.png`
- `screenshot-grafana-dashboard.png` (optional)
