# Setup Guide

This walks through every prerequisite from zero to a working HPA demo.

## Choose your Kubernetes environment

You need a Kubernetes cluster. Pick one:

| Option | Cost | Pros | Cons |
|---|---|---|---|
| **minikube** | Free | Easy local install | Single-node, fake CA |
| **kind** | Free | Lightweight, multi-node possible | Patched metrics-server needed |
| **k3d** | Free | Fast startup | Same metrics-server caveat |
| **EKS / GKE / AKS** | $$ | Real Cluster Autoscaler works | Costs $$ per hour |

For coursework, **minikube** is the recommended path.

## Prerequisites

Install these on your machine first:

```bash
# Linux / WSL2
sudo apt update
sudo apt install -y curl wget apt-transport-https

# 1. Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# log out / back in for the group change

# 2. kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 3. minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 4. Optional: helm (only if you want the monitoring dashboard)
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update && sudo apt install -y helm
```

## Start the cluster

```bash
# Single-node is enough for HPA demonstration
minikube start --cpus=4 --memory=4g --driver=docker

# Verify
kubectl get nodes
kubectl cluster-info
```

For Cluster Autoscaler demonstration via multi-node minikube (Option 1
from `k8s/cluster-autoscaler/README.md`):

```bash
minikube start --nodes=3 --cpus=2 --memory=2g --driver=docker
```

## Install metrics-server

HPA cannot scale without metrics-server. On minikube, the easy way:

```bash
minikube addons enable metrics-server
```

On kind / k3d / custom clusters, use the patched manifest:

```bash
kubectl apply -f k8s/metrics-server/components-patched.yaml
kubectl -n kube-system rollout status deploy/metrics-server
```

Verify:

```bash
# Should return non-zero CPU/memory after ~30s
kubectl top nodes
kubectl top pods -A
```

## Build the app image into minikube

Minikube has its own internal Docker daemon. Build directly there
so you don't have to push to a registry:

```bash
# Switch your local docker CLI to minikube's daemon
eval $(minikube docker-env)

# Build
docker build -t hpa-demo-app:1.0.0 ./app

# Verify it's there
docker images | grep hpa-demo-app

# (Optional) switch back when you're done
eval $(minikube docker-env -u)
```

## Deploy

The fastest way is the helper script:

```bash
./scripts/deploy.sh --minikube
```

Or manually:

```bash
kubectl apply -k k8s/base
kubectl -n hpa-demo rollout status deploy/hpa-demo-app
```

## Verify

```bash
kubectl -n hpa-demo get all
kubectl -n hpa-demo get hpa

# After ~30s, the TARGETS column should show real numbers like "1%/50%"
# If it shows "<unknown>/50%", metrics-server isn't ready yet.
```

You're ready to run the load test — see `docs/testing.md`.
