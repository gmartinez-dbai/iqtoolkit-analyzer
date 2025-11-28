# 🚦 Slow Query Doctor Roadmap

## Current Release: v0.1.5 ✅ SHIPPED

- Database slow query log parsing (PostgreSQL focus)
- Query normalization and grouping
- Statistical analysis (impact scores, percentiles)
- AI-powered optimization recommendations (OpenAI only)
- Markdown report generation
- Docker containerization
- Anti-pattern detection
- Multi-format log support (plain, CSV, JSON)

**AI Provider Limitation**: v0.1.x supports **OpenAI GPT models only** (requires OPENAI_API_KEY). For sensitive database logs, consider waiting for v0.2.0 with local Ollama support and configurable AI providers.

---

## v0.1.6 - Final v0.1.x Feature Release (November 2025) 🔒 FEATURE FREEZE

**Focus:** Complete documentation and prepare for v0.2.0

**🚨 IMPORTANT**: This is the **FINAL v0.1.x release with new features**. Any future v0.1.x updates (v0.1.7+) will be **bug fixes only**. All new features go to v0.2.0+.

- [x] Add comprehensive ARCHITECTURE.md documentation
- [x] Update all references from "PostgreSQL-specific" to "database log analyzer"
- [x] Clear roadmap timeline and scope boundaries
- [x] Project discipline guidelines (.gitmessage)
- [x] Prepare codebase for multi-database expansion in v0.4.0
- [x] Plan configurable AI provider architecture (Ollama default, OpenAI optional)
- [x] Design extensible AI provider system for future models (Claude, Gemini, etc.)
- [x] Create placeholder sample log directories for MySQL and SQL Server
- [x] Add comprehensive AI provider extensibility guide in ARCHITECTURE.md
- [x] Establish release tagging strategy (v0.1.6-final-feature)

**Post-v0.1.6**: Only critical bug fixes allowed in v0.1.x branch. Feature development moves to v0.2.0.

---

## v0.2.2 - MongoDB Support + AI Provider Flexibility (Nov 2025) ✅ STABLE

**Focus:** MongoDB slow query analysis and configurable AI providers

**🎉 SHIPPED FEATURES**
- ✅ **MongoDB slow query analyzer** with profiler integration
- ✅ **MongoDB query pattern recognition** and normalization
- ✅ **Enhanced configuration system** (expanded YAML configuration with MongoDB support)
- ✅ **HTML report generation** (interactive dashboards with MongoDB-specific insights)
- ✅ **Multi-format reporting** (JSON, Markdown, HTML)
- ✅ **CLI integration** with database-specific subcommands
- ✅ **Configurable AI providers** (Ollama + OpenAI) - **SHIPPED EARLY** 🚀
- ✅ **Privacy-first AI** with local Ollama support (enterprise-ready)
- ✅ **Flexible model configuration** (custom hosts, multiple models)

**Complete Feature List:**
- [x] **MongoDB slow query analyzer** (complete with profiler integration)
- [x] **Enhanced configuration system** (expanded .iqtoolkit-analyzer.yml options)
- [x] **HTML report generation** (interactive dashboards)
# 🚦 IQToolkit Analyzer Roadmap

This roadmap reflects the current state at v0.2.2 and aligns with the multi-phase central plan (Phase 0–5) for evolving the platform to a modular, service-oriented architecture inside a single monorepo.

---

## Current Release: v0.2.2 ✅ STABLE

MongoDB support and configurable AI providers are fully shipped.

**Highlights**
- ✅ MongoDB slow query analyzer with profiler integration
- ✅ MongoDB query pattern recognition and normalization
- ✅ Enhanced configuration system (expanded YAML + MongoDB options)
- ✅ Multi-format reporting (JSON, Markdown, HTML)
- ✅ CLI integration with database-specific subcommands
- ✅ Configurable AI providers (Ollama + OpenAI)
- ✅ Privacy-first AI with local Ollama support
- ✅ Flexible model configuration (custom hosts, multiple models)
- [ ] **Execution metrics extraction** (performance, I/O, estimation accuracy)
- [ ] **Anti-pattern detection** (seq scans, inefficient joins, poor filters)
- [ ] **Index recommendations** from EXPLAIN analysis
## v0.2.3 - PostgreSQL EXPLAIN + MongoDB Enhancements (Q1 2026) 🎯 NEXT

Focus: Advanced query plan analysis (PostgreSQL EXPLAIN per RFC-002) and MongoDB improvements.

**PostgreSQL EXPLAIN Analyzer (RFC-002):**
- [ ] EXPLAIN plan parser (JSON/YAML)
- [ ] Execution metrics extraction (performance, I/O, estimation accuracy)
- [ ] Anti-pattern detection (seq scans, inefficient joins, poor filters)
- [ ] Index recommendations from EXPLAIN analysis
- [ ] Unified reporting (integrate EXPLAIN insights)
- [ ] LLM-powered insights for complex plans
- [ ] PostgreSQL 9.6–16 support with version-specific handling

**MongoDB Enhancements:**
- [ ] Aggregation pipeline optimization recommendations
- [ ] Indexing strategy analysis and suggestions
- [ ] Query complexity scoring and classification
- [ ] Enhanced anti-pattern detection (MongoDB-specific)

**Developer Experience:**
- [ ] Optional FastAPI backend for programmatic access
- [ ] Improved error messages and troubleshooting
- [ ] Performance benchmarks and docs

**Focus:** Expand to traditional SQL databases (moved up from v0.4.0)

## v0.3.0 - Platform Modularity & Orchestration (Q2 2026) 📋 PLANNED

Focus: Solidify the modular architecture and introduce orchestration.

**Service Modules (Monorepo):**
- [ ] Analyzer service (deterministic engine; optional API)
- [ ] IQAI service (LLM explanations; pydantic-ai)
- [ ] Hub gateway (orchestration; calls Analyzer + IQAI)
- [ ] Shared contracts (Pydantic models; path deps)

**Deployment:**
- [ ] Helm charts (component + umbrella)
- [ ] CI/CD pipelines (dev → staging → prod)
---

## Central Plan Alignment (Monorepo Phases)

The following summarizes the central-plan execution inside this monorepo:

- ✅ Phase 0: Foundations & Separation
	- 0.1: Scaffolding created — `iqtoolkit-contracts/`, `iqtoolkit-iqai/`, `iqtoolkithub/`, `iqtoolkit-deployment/`
	- 0.2: Shared contracts package (pending models)
	- 0.3: Current repo cleanup (pending: isolate analyzer code)
- 🛠️ Phase 1: Analyzer Service Refactor (planned)
- 🛠️ Phase 2: IQAI Copilot Service (planned)
- 🛠️ Phase 3: Hub Orchestration (planned)
- 🛠️ Phase 4: Deployment & Environments (planned)
- 🛠️ Phase 5: Production Readiness (planned)
- [ ] **Track query performance over time** (SQLite/PostgreSQL storage)
- [ ] **Trend analysis** (queries getting slower/faster over time)
- [ ] **Automatic baseline detection** (establish normal performance)
## Database Expansion (Beyond v0.3.x)

As Analyzer modularizes, we will expand to MySQL and SQL Server:

**MySQL**
- [ ] Slow query log parser (standard + JSON)
- [ ] MySQL-specific anti-patterns
- [ ] InnoDB-focused optimizations
- [ ] EXPLAIN FORMAT=JSON analysis

**SQL Server**
- [ ] Extended Events parser
- [ ] Query Store integration (if available)
- [ ] Execution plan analysis (XML)
- [ ] SQL Server-specific recommendations

- **Ravi Bhatia:** ML/self-learning system for recommendations → BACKLOG (v0.3.0, Q2 2026)
- **Uri Dimant:** Query rewrites (not just indexes) → IMPLEMENTED ✅

## Version Timeline Summary

| Version | Timeline | Status | Key Features |
|---------|----------|--------|--------------|
| v0.1.5 | ✅ Shipped | Historical | PostgreSQL analyzer with OpenAI only |
| v0.1.6 | ✅ Shipped | Historical | Final v0.1.x feature release, documentation |
| v0.2.2 | ✅ **Stable** | **Current** | **MongoDB + Ollama/OpenAI providers** |
| v0.2.3 | Q1 2026 | 🎯 Next | **PostgreSQL EXPLAIN analyzer + MongoDB enhancements** |
| ~~v0.2.4~~ | ~~Q1 2026~~ | ❌ Cancelled | Features merged into v0.2.2/0.2.3 |
| v0.3.0 | Q2 2026 | 📋 Planned | **Modular services + orchestration** |
| v0.4.0 | Q3 2026 | 📋 Planned | **ML/self-learning, anomaly detection** |
| v1.0.0 | Q4 2026 | 📋 Planned | Web UI, enterprise features |

**🎉 Ahead of Schedule:** v0.2.4's AI provider flexibility shipped **3 months early** in v0.2.2!

---

## Release & Versioning (short)

See `docs/release-process.md`.

Key points:
- `VERSION` at repo root is the single source of truth.
- Use the `scripts/propagate_version.py` utility (with `--dry-run` first) to sync versions and create tags.
- For packaging, use Poetry: `poetry build && poetry publish` (service packages that are meant for PyPI).


## Contributing

See issues labeled with `good-first-issue` or `help-wanted` for ways to contribute!

Questions or suggestions? Email: gio@iqtoolkit.ai
---

**Made with ❤️ for Database performance optimization**