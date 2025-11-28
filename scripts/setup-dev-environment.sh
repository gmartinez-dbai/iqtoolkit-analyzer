#!/bin/bash

# Enhanced setup script for iqtoolkit-analyzer development environment
# This script sets up everything needed for development

set -e

echo "🚀 Setting up iqtoolkit-analyzer development environment..."

# Check if .venv directory exists, create if not
if [ ! -d ".venv" ]; then
    echo "📦 Creating '.venv' virtual environment in repository root..."
    python -m venv .venv
    echo "✅ Virtual environment created at ./.venv"
    echo ""
else
    echo "✅ Virtual environment '.venv' already exists"
fi

echo "🧰 Installing dependencies with pip..."
.venv/bin/pip install -r requirements.txt
echo "📥 Installing iqtoolkit-analyzer with dev dependencies..."
.venv/bin/pip install -e .[dev]

# Verify ruamel.yaml is installed
echo "🔍 Verifying ruamel.yaml installation..."
if .venv/bin/python -c "import ruamel.yaml; print('✅ ruamel.yaml installed successfully')" 2>/dev/null; then
    echo "✅ ruamel.yaml is available"
else
    echo "❌ ruamel.yaml not found, installing explicitly..."
    .venv/bin/pip install "ruamel.yaml>=0.17.21"
fi

# Test the version script
echo "🧪 Testing version management script..."
if .venv/bin/python scripts/propagate_version.py --verify; then
    echo "✅ Version management script works correctly"
else
    echo "❌ Version script test failed"
    exit 1
fi

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "📋 What was installed:"
echo "   • Virtual environment at ./.venv"
echo "   • iqtoolkit-analyzer package (development mode)"
echo "   • All development dependencies (pytest, black, flake8, mypy, etc.)"
echo "   • ruamel.yaml for version management"
echo ""
echo "🚀 Next steps:"
echo "   1. Activate virtual environment: source .venv/bin/activate"
echo "   2. Install git hooks: bash scripts/setup-hooks.sh"
echo "   3. Run tests: make test"
echo "   4. Check version consistency: make check-version"
echo ""
echo "💡 Available commands (all use ./.venv):"
echo "   make help           # See all available commands"
echo "   make setup          # Full setup including git hooks"
echo "   make check-version  # Verify version consistency"
echo "   make test           # Run test suite"
echo ""
echo "⚠️  Important: Always use '.venv' directory in repo root for this project!"