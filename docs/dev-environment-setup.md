# [← Back to Index](index.md)
# 🛠️ Development Environment Setup

This guide covers setting up a complete local development environment for IQToolkit Analyzer, including Ollama configuration for AI-powered database analysis.

## 📋 Table of Contents

- [System Requirements](#-system-requirements)
- [Ubuntu Development Environment Setup](#-ubuntu-development-environment-setup)
- [Ollama Installation and Configuration](#-ollama-installation-and-configuration)
- [Python Environment Setup](#-python-environment-setup)
- [Database Setup](#-database-setup)
- [Verification](#-verification)

---

## 💻 System Requirements

### Minimum Requirements (Small Test Datasets Only)

**⚠️ WARNING: Not recommended for production use or large log files**

- **RAM**: 24GB minimum
- **CPU**: 4 cores (8+ recommended)
- **Storage**: 100GB free space
- **OS**: Ubuntu 20.04 LTS or newer
- **GPU**: Optional, but significantly improves Ollama performance

### Recommended Requirements (Production & Large Files)

**✅ Recommended for serious development and production analysis**

- **RAM**: 64GB or more
- **CPU**: 8+ cores (16+ recommended)
- **Storage**: 500GB+ SSD
- **OS**: Ubuntu 22.04 LTS or newer
- **GPU**: NVIDIA GPU with 16GB+ VRAM (for larger AI models)

### Why These Requirements?

**Memory Intensive Operations:**
- Loading and parsing large PostgreSQL/MongoDB log files (100MB-10GB+)
- Running AI models locally (8GB-40GB depending on model size)
- Concurrent data processing with pandas/numpy
- Multiple database connections and profiler data

**Real-World Scenarios:**
- **24GB RAM**: Can handle ~500MB log files with 7B parameter models
- **64GB RAM**: Handles multi-GB log files with 32B parameter models comfortably
- **128GB+ RAM**: Required for 70B models or processing very large datasets (10GB+ logs)

**Storage Considerations:**
- Ollama models: 5-50GB per model
- Python dependencies: ~2GB
- Sample data and test databases: 10-50GB
- Generated reports and cache: 5-10GB

---

## 🐧 Ubuntu Development Environment Setup

### 1. System Update

```bash
# Update package lists
sudo apt update && sudo apt upgrade -y

# Install essential build tools
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release
```

### 2. Install Python 3.11+

```bash
# Add deadsnakes PPA for latest Python versions
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update

# Install Python 3.11 and essential packages
sudo apt install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip

# Set Python 3.11 as default (optional)
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
sudo update-alternatives --config python3

# Verify installation
python3 --version  # Should show Python 3.11.x
```

### 3. Install Development Dependencies

```bash
# Install additional development tools
sudo apt install -y \
    gcc \
    g++ \
    make \
    libpq-dev \
    libssl-dev \
    libffi-dev \
    postgresql-client \
    mongodb-clients

# Install monitoring tools
sudo apt install -y htop iotop nethogs
```

---

## 🤖 Ollama Installation and Configuration

### 1. Install Ollama on Ubuntu

```bash
# Download and install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Verify installation
ollama --version

# Start Ollama service
sudo systemctl start ollama

# Enable Ollama to start on boot
sudo systemctl enable ollama

# Check Ollama status
sudo systemctl status ollama
```

### 2. Configure Ollama Service

Create or edit the Ollama service configuration:

```bash
# Create systemd override directory
sudo mkdir -p /etc/systemd/system/ollama.service.d/

# Create override configuration
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
# Increase if you have more RAM
Environment="OLLAMA_MAX_QUEUE=512"
EOF

# Reload systemd and restart Ollama
sudo systemctl daemon-reload
sudo systemctl restart ollama

# Verify configuration
curl http://localhost:11434/api/version
```

### 3. Install Recommended AI Models

#### For PostgreSQL Analysis (Current Primary Use)

```bash
# Primary model: SQL-specialized, 7B parameters (~5GB)
ollama pull a-kore/Arctic-Text2SQL-R1-7B

# Alternative: General-purpose SQL analysis
ollama pull sqlcoder:7b

# Verify installation
ollama list
```

#### For MongoDB Analysis (v0.2.0+)

Based on research for optimal MongoDB analysis models:

```bash
# Primary: Best for complex reasoning and aggregation pipelines (~6GB)
ollama pull deepseek-r1:8b

# Code generation: MongoDB query and aggregation code (~5GB)
ollama pull qwen2.5-coder:7b

# Natural language queries: Convert text to MongoDB queries (~4GB)
ollama pull mistral:7b

# Vector embeddings: Essential for MongoDB vector search (~274MB)
ollama pull nomic-embed-text

# Verify all models
ollama list
```

#### Advanced Models (High-End Systems Only)

**⚠️ Only install if you have 64GB+ RAM**

```bash
# Advanced reasoning: 32B parameters (~20GB VRAM required)
ollama pull deepseek-r1:32b

# Advanced code generation (~39GB VRAM required)
ollama pull qwen2.5-coder:32b

# Maximum capability (~85GB VRAM required, needs high-end GPU)
# ollama pull llama3.3:70b
```

### 4. Test Ollama Models

#### Test PostgreSQL Model

```bash
# Test Arctic-Text2SQL-R1-7B
ollama run a-kore/Arctic-Text2SQL-R1-7B

# In the Ollama prompt, try:
# > Analyze this SQL query: SELECT * FROM users WHERE email LIKE '%@gmail.com' ORDER BY created_at
# Press Ctrl+D to exit
```

#### Test MongoDB Models

```bash
# Test DeepSeek-R1 for reasoning
ollama run deepseek-r1:8b

# In the Ollama prompt, try:
# > Explain this MongoDB aggregation: db.users.aggregate([{$match: {age: {$gte: 18}}}, {$group: {_id: "$country", count: {$sum: 1}}}])
# Press Ctrl+D to exit

# Test embeddings model
curl http://localhost:11434/api/embeddings -d '{
  "model": "nomic-embed-text",
  "prompt": "database performance optimization"
}'
```

### 5. Model Recommendations by Use Case

| Use Case | Model | RAM Required | Best For |
|----------|-------|--------------|----------|
| **PostgreSQL Query Analysis** | `a-kore/Arctic-Text2SQL-R1-7B` | 12GB+ | Production PostgreSQL analysis |
| **MongoDB Aggregations** | `qwen2.5-coder:7b` | 12GB+ | Aggregation pipeline generation |
| **MongoDB Schema Analysis** | `deepseek-r1:8b` | 12GB+ | Complex reasoning, schema optimization |
| **Natural Language Queries** | `mistral:7b` | 8GB+ | Converting text to database queries |
| **Vector Search** | `nomic-embed-text` | 2GB+ | Embeddings for MongoDB vector search |
| **Advanced Analysis** | `deepseek-r1:32b` | 32GB+ | High-accuracy, complex analysis |

### 6. Ollama Performance Optimization

#### For Systems with GPU

```bash
# Verify GPU availability
nvidia-smi

# Configure Ollama to use GPU
sudo tee -a /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
Environment="OLLAMA_GPU_LAYERS=-1"
Environment="OLLAMA_CUDA_COMPUTE_CAPABILITY=8.6"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

#### For CPU-Only Systems

```bash
# Optimize for CPU inference
sudo tee -a /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
Environment="OLLAMA_NUM_THREADS=8"
Environment="OLLAMA_USE_MMAP=1"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

#### Monitor Ollama Performance

```bash
# Watch resource usage
watch -n 1 'free -h && echo "---" && nvidia-smi 2>/dev/null || echo "No GPU"'

# Monitor Ollama logs
sudo journalctl -u ollama -f

# Check Ollama metrics
curl http://localhost:11434/api/metrics
```

---

## 🐍 Python Environment Setup

### 1. Clone the Repository

```bash
# Clone from main repository
git clone https://github.com/iqtoolkit/iqtoolkit-analyzer.git
cd iqtoolkit-analyzer

# Or clone your fork
git clone https://github.com/YOUR-USERNAME/iqtoolkit-analyzer.git
cd iqtoolkit-analyzer
```

### 2. Create Virtual Environment

```bash
# Create virtual environment with Python 3.11
python3.11 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Verify Python version in venv
python --version  # Should show Python 3.11.x
```

### 3. Install Dependencies

```bash
# Install all dependencies
pip install -r requirements.txt

# Or install with development extras
pip install -e ".[dev,test]"

# Verify installation
python -c "import ollama; import openai; import pandas; print('✅ All imports successful')"
```

### 4. Configure IQToolkit Analyzer for Ollama

```bash
# Copy example configuration
cp .iqtoolkit-analyzer.yml.example .iqtoolkit-analyzer.yml

# Edit configuration for local Ollama
cat > .iqtoolkit-analyzer.yml <<EOF
# AI Provider Configuration
llm_provider: ollama
ollama_model: a-kore/Arctic-Text2SQL-R1-7B
ollama_host: http://localhost:11434

# MongoDB Models (for v0.2.0+)
# ollama_model: deepseek-r1:8b
# ollama_model: qwen2.5-coder:7b

# LLM Settings
llm_temperature: 0.3
max_tokens: 300
llm_timeout: 30

# Analysis Options
top_n: 10
min_duration: 1000
output: reports/analysis.md
EOF
```

### 5. Install Pre-commit Hooks

```bash
# Install git hooks for automated checks
bash scripts/setup-hooks.sh

# Or install pre-commit manually
pre-commit install

# Test pre-commit hooks
pre-commit run --all-files
```

---

## 🗄️ Database Setup

### PostgreSQL Setup (for Testing)

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create test database and user
sudo -u postgres psql <<EOF
CREATE DATABASE iqtoolkit_test;
CREATE USER iqtoolkit_user WITH PASSWORD 'test_password';
GRANT ALL PRIVILEGES ON DATABASE iqtoolkit_test TO iqtoolkit_user;
ALTER DATABASE iqtoolkit_test OWNER TO iqtoolkit_user;

-- Enable slow query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;
ALTER SYSTEM SET logging_collector = on;
ALTER SYSTEM SET log_directory = 'log';
ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log';
SELECT pg_reload_conf();
EOF

# Verify setup
psql -U iqtoolkit_user -d iqtoolkit_test -h localhost -c "SELECT version();"
```

### MongoDB Setup (for v0.2.0+ Testing)

```bash
# Import MongoDB GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Install MongoDB
sudo apt update
sudo apt install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Enable profiler for slow query analysis
mongosh <<EOF
use iqtoolkit_test
db.setProfilingLevel(2, {slowms: 100})
db.getProfilingStatus()
EOF

# Verify setup
mongosh --eval "db.version()"
```

---

## ✅ Verification

### 1. Verify System Resources

```bash
# Check RAM
free -h

# Check CPU cores
nproc

# Check disk space
df -h

# Check GPU (if available)
nvidia-smi || echo "No GPU detected (CPU-only mode)"
```

### 2. Test Ollama Integration

```bash
# Activate virtual environment if not already
source .venv/bin/activate

# Run Ollama test script
python test_remote_ollama.py
```

**Expected output:**
```
============================================================
Testing Remote Ollama Server at localhost:11434
============================================================

1. Testing direct Ollama connection...
✅ Connected successfully!
   Available models: [list of installed models]

2. Testing chat functionality...
✅ Chat test successful!

3. Testing IQToolkit Analyzer LLMClient integration...
✅ LLMClient integration working!
```

### 3. Run Unit Tests

```bash
# Run all tests
pytest tests/ -v

# Run specific tests
pytest tests/test_llm_client.py -v

# Run tests with coverage
pytest tests/ --cov=iqtoolkit_analyzer --cov-report=html
```

### 4. Test with Sample Data

```bash
# Test PostgreSQL analysis
python -m iqtoolkit_analyzer postgresql docs/sample_logs/postgresql/postgresql-2025-10-28_192816.log.txt \
  --output test_report.md \
  --verbose

# Verify report was generated
cat test_report.md
```

### 5. Code Quality Checks

```bash
# Format code
make format

# Run linters
make lint

# Run all checks
make validate
```

---

## 🔧 Troubleshooting

### Ollama Not Starting

```bash
# Check Ollama service status
sudo systemctl status ollama

# View Ollama logs
sudo journalctl -u ollama -n 50

# Restart Ollama
sudo systemctl restart ollama

# Check if port is in use
sudo netstat -tlnp | grep 11434
```

### Model Download Issues

```bash
# Check available disk space
df -h

# Manually download model with progress
ollama pull a-kore/Arctic-Text2SQL-R1-7B --verbose

# Clear Ollama cache if needed
rm -rf ~/.ollama/models/blobs/*
```

### Memory Issues

```bash
# Monitor memory during model loading
watch -n 1 free -h

# Reduce model size by using quantized versions
ollama pull deepseek-r1:8b-q4_K_M  # 4-bit quantization

# Limit concurrent models
# Edit /etc/systemd/system/ollama.service.d/override.conf
Environment="OLLAMA_MAX_LOADED_MODELS=1"
```

### Python Import Errors

```bash
# Reinstall dependencies
pip install --force-reinstall -r requirements.txt

# Check for missing system dependencies
sudo apt install -y libpq-dev python3.11-dev

# Verify virtual environment
which python  # Should point to .venv/bin/python
```

---

## 📚 Next Steps

After completing this setup:

1. **Read the documentation**:
   - [Getting Started Guide](getting-started.md)
   - [Configuration Guide](configuration.md)
   - [Contributing Guide](../CONTRIBUTING.md)

2. **Try the examples**:
   - [PostgreSQL Examples](pg_examples.md)
   - [MongoDB Guide](mongodb-guide.md)

3. **Set up remote Ollama** (optional):
   - [Remote Ollama Testing](remote-ollama-testing.md)

4. **Start contributing**:
   - Check [GitHub Issues](https://github.com/iqtoolkit/iqtoolkit-analyzer/issues)
   - Review [ROADMAP.md](../ROADMAP.md)

---

## 💡 Performance Tips

### For 24GB RAM Systems (Minimum)

- Use 7B models only: `a-kore/Arctic-Text2SQL-R1-7B`, `mistral:7b`
- Process one log file at a time
- Close other applications during analysis
- Use `--top-n 5` to limit analysis scope
- Monitor RAM with `htop`

### For 64GB+ RAM Systems (Recommended)

- Can use 7B, 13B, and 32B models
- Process multiple log files in parallel
- Run MongoDB and PostgreSQL simultaneously
- Use larger context windows (`--max-tokens 500`)
- Keep multiple models loaded

### For 128GB+ RAM Systems (Optimal)

- Use any model size, including 70B
- Run multiple analyses concurrently
- Process very large log files (10GB+)
- Enable all AI features
- Run development database instances

---

**Environment setup complete! You're ready to contribute to IQToolkit Analyzer.** 🚀
