# Monitoring Dashboard (Optional)

The TA marked this as optional, but it's the part that makes your demo
look genuinely professional. This sets up **Prometheus + Grafana** and
loads a pre-built dashboard showing:

- HPA current/desired/min/max replicas over time
- Average CPU utilization per pod
- Average memory utilization per pod
- Request rate to the app
- Pod count over time

## Install with Helm (recommended)

The fastest path is the `kube-prometheus-stack` Helm chart, which
installs Prometheus, Grafana, Alertmanager, and a bunch of useful
default dashboards in one shot.

```bash
# Add the helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install in the monitoring namespace
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/prometheus-values.yaml

# Wait for everything
kubectl -n monitoring rollout status deploy/monitoring-grafana
```

## Access Grafana

```bash
# Default admin password (set in values file): admin-demo-password
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
# Open http://localhost:3000
# Username: admin
# Password: admin-demo-password
```

## Load the HPA dashboard

The dashboard JSON is `grafana-dashboard-hpa.json` in this directory.

In Grafana:
1. Left sidebar -> Dashboards -> New -> Import
2. Click "Upload JSON file"
3. Select `monitoring/grafana-dashboard-hpa.json`
4. Pick the "Prometheus" datasource when prompted

## What to capture for your report

While your load test is running, screenshot:
1. The **Replicas** panel as it climbs from 2 -> 6 -> 10
2. The **CPU Utilization** panel showing utilization spiking past the 50% target
3. The **Pods Running** panel after scale-down kicks in 5 min after load stops

## Lightweight alternative: kubectl + a screenshot

If you don't want to install the whole Helm stack, you can simply
screenshot the output of `./scripts/watch.sh` running during a load
test. It's not pretty, but it proves the same point.
