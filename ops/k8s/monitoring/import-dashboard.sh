#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Get the Grafana pod name
GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath="{.items[0].metadata.name}")

if [ -z "$GRAFANA_POD" ]; then
  echo "Error: Grafana pod not found. Make sure Grafana is deployed in the monitoring namespace."
  exit 1
fi

echo "Found Grafana pod: $GRAFANA_POD"

# Get Grafana admin password from Kubernetes secret
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

if [ -z "$GRAFANA_PASSWORD" ]; then
  echo "Warning: Could not retrieve Grafana password from secret. Using default 'admin' password."
  GRAFANA_PASSWORD="admin"
fi

echo "Grafana credentials: admin:$GRAFANA_PASSWORD"

echo "Copying dashboard JSON to Grafana pod..."
# Copy the dashboard JSON to the pod
kubectl cp ./ops/k8s/monitoring/bookly-dashboard.json monitoring/$GRAFANA_POD:/tmp/bookly-dashboard.json

echo "Importing dashboard to Grafana..."
# Import the dashboard using the Grafana API and capture the response
RESPONSE=$(kubectl exec -n monitoring $GRAFANA_POD -- curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d @/tmp/bookly-dashboard.json \
  http://admin:${GRAFANA_PASSWORD}@localhost:3000/api/dashboards/db)

echo "API Response: $RESPONSE"

# Check if the response contains an error
if echo "$RESPONSE" | grep -q "error"; then
  echo "Error importing dashboard:"
  echo "$RESPONSE"
  exit 1
elif echo "$RESPONSE" | grep -q "success\|id\|uid"; then
  echo "Dashboard imported successfully!"
  
  # Extract dashboard UID for the URL
  DASHBOARD_UID=$(echo "$RESPONSE" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
  
  if [ ! -z "$DASHBOARD_UID" ]; then
    echo "Dashboard URL: http://localhost:3000/d/$DASHBOARD_UID"
    echo "Access with username: admin, password: $GRAFANA_PASSWORD"
    
    # Set up port-forwarding to access Grafana
    echo "Setting up port-forwarding to access Grafana..."
    echo "Press Ctrl+C when you're done viewing the dashboard."
    kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
  else
    echo "Dashboard imported, but couldn't extract UID."
    echo "You can access Grafana at http://localhost:3000 after setting up port-forwarding:"
    echo "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
  fi
else
  echo "Unexpected response:"
  echo "$RESPONSE"
  echo "Please check if the dashboard was imported correctly."
fi

# Clean up the temporary file
kubectl exec -n monitoring $GRAFANA_POD -- rm -f /tmp/bookly-dashboard.json
