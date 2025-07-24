# Grafana Dashboard Setup Guide

This guide provides instructions for setting up and accessing Grafana dashboards for the Bookly API.

## Prerequisites

- A running Kubernetes cluster with the monitoring stack installed
- The Bookly API deployed to the cluster

## Option 1: Automatic Dashboard Import

Use the provided script to automatically import a dashboard:

```bash
./ops/k8s/monitoring/import-simple-dashboard.sh
```

This script will:
1. Find the Grafana pod
2. Get the admin password from Kubernetes secrets
3. Set up port-forwarding to Grafana
4. Import the dashboard
5. Provide the URL to access the dashboard

The script will keep running to maintain the port-forwarding. Press Ctrl+C when you're done.

## Option 2: Manual Dashboard Import

If the automatic import doesn't work, you can manually import the dashboard:

1. First, prepare the dashboard for manual import:

```bash
./ops/k8s/monitoring/prepare-dashboard-for-import.sh
```

2. Then, expose Grafana:

```bash
./ops/k8s/monitoring/expose-grafana.sh
```

3. In your browser, go to http://localhost:3000 and log in with:
   - Username: admin
   - Password: (shown in the terminal)

4. In Grafana:
   - Click on "Dashboards" in the left sidebar
   - Click on "New" and select "Import"
   - Click on "Upload JSON file"
   - Select the file at `./ops/k8s/monitoring/dashboard-for-manual-import.json`
   - Click "Import"

## Option 3: Create a Dashboard from Scratch

If you prefer to create your own dashboard:

1. Expose Grafana:

```bash
./ops/k8s/monitoring/expose-grafana.sh
```

2. In your browser, go to http://localhost:3000 and log in

3. Click on "Dashboards" in the left sidebar

4. Click on "New" and select "New Dashboard"

5. Click on "Add visualization"

6. Select "Prometheus" as the data source

7. Use these queries for your panels:
   - Request Rate: `sum(rate(http_requests_total[1m]))`
   - Response Time: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[1m])) by (le))`
   - Status Codes: `sum(rate(http_requests_total[5m])) by (status_code)`

## Troubleshooting

If you encounter issues:

1. Check if Grafana is running:
```bash
kubectl get pods -n monitoring | grep grafana
```

2. Check Grafana logs:
```bash
kubectl logs -n monitoring $(kubectl get pods -n monitoring | grep grafana | awk '{print $1}')
```

3. Verify the Prometheus data source is configured:
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
Then go to http://localhost:3000/datasources to check if Prometheus is configured.

4. Check if metrics are being collected:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Then go to http://localhost:9090/graph and query for `http_requests_total` to see if metrics are being collected.
