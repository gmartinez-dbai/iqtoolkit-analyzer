# PostgreSQL EXPLAIN Analyzer - Technical Specifications

**Version:** 1.0  
**Target Release:** v0.3.0  
**Last Updated:** November 23, 2025  
**Related:** [RFC-002](rfcs/RFC-002-explain-analyzer.md)

---

## Overview

This document provides detailed technical specifications for implementing the PostgreSQL EXPLAIN Plan Analyzer feature in IQToolkit Analyzer. It serves as a reference for developers implementing the feature described in RFC-002.

---

## Module Specifications

### 1. ExplainParser (`iqtoolkit_analyzer/explain_parser.py`)

#### Purpose
Parse EXPLAIN output in JSON/YAML formats and convert to structured Python objects.

#### Public API

```python
from dataclasses import dataclass
from typing import List, Optional, Dict, Any
from enum import Enum

class ExplainFormat(Enum):
    """Supported EXPLAIN output formats."""
    JSON = "json"
    YAML = "yaml"

@dataclass
class PlanNode:
    """Represents a single node in the execution plan tree."""
    
    # Node identification
    node_type: str  # e.g., "Seq Scan", "Index Scan", "Hash Join"
    relation_name: Optional[str] = None
    alias: Optional[str] = None
    
    # Cost estimates
    startup_cost: float = 0.0
    total_cost: float = 0.0
    plan_rows: int = 0
    plan_width: int = 0
    
    # Actual execution metrics (from ANALYZE)
    actual_startup_time: Optional[float] = None
    actual_total_time: Optional[float] = None
    actual_rows: Optional[int] = None
    actual_loops: Optional[int] = None
    
    # I/O statistics (from BUFFERS)
    shared_hit_blocks: Optional[int] = None
    shared_read_blocks: Optional[int] = None
    shared_dirtied_blocks: Optional[int] = None
    shared_written_blocks: Optional[int] = None
    temp_read_blocks: Optional[int] = None
    temp_written_blocks: Optional[int] = None
    
    # Filtering and conditions
    filter: Optional[str] = None
    rows_removed_by_filter: Optional[int] = None
    index_cond: Optional[str] = None
    join_type: Optional[str] = None
    join_filter: Optional[str] = None
    
    # Tree structure
    children: List['PlanNode'] = field(default_factory=list)
    
    # Raw data for version-specific fields
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class ExplainPlan:
    """Complete parsed EXPLAIN plan."""
    
    # Query information
    query_text: Optional[str] = None
    
    # Execution summary
    planning_time: float = 0.0  # milliseconds
    execution_time: float = 0.0  # milliseconds
    
    # Plan tree
    root_node: PlanNode = None
    
    # Metadata
    postgres_version: Optional[str] = None
    format: ExplainFormat = ExplainFormat.JSON
    has_analyze: bool = False
    has_buffers: bool = False
    
    # Triggers (if any)
    triggers: List[Dict[str, Any]] = field(default_factory=list)

class ExplainParser:
    """Parse PostgreSQL EXPLAIN output."""
    
    def parse(self, explain_output: str, format: ExplainFormat = ExplainFormat.JSON) -> ExplainPlan:
        """
        Parse EXPLAIN output in specified format.
        
        Args:
            explain_output: Raw EXPLAIN output string
            format: Output format (JSON or YAML)
            
        Returns:
            Parsed ExplainPlan object
            
        Raises:
            ValueError: If output is invalid or unsupported format
            json.JSONDecodeError: If JSON parsing fails
            yaml.YAMLError: If YAML parsing fails
        """
        
    def parse_json(self, explain_json: str) -> ExplainPlan:
        """Parse EXPLAIN (FORMAT JSON) output."""
        
    def parse_yaml(self, explain_yaml: str) -> ExplainPlan:
        """Parse EXPLAIN (FORMAT YAML) output."""
        
    def _build_plan_tree(self, plan_dict: Dict[str, Any]) -> PlanNode:
        """Recursively build plan node tree from parsed data."""
        
    def _extract_node_metadata(self, plan_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Extract version-specific fields into metadata."""
        
    def validate_plan(self, plan: ExplainPlan) -> bool:
        """Validate parsed plan structure."""
```

#### Implementation Notes

**JSON Parsing:**
```python
def parse_json(self, explain_json: str) -> ExplainPlan:
    # PostgreSQL returns array with single plan object
    data = json.loads(explain_json)
    
    if isinstance(data, list):
        plan_data = data[0]
    else:
        plan_data = data
    
    plan = ExplainPlan(
        planning_time=plan_data.get('Planning Time', 0.0),
        execution_time=plan_data.get('Execution Time', 0.0),
        format=ExplainFormat.JSON,
        has_analyze='Actual Total Time' in str(plan_data),
        has_buffers='Shared Hit Blocks' in str(plan_data)
    )
    
    if 'Plan' in plan_data:
        plan.root_node = self._build_plan_tree(plan_data['Plan'])
    
    return plan
```

**Tree Building:**
```python
def _build_plan_tree(self, plan_dict: Dict[str, Any]) -> PlanNode:
    node = PlanNode(
        node_type=plan_dict['Node Type'],
        relation_name=plan_dict.get('Relation Name'),
        startup_cost=plan_dict.get('Startup Cost', 0.0),
        total_cost=plan_dict.get('Total Cost', 0.0),
        plan_rows=plan_dict.get('Plan Rows', 0),
        actual_rows=plan_dict.get('Actual Rows'),
        actual_total_time=plan_dict.get('Actual Total Time'),
        # ... extract all fields
    )
    
    # Recursively process child plans
    if 'Plans' in plan_dict:
        for child_dict in plan_dict['Plans']:
            node.children.append(self._build_plan_tree(child_dict))
    
    return node
```

#### Error Handling

```python
class ExplainParseError(Exception):
    """Raised when EXPLAIN output cannot be parsed."""
    pass

class UnsupportedFormatError(ExplainParseError):
    """Raised when EXPLAIN format is not supported."""
    pass

class InvalidPlanError(ExplainParseError):
    """Raised when parsed plan is structurally invalid."""
    pass
```

#### Test Coverage

**Unit Tests:**
```python
# tests/test_explain_parser.py

def test_parse_json_seq_scan():
    """Test parsing sequential scan plan."""
    
def test_parse_json_index_scan():
    """Test parsing index scan plan."""
    
def test_parse_json_complex_join():
    """Test parsing multi-table join plan."""
    
def test_parse_json_with_buffers():
    """Test parsing plan with buffer statistics."""
    
def test_parse_yaml_format():
    """Test YAML format parsing."""
    
def test_invalid_json_raises_error():
    """Test error handling for malformed JSON."""
    
def test_tree_structure_correct():
    """Test child nodes are properly nested."""
```

---

### 2. ExplainMetrics (`iqtoolkit_analyzer/explain_metrics.py`)

#### Purpose
Extract quantitative metrics from parsed EXPLAIN plans.

#### Public API

```python
@dataclass
class PerformanceMetrics:
    """Overall performance metrics."""
    execution_time_ms: float
    planning_time_ms: float
    total_cost: float
    planning_execution_ratio: float
    slowest_node: Tuple[str, str, float]  # (type, relation, time_ms)
    top_nodes_by_time: List[Tuple[str, float]]
    cost_breakdown: Dict[str, float]  # node_type -> total_cost

@dataclass
class EstimationMetrics:
    """Row estimation accuracy metrics."""
    node_path: str  # e.g., "Seq Scan on users"
    estimated_rows: int
    actual_rows: int
    error_ratio: float  # actual / estimated
    error_percentage: float
    confidence: str  # 'accurate', 'moderate', 'poor', 'critical'

@dataclass
class IOMetrics:
    """I/O and buffer statistics."""
    total_buffers_hit: int
    total_buffers_read: int
    total_temp_read: int
    total_temp_written: int
    cache_hit_ratio: float  # percentage
    uses_temp_files: bool
    temp_file_size_mb: float
    disk_intensive_nodes: List[Tuple[str, int]]

@dataclass
class ScanMetrics:
    """Scan method analysis."""
    node_type: str
    relation_name: str
    actual_rows: int
    actual_loops: int
    total_rows_processed: int
    scan_efficiency: float  # rows_returned / rows_scanned

@dataclass
class JoinMetrics:
    """Join strategy metrics."""
    join_type: str
    inner_table: str
    outer_table: str
    estimated_rows: int
    actual_rows: int
    loops: int
    cost_contribution: float  # percentage of total

@dataclass
class FilterMetrics:
    """Filter efficiency metrics."""
    filter_condition: str
    rows_scanned: int
    rows_removed: int
    rows_returned: int
    selectivity: float
    efficiency: str  # 'excellent', 'good', 'poor', 'terrible'

@dataclass
class ExplainMetricsSummary:
    """Complete metrics summary."""
    performance: PerformanceMetrics
    estimations: List[EstimationMetrics]
    io_stats: IOMetrics
    scans: List[ScanMetrics]
    joins: List[JoinMetrics]
    filters: List[FilterMetrics]
    
    # Health scores (0-100)
    performance_score: float
    index_health_score: float
    optimization_score: float

class ExplainMetrics:
    """Extract and analyze metrics from EXPLAIN plans."""
    
    def extract_all_metrics(self, plan: ExplainPlan) -> ExplainMetricsSummary:
        """Extract complete metrics summary."""
        
    def get_performance_metrics(self, plan: ExplainPlan) -> PerformanceMetrics:
        """Extract performance metrics."""
        
    def find_estimation_errors(
        self, 
        plan: ExplainPlan, 
        threshold: float = 10.0
    ) -> List[EstimationMetrics]:
        """Find nodes with significant estimation errors."""
        
    def calculate_io_metrics(self, plan: ExplainPlan) -> IOMetrics:
        """Calculate I/O statistics."""
        
    def analyze_scans(self, plan: ExplainPlan) -> List[ScanMetrics]:
        """Analyze scan methods."""
        
    def analyze_joins(self, plan: ExplainPlan) -> List[JoinMetrics]:
        """Analyze join strategies."""
        
    def analyze_filters(self, plan: ExplainPlan) -> List[FilterMetrics]:
        """Analyze filter efficiency."""
        
    def calculate_performance_score(self, plan: ExplainPlan) -> float:
        """Calculate overall performance score (0-100)."""
```

#### Implementation Notes

**Cache Hit Ratio Calculation:**
```python
def _calculate_cache_hit_ratio(self, node: PlanNode) -> float:
    """Calculate cache hit ratio for a node."""
    hit = node.shared_hit_blocks or 0
    read = node.shared_read_blocks or 0
    
    total = hit + read
    if total == 0:
        return 100.0  # No I/O = perfect cache
    
    return (hit / total) * 100.0
```

**Estimation Error Severity:**
```python
def _calculate_estimation_confidence(self, error_ratio: float) -> str:
    """Classify estimation accuracy."""
    error_pct = abs(1 - error_ratio) * 100
    
    if error_pct < 10:
        return 'accurate'
    elif error_pct < 50:
        return 'moderate'
    elif error_pct < 90:
        return 'poor'
    else:
        return 'critical'
```

**Performance Score Algorithm:**
```python
def calculate_performance_score(self, plan: ExplainPlan) -> float:
    """
    Calculate performance score (0-100).
    
    Factors:
    - Cache hit ratio (weight: 30%)
    - Scan efficiency (weight: 25%)
    - Join efficiency (weight: 20%)
    - Estimation accuracy (weight: 15%)
    - Temp file usage (weight: 10%)
    """
    score = 100.0
    
    # Cache penalty
    cache_ratio = self._get_cache_hit_ratio(plan)
    if cache_ratio < 99:
        score -= (99 - cache_ratio) * 0.3
    
    # Scan penalty (seq scans on large tables)
    seq_scan_penalty = self._calculate_seq_scan_penalty(plan)
    score -= seq_scan_penalty * 25
    
    # Join penalty (nested loops on large sets)
    join_penalty = self._calculate_join_penalty(plan)
    score -= join_penalty * 20
    
    # Estimation penalty
    est_penalty = self._calculate_estimation_penalty(plan)
    score -= est_penalty * 15
    
    # Temp file penalty
    if self._uses_temp_files(plan):
        score -= 10
    
    return max(0.0, min(100.0, score))
```

#### Test Coverage

```python
# tests/test_explain_metrics.py

def test_performance_metrics_extraction():
    """Test extraction of performance metrics."""
    
def test_estimation_error_detection():
    """Test detection of row estimation errors."""
    
def test_cache_hit_ratio_calculation():
    """Test cache hit ratio calculation."""
    
def test_scan_efficiency_analysis():
    """Test scan method analysis."""
    
def test_join_metrics_extraction():
    """Test join strategy analysis."""
    
def test_filter_efficiency_calculation():
    """Test filter selectivity calculation."""
    
def test_performance_score_accurate():
    """Test performance score for efficient query."""
    
def test_performance_score_poor():
    """Test performance score for inefficient query."""
```

---

### 3. ExplainAntipatterns (`iqtoolkit_analyzer/explain_antipatterns.py`)

#### Purpose
Detect execution-specific anti-patterns and performance issues.

#### Public API

```python
from typing import List
from enum import Enum

class AntiPatternSeverity(Enum):
    """Severity levels for anti-patterns."""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"

@dataclass
class ExplainAntiPattern:
    """Detected anti-pattern from EXPLAIN analysis."""
    severity: AntiPatternSeverity
    type: str  # e.g., "seq_scan_large_table"
    node_type: str
    relation_name: str
    problem: str
    impact: str
    recommendation: str
    sql_example: Optional[str] = None
    estimated_improvement: Optional[str] = None
    metrics: Dict[str, Any] = field(default_factory=dict)

@dataclass
class IndexRecommendation:
    """Index recommendation from EXPLAIN analysis."""
    priority: str  # 'critical', 'high', 'medium', 'low'
    table_name: str
    columns: List[str]
    index_type: str  # 'btree', 'gin', 'gist', 'hash'
    reason: str
    sql: str  # CREATE INDEX statement
    estimated_improvement: str
    affected_queries: int = 1

class ExplainAntipatterns:
    """Detect anti-patterns in EXPLAIN plans."""
    
    def detect_all(self, plan: ExplainPlan) -> List[ExplainAntiPattern]:
        """Detect all anti-patterns in plan."""
        
    def detect_seq_scans_on_large_tables(
        self, 
        plan: ExplainPlan,
        row_threshold: int = 10000
    ) -> List[ExplainAntiPattern]:
        """Detect sequential scans on large tables."""
        
    def detect_inefficient_joins(
        self, 
        plan: ExplainPlan
    ) -> List[ExplainAntiPattern]:
        """Detect inefficient join strategies."""
        
    def detect_estimation_errors(
        self, 
        plan: ExplainPlan,
        error_threshold: float = 10.0
    ) -> List[ExplainAntiPattern]:
        """Detect significant row estimation errors."""
        
    def detect_poor_filters(
        self, 
        plan: ExplainPlan,
        removal_threshold: float = 0.99
    ) -> List[ExplainAntiPattern]:
        """Detect filters removing >99% of rows."""
        
    def detect_low_cache_hits(
        self, 
        plan: ExplainPlan,
        threshold: float = 0.90
    ) -> List[ExplainAntiPattern]:
        """Detect nodes with low cache hit ratios."""
        
    def detect_temp_file_usage(
        self, 
        plan: ExplainPlan
    ) -> List[ExplainAntiPattern]:
        """Detect queries using temp files."""
        
    def generate_index_recommendations(
        self, 
        antipatterns: List[ExplainAntiPattern]
    ) -> List[IndexRecommendation]:
        """Generate index recommendations from detected anti-patterns."""
```

#### Implementation Notes

**Sequential Scan Detection:**
```python
def detect_seq_scans_on_large_tables(
    self, 
    plan: ExplainPlan,
    row_threshold: int = 10000
) -> List[ExplainAntiPattern]:
    """Detect seq scans on large tables."""
    antipatterns = []
    
    def check_node(node: PlanNode):
        if node.node_type == 'Seq Scan':
            rows = node.actual_rows or node.plan_rows
            
            if rows > row_threshold:
                time_pct = (node.actual_total_time / plan.execution_time * 100) \
                    if node.actual_total_time and plan.execution_time else 0
                
                antipatterns.append(ExplainAntiPattern(
                    severity=AntiPatternSeverity.CRITICAL if time_pct > 50 else AntiPatternSeverity.HIGH,
                    type="seq_scan_large_table",
                    node_type="Seq Scan",
                    relation_name=node.relation_name,
                    problem=f"Sequential scan on {rows:,} rows",
                    impact=f"{time_pct:.1f}% of execution time",
                    recommendation=f"Create index on {node.relation_name}",
                    metrics={'rows': rows, 'time_pct': time_pct}
                ))
        
        for child in node.children:
            check_node(child)
    
    check_node(plan.root_node)
    return antipatterns
```

**Index Recommendation Generation:**
```python
def generate_index_recommendations(
    self, 
    antipatterns: List[ExplainAntiPattern]
) -> List[IndexRecommendation]:
    """Generate index recommendations."""
    recommendations = []
    
    for ap in antipatterns:
        if ap.type == 'seq_scan_large_table':
            # Infer columns from filter condition
            columns = self._extract_filter_columns(ap.metrics.get('filter'))
            
            if columns:
                rec = IndexRecommendation(
                    priority='critical' if ap.severity == AntiPatternSeverity.CRITICAL else 'high',
                    table_name=ap.relation_name,
                    columns=columns,
                    index_type='btree',
                    reason=f"Eliminate sequential scan on {ap.metrics['rows']:,} rows",
                    sql=f"CREATE INDEX idx_{ap.relation_name}_{'_'.join(columns)} "
                        f"ON {ap.relation_name} ({', '.join(columns)});",
                    estimated_improvement="70-90% reduction in execution time"
                ))
                recommendations.append(rec)
    
    return recommendations
```

#### Test Coverage

```python
# tests/test_explain_antipatterns.py

def test_detect_seq_scan_large_table():
    """Test detection of seq scans on large tables."""
    
def test_detect_nested_loop_issue():
    """Test detection of inefficient nested loops."""
    
def test_detect_estimation_error():
    """Test detection of row estimation errors."""
    
def test_detect_poor_filter():
    """Test detection of filters removing >99% rows."""
    
def test_detect_low_cache_hits():
    """Test detection of low cache hit ratios."""
    
def test_generate_index_recommendation():
    """Test index recommendation generation."""
    
def test_recommendation_sql_valid():
    """Test generated SQL is syntactically valid."""
```

---

### 4. ExplainRecommender (`iqtoolkit_analyzer/explain_recommender.py`)

#### Purpose
Generate prioritized optimization recommendations with optional LLM insights.

#### Public API

```python
@dataclass
class Recommendation:
    """Optimization recommendation."""
    priority: str  # 'critical', 'high', 'medium', 'low'
    category: str  # 'index', 'query_rewrite', 'statistics', 'config', 'schema'
    title: str
    description: str
    sql_example: Optional[str] = None
    estimated_impact: Optional[str] = None
    llm_insight: Optional[str] = None
    related_metrics: Dict[str, Any] = field(default_factory=dict)

class ExplainRecommender:
    """Generate optimization recommendations."""
    
    def __init__(self, llm_client: Optional[LLMClient] = None):
        """
        Initialize recommender.
        
        Args:
            llm_client: Optional LLM client for AI insights
        """
        self.llm_client = llm_client
    
    def generate_recommendations(
        self,
        plan: ExplainPlan,
        metrics: ExplainMetricsSummary,
        antipatterns: List[ExplainAntiPattern],
        use_llm: bool = True
    ) -> List[Recommendation]:
        """Generate complete set of recommendations."""
        
    def prioritize_recommendations(
        self, 
        recommendations: List[Recommendation]
    ) -> List[Recommendation]:
        """Sort recommendations by priority and impact."""
        
    def generate_llm_insights(
        self, 
        plan: ExplainPlan,
        antipatterns: List[ExplainAntiPattern]
    ) -> Optional[str]:
        """Generate AI-powered insights for complex issues."""
```

#### Implementation Notes

**LLM Prompt Construction:**
```python
def _build_llm_prompt(
    self, 
    plan: ExplainPlan,
    antipatterns: List[ExplainAntiPattern]
) -> str:
    """Build detailed prompt for LLM."""
    
    prompt = f"""Analyze this PostgreSQL EXPLAIN plan and provide optimization insights:

Execution Summary:
- Total time: {plan.execution_time:.2f}ms
- Planning time: {plan.planning_time:.2f}ms
- Root node: {plan.root_node.node_type}

Detected Issues:
"""
    
    for i, ap in enumerate(antipatterns, 1):
        prompt += f"\n{i}. {ap.problem}"
        prompt += f"\n   Severity: {ap.severity.value}"
        prompt += f"\n   Impact: {ap.impact}"
    
    prompt += """

Provide:
1. Root cause analysis (why is this happening?)
2. Specific optimization steps with SQL examples
3. Expected performance improvement
4. Any potential trade-offs or considerations

Format as clear, actionable recommendations for a database administrator.
"""
    
    return prompt
```

**Recommendation Prioritization:**
```python
def prioritize_recommendations(
    self, 
    recommendations: List[Recommendation]
) -> List[Recommendation]:
    """Sort by priority and estimated impact."""
    
    priority_order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3}
    
    return sorted(
        recommendations,
        key=lambda r: (
            priority_order.get(r.priority, 99),
            -self._parse_impact(r.estimated_impact)
        )
    )

def _parse_impact(self, impact: Optional[str]) -> float:
    """Extract numeric impact from string like '80-90%'."""
    if not impact:
        return 0.0
    
    # Extract first number from string
    match = re.search(r'(\d+)', impact)
    return float(match.group(1)) if match else 0.0
```

#### Test Coverage

```python
# tests/test_explain_recommender.py

def test_generate_recommendations():
    """Test recommendation generation."""
    
def test_prioritize_by_impact():
    """Test recommendations are prioritized correctly."""
    
def test_llm_prompt_construction():
    """Test LLM prompt is well-formed."""
    
def test_llm_insights_generation():
    """Test LLM insights are generated (integration test)."""
    
@pytest.mark.skip("Requires LLM connection")
def test_llm_with_real_client():
    """Test with actual LLM client."""
```

---

## Integration Specifications

### Enhanced Parser (`iqtoolkit_analyzer/parser.py`)

**Modifications:**

```python
def parse_postgres_log_with_explain(
    log_file_path: str, 
    log_format: str = "plain"
) -> pd.DataFrame:
    """
    Parse PostgreSQL logs with auto_explain output.
    
    Extracts both slow query entries and associated EXPLAIN plans.
    
    Returns:
        DataFrame with columns: timestamp, duration_ms, query, explain_json
    """
    
    # Parse regular log entries
    df = parse_postgres_log(log_file_path, log_format)
    
    # Extract EXPLAIN JSON blocks from log
    explain_map = _extract_explain_plans(log_file_path)
    
    # Match EXPLAIN plans to queries
    df['explain_json'] = df.apply(
        lambda row: _match_explain_to_query(row, explain_map),
        axis=1
    )
    
    return df

def _extract_explain_plans(log_file_path: str) -> Dict[str, str]:
    """
    Extract EXPLAIN JSON blocks from PostgreSQL log.
    
    Returns:
        Dict mapping query hash -> EXPLAIN JSON
    """
    
def _match_explain_to_query(row: pd.Series, explain_map: Dict) -> Optional[str]:
    """Match EXPLAIN plan to query row."""
```

### Enhanced Analyzer (`iqtoolkit_analyzer/analyzer.py`)

**Modifications:**

```python
from .explain_parser import ExplainParser, ExplainPlan
from .explain_metrics import ExplainMetrics, ExplainMetricsSummary
from .explain_antipatterns import ExplainAntipatterns, ExplainAntiPattern
from .explain_recommender import ExplainRecommender, Recommendation

@dataclass
class SlowQuery:
    # Existing fields...
    
    # NEW: EXPLAIN analysis fields
    explain_plan: Optional[ExplainPlan] = None
    explain_metrics: Optional[ExplainMetricsSummary] = None
    explain_antipatterns: List[ExplainAntiPattern] = field(default_factory=list)
    explain_recommendations: List[Recommendation] = field(default_factory=list)
    llm_explain_insight: Optional[str] = None

class SlowQueryAnalyzer:
    def __init__(self, llm_client: Optional[LLMClient] = None):
        self.query_rewriter = StaticQueryRewriter()
        
        # NEW: EXPLAIN analyzer components
        self.explain_parser = ExplainParser()
        self.explain_metrics = ExplainMetrics()
        self.explain_antipatterns = ExplainAntipatterns()
        self.explain_recommender = ExplainRecommender(llm_client)
    
    def analyze_slow_queries(
        self, 
        queries: Sequence[QueryRecord], 
        min_duration: float = 1000,
        analyze_explain: bool = True  # NEW parameter
    ) -> List[SlowQuery]:
        """Analyze slow queries with optional EXPLAIN analysis."""
        
        # Existing analysis...
        analyzed_queries = self._analyze_text_only(queries, min_duration)
        
        # NEW: Add EXPLAIN analysis if available
        if analyze_explain:
            for query in analyzed_queries:
                if query.explain_json:
                    self._analyze_explain_plan(query)
        
        return analyzed_queries
    
    def _analyze_explain_plan(self, query: SlowQuery):
        """Analyze EXPLAIN plan for a query."""
        try:
            # Parse EXPLAIN output
            query.explain_plan = self.explain_parser.parse(query.explain_json)
            
            # Extract metrics
            query.explain_metrics = self.explain_metrics.extract_all_metrics(
                query.explain_plan
            )
            
            # Detect anti-patterns
            query.explain_antipatterns = self.explain_antipatterns.detect_all(
                query.explain_plan
            )
            
            # Generate recommendations
            query.explain_recommendations = self.explain_recommender.generate_recommendations(
                query.explain_plan,
                query.explain_metrics,
                query.explain_antipatterns
            )
            
        except Exception as e:
            logger.warning(f"Failed to analyze EXPLAIN plan: {e}")
```

---

## Configuration Schema

### YAML Configuration

```yaml
# .iqtoolkit-analyzer.yml

explain_analysis:
  # Enable EXPLAIN plan analysis
  enabled: true
  
  # Analysis mode
  mode: 'auto'  # 'auto', 'log_only', 'connection_only'
  
  # Log-based configuration
  log_based:
    expect_auto_explain: true
    explain_format: 'json'  # 'json' or 'yaml'
  
  # Connection-based configuration (future)
  connection:
    enabled: false
    host: 'localhost'
    port: 5432
    database: 'mydb'
    user: 'readonly_user'
    password: '${PG_PASSWORD}'  # Environment variable
    
  # Detection thresholds
  thresholds:
    seq_scan_min_rows: 10000
    estimation_error_ratio: 10.0
    cache_hit_ratio_min: 0.95
    filter_removal_threshold: 0.99
    
  # LLM integration
  llm:
    use_for_explain: true
    trigger_conditions:
      - estimation_error > 100
      - multiple_antipatterns
      - critical_severity
```

### Environment Variables

```bash
# PostgreSQL connection for on-demand EXPLAIN
export PG_HOST=localhost
export PG_PORT=5432
export PG_DATABASE=mydb
export PG_USER=readonly_user
export PG_PASSWORD=secret

# EXPLAIN analysis options
export EXPLAIN_ENABLED=true
export EXPLAIN_USE_LLM=true
```

---

## Testing Strategy

### Test Data Fixtures

```
tests/fixtures/explain_plans/
├── basic/
│   ├── seq_scan.json
│   ├── index_scan.json
│   ├── index_only_scan.json
│   └── bitmap_scan.json
├── joins/
│   ├── nested_loop.json
│   ├── hash_join.json
│   ├── merge_join.json
│   └── cartesian_product.json
├── issues/
│   ├── estimation_error.json
│   ├── low_cache_hits.json
│   ├── temp_files.json
│   └── poor_filter.json
└── complex/
    ├── multi_table_join.json
    ├── subquery.json
    ├── cte.json
    └── window_function.json
```

### Performance Benchmarks

```python
# tests/benchmarks/test_explain_performance.py

@pytest.mark.benchmark
def test_parse_1000_plans(benchmark):
    """Benchmark parsing 1000 EXPLAIN plans."""
    plans = load_test_plans(1000)
    parser = ExplainParser()
    
    result = benchmark(lambda: [parser.parse(p) for p in plans])
    
    assert benchmark.stats.mean < 1.0  # < 1 second

@pytest.mark.benchmark
def test_analyze_100_queries(benchmark):
    """Benchmark analyzing 100 queries with EXPLAIN."""
    queries = load_test_queries_with_explain(100)
    analyzer = SlowQueryAnalyzer()
    
    result = benchmark(lambda: analyzer.analyze_slow_queries(queries))
    
    assert benchmark.stats.mean < 5.0  # < 5 seconds
```

---

## Documentation Requirements

### User Documentation

1. **EXPLAIN Setup Guide** (`docs/explain-setup.md`)
   - How to enable auto_explain in PostgreSQL
   - Configuration examples
   - Troubleshooting

2. **EXPLAIN Analysis Guide** (`docs/explain-analysis.md`)
   - Understanding EXPLAIN output
   - Interpreting metrics
   - Acting on recommendations

3. **FAQ** (update `docs/faq.md`)
   - "Why is EXPLAIN analysis not working?"
   - "Do I need auto_explain enabled?"
   - "Can I use without database connection?"

### Developer Documentation

1. **Architecture Diagram** (update `ARCHITECTURE.md`)
   - EXPLAIN analyzer component diagram
   - Data flow diagrams

2. **API Reference** (auto-generated from docstrings)
   - All public classes and methods
   - Examples and usage patterns

---

## Migration Path

### Phase 1: MVP Release (v0.3.0)

**Features:**
- ✅ JSON parsing
- ✅ Core metrics extraction
- ✅ 7 anti-pattern rules
- ✅ Index recommendations
- ✅ Unified reporting

**Not Included:**
- ❌ YAML parsing (deferred to v0.3.1)
- ❌ Connection-based EXPLAIN (deferred to v0.3.2)
- ❌ Advanced LLM features (optional in v0.3.0)

### Phase 2: Enhancement (v0.3.1)

**Features:**
- ✅ YAML format support
- ✅ Enhanced LLM integration
- ✅ Cross-query analysis
- ✅ Health scoring

### Phase 3: Advanced (v0.3.2)

**Features:**
- ✅ Connection-based EXPLAIN
- ✅ Before/after comparisons
- ✅ Trend analysis
- ✅ Performance regression detection

---

## Success Criteria

### Functional Requirements

- ✅ Parse 95%+ of valid EXPLAIN JSON without errors
- ✅ Detect sequential scans with 90%+ accuracy
- ✅ Generate syntactically valid index recommendations
- ✅ Handle PostgreSQL 9.6 through 16
- ✅ Graceful degradation when EXPLAIN unavailable

### Performance Requirements

- ✅ Parse EXPLAIN plan < 10ms per query
- ✅ Full analysis < 50ms per query
- ✅ Report generation overhead < 10%
- ✅ Memory usage < 100MB for 1000 queries

### Quality Requirements

- ✅ Test coverage > 85%
- ✅ No breaking changes to existing features
- ✅ Full documentation coverage
- ✅ Example EXPLAIN plans for all scenarios

---

## Appendix A: Example EXPLAIN JSON

```json
[
  {
    "Plan": {
      "Node Type": "Seq Scan",
      "Parallel Aware": false,
      "Relation Name": "users",
      "Alias": "users",
      "Startup Cost": 0.00,
      "Total Cost": 431.00,
      "Plan Rows": 1,
      "Plan Width": 36,
      "Actual Startup Time": 0.156,
      "Actual Total Time": 5.234,
      "Actual Rows": 12,
      "Actual Loops": 1,
      "Filter": "(email ~~ '%@gmail.com'::text)",
      "Rows Removed by Filter": 124988,
      "Shared Hit Blocks": 15234,
      "Shared Read Blocks": 2211,
      "Shared Dirtied Blocks": 0,
      "Shared Written Blocks": 0
    },
    "Planning Time": 0.125,
    "Triggers": [],
    "Execution Time": 5.456
  }
]
```

---

**End of Technical Specifications**

For questions or clarifications, please refer to:
- [RFC-002](rfcs/RFC-002-explain-analyzer.md) for design rationale
- [GitHub Issues](https://github.com/iqtoolkit/iqtoolkit-analyzer/issues) for bugs
- [GitHub Discussions](https://github.com/iqtoolkit/iqtoolkit-analyzer/discussions) for questions
