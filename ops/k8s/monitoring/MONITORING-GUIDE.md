# Bookly API Monitoring Guide

This guide explains how to use the monitoring stack for the Bookly API.

## Components

The monitoring stack consists of:

1. **Prometheus** - For metrics collection and storage
2. **Grafana** - For visualization of metrics

## Accessing Monitoring Tools

### Grafana

```bash
make expose-grafana
```

Access at http://localhost:3000
- Username: admin
- Password: admin (or check with `kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode`)

### Prometheus

```bash
make expose-prometheus
```

Access at http://localhost:9090

### Viewing Application Logs

For viewing application logs, we use direct Kubernetes logs:

```bash
make view-direct-logs
```

This will show the logs from the Bookly API pods directly.

## Generating Test Traffic

To generate test traffic and create metrics:

```bash
# Expose the API
kubectl port-forward svc/bookly-api 8000:8000

# In another terminal, send requests
for i in {1..20}; do 
  curl http://localhost:8000/books
  curl http://localhost:8000/books/1
  curl http://localhost:8000/error
  sleep 1
done
```

## Dashboards

A Grafana dashboard for the Bookly API is available. To import it:

```bash
./ops/k8s/monitoring/import-dashboard.sh
```

This dashboard shows:
- Request rate by endpoint
- Response time by endpoint
- Error rate
- Endpoint distribution

## Troubleshooting

### If Grafana port is already in use

Try a different port:
```bash
kubectl port-forward svc/prometheus-grafana -n monitoring 3001:80
```

### If you need to check the status of monitoring components

```bash
# Check all monitoring pods
kubectl get pods -n monitoring

# Check Grafana specifically
kubectl get pods -n monitoring | grep grafana
```
