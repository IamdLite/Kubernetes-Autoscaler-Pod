# Metrics Server

The Horizontal Pod Autoscaler reads pod CPU and memory usage from the
**Kubernetes Metrics API** (`metrics.k8s.io`). That API is served by the
metrics-server, which is **not** installed by default on most clusters.

If `kubectl top pods` returns `error: Metrics API not available`, you need this.

## Option A — Install from upstream (recommended for real clusters)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Verify after ~30 seconds:

```bash
kubectl -n kube-system get deploy metrics-server
kubectl top nodes
kubectl top pods -A
```

## Option B — Patched install for minikube / kind / k3d

Local clusters serve kubelets with self-signed certificates that the
metrics-server rejects by default. Two ways to fix it:

### B.1 — On minikube, just enable the addon

```bash
minikube addons enable metrics-server
```

### B.2 — On kind / k3d / custom clusters, apply the patched manifest

The `components-patched.yaml` file in this directory is the upstream
components.yaml with one extra arg on the metrics-server container:
`--kubelet-insecure-tls`. This tells metrics-server to accept the
self-signed kubelet cert.

```bash
kubectl apply -f k8s/metrics-server/components-patched.yaml
```

Wait for the deployment to be ready, then verify:

```bash
kubectl -n kube-system rollout status deploy/metrics-server
kubectl top nodes
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `kubectl top` returns `Metrics API not available` | metrics-server pod not ready | `kubectl -n kube-system describe pod -l k8s-app=metrics-server` |
| HPA TARGETS column shows `<unknown>/50%` | metrics-server not running OR pod has no resource requests | Install metrics-server, ensure deployment has `resources.requests.cpu` |
| metrics-server pod crashlooping with TLS error on local cluster | self-signed kubelet certs | Use Option B.2 (`--kubelet-insecure-tls`) |
| Metrics show 0m for all pods | Wait 15–30 seconds; metrics-server scrapes every 15s | Be patient on first install |
