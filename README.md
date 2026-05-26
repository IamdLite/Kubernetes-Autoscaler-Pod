# Kubernetes Pod Autoscaler Setup

> Coursework project — deploy a web app, configure HPA on CPU/memory,
> set up the metrics server, include Cluster Autoscaler configuration,
> load-test the stack to trigger autoscaling, and document the result.

## What's in here

```
k8s-pod-autoscaler/
├── README.md                          <- you are here
├── app/                               <- the sample web application
│   ├── Dockerfile                     <- multi-stage build, non-root
│   ├── package.json
│   ├── server.js                      <- /cpu and /memory load endpoints
│   └── .dockerignore
├── k8s/
│   ├── base/                          <- core manifests, apply with `kubectl apply -k`
│   │   ├── 00-namespace.yaml
│   │   ├── 01-deployment.yaml         <- with resource requests (HPA needs these)
│   │   ├── 02-service.yaml
│   │   ├── 03-hpa.yaml                <- autoscaling/v2 — CPU + memory targets
│   │   └── kustomization.yaml
│   ├── metrics-server/                <- prerequisite for HPA on resource metrics
│   │   ├── README.md
│   │   └── components-patched.yaml    <- for kind/k3d/custom (--kubelet-insecure-tls)
│   └── cluster-autoscaler/            <- node-level scaling
└── results/                           <- captured logs land here

utility/                               <- NOT part of PoC
├── load-test/
│   ├── load-test-simple.sh            <- busybox while-loop (classic)
│   ├── k6-load-test.yaml              <- 100 VUs, 7-min profile (recommended)
│   ├── hey-load-test.yaml             <- simple HTTP benchmark alternative
│   └── capture-scaling-events.sh      <- logs HPA state every 15s
├── monitoring/                        <- optional Grafana dashboard
│   ├── README.md
│   ├── prometheus-values.yaml         <- helm values for kube-prometheus-stack
│   └── grafana-dashboard-hpa.json     <- importable HPA dashboard
├── scripts/
│   ├── deploy.sh                      <- one-shot deploy
│   ├── cleanup.sh                     <- tear down
│   └── watch.sh                       <- live HPA + pods view
├── docs/
    ├── setup.md                       <- step-by-step environment setup
    ├── testing.md                     <- the load-test playbook
    └── results-template.md            <- fill this in after the demo

```

## How the pieces fit together

```
                        ┌──────────────────────────────┐
                        │   metrics-server              │
                        │   (kube-system namespace)     │
                        │   scrapes pod CPU/memory      │
                        │   every 15s                   │
                        └────────────┬─────────────────┘
                                     │ metrics.k8s.io API
                                     ▼
   ┌─────────────────────────┐   ┌─────────────────────────┐
   │  HorizontalPodAutoscaler│◀──┤  Deployment             │
   │  cpu: 50% target        │   │  hpa-demo-app           │
   │  mem: 70% target        │   │  replicas: 2..10        │
   │  min: 2,  max: 10       │──▶│  cpu req: 100m          │
   └─────────────────────────┘   │  mem req: 128Mi         │
              ▲                  └───────────┬─────────────┘
              │                              │
   ┌──────────┴──────────┐                   ▼
   │  Cluster Autoscaler │            ┌──────────────┐
   │  (cloud only)       │            │   Service    │
   │  adds nodes when    │            │   ClusterIP  │
   │  pods are Pending   │            └──────┬───────┘
   └─────────────────────┘                   │
                                             ▼
                               ┌────────────────────────────┐
                               │  Load test (k6 / hey /     │
                               │  busybox) hammers /cpu     │
                               │  -> CPU rises above 50%    │
                               │  -> HPA scales pods up     │
                               └────────────────────────────┘
```

## Quick start

```bash
# 1. Start a cluster (any K8s cluster works; minikube is easiest)
minikube start --cpus=4 --memory=4g

# 2. Install metrics-server (HPA needs it)
minikube addons enable metrics-server
# (or, on non-minikube clusters:
#   kubectl apply -f k8s/metrics-server/components-patched.yaml )

# 3. Build the app image into the cluster
eval $(minikube docker-env)
docker build -t hpa-demo-app:1.0.0 ./app

# 4. Deploy everything
kubectl apply -k k8s/base

# 5. Confirm
kubectl -n hpa-demo get hpa,deploy,pods
# Expect: TARGETS column shows real numbers within ~30s

# 6. In another terminal: watch the HPA live
./scripts/watch.sh

# 7. In a third terminal: generate load
kubectl apply -f load-test/k6-load-test.yaml
# or the quick way:
./load-test/load-test-simple.sh
```

See **`docs/setup.md`** for the full walkthrough and **`docs/testing.md`**
for the demo playbook.

## Deliverables checklist

This is what the TA asked for, mapped to files in this repo:

- [x] Deployment YAML — `k8s/base/01-deployment.yaml`
- [x] Service YAML — `k8s/base/02-service.yaml`
- [x] HPA configuration — `k8s/base/03-hpa.yaml` (CPU + memory)
- [x] Metrics server deployment — `k8s/metrics-server/components-patched.yaml`
- [x] Cluster Autoscaler config — `k8s/cluster-autoscaler/cluster-autoscaler-aws.yaml`
- [x] Build files (Dockerfile, app source) — `app/`
- [x] Load test — `load-test/` (three flavors)
- [x] Monitoring dashboard (optional) — `monitoring/grafana-dashboard-hpa.json`
- [ ] Load test results — fill in `docs/results-template.md` after running

## Tech stack

- **Kubernetes** 1.28+ (autoscaling/v2 HPA API)
- **Docker** (multi-stage build, non-root runtime)
- **Node.js 20** (sample app)
- **metrics-server** v0.7.2
- **Cluster Autoscaler** v1.30.0 (AWS provider)
- **k6** / **hey** / **busybox** for load generation
- **Prometheus + Grafana** for the optional dashboard

## License

MIT. Coursework — do whatever you want with it.
# Kubernetes-Autoscaler-Pod
