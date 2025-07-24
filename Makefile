# Define variables
CLUSTER_NAME := bookly-cluster
IMAGE_NAME := bookly-api
CONTAINER_NAME := bookly-api
PORT := 8000

.PHONY: create-cluster get-cluster set-context delete-cluster install-nginxingresscontroller get-nginxingress get-logs cluster-info get-nodes get-pods expose-frontend build run stop remove remove-image ps ps-all images exec clean help install-monitoring install-prometheus deploy-app run-load-test 

create-cluster:
	@echo "Creating Kind cluster..."
	kind create cluster --config ./ops/kind/config.yml

get-cluster:
	@echo "Getting Kind clusters..."
	kind get clusters

set-context:
	@echo "Setting kubectl context to $(CLUSTER_NAME)..."
	kubectl config use-context kind-$(CLUSTER_NAME)

delete-cluster:
	@echo "Deleting Kind cluster..."
	kind delete cluster --name $(CLUSTER_NAME)

push-image:
	docker push cyrilbaah/bookly-api:latest

load-image-to-kind:
	@echo "Loading Docker image to Kind cluster..."
	kind load docker-image cyrilbaah/bookly-api:latest --name $(CLUSTER_NAME)

install-nginxingresscontroller:
	@echo "Install NGINX Ingress Controller..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@echo "Waiting for ingress controller to be ready..."
	kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=90s

get-nginxingress:
	@echo "Get nginxingress pods..."
	kubectl get pods -n ingress-nginx -owide

get-logs:
	@echo "Get pods for logs command..."
	@echo "$ kubectl logs -f <name-app-xxx>"

cluster-info:
	@echo "Get cluster information..."
	kubectl cluster-info --context kind-$(CLUSTER_NAME)

get-nodes:
	@echo "Get cluster nodes..."
	kubectl get nodes -owide

get-pods:
	@echo "Get cluster pods..."
	kubectl get pods -owide

get-all:
	@echo "Get all resources..."
	kubectl get all --all-namespaces

expose-backend:
	@echo "Get port for backend..."
	kubectl port-forward svc/$(CONTAINER_NAME) -n default 8000:8000

expose-grafana:
	@echo "Exposing Grafana dashboard..."
	kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80

expose-prometheus:
	@echo "Exposing Prometheus dashboard..."
	kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090

view-app-logs:
	@echo "Viewing application logs through Grafana..."
	@echo "Access Grafana at http://localhost:3000 and use Explore"
	@echo ""
	@echo "If port 3000 is already in use, try a different port:"
	@echo "kubectl port-forward svc/prometheus-grafana -n monitoring 3001:80"
	@echo "Then access Grafana at http://localhost:3001"
	@echo ""
	kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 || kubectl port-forward svc/prometheus-grafana -n monitoring 3001:80

view-direct-logs:
	@echo "Viewing application logs directly from Kubernetes..."
	@POD_NAME=$$(kubectl get pods -l app=bookly-api -o jsonpath="{.items[0].metadata.name}") && \
	echo "Viewing logs for pod: $$POD_NAME" && \
	echo "Press Ctrl+C to exit" && \
	echo "" && \
	kubectl logs -f $$POD_NAME

build:
	docker build -t cyrilbaah/$(IMAGE_NAME) -f ./app/Dockerfile .

run:
	docker run -d -p $(PORT):$(PORT) --name $(CONTAINER_NAME) cyrilbaah/$(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME)

remove:
	docker rm $(CONTAINER_NAME)

remove-image:
	docker rmi $(IMAGE_NAME)

ps:
	docker ps

ps-all:
	docker ps -a

images:
	docker images

exec:
	docker exec -it $(CONTAINER_NAME) bash

clean:
	docker stop $(shell docker ps -aq) || true
	docker rm $(shell docker ps -aq) || true
	docker rmi $(shell docker images -aq) || true

# Monitoring stack commands
install-monitoring: install-prometheus
	@echo "Monitoring stack installed"
	@echo "Deploying ServiceMonitor for Prometheus..."
	kubectl apply -f ./ops/k8s/app/service-monitor.yaml || echo "Note: If this fails, wait a few seconds for the CRDs to be fully established and run 'make deploy-service-monitor'"

install-prometheus:
	@echo "Installing Prometheus stack (includes Grafana)..."
	kubectl create namespace monitoring || true
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	helm repo update
	helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
		-f ./ops/k8s/monitoring/prometheus-values.yaml \
		--namespace monitoring \
		--create-namespace

# Application deployment
deploy-app:
	@echo "Deploying bookly-api application..."
	kubectl apply -f ./ops/k8s/app/deployment.yaml
	kubectl apply -f ./ops/k8s/app/service.yaml
	kubectl apply -f ./ops/k8s/app/ingress.yaml
	@echo "Note: ServiceMonitor will be applied after installing the monitoring stack"

deploy-service-monitor:
	@echo "Deploying ServiceMonitor for Prometheus..."
	kubectl apply -f ./ops/k8s/app/service-monitor.yaml

# Load testing
run-load-test:
	@echo "Running k6 load test..."
	k6 run ./ops/k6/load-test.js

decode:
	@echo "Decode the secret..."
	@echo "$ echo -n 'decodeyourwordhere' | base64 --decode"

encode:
	@echo "Encode the secret..."
	@echo "$ echo -n 'encodeyourwordhere' | base64"

help:
	@echo "Available targets:"
	@echo "  create-cluster   - Create the Kind cluster"
	@echo "  get-cluster      - List available Kind clusters"
	@echo "  set-context      - Set kubectl context to the Kind cluster"
	@echo "  delete-cluster   - Delete the Kind cluster"
	@echo "  load-image-to-kind - Load Docker image to Kind cluster"
	@echo "  get-pods         - List all pods"
	@echo "  get-nodes        - List all nodes"
	@echo "  get-all          - List all resources in all namespaces"
	@echo "  expose-backend   - Makes backend app accessible"
	@echo "  expose-grafana   - Expose Grafana dashboard on port 3000"
	@echo "  expose-prometheus - Expose Prometheus dashboard on port 9090"
	@echo "  get-nginxingress - List all nginx ingress"
	@echo "  get-logs         - Get logs command"
	@echo "  build            - Build Docker image"
	@echo "  run              - Run Docker container in detached mode"
	@echo "  stop             - Stop Docker container"
	@echo "  remove           - Remove Docker container"
	@echo "  remove-image     - Remove Docker image"
	@echo "  ps               - View running containers"
	@echo "  ps-all           - View all containers (including stopped ones)"
	@echo "  images           - View Docker images"
	@echo "  exec             - Execute a command inside the running container"
	@echo "  clean            - Clean up (stop and remove) all containers and images"
	@echo "  install-monitoring - Install the monitoring stack (Prometheus and Grafana)"
	@echo "  install-prometheus - Install Prometheus and Grafana"
	@echo "  deploy-app       - Deploy the application to Kubernetes"
	@echo "  deploy-service-monitor - Deploy the ServiceMonitor for Prometheus"
	@echo "  run-load-test    - Run k6 load test against the application"
	@echo "  help             - Display this help message"

.DEFAULT_GOAL := help
