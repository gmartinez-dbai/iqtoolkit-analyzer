# Monorepo Guide: Poetry + Path Dependencies

This repository uses a single monorepo to host multiple Python packages and deployment assets. We use **Poetry** for dependency management and publishing, and **path dependencies** for local development across packages.

## Packages

- `iqtoolkit_analyzer/` – Current CLI package (to be service-ized)
- `iqtoolkit-contracts/` – Shared Pydantic models (published or path dep)
- `iqtoolkit-iqai/` – AI Copilot service (pydantic-ai)
- `iqtoolkithub/` – Orchestration gateway
- `iqtoolkit-deployment/` – Helm charts and deployment assets

## Setup

```bash
# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Install per package (path deps wired)
cd iqtoolkit-contracts && poetry install && cd -
cd iqtoolkit-iqai && poetry install && cd -
cd iqtoolkithub && poetry install && cd -

# Analyzer CLI (root package)
poetry install
```

In `iqtoolkit-iqai/pyproject.toml` and `iqtoolkithub/pyproject.toml`, the contracts package is referenced as a **path dependency**:

```toml
[tool.poetry.dependencies]
iqtoolkit-contracts = { path = "../iqtoolkit-contracts", develop = true }
```

This allows you to edit `iqtoolkit-contracts` and immediately use the changes in dependent packages without publishing to PyPI.

## Publishing

- For libraries you want on PyPI (e.g., `iqtoolkit-contracts`, later the analyzer package):

```bash
poetry build
poetry publish  # configure PyPI token first: poetry config pypi-token.pypi <TOKEN>
```

- Service packages (IQAI, Hub) are typically deployed as containers, not PyPI artifacts.

## Tips

- Prefer **atomic PRs** across packages in the monorepo when contracts change.
- Keep `VERSION` in repo root as the single source of truth and use `scripts/propagate_version.py --dry-run` before tagging.
- Use `poetry run` to execute commands in the right environment, e.g.:

```bash
poetry run python -m iqtoolkit_analyzer --help
```
