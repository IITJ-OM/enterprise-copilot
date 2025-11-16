#!/bin/bash

# Kubernetes Deployment Script for Enterprise Copilot
# This script helps deploy the application to a Kubernetes cluster

set -e

echo "🚀 Enterprise Copilot Kubernetes Deployment"
echo "==========================================="
echo ""
echo "📋 Prerequisites:"
echo "  ✓ Ollama must be running on your local machine"
echo "  ✓ Model qwen2.5:7b-instruct should be available (check: ollama list)"
echo "  ✓ Minikube running with Docker driver"
echo ""

# Step 1: Build Docker image
echo ""
echo "Step 1: Building Docker image..."
docker build --no-cache -t enterprise-copilot:latest .
docker tag enterprise-copilot:latest pbajpai21/iitj-pbajpai:enterprise-copilot
docker push pbajpai21/iitj-pbajpai:enterprise-copilot

# Optional: Tag and push to registry
# docker tag enterprise-copilot:latest your-registry/enterprise-copilot:latest
# docker push your-registry/enterprise-copilot:latest

# Step 2: Create namespace and deploy resources
echo ""
echo "Step 2: Creating namespace and deploying to Kubernetes..."
kubectl apply -f k8s/kubernetes-deployment.yaml

# Step 3: Create/Update secrets (if API keys provided)
echo ""
echo "Step 3: Setting up secrets in namespace iitj-sde..."
if [ ! -z "$OPENAI_API_KEY" ]; then
    kubectl create secret generic app-secrets \
        --namespace=iitj-sde \
        --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
        --from-literal=GOOGLE_API_KEY="${GOOGLE_API_KEY:-}" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✓ Secrets configured with provided API keys"
else
    echo "⚠️  No OPENAI_API_KEY found. Using empty secret from deployment file."
fi

# Step 4: Wait for deployments
echo ""
echo "Step 4: Waiting for deployments to be ready in namespace iitj-sde..."
kubectl wait --for=condition=available --timeout=300s deployment/redis-deployment -n iitj-sde
kubectl wait --for=condition=available --timeout=300s deployment/qdrant-deployment -n iitj-sde
echo "ℹ️  Using host Ollama (not deploying Ollama in cluster)"
kubectl wait --for=condition=available --timeout=300s deployment/enterprise-copilot-deployment -n iitj-sde

# Step 5: Get service info
echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "Service Information:"
kubectl get services -n iitj-sde

echo ""
echo "Pod Status:"
kubectl get pods -n iitj-sde

echo ""
echo "To access the application:"
echo "  Local cluster: kubectl port-forward service/enterprise-copilot-service 8000:8000 -n iitj-sde"
echo "  Then visit: http://localhost:8000"
echo ""
echo "To check logs:"
echo "  kubectl logs -f deployment/enterprise-copilot-deployment -n iitj-sde"
echo ""
echo "To get external IP (if LoadBalancer):"
echo "  kubectl get service enterprise-copilot-service -n iitj-sde"
echo ""
echo "To cleanup all resources:"
echo "  ./cleanup-k8s.sh"

