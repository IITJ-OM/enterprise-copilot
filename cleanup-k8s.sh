#!/bin/bash

# Kubernetes Cleanup Script for Enterprise Copilot
# This script removes all resources from the iitj-sde namespace

set -e

echo "🧹 Enterprise Copilot Kubernetes Cleanup"
echo "========================================"
echo ""
echo "WARNING: This will delete ALL resources in the 'iitj-sde' namespace!"
echo "   - All deployments (FastAPI app, Redis, Qdrant, Ollama)"
echo "   - All services"
echo "   - All persistent volumes and data"
echo "   - All configurations and secrets"
echo ""

# Ask for confirmation
read -p "Are you sure you want to continue? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."

# Option 1: Delete the entire namespace (fastest, deletes everything)
echo ""
echo "Deleting namespace 'iitj-sde' and all its resources..."
kubectl delete namespace iitj-sde

echo ""
echo "Waiting for namespace to be fully deleted..."
kubectl wait --for=delete namespace/iitj-sde --timeout=120s 2>/dev/null || true

# Optional: If you want to keep the namespace but delete resources individually
# Uncomment the lines below and comment out the namespace deletion above

# echo ""
# echo "Deleting deployments..."
# kubectl delete deployment --all -n iitj-sde
#
# echo ""
# echo "Deleting services..."
# kubectl delete service --all -n iitj-sde
#
# echo ""
# echo "Deleting persistent volume claims..."
# kubectl delete pvc --all -n iitj-sde
#
# echo ""
# echo "Deleting configmaps and secrets..."
# kubectl delete configmap --all -n iitj-sde
# kubectl delete secret --all -n iitj-sde

echo ""
echo "✅ Cleanup completed successfully!"
echo ""
echo "All resources have been removed from the cluster."
echo ""
echo "To redeploy, run: ./deploy-k8s.sh"
echo ""

