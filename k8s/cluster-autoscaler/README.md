# Cluster Autoscaler

The **HPA** scales _pods_ within the existing cluster. The **Cluster Autoscaler (CA)**
scales the _cluster itself_ by adding or removing nodes when pods can't be scheduled
due to insufficient resources.

> **Important:** Cluster Autoscaler is **cloud-provider-specific**. It talks to
> the cloud's API (AWS Auto Scaling Groups, GCP MIGs, Azure VMSS, etc.) to add
> or remove nodes. It does NOT run on plain minikube or kind, because those
> don't have a "node pool" concept — they run on your laptop.

## Pick the path that matches your cluster

| Cluster type | What to use |
|---|---|
| AWS EKS | `cluster-autoscaler-aws.yaml` in this directory |
| GKE | Built-in — enable with `gcloud container clusters update ... --enable-autoscaling` |
| AKS | Built-in — enable in the portal or with `az aks update --enable-cluster-autoscaler` |
| minikube / kind / k3d | Demonstrate locally with **karpenter-on-kind** or skip and document why |

## For local clusters (no real CA possible)

If you're demonstrating this on minikube, you have two options:

### Option 1 — Simulate node scaling with multi-node minikube

Start minikube with multiple nodes:

```bash
minikube start --nodes=3 --cpus=2 --memory=2g
```

Then trigger the HPA to scale up enough pods that they have to be spread
across nodes. Capture `kubectl get pods -o wide` showing pods on different
nodes. This isn't true cluster autoscaling, but it shows the multi-node
scheduling behavior CA depends on.

### Option 2 — Document the limitation in your report

State plainly: "Cluster Autoscaler requires a cloud provider with elastic
node pools. Locally, we demonstrated HPA-driven pod autoscaling and provide
the production CA manifest for AWS EKS deployment."

This is what the TA's note likely expects — the **configuration file in the
repo** as evidence that you understand how it works.

## For AWS EKS

See `cluster-autoscaler-aws.yaml`. Before applying, you must:

1. **Tag your Auto Scaling Group** so CA can discover it:
   ```
   k8s.io/cluster-autoscaler/enabled                  = true
   k8s.io/cluster-autoscaler/<YOUR_CLUSTER_NAME>      = owned
   ```
2. **Create an IAM policy** for the CA service account (see file comments).
3. **Replace the placeholder** `<YOUR_CLUSTER_NAME>` in the manifest with your
   EKS cluster name.
4. Apply: `kubectl apply -f cluster-autoscaler-aws.yaml`

## Verifying CA works

After the HPA scales pods beyond what nodes can hold, you should see:

```bash
kubectl get events -n kube-system | grep -i "TriggeredScaleUp"
kubectl logs -n kube-system deploy/cluster-autoscaler | tail -50
kubectl get nodes -w
```

New nodes should appear within 2–5 minutes (depending on cloud provider speed).
