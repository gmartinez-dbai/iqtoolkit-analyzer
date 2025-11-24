# RFC-002: PostgreSQL EXPLAIN Plan Analyzer

**Status:** Draft  
**Author:** IQToolkit Team  
**Created:** November 23, 2025  
**Target Version:** v0.3.0  
**Feedback Deadline:** December 23, 2025  
**Discussion:** [GitHub Discussions](https://github.com/iqtoolkit/iqtoolkit-analyzer/discussions)

---

## Executive Summary

This RFC proposes adding **EXPLAIN plan analysis** capabilities to IQToolkit Analyzer, enabling deep insights into PostgreSQL query execution beyond text-based anti-pattern detection. The feature will parse `EXPLAIN ANALYZE` output, extract execution metrics, detect performance issues, and generate actionable optimization recommendations.

**Key Benefits:**
- 🎯 **Precision:** Detect issues from actual execution data (not just query text)
- 📊 **Metrics:** Expose cache hits, I/O patterns, estimation errors, join costs
- 🤖 **AI Integration:** Provide rich context to LLM for intelligent insights
- 🔍 **Root Cause Analysis:** Identify why queries are slow (missing indexes, bad joins, poor stats)

**Scope:** PostgreSQL-only (v9.6+), MongoDB EXPLAIN support deferred to future RFC

---

## Problem Statement

### Current Limitations

IQToolkit Analyzer v0.2.x analyzes slow queries using:
1. **Log parsing** - Extracts timestamp, duration, query text
2. **Text-based anti-patterns** - Regex detection (5 patterns: leading LIKE, functions on columns, etc.)
3. **Impact scoring** - Duration × frequency

**What's Missing:**
- ❌ No execution plan analysis
- ❌ No insight into why planner chose suboptimal strategy
- ❌ Can't detect missing indexes from actual execution
- ❌ Can't identify estimation errors causing bad plans
- ❌ No I/O statistics (cache hits vs disk reads)
- ❌ No join strategy analysis

### Real-World Scenario

**Current Analysis:**
```
Query: SELECT * FROM users WHERE email LIKE '%@gmail.com'
Duration: 2.5s
Anti-pattern: Leading wildcard LIKE (regex detected)
Recommendation: Use full-text search
```

**With EXPLAIN Analysis:**
```
Query: SELECT * FROM users WHERE email LIKE '%@gmail.com'
Duration: 2.5s (82% in Seq Scan on users)

EXPLAIN Insights:
- Seq Scan on 125,000 rows (should be Index Scan)
- Filter removed 124,988 rows (99.99% wasted I/O)
- Planner estimated 1 row, actual 12 rows (12x error)
- Cache hit ratio: 87.3% (2,211 disk reads)
- Missing index on users.email with pattern ops

Recommendations:
1. CREATE INDEX idx_users_email_trgm ON users USING GIN (email gin_trgm_ops);
   Impact: 80-90% reduction
2. Run ANALYZE users; to fix estimation errors
```

The EXPLAIN analysis provides **actionable, data-driven recommendations** vs generic text-based suggestions.

---

## Proposed Solution

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Slow Query Analysis Flow                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PostgreSQL Log                                              │
│  ┌──────────────────────────────────────┐                   │
│  │ 2025-11-23 10:30:00 duration: 2500ms │                   │
│  │ SELECT * FROM users WHERE ...        │                   │
│  │ {                                    │  (auto_explain)   │
│  │   "Plan": { "Node Type": "Seq Scan", │                   │
│  │     "Actual Rows": 12, ... }         │                   │
│  │ }                                    │                   │
│  └──────────────────────────────────────┘                   │
│                    │                                         │
│                    ▼                                         │
│         ┌──────────────────────┐                            │
│         │   Parser (Enhanced)  │                            │
│         │  - Extract query     │                            │
│         │  - Extract EXPLAIN   │                            │
│         └──────────────────────┘                            │
│                    │                                         │
│         ┌──────────┴──────────┐                             │
│         ▼                     ▼                              │
│  ┌──────────────┐    ┌───────────────────┐                 │
│  │   Existing   │    │ EXPLAIN Analyzer  │  (NEW)          │
│  │   Analysis   │    │  ┌──────────────┐ │                 │
│  │ - Normalize  │    │  │ExplainParser │ │                 │
│  │ - Antipattrn │    │  └──────┬───────┘ │                 │
│  │ - Impact     │    │         ▼          │                 │
│  └──────────────┘    │  ┌──────────────┐ │                 │
│         │            │  │ExplainMetrics│ │                 │
│         │            │  └──────┬───────┘ │                 │
│         │            │         ▼          │                 │
│         │            │  ┌──────────────┐ │                 │
│         │            │  │Antipatterns  │ │                 │
│         │            │  └──────┬───────┘ │                 │
│         │            │         ▼          │                 │
│         │            │  ┌──────────────┐ │                 │
│         │            │  │ Recommender  │◄┼─ LLMClient     │
│         │            │  └──────────────┘ │                 │
│         │            └───────────────────┘                 │
│         │                     │                             │
│         └──────────┬──────────┘                             │
│                    ▼                                         │
│         ┌────────────────────┐                              │
│         │  Report Generator  │                              │
│         │  (Enhanced)        │                              │
│         └────────────────────┘                              │
│                    │                                         │
│                    ▼                                         │
│         Markdown / JSON / HTML                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Design Decisions

### Decision 1: Input Source - Log-Based vs Connection-Based

**Options Considered:**

| Approach | Pros | Cons |
|----------|------|------|
| **Log-based only** | No DB connection needed, read-only, safe | Requires auto_explain setup |
| **Connection-based only** | Can run EXPLAIN on-demand | Needs credentials, connection overhead |
| **Hybrid** | Flexible, fallback options | More complexity |

**Decision:** ✅ **Hybrid approach with log-based as primary**

**Rationale:**
- Most production environments already have slow query logging
- Adding `auto_explain` is a config change (no code changes)
- Connection-based is optional for users who can't modify PostgreSQL config
- Maintains "privacy-first" design (no forced connections)

**Configuration:**
```yaml
explain_analysis:
  mode: 'auto'  # 'auto', 'log_only', 'connection_only'
  expect_auto_explain: true
  
  # Optional: on-demand EXPLAIN via connection
  database:
    enabled: false
    connection_string: 'postgresql://readonly@localhost/db'
```

---

### Decision 2: EXPLAIN Format - JSON vs TEXT vs XML vs YAML

**Options Considered:**

| Format | Parsing Difficulty | Data Completeness | Human Readable |
|--------|-------------------|-------------------|----------------|
| **TEXT** | Hard (regex hell) | Full | Yes |
| **JSON** | Easy (native) | Full | No |
| **XML** | Medium (requires lib) | Full | No |
| **YAML** | Easy (requires lib) | Full | Medium |

**Decision:** ✅ **JSON as primary, YAML as secondary**

**Rationale:**
- JSON: Built-in Python `json` module, no dependencies
- JSON: Structured access to all metrics
- JSON: PostgreSQL 9.6+ support (widest compatibility)
- YAML: Fallback for human-friendly logs (requires `pyyaml` dependency)
- TEXT/XML: Too complex to parse, low ROI

**PostgreSQL Configuration:**
```sql
-- Enable auto_explain with JSON output (PostgreSQL 14+)
ALTER SYSTEM SET auto_explain.log_format = 'json';

-- For PostgreSQL < 14, parse JSON from text logs
-- (EXPLAIN output embedded as text block)
```

---

### Decision 3: Metrics to Extract - Comprehensive vs Minimal

**Options Considered:**

| Approach | Metrics Count | Implementation Effort | Value |
|----------|---------------|----------------------|-------|
| **Minimal** | 5-10 core metrics | Low | Quick wins |
| **Comprehensive** | 30+ metrics | High | Deep insights |
| **Progressive** | Start minimal, expand | Medium | Balanced |

**Decision:** ✅ **Progressive approach - MVP + extensions**

**MVP Metrics (v0.3.0):**
1. Execution time, planning time
2. Node types (Seq Scan, Index Scan, etc.)
3. Actual vs estimated rows
4. Sequential scans on large tables
5. Filter efficiency (rows removed)

**Phase 2 Metrics (v0.3.1+):**
6. Buffer statistics (cache hits/reads)
7. Join strategy analysis
8. Cost breakdown by node
9. Temp file usage
10. Parallel query workers

**Rationale:**
- Get value to users faster with MVP
- Validate architecture before expanding
- Community feedback guides priority

---

### Decision 4: Anti-Pattern Detection - Rule-Based vs ML

**Options Considered:**

| Approach | Accuracy | Maintenance | Dependencies |
|----------|----------|-------------|--------------|
| **Rule-based** | High (known patterns) | Low | None |
| **ML-based** | Variable | High | TensorFlow/PyTorch |
| **Hybrid** | Highest | Medium | Optional ML |

**Decision:** ✅ **Rule-based with optional LLM insights**

**Rationale:**
- EXPLAIN anti-patterns are well-documented (Seq Scan, bad joins, etc.)
- Rules are interpretable and debuggable
- LLM provides contextual insights without complex ML pipeline
- Keeps dependencies minimal

**Detected Anti-Patterns:**
1. Sequential scans on tables > 10k rows
2. Nested loops with large outer tables
3. Estimation errors > 10x (statistics outdated)
4. Filters removing > 99% of rows
5. Low cache hit ratio (< 90%)
6. Hash joins spilling to disk
7. Missing indexes (inferred from execution)

---

### Decision 5: LLM Integration - When to Use AI

**Options Considered:**

| Strategy | LLM Calls | Cost | Value |
|----------|-----------|------|-------|
| **Never** | 0 | Free | Rule-based only |
| **Always** | Per query | High | Rich insights |
| **Selective** | Critical issues only | Low | Best ROI |

**Decision:** ✅ **Selective LLM usage for complex issues**

**Trigger LLM when:**
- Estimation error > 100x (severely wrong statistics)
- Multiple anti-patterns in single query
- Unusual node types or execution patterns
- User explicitly requests AI analysis (`--ai-explain`)

**LLM Prompt Context:**
```
Analyze this PostgreSQL EXPLAIN plan and provide optimization insights:

Query: SELECT * FROM users WHERE email LIKE '%@gmail.com'

Execution Metrics:
- Total time: 2543ms (82% in Seq Scan)
- Rows scanned: 125,000
- Rows returned: 12 (99.99% filtered)
- Cache hit ratio: 87.3%

Anti-patterns Detected:
- Sequential scan on large table (users)
- Leading wildcard LIKE pattern
- Estimation error: estimated 1 row, actual 12 rows

Provide:
1. Root cause analysis
2. Specific index recommendation with SQL
3. Query rewrite alternatives if applicable
4. Expected performance improvement
```

---

### Decision 6: Report Integration - Separate vs Unified

**Options Considered:**

| Approach | User Experience | Maintenance |
|----------|----------------|-------------|
| **Separate EXPLAIN report** | Need 2 reports | Duplicate code |
| **Unified report** | Single source of truth | Clean integration |
| **Optional section** | User choice | Best flexibility |

**Decision:** ✅ **Unified report with optional EXPLAIN section**

**Rationale:**
- Single report shows complete picture
- EXPLAIN enriches existing slow query analysis
- Users can disable if auto_explain not available
- Backward compatible (graceful degradation)

**Report Structure:**
```markdown
## Query #1: User Email Search

### Query Stats (existing)
- Duration: 2.5s
- Frequency: 45
- Impact: 112,500

### Text-Based Analysis (existing)
- Anti-pattern: Leading wildcard LIKE

### EXPLAIN Analysis (NEW - optional)
- Execution breakdown
- Hotspot identification  
- Index recommendations
- AI insights
```

---

### Decision 7: PostgreSQL Version Support

**Target Compatibility:**

| Version | Support Level | Rationale |
|---------|--------------|-----------|
| **9.6+** | Full | JSON/YAML EXPLAIN available |
| **12+** | Enhanced | WAL usage, improved metrics |
| **14+** | Optimal | `auto_explain.log_format` JSON |
| **16+** | Best | Latest performance features |

**Decision:** ✅ **Minimum PostgreSQL 9.6, optimized for 14+**

**Handling Version Differences:**
```python
class ExplainParser:
    def parse_json(self, explain_json: str, pg_version: str) -> ExplainPlan:
        plan = json.loads(explain_json)
        
        # Extract version-specific fields
        if version >= '12.0':
            metrics.wal_usage = plan.get('WAL Usage')
        
        if version >= '14.0':
            metrics.io_timings = plan.get('I/O Timings')
        
        return metrics
```

---

## Implementation Plan

### Phase 1: Foundation (v0.3.0 - Week 1-2)

**Deliverables:**
- [ ] `explain_parser.py` - JSON parsing
- [ ] `explain_metrics.py` - Core metrics extraction
- [ ] Unit tests with fixture EXPLAIN plans
- [ ] Documentation: EXPLAIN setup guide

**Success Criteria:**
- Parse 100% of valid EXPLAIN JSON
- Extract 10+ core metrics
- Handle PostgreSQL 9.6-16 variations

---

### Phase 2: Anti-Pattern Detection (v0.3.0 - Week 3)

**Deliverables:**
- [ ] `explain_antipatterns.py` - 7 detection rules
- [ ] Index recommendation engine
- [ ] Integration tests with real logs
- [ ] Documentation: Anti-pattern catalog

**Success Criteria:**
- Detect Seq Scans on large tables (>90% accuracy)
- Generate actionable index recommendations
- Flag estimation errors (>10x threshold)

---

### Phase 3: Reporting (v0.3.0 - Week 4)

**Deliverables:**
- [ ] `explain_recommender.py` - Recommendation formatting
- [ ] Enhanced report generator
- [ ] LLM integration for insights
- [ ] HTML/Markdown/JSON output

**Success Criteria:**
- EXPLAIN section in existing reports
- JSON export for programmatic access
- Optional LLM insights (user configurable)

---

### Phase 4: Integration & Polish (v0.3.1 - Week 5-6)

**Deliverables:**
- [ ] Enhanced log parser (extract auto_explain)
- [ ] Configuration schema updates
- [ ] End-to-end testing
- [ ] User documentation

**Success Criteria:**
- Works with real auto_explain logs
- Zero breaking changes to existing features
- < 100ms overhead per query analyzed

---

## Testing Strategy

### Unit Tests

**Fixtures:**
```
tests/fixtures/explain_plans/
├── seq_scan_large_table.json
├── index_scan_efficient.json
├── nested_loop_issue.json
├── hash_join_spill.json
├── estimation_error.json
└── complex_multinode.json
```

**Coverage Targets:**
- Parser: 95%+ (handle all node types)
- Metrics: 90%+ (all calculation paths)
- Anti-patterns: 85%+ (each rule tested)

---

### Integration Tests

**Test Scenarios:**
1. Parse real PostgreSQL auto_explain logs
2. Analyze queries with/without EXPLAIN data
3. Generate reports with mixed content
4. Handle missing/malformed EXPLAIN output

---

### Performance Tests

**Benchmarks:**
- Parse 1000 EXPLAIN plans < 1s
- Analyze 100 queries with EXPLAIN < 5s
- Report generation overhead < 10%

---

## Migration & Backward Compatibility

### No Breaking Changes

**Existing functionality preserved:**
- ✅ All current CLI options work unchanged
- ✅ Log parsing backward compatible
- ✅ Report format extends (doesn't replace)
- ✅ EXPLAIN analysis is optional feature

### New Configuration (Optional)

```yaml
# Users add this to enable EXPLAIN analysis
explain_analysis:
  enabled: true  # Default: false (opt-in)
  mode: 'auto'
```

### Graceful Degradation

```python
# If EXPLAIN data not available
if query.explain_plan:
    report += generate_explain_analysis(query)
else:
    # Continue with text-based analysis only
    report += generate_text_analysis(query)
```

---

## Risks & Mitigations

### Risk 1: auto_explain Configuration Barrier

**Risk:** Users can't enable auto_explain (permissions, production concerns)

**Mitigation:**
- Provide clear setup guide with minimal config
- Support connection-based EXPLAIN as fallback
- Make feature optional (degradation path)

---

### Risk 2: EXPLAIN Output Variations

**Risk:** PostgreSQL versions have different EXPLAIN formats

**Mitigation:**
- Comprehensive test fixtures (9.6, 10, 12, 14, 16)
- Version detection and conditional parsing
- Graceful handling of unknown fields

---

### Risk 3: Performance Overhead

**Risk:** Parsing large EXPLAIN plans slows analysis

**Mitigation:**
- Benchmark with 1000+ query plans
- Implement plan caching if needed
- Offer `--skip-explain` flag for speed

---

### Risk 4: LLM Cost/Latency

**Risk:** AI insights add cost and time

**Mitigation:**
- Selective LLM calls (critical issues only)
- User-controlled via `--ai-explain` flag
- Cache LLM responses for repeated patterns

---

## Open Questions

### Q1: Should we support EXPLAIN without ANALYZE?

**Context:** `EXPLAIN` (no ANALYZE) provides estimates only, not actual execution.

**Options:**
- A) Support both EXPLAIN and EXPLAIN ANALYZE
- B) Require EXPLAIN ANALYZE (actual metrics)

**Recommendation:** Start with ANALYZE only, add EXPLAIN support if demanded.

---

### Q2: How to handle multi-statement transactions?

**Context:** auto_explain may log multiple queries per transaction.

**Options:**
- A) Analyze each statement independently
- B) Group by transaction and aggregate metrics
- C) Ignore (out of scope for v0.3)

**Recommendation:** Option A for MVP, Option B for future enhancement.

---

### Q3: Connection-based EXPLAIN: Read-only safety?

**Context:** Running EXPLAIN ANALYZE executes the query.

**Options:**
- A) Require read-only connection (prevent mutations)
- B) Use EXPLAIN only (no ANALYZE) via connection
- C) Explicit user confirmation required

**Recommendation:** Option A + read-only transaction wrapper.

---

## Success Metrics

### Quantitative Goals (v0.3.0)

- ✅ Parse ≥95% of auto_explain logs without errors
- ✅ Generate actionable index recommendations for ≥80% of slow queries
- ✅ Detect ≥90% of sequential scans on large tables
- ✅ Zero performance regression in existing analysis
- ✅ Add <100ms latency per query analyzed

### Qualitative Goals

- 📈 User feedback: "EXPLAIN analysis helped me fix X slow queries"
- 🎯 GitHub issues: Reduced questions about "how to optimize this query"
- 🚀 Adoption: 30%+ of users enable EXPLAIN analysis within 3 months

---

## Alternatives Considered

### Alternative 1: Use pg_stat_statements Instead

**Pros:**
- Built-in PostgreSQL view
- Aggregate statistics across executions
- No log parsing needed

**Cons:**
- No execution plan details
- Requires database connection
- Less detailed than EXPLAIN

**Why Rejected:** Complements but doesn't replace EXPLAIN analysis.

---

### Alternative 2: Integrate pgBadger for EXPLAIN

**Pros:**
- Mature tool with EXPLAIN parsing
- Proven in production

**Cons:**
- Adds heavy dependency
- Different architecture (Perl-based)
- Limited customization

**Why Rejected:** Better to build native integration for IQToolkit architecture.

---

### Alternative 3: Defer to Future "EXPLAIN Service"

**Pros:**
- Microservice could serve multiple tools
- Focused development

**Cons:**
- Delays value to users
- Adds complexity (networking, deployment)

**Why Rejected:** Core feature should be built-in, not external service.

---

## References

- [PostgreSQL EXPLAIN Documentation](https://www.postgresql.org/docs/current/using-explain.html)
- [PostgreSQL auto_explain Extension](https://www.postgresql.org/docs/current/auto-explain.html)
- [Explaining the Postgres Query Optimizer (Bruce Momjian)](https://momjian.us/main/writings/pgsql/optimizer.pdf)
- [IQToolkit RFC-001: Multi-Database Platform](./RFC-001.md)
- [Use The Index, Luke! - SQL Performance](https://use-the-index-luke.com/)

---

## Feedback & Discussion

**Questions for Community:**

1. Would you use EXPLAIN analysis if it required enabling auto_explain in PostgreSQL?
2. Is connection-based EXPLAIN important for your use case?
3. What EXPLAIN metrics matter most to you?
4. Should LLM insights be default or opt-in?

**How to Provide Feedback:**
- GitHub Discussions: https://github.com/iqtoolkit/iqtoolkit-analyzer/discussions
- GitHub Issues: https://github.com/iqtoolkit/iqtoolkit-analyzer/issues
- Email: team@iqtoolkit.dev

---

**Revision History:**
- v1.0 (2025-11-23): Initial draft
