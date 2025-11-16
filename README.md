# Enterprise Copilot

A sophisticated multi-layer caching system with LLM integration, designed to optimize response times and reduce API costs through intelligent caching strategies.

## 🏗️ Architecture

The application implements a hierarchical cache system with three layers:

```
User Query
    ↓
Layer 0: Exact Cache (Redis)
    ↓ (if not found)
Layer 1: Semantic Cache (Qdrant)
    ↓ (if not found)
Layer 2: RAG/Document Cache (Qdrant)
    ↓ (if not found)
Call LLM (OpenAI/Gemini/Custom)
```

### Cache Layers

1. **Layer 0 - Exact Cache (Redis)**
   - Fastest lookup for exact query matches
   - Uses hash-based key generation
   - Configurable TTL for cache expiration

2. **Layer 1 - Semantic Cache (Qdrant)**
   - Finds semantically similar queries using vector embeddings
   - Returns cached responses for similar questions
   - Uses cosine similarity with configurable threshold

3. **Layer 2 - RAG/Document Cache (Qdrant)**
   - Document retrieval for context-aware responses
   - Combines retrieved documents with LLM for accurate answers
   - Supports batch document ingestion

## 🚀 Features

- ✅ Multi-layer caching with automatic fallback
- ✅ Multi-LLM support (OpenAI GPT, Google Gemini)
- ✅ **Custom LLM support** (Ollama, HuggingFace, custom APIs, local models)
- ✅ Vector-based semantic search
- ✅ RAG (Retrieval-Augmented Generation) capabilities
- ✅ FastAPI REST API with interactive documentation
- ✅ Configurable similarity thresholds
- ✅ Health monitoring for all components
- ✅ Cache management endpoints
- ✅ Batch document operations
- ✅ Dynamic provider registration/unregistration

## 📋 Prerequisites

- Python 3.8+
- Redis server
- Qdrant vector database
- OpenAI API key (optional)
- Google API key for Gemini (optional)
- Custom LLM key (optional)

## 🔧 Installation

### 1. Clone the repository

```bash
cd project_sde
```

### 2. Create virtual environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Set up Redis

**Using Docker:**
```bash
docker run -d --name redis-cache -p 6379:6379 redis:latest
```

**Or install locally:**
- Windows: Download from https://redis.io/download
- Linux: `sudo apt-get install redis-server`
- Mac: `brew install redis`

### 5. Set up Qdrant

**Using Docker:**
```bash
docker run -d --name qdrant -p 6333:6333 qdrant/qdrant
```

**Or install locally:**
Follow instructions at https://qdrant.tech/documentation/quick-start/

### 6. Configure environment variables

Create a `.env` file in the project root:

```env
# API Keys
OPENAI_API_KEY=your_openai_api_key_here
GOOGLE_API_KEY=your_google_api_key_here

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=

# Qdrant Configuration
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_API_KEY=

# LLM Configuration
DEFAULT_LLM=openai
OPENAI_MODEL=gpt-3.5-turbo
GEMINI_MODEL=gemini-pro

# Cache Configuration
SEMANTIC_SIMILARITY_THRESHOLD=0.85
RAG_SIMILARITY_THRESHOLD=0.75
CACHE_TTL=3600

# Embedding Model
EMBEDDING_MODEL=all-MiniLM-L6-v2
```

## 🎯 Usage

### Start the application

```bash
python main.py
```

The API will be available at `http://localhost:8000`

### Interactive API Documentation

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 📡 API Endpoints

### 1. Process Query

```bash
POST /api/query
```

**Request:**
```json
{
  "query": "What is machine learning?",
  "llm_provider": "openai"
}
```

**Response:**
```json
{
  "query": "What is machine learning?",
  "response": "Machine learning is...",
  "cache_layer": "Layer 1 (Semantic Cache)",
  "cache_hit": true,
  "elapsed_time": 0.125,
  "llm_called": false
}
```

### 2. Add Document

```bash
POST /api/documents
```

**Request:**
```json
{
  "content": "Machine learning is a subset of artificial intelligence...",
  "metadata": {
    "source": "documentation",
    "topic": "AI"
  }
}
```

### 3. Add Documents in Batch

```bash
POST /api/documents/batch
```

**Request:**
```json
{
  "documents": [
    {
      "content": "Document 1 content...",
      "metadata": {"source": "book1"}
    },
    {
      "content": "Document 2 content...",
      "metadata": {"source": "book2"}
    }
  ]
}
```

### 4. Clear Cache

```bash
DELETE /api/cache?layer=1
```

Clear specific layer (0, 1, 2) or all layers (omit parameter)

### 5. Health Check

```bash
GET /api/health
```

**Response:**
```json
{
  "status": "healthy",
  "components": {
    "layer0_redis": true,
    "layer1_qdrant": true,
    "layer2_qdrant": true,
    "llm_providers": ["openai", "gemini"]
  }
}
```

### 6. List LLM Providers

```bash
GET /api/providers
```

## 🔧 Custom LLM Support

The application supports custom LLM providers in **three ways**:

### 1. Langchain Instances (Ollama, HuggingFace, etc.)

```python
from langchain_community.chat_models import ChatOllama
from orchestrator import CacheOrchestrator

orchestrator = CacheOrchestrator()

# Register Ollama
orchestrator.llm_manager.register_custom_provider(
    provider_name="ollama",
    llm_instance=ChatOllama(model="llama2"),
    model_name="Llama2"
)

# Use it
result = orchestrator.query("What is AI?", llm_provider="ollama")
```

### 2. Custom API Endpoints

```python
# Register custom API
orchestrator.llm_manager.register_custom_provider(
    provider_name="my_api",
    api_endpoint="https://api.example.com/generate",
    api_key="your-key",
    model_name="My Custom API"
)
```

### 3. Custom Functions

```python
# Define custom function
def my_llm(query, context=None):
    return f"Custom response to: {query}"

# Register it
orchestrator.llm_manager.register_custom_provider(
    provider_name="my_llm",
    custom_function=my_llm
)
```

**See detailed guide:** [`CUSTOM_LLM_GUIDE.md`](CUSTOM_LLM_GUIDE.md)

**Examples:** Run `python example_custom_llm.py`

## 💡 Example Usage

### Python Client Example

```python
import requests

# Process a query
response = requests.post(
    "http://localhost:8000/api/query",
    json={
        "query": "Explain neural networks",
        "llm_provider": "openai"
    }
)
print(response.json())

# Add a document to RAG cache
response = requests.post(
    "http://localhost:8000/api/documents",
    json={
        "content": "Neural networks are computing systems inspired by biological neural networks...",
        "metadata": {"topic": "deep-learning"}
    }
)
print(response.json())
```

### cURL Example

```bash
# Query
curl -X POST "http://localhost:8000/api/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "What is AI?", "llm_provider": "openai"}'

# Add document
curl -X POST "http://localhost:8000/api/documents" \
  -H "Content-Type: application/json" \
  -d '{"content": "AI is...", "metadata": {"source": "wiki"}}'

# Clear cache
curl -X DELETE "http://localhost:8000/api/cache?layer=0"
```

## 🔍 How It Works

1. **User submits a query** via the API
2. **Layer 0 Check**: System checks Redis for exact match
   - If found: Return cached response (fastest)
3. **Layer 1 Check**: System checks Qdrant for semantically similar queries
   - If found: Return similar cached response
   - Cache in Layer 0 for future exact matches
4. **Layer 2 Check**: System retrieves relevant documents from RAG cache
   - If found: Generate response using LLM + documents as context
   - Cache in Layers 0 and 1
5. **LLM Fallback**: If no cache hit, call LLM directly
   - Cache response in all layers

## ⚙️ Configuration

### Cache Thresholds

- `SEMANTIC_SIMILARITY_THRESHOLD`: Minimum similarity score for Layer 1 (default: 0.85)
- `RAG_SIMILARITY_THRESHOLD`: Minimum similarity score for Layer 2 (default: 0.75)
- `CACHE_TTL`: Time-to-live for Layer 0 cache in seconds (default: 3600)

### Embedding Model

The default embedding model is `all-MiniLM-L6-v2`. You can change this in the `.env` file:

```env
EMBEDDING_MODEL=all-mpnet-base-v2  # More accurate but slower
```

## 🧪 Testing

You can test the cache hierarchy by:

1. **First query** (Cache miss - calls LLM):
```bash
curl -X POST "http://localhost:8000/api/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "What is Python?"}'
```

2. **Exact same query** (Layer 0 hit):
```bash
curl -X POST "http://localhost:8000/api/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "What is Python?"}'
```

3. **Similar query** (Layer 1 hit):
```bash
curl -X POST "http://localhost:8000/api/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "Can you explain Python programming language?"}'
```

## 🌐 Kubernetes Deployment

If you want to run Enterprise Copilot on a Kubernetes cluster (Minikube, Docker Desktop, or a managed cloud cluster), follow this high‑level workflow. For a deep dive, see `K8S_DEPLOYMENT.md`.

### Prerequisites (Kubernetes)

- **Kubernetes cluster**: Minikube, Docker Desktop, GKE, EKS, or AKS
- **kubectl**: Configured to talk to your cluster
- **Docker**: Installed and logged in to your registry (Docker Hub, etc.)
- **Ollama (recommended)**: Running on your host with the `qwen2.5:7b-instruct` model  
  - Or, alternatively, valid **OpenAI/Gemini API keys**

The Kubernetes manifests assume:

- **Namespace**: `iitj-sde`
- **Redis service**: `redis-cache` on port `6379`
- **Qdrant service**: `qdrant-vector-db` on ports `6333` (HTTP) and `6334` (gRPC)
- **App service**: `enterprise-copilot-service` on port `8000` (type `LoadBalancer` by default)

### Option 1 – Deploy using the script (recommended for local dev)

From the project root:

```bash
# (Optional) set API keys if you want to use OpenAI/Gemini instead of Ollama
export OPENAI_API_KEY="your-openai-key"
export GOOGLE_API_KEY="your-google-key"

chmod +x deploy-k8s.sh
./deploy-k8s.sh
```

The script will:

- **Build** the Docker image (`enterprise-copilot:latest`)
- **Tag & push** it to `pbajpai21/iitj-pbajpai:enterprise-copilot`
- **Apply** `k8s/kubernetes-deployment.yaml`
- **Create/patch** the `app-secrets` secret (if `OPENAI_API_KEY` is set)
- **Wait** for Redis, Qdrant, and the app deployment to become ready

### Option 2 – Manual deployment

If you prefer to deploy manually:

```bash
# 1. Build the image locally
docker build -t enterprise-copilot:latest .

# 2. (Optional) tag & push to your own registry
docker tag enterprise-copilot:latest your-registry/enterprise-copilot:v1.0.0
docker push your-registry/enterprise-copilot:v1.0.0
```

Update the `image` field in `k8s/kubernetes-deployment.yaml` if you push to your own registry:

```yaml
spec:
  template:
    spec:
      containers:
        - name: enterprise-copilot
          image: your-registry/enterprise-copilot:v1.0.0
```

Create the namespace and deploy all resources:

```bash
# 3. Apply all Kubernetes resources (namespace, Redis, Qdrant, app, services, config)
kubectl apply -f k8s/kubernetes-deployment.yaml
```

(Optional) create secrets from your API keys instead of the empty placeholders in the YAML:

```bash
kubectl create secret generic app-secrets \
  --namespace=iitj-sde \
  --from-literal=OPENAI_API_KEY="your-openai-key" \
  --from-literal=GOOGLE_API_KEY="your-google-key"
```

### Accessing the application on Kubernetes

- **Port‑forward (local cluster)**:

  ```bash
  kubectl port-forward service/enterprise-copilot-service 8000:8000 -n iitj-sde
  # Then open http://localhost:8000
  ```

- **LoadBalancer (cloud cluster)**:

  ```bash
  kubectl get service enterprise-copilot-service -n iitj-sde
  # Wait for EXTERNAL-IP, then open http://<EXTERNAL-IP>:8000
  ```

- **NodePort (if you change the service type)**:

  ```bash
  kubectl get nodes -o wide
  kubectl get service enterprise-copilot-service -n iitj-sde
  # Then open http://<NODE-IP>:<NODE-PORT>
  ```

### Updating configuration & secrets

- **ConfigMap** values (e.g., `SEMANTIC_SIMILARITY_THRESHOLD`, `OLLAMA_BASE_URL`, `OLLAMA_MODEL`) are defined in `k8s/kubernetes-deployment.yaml` under the `app-config` `ConfigMap`.  
- After changing them, re‑apply and restart the deployment:

  ```bash
  kubectl apply -f k8s/kubernetes-deployment.yaml
  kubectl rollout restart deployment/enterprise-copilot-deployment -n iitj-sde
  ```

To rotate API keys while keeping the same secret name:

```bash
kubectl create secret generic app-secrets \
  --namespace=iitj-sde \
  --from-literal=OPENAI_API_KEY="new-openai-key" \
  --from-literal=GOOGLE_API_KEY="new-google-key" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/enterprise-copilot-deployment -n iitj-sde
```

### Cleanup

To remove everything created in the `iitj-sde` namespace:

```bash
chmod +x cleanup-k8s.sh
./cleanup-k8s.sh
```

Or manually:

```bash
kubectl delete namespace iitj-sde
```

For a more detailed, step‑by‑step production‑grade guide (including scaling, monitoring and optional in‑cluster Ollama), see `K8S_DEPLOYMENT.md`.

## 📊 Performance Benefits

- **Layer 0 (Redis)**: ~1-5ms response time
- **Layer 1 (Semantic)**: ~10-50ms response time
- **Layer 2 (RAG)**: ~100-500ms response time
- **LLM Call**: ~1000-5000ms response time

By caching responses, the system can reduce:
- Response time by up to 99%
- LLM API costs by 80-95%
- Server load significantly

## 🛠️ Troubleshooting

### Redis Connection Error
```
Error: Could not connect to Redis
```
**Solution**: Ensure Redis is running on the configured host and port

### Qdrant Connection Error
```
Error: Could not connect to Qdrant
```
**Solution**: Ensure Qdrant is running and accessible

### LLM API Error
```
Error: OpenAI API key not configured
```
**Solution**: Add your API key to the `.env` file

## 📝 Project Structure

```
project_sde/
├── cache/
│   ├── __init__.py
│   ├── layer0_exact_cache.py      # Redis exact cache
│   ├── layer1_semantic_cache.py   # Qdrant semantic cache
│   └── layer2_rag_cache.py        # Qdrant RAG cache
├── llm/
│   ├── __init__.py
│   └── llm_provider.py             # Multi-LLM support
├── config.py                       # Configuration management
├── orchestrator.py                 # Main cache orchestrator
├── main.py                         # FastAPI application
├── requirements.txt                # Python dependencies
└── README.md                       # Documentation
```

## 🚀 Advanced Features

### Custom Similarity Thresholds

You can adjust thresholds per query (future enhancement):
```python
# In orchestrator.py, modify the get() methods to accept threshold parameter
```

### Custom Embeddings

To use a different embedding model:
```python
# In config.py
EMBEDDING_MODEL=sentence-transformers/all-mpnet-base-v2
```


