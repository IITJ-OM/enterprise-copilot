# Kubernetes Deployment Guide

## Prerequisites

- Kubernetes cluster (Minikube, Docker Desktop, GKE, EKS, AKS, etc.)
- kubectl configured
- Docker installed
- **Ollama running on your local machine** (with `qwen2.5:7b-instruct` model)
- API keys (optional, for OpenAI/Gemini)

## Ollama Configuration

**Current Setup: Using Host Machine Ollama**

The application is configured to connect to Ollama running on your **host machine** (not in Kubernetes). This setup:
- Saves 4-8GB memory in your cluster
- Faster deployment (no model download)
- Uses your existing Ollama installation
- Requires Ollama to be running on host

**Before deploying, ensure:**
```bash
# 1. Ollama is running
curl http://localhost:11434
# Should return: "Ollama is running"

# 2. Model is available
ollama list | grep qwen2.5:7b-instruct
```

**Connection Details:**
- Minikube with Docker driver uses: `http://host.docker.internal:11434`
- Configured in `ConfigMap` → `OLLAMA_BASE_URL`

**To deploy Ollama in Kubernetes instead:**
1. Apply the optional Ollama resources:
   ```bash
   kubectl apply -f k8s/ollama-k8s-optional.yaml
   ```
2. Update `OLLAMA_BASE_URL` in `k8s/kubernetes-deployment.yaml`:
   ```yaml
   OLLAMA_BASE_URL: "http://ollama-service:11434"
   ```
3. Redeploy the application

## Quick Start

### Option 1: Using the deployment script

```bash
# Set API keys (optional)
export OPENAI_API_KEY="your-key"
export GOOGLE_API_KEY="your-key"

# Make script executable and run
chmod +x deploy-k8s.sh
./deploy-k8s.sh
```

### Option 2: Manual deployment

**Step 1: Build Docker image**

```bash
docker build -t enterprise-copilot:latest .
```

**Step 2: Create secrets (optional)**

```bash
kubectl create secret generic app-secrets \
  --namespace=iitj-sde \
  --from-literal=OPENAI_API_KEY="your-key" \
  --from-literal=GOOGLE_API_KEY="your-key"
```

**Step 3: Deploy all resources**

```bash
kubectl apply -f k8s/kubernetes-deployment.yaml
```

**Step 4: Check deployment status**

```bash
kubectl get pods -n iitj-sde
kubectl get services -n iitj-sde
```

All resources are deployed in the `iitj-sde` namespace for better isolation.

## Accessing the Application

### Local Cluster (Minikube/Docker Desktop)

```bash
# Port forward the service
kubectl port-forward service/enterprise-copilot-service 8000:8000 -n iitj-sde

# Access at
http://localhost:8000
```

### Cloud Cluster (with LoadBalancer)

```bash
# Get external IP
kubectl get service enterprise-copilot-service -n iitj-sde

# Wait for EXTERNAL-IP to be assigned
# Then access at http://<EXTERNAL-IP>:8000
```

### Using NodePort

If you change the service type to `NodePort`, access via:

```bash
# Get node IP
kubectl get nodes -o wide

# Get NodePort
kubectl get service enterprise-copilot-service -n iitj-sde

# Access at http://<NODE-IP>:<NODE-PORT>
```

## Configuration

### Update Environment Variables

Edit the ConfigMap in `k8s/kubernetes-deployment.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  REDIS_HOST: "redis-cache"
  QDRANT_HOST: "qdrant-vector-db"
  SEMANTIC_SIMILARITY_THRESHOLD: "0.75"
  # ... other configs
```

Apply changes:

```bash
kubectl apply -f k8s/kubernetes-deployment.yaml
kubectl rollout restart deployment/enterprise-copilot-deployment -n iitj-sde
```

### Update API Keys

```bash
kubectl create secret generic app-secrets \
  --namespace=iitj-sde \
  --from-literal=OPENAI_API_KEY="new-key" \
  --from-literal=GOOGLE_API_KEY="new-key" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/enterprise-copilot-deployment -n iitj-sde
```

## Scaling

```bash
# Scale the application
kubectl scale deployment/enterprise-copilot-deployment --replicas=5 -n iitj-sde

# Check status
kubectl get deployment enterprise-copilot-deployment -n iitj-sde
```

## Monitoring & Debugging

### View logs

```bash
# All pods
kubectl logs -f deployment/enterprise-copilot-deployment -n iitj-sde

# Specific pod
kubectl logs -f <pod-name> -n iitj-sde

# Previous logs (if pod crashed)
kubectl logs --previous <pod-name> -n iitj-sde
```

### Check health

```bash
# Port forward and check
kubectl port-forward service/enterprise-copilot-service 8000:8000 -n iitj-sde
curl http://localhost:8000/api/health
```

### Exec into pod

```bash
kubectl exec -it <pod-name> -n iitj-sde -- /bin/bash
```

### Describe resources

```bash
kubectl describe pod <pod-name> -n iitj-sde
kubectl describe deployment enterprise-copilot-deployment -n iitj-sde
kubectl describe service enterprise-copilot-service -n iitj-sde
```

## Cleanup

### Easy cleanup (recommended)

Use the cleanup script to remove everything:

```bash
chmod +x cleanup-k8s.sh
./cleanup-k8s.sh
```

This will:
- Delete the entire `iitj-sde` namespace
- Remove all deployments, services, PVCs, and configs
- Clean up all data (Redis, Qdrant, Ollama models)

### Manual cleanup

```bash
# Delete entire namespace (deletes everything)
kubectl delete namespace iitj-sde

# Or delete using the YAML file
kubectl delete -f k8s/kubernetes-deployment.yaml

# Or delete by resource type
kubectl delete deployment --all -n iitj-sde
kubectl delete service --all -n iitj-sde
kubectl delete pvc --all -n iitj-sde
kubectl delete configmap --all -n iitj-sde
kubectl delete secret --all -n iitj-sde
```

## Architecture Overview

The deployment includes:

1. **Redis** (Layer 0 - Exact Cache)
   - 1Gi persistent volume
   - Exposed on port 6379
   - Service: `redis-cache`

2. **Qdrant** (Layer 1 & 2 - Semantic & RAG Cache)
   - 5Gi persistent volume
   - Exposed on ports 6333 (HTTP) and 6334 (gRPC)
   - Service: `qdrant-vector-db`

3. **Ollama** (Local LLM - qwen2.5:7b-instruct)
   - 10Gi persistent volume (for models)
   - Exposed on port 11434
   - Service: `ollama-service`
   - Resource limits: 8Gi RAM, 4 CPU cores
   - **Auto-pulls model on startup** (first deployment takes longer)
   - **Zero cost** - runs completely in your cluster!

4. **FastAPI Application** (Main Service)
   - 2 replicas for high availability
   - Health checks configured
   - Resource limits: 2Gi RAM, 2 CPU cores
   - Service: `enterprise-copilot-service` (LoadBalancer)

## Production Considerations

1. **Use a container registry**: Push your image to Docker Hub, GCR, ECR, or ACR
   ```bash
   docker tag enterprise-copilot:latest your-registry/enterprise-copilot:v1.0.0
   docker push your-registry/enterprise-copilot:v1.0.0
   ```
   Update `image` in kubernetes-deployment.yaml

2. **Use proper storage classes**: Configure StorageClass for your cloud provider

3. **Enable TLS/SSL**: Use Ingress with cert-manager for HTTPS

4. **Set resource limits**: Adjust based on your workload

5. **Configure monitoring**: Use Prometheus + Grafana

6. **Backup persistent volumes**: Regular backups of Redis and Qdrant data

7. **Namespace isolation**: All resources are already deployed in the `iitj-sde` namespace for isolation
   - Easy cleanup: delete the entire namespace
   - No conflicts with other applications
   - Organized resource management

## Managing Ollama in Kubernetes

### Check Ollama model status

```bash
# Check if model is downloaded
kubectl exec -it deployment/ollama-deployment -n iitj-sde -- ollama list

# Pull a different model
kubectl exec -it deployment/ollama-deployment -n iitj-sde -- ollama pull llama2

# Test Ollama directly
kubectl port-forward service/ollama-service 11434:11434 -n iitj-sde
curl http://localhost:11434/api/tags
```

### Change Ollama model

Update the ConfigMap in `k8s/kubernetes-deployment.yaml`:

```yaml
data:
  OLLAMA_MODEL: "llama2"  # or mistral, codellama, etc.
```

Then update the Ollama deployment to pull the new model:

```yaml
# In Ollama deployment lifecycle
ollama pull llama2  # Change to your model
```

Apply changes:

```bash
kubectl apply -f k8s/kubernetes-deployment.yaml
kubectl rollout restart deployment/ollama-deployment -n iitj-sde
kubectl rollout restart deployment/enterprise-copilot-deployment -n iitj-sde
```

### Ollama resource requirements

- **qwen2.5:7b-instruct**: ~8GB RAM, 2-4 CPU cores
- **llama2:7b**: ~8GB RAM, 2-4 CPU cores
- **llama2:13b**: ~16GB RAM, 4-8 CPU cores
- **mixtral:8x7b**: ~48GB RAM, 8+ CPU cores

Adjust resources in the deployment based on your model:

```yaml
resources:
  limits:
    memory: "16Gi"  # For larger models
    cpu: "8000m"
```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n iitj-sde
kubectl logs <pod-name> -n iitj-sde
```

Common issues:
- Image pull errors: Check image name and registry access
- CrashLoopBackOff: Check logs for application errors
- Pending: Check PVC status and storage class

### Service not accessible

```bash
kubectl get endpoints enterprise-copilot-service -n iitj-sde
```

- No endpoints: Pods aren't ready
- Can't access externally: Check service type and firewall rules

### Connection to Redis/Qdrant/Ollama fails

```bash
# Check if services are running
kubectl get pods -n iitj-sde
kubectl logs deployment/redis-deployment -n iitj-sde
kubectl logs deployment/qdrant-deployment -n iitj-sde
kubectl logs deployment/ollama-deployment -n iitj-sde

# Check service DNS
kubectl exec -it <app-pod-name> -n iitj-sde -- nslookup redis-cache
kubectl exec -it <app-pod-name> -n iitj-sde -- nslookup qdrant-vector-db
kubectl exec -it <app-pod-name> -n iitj-sde -- nslookup ollama-service
```

