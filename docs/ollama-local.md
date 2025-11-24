# Running Ollama Locally

Ollama lets you run large language models on your own machine. To use it with this project, follow these steps:

## 1. Install Ollama
- Visit https://ollama.com/download and download the installer for your OS (macOS, Linux, Windows).
- Follow the installation instructions for your platform.

## 2. Start the Ollama Server
- After installation, start the Ollama server:
  - On macOS: Open Terminal and run:
    ```sh
    ollama serve
    ```
  - On Linux/Windows: Use the provided launcher or run the same command in your shell.

## 3. Pull a Model
- Before you can use a model, you need to download it. For example, to use the SQL-specialized model:
    ```sh
    ollama pull a-kore/Arctic-Text2SQL-R1-7B
    ```
- You can find other models at https://ollama.com/library

## 4. Test the Server
- You can test the server with:
    ```sh
    ollama run a-kore/Arctic-Text2SQL-R1-7B
    ```
- Or use the Python client as shown in `scripts/test_ollama.py`.

## 5. Using a Remote Ollama Server

You can run Ollama on a remote server and connect to it from your development machine:

### Server Setup
```bash
# On your remote server (e.g., 192.168.0.30)
curl -LsSf https://ollama.com/install.sh | sh
ollama serve
ollama pull a-kore/Arctic-Text2SQL-R1-7B
```

### Client Configuration

**Option 1: Environment Variable**
```bash
export OLLAMA_HOST=http://192.168.0.30:11434
python -m iqtoolkit_analyzer your_log.log
```

**Option 2: Configuration File**

Add to `.iqtoolkit-analyzer.yml`:
```yaml
llm_provider: ollama
ollama_model: a-kore/Arctic-Text2SQL-R1-7B
ollama_host: http://192.168.0.30:11434
```

### Testing Remote Connection

Use the included test script:
```bash
# Test connection and functionality
export OLLAMA_HOST=http://192.168.0.30:11434
python test_remote_ollama.py

# Or test directly
python -c "import ollama; print(ollama.list())"
```

### Running Tests Against Remote Server
```bash
# Run unit tests
OLLAMA_HOST=http://192.168.0.30:11434 pytest -c pytest-remote.ini tests/test_llm_client.py -v

# Run specific Ollama tests
OLLAMA_HOST=http://192.168.0.30:11434 pytest -c pytest-remote.ini tests/test_llm_client.py::TestLLMClientOllama -v
```

## 6. Troubleshooting
- If you get a `model not found` error, make sure you have pulled the model on the server.
- The default server runs at `http://localhost:11434`.
- For remote servers, ensure the port (11434) is accessible (check firewalls).
- To make IQToolkit Analyzer use Ollama, set `llm_provider: ollama` in `.iqtoolkit-analyzer.yml`.
- If your Ollama server runs on a different host/port, add `ollama_host: http://your-host:port` to the config.

---
For more details, see the official docs: https://ollama.com/docs
