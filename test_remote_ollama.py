#!/usr/bin/env python3
"""
Test script for remote Ollama server at 192.168.0.30

Usage:
    python test_remote_ollama.py
"""

import os
import sys
from pathlib import Path

# Add project root to path first, before importing iqtoolkit_analyzer
sys.path.insert(0, str(Path(__file__).parent))

# Set the remote Ollama host
os.environ["OLLAMA_HOST"] = "http://192.168.0.30:11434"

from iqtoolkit_analyzer.llm_client import LLMClient, LLMConfig  # noqa: E402


def test_remote_ollama():
    """Test connection to remote Ollama server."""
    print("=" * 60)
    print("Testing Remote Ollama Server at 192.168.0.30:11434")
    print("=" * 60)

    # Test 1: Direct ollama connection
    print("\n1. Testing direct Ollama connection...")
    try:
        import ollama

        models = ollama.list()
        print("✅ Connected successfully!")
        print(f"   Available models: {len(models.models)}")
        for model in models.models:
            print(f"   - {model.model} ({model.details.parameter_size})")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False

    # Test 2: Simple chat test
    print("\n2. Testing chat functionality...")
    try:
        response = ollama.chat(
            model="a-kore/Arctic-Text2SQL-R1-7B",
            messages=[
                {
                    "role": "user",
                    "content": 'Say "Hello from remote Ollama!" in one sentence.',
                }
            ],
        )
        content = (
            response.message.content
            if hasattr(response, "message")
            else response.get("message", {}).get("content", "")
        )
        print("✅ Chat test successful!")
        print(f"   Response: {content}")
    except Exception as e:
        print(f"❌ Chat test failed: {e}")
        return False

    # Test 3: LLMClient integration
    print("\n3. Testing IQToolkit Analyzer LLMClient integration...")
    try:
        config = LLMConfig(
            llm_provider="ollama",
            ollama_model="a-kore/Arctic-Text2SQL-R1-7B",
            ollama_host="http://192.168.0.30:11434",
            max_tokens=200,
        )

        client = LLMClient(config)

        # Test with a realistic slow query
        test_query = """
        SELECT u.*, o.*, p.*
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        LEFT JOIN products p ON o.product_id = p.id
        WHERE u.email LIKE '%@gmail.com'
        ORDER BY u.created_at DESC
        """

        print(f"   Analyzing query: {test_query.strip()[:50]}...")
        recommendation = client.generate_recommendations(
            query_text=test_query, avg_duration=3500.0, frequency=150
        )

        if recommendation and "error" not in recommendation.lower():
            print("✅ LLMClient integration working!")
            print("\n   Recommendation:")
            print(f"   {'-' * 56}")
            for line in recommendation.split("\n")[:5]:  # First 5 lines
                print(f"   {line}")
            if len(recommendation.split("\n")) > 5:
                print("   ... (truncated)")
            print(f"   {'-' * 56}")
        else:
            print(f"❌ Integration failed: {recommendation}")
            return False

    except Exception as e:
        print(f"❌ LLMClient test failed: {e}")
        import traceback

        traceback.print_exc()
        return False

    print("\n" + "=" * 60)
    print("🎉 All tests passed! Remote Ollama is ready to use.")
    print("=" * 60)
    print("\nTo use with IQToolkit Analyzer, run:")
    print("  export OLLAMA_HOST=http://192.168.0.30:11434")
    print("  python -m iqtoolkit_analyzer your_log_file.log")
    print("\nOr create a .iqtoolkit-analyzer.yml with:")
    print("  llm_provider: ollama")
    print("  ollama_host: http://192.168.0.30:11434")
    print("  ollama_model: a-kore/Arctic-Text2SQL-R1-7B")

    return True


if __name__ == "__main__":
    success = test_remote_ollama()
    sys.exit(0 if success else 1)
