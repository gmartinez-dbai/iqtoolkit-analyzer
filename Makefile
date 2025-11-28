# Makefile for iqtoolkit-analyzer

.PHONY: help setup sync-version check-version install test lint format clean hooks validate dev-check test-ollama update-requirements

# Python interpreter from virtual environment
PYTHON := .venv/bin/python
PIP := .venv/bin/pip

# Default target
help:
	@echo "🚀 Iqtoolkit Analyzer - Development Commands"
	@echo ""
	@echo "⚠️  IMPORTANT: All commands require '.venv' directory in repo root!"
	@echo "   First time: make setup  (creates .venv and installs deps)"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make validate     Check if environment is properly configured"
	@echo "  make setup        Install development dependencies and git hooks"
	@echo "  make hooks        Install git hooks only" 
	@echo "  make install      Install package in development mode"
	@echo ""
	@echo "Version Management:"
	@echo "  make sync-version Update all files to match VERSION file"
	@echo "  make check-version Verify all versions are consistent"
	@echo ""
	@echo "Dependency Management:"
	@echo "  make update-requirements  Regenerate requirements.txt from pyproject.toml"
	@echo ""
	@echo "Code Quality:"
	@echo "  make format       Format code with black"
	@echo "  make lint         Run linting (flake8, mypy)"
	@echo "  make test         Run tests with coverage"
	@echo "  make test-ollama  Test Ollama setup and integration"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean        Remove build artifacts and cache"

# Setup development environment
setup: hooks install
	@if [ ! -d ".venv" ]; then \
		echo "📦 Creating '.venv' with standard venv..."; \
		python -m venv .venv; \
	fi
	@echo "📦 Installing development dependencies..."
	@.venv/bin/pip install -r requirements.txt; \
	.venv/bin/pip install -e .[dev]
	@echo "✅ Development environment ready!"

# Install git hooks
hooks:
	@chmod +x scripts/setup-hooks.sh
	@bash scripts/setup-hooks.sh

# Install package in development mode
install:
	@if [ ! -d ".venv" ]; then \
		echo "📦 Creating '.venv' with standard venv..."; \
		python -m venv .venv; \
	fi
	@echo "🐍 Installing with pip..."; \
	.venv/bin/pip install -r requirements.txt; \
	.venv/bin/pip install -e .

# Version management
sync-version:
	@if [ ! -d ".venv" ]; then \
		echo "📦 Creating '.venv' with standard venv..."; \
		python -m venv .venv; \
	fi
	@echo "🔄 Synchronizing versions..."
	@.venv/bin/pip install -r requirements.txt > /dev/null 2>&1; \
	.venv/bin/python scripts/propagate_version.py

check-version:
	@if [ ! -d ".venv" ]; then \
		echo "📦 Creating '.venv' with standard venv..."; \
		python -m venv .venv; \
	fi
	@echo "🔍 Checking version consistency..."
	@.venv/bin/pip install -r requirements.txt > /dev/null 2>&1; \
	.venv/bin/python scripts/propagate_version.py --verify

# Dependency management
update-requirements:
	@if [ ! -d ".venv" ]; then \
		echo "📦 Creating '.venv' with standard venv..."; \
		python -m venv .venv; \
	fi
	@echo "📦 Updating requirements.txt using custom script..."; \
	.venv/bin/pip install -r requirements.txt > /dev/null 2>&1; \
	.venv/bin/python scripts/update_requirements.py

# Code formatting
format:
	@if [ ! -d ".venv" ]; then \
		echo "📦 Creating '.venv' with standard venv..."; \
		python -m venv .venv; \
	fi
	@echo "🎨 Formatting code..."
	@.venv/bin/pip install -r requirements.txt > /dev/null 2>&1; \
	.venv/bin/python -m black iqtoolkit_analyzer tests scripts *.py
	@echo "✅ Code formatted!"

# Linting
lint:
	@if [ ! -d ".venv" ]; then \
		echo "📦 Creating '.venv' with standard venv..."; \
		python -m venv .venv; \
	fi
	@echo "🔍 Running linting..."
	@.venv/bin/pip install -r requirements.txt > /dev/null 2>&1; \
	.venv/bin/python -m flake8 . --max-line-length=88 --extend-ignore=E203,W503 --exclude=.venv,build,dist,*.egg-info,scripts/propagate_version.py; \
	.venv/bin/python -m mypy iqtoolkit_analyzer --ignore-missing-imports
	@echo "✅ Linting passed!"

# Run tests
test:
	@if [ ! -d ".venv" ]; then \
		echo "📦 Creating '.venv' with standard venv..."; \
		python -m venv .venv; \
	fi
	@echo "🧪 Running tests..."
	@.venv/bin/pip install -r requirements.txt > /dev/null 2>&1; \
	.venv/bin/python -m pytest tests/ --cov=iqtoolkit_analyzer --cov-report=term-missing --cov-report=html
	@echo "✅ Tests completed!"

# Test Ollama setup
test-ollama:
	@echo "🤖 Testing Ollama setup..."
	@.venv/bin/python scripts/test_ollama.py

# Clean build artifacts
clean:
	@echo "🧹 Cleaning up..."
	@rm -rf build/ dist/ *.egg-info/
	@rm -rf .pytest_cache/ .coverage htmlcov/
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -delete
	@echo "✅ Cleaned up!"

# Validate environment setup
validate:
	@chmod +x scripts/validate-environment.sh
	@bash scripts/validate-environment.sh

# Quick development workflow
dev-check: format lint test check-version
	@echo "✅ All development checks passed!"