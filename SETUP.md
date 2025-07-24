# Bookly API with Kubernetes and Observability

This guide will walk you through setting up the Bookly API on Kubernetes with a complete observability stack.

## Prerequisites

Make sure you have the following tools installed:

- Docker
- KinD (Kubernetes in Docker)
- kubectl
- Helm
- k6 (for load testing)

## Step 1: Build the Docker Image

```bash
make build
```

This will build a lightweight Docker image (under 100MB) based on Alpine Linux.

## Step 2: Create a KinD Cluster

```bash
make create-cluster
```

This will create a Kubernetes cluster with one control plane node and two worker nodes.

## Step 3: Install NGINX Ingress Controller

```bash
make install-nginxingresscontroller
```

Wait for the ingress controller to be ready:

```bash
kubectl get pods -n ingress-nginx
```

## Step 4: Load the Docker Image to KinD

```bash
make load-image-to-kind
```

This will load the Docker image into the KinD cluster without needing to push it to a registry.

## Step 5: Deploy the Application

```bash
make deploy-app
```

Verify the deployment:

```bash
kubectl get pods
```

## Step 6: Install the Monitoring Stack

```bash
make install-monitoring
```

This will install:
- Prometheus (metrics collection)
- Loki (log aggregation)
- Tempo (distributed tracing)
- Grafana (visualization)
- ServiceMonitor for your application

Wait for all pods to be ready:

```bash
kubectl get pods -n monitoring
```

If the ServiceMonitor deployment fails, wait a few seconds for the CRDs to be fully established and run:

```bash
make deploy-service-monitor
```

## Step 7: Import the Custom Dashboard

```bash
./ops/k8s/monitoring/import-dashboard.sh
```

## Step 8: Access the Services

### Access the API

```bash
# The API should be accessible at http://localhost/
# Or you can use port-forwarding:
make expose-backend
# Then access at http://localhost:8000/
```

### Access Grafana

```bash
make expose-grafana
# Then access at http://localhost:3000/
# Default credentials: admin/admin
```

### Access Prometheus

```bash
make expose-prometheus
# Then access at http://localhost:9090/
```

## Step 9: Run Load Tests

```bash
make run-load-test
```

This will run a k6 load test that simulates user traffic to various endpoints.

## Step 10: Explore the Observability Stack

1. In Grafana (http://localhost:3000/), log in with admin/admin
2. Navigate to Dashboards > Bookly API Dashboard
3. Explore metrics, logs, and traces:
   - View request rates and latencies
   - Check error rates
   - Explore logs from Loki
   - View distributed traces in Tempo

## Cleanup

When you're done, you can delete the KinD cluster:

```bash
make delete-cluster
```

## Troubleshooting

If you encounter any issues:

1. Check pod status:
   ```bash
   kubectl get pods -A
   ```

2. Check pod logs:
   ```bash
   kubectl logs -n <namespace> <pod-name>
   ```

3. Check service status:
   ```bash
   kubectl get svc -A
   ```

4. Check ingress status:
   ```bash
   kubectl get ingress -A
   ```
