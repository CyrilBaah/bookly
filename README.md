# Bookly API

A FastAPI-based API for a book management system.

## Prerequisites

- Docker
- Kubernetes (via KinD)
- kubectl
- Helm
- k6 (for load testing)

## Getting Started

### Create a KinD Cluster

```bash
make create-cluster
```

### Install NGINX Ingress Controller

```bash
make install-nginxingresscontroller
```

### Load the Docker Image to KinD

```bash
make load-image-to-kind
```

### Deploy the Application

```bash
make deploy-app
```

### Install the Monitoring Stack

```bash
make install-monitoring
```

This will install:
- Prometheus (metrics collection)
- Grafana (visualization)

### Access the Services

#### Access the API

```bash
# The API should be accessible at http://localhost/
# Or you can use port-forwarding:
make expose-backend
# Then access at http://localhost:8000/
```

#### Access Grafana

```bash
make expose-grafana
# Then access at http://localhost:3000/
# Default credentials: admin/admin
```

#### Access Prometheus

```bash
make expose-prometheus
# Then access at http://localhost:9090/
```

### Run Load Tests

```bash
make run-load-test
```

## Cleanup

```bash
# Delete the KinD cluster
make delete-cluster
```

## Makefile Commands

Run `make help` to see all available commands.

## Docker Image

The Docker image is based on Alpine Linux to keep it small and efficient. The current image size is approximately 74MB.

## Monitoring Stack

### Grafana Dashboards

After installing the monitoring stack, you can access Grafana and explore the following dashboards:
- Kubernetes cluster monitoring
- Node metrics
- Pod metrics
- Application metrics

### Connecting the Dots

The monitoring stack is configured to collect and visualize metrics from Prometheus through Grafana dashboards, providing insights into your application and cluster performance.
