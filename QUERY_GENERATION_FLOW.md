# Complete NL-to-SQL Query Generation Flow

## Overview
This document provides a detailed walkthrough of how natural language queries are converted to SQL in your healthcare analytics system.

---

## 1. DATABASE SCHEMA LAYER

### **1.1 Core Tables Structure**

Your database follows a **dimensional data warehouse** design:

#### **Dimension Tables** (Reference Data)
- `dim_patient` - Patient master data
- `dim_provider` - Healthcare providers
- `dim_facility` - Healthcare facilities
- `dim_payer_plan` - Insurance payers
- `dim_date` - Date dimension
- `dim_code` - Medical codes (ICD, CPT, etc.)
- `dim_condition_group` - Condition groupings
- `dim_quality_measure` - Quality measures

#### **Fact Tables** (Transactional Data)
- `fact_encounter` - Patient encounters/visits
- `fact_diagnosis` - Diagnoses
- `fact_medication` - Medications prescribed
- `fact_claim_line` - Claim line items
- `fact_lab_result` - Lab test results
- `fact_patient_monthly_cost` - Monthly patient costs

#### **Bridge Tables** (Many-to-Many Relationships)
- `bridge_patient_condition_year` - Patient-condition mappings

#### **Reference Tables**
- `county_ref` - County reference data
- `patient_attribution` - Patient-organization-payer attribution (1,100 records)
  - Tracks which patients are attributed to which organizations and payers
  - 1,000 current attributions, 100 historical attributions
  - 50 unique organizations (ORG-001 to ORG-050)
  - 5 payer plans (BCBS, Aetna, United Healthcare, Cigna, Humana)
- `code_map_condition_group` - Code-to-condition mappings

### **1.2 Pre-built Views (Materialized Views)**

The system uses **pre-aggregated views** for performance:

**Key Views:**
- `vw_patients_2025` - Current year patient demographics
- `vw_patient_monthly_costs_2025` - Monthly patient costs
- `vw_patient_conditions_2025` - Patient conditions
- `vw_er_visits_2025` - ER visit data
- `vw_patient_er_summary_2025` - ER visit summary by patient
- `vw_cancer_prevalence_2025` - Cancer prevalence data
- `vw_total_cost_by_month_2025` - Monthly cost aggregates
- `vw_top100_patients_by_county_2025` - Top patients per county
- `vw_patient_procedure_events_2025` - Procedure events

**View Purpose:**
- Pre-join fact and dimension tables
- Pre-aggregate common metrics
- Simplify query generation
- Improve query performance

---

## 2. SEMANTIC LAYER (NL-SQL MAPPING)

### **2.1 Semantic Dictionary** (`nlsql_semantic_alias` table)

**84 active semantic terms** that map natural language to SQL constructs.

**Structure:**
```sql
CREATE TABLE nlsql_semantic_alias (
    alias_id INTEGER PRIMARY KEY,
    term VARCHAR(200) NOT NULL,           -- Natural language term
    term_type VARCHAR(50),                -- AGGREGATION, ATTRIBUTE, CONDITION, etc.
    table_name VARCHAR(100),              -- Source table
    column_name VARCHAR(100),             -- Target column
    view_name VARCHAR(100),               -- Target view
    filter_logic TEXT,                    -- WHERE clause logic
    aggregation VARCHAR(50),              -- SUM, COUNT, AVG, etc.
    description TEXT,                     -- Term description
    synonyms TEXT[],                      -- Alternative terms
    example_usage TEXT,                   -- Example query
    is_active BOOLEAN DEFAULT TRUE
);
```

**Examples:**
| Term | Type | View | Example Usage |
|------|------|------|---------------|
| top | AGGREGATION | - | Top 100 patients |
| count | AGGREGATION | - | Count of patients |
| county | ATTRIBUTE | vw_patients_current | Patients by county |
| state | ATTRIBUTE | vw_patients_current | Patients in California |
| age | ATTRIBUTE | vw_patients_current | Patients over 65 |
| gender | ATTRIBUTE | vw_patients_current | Women aged 65-75 |
| CPT code | ATTRIBUTE | vw_claim_lines_2025 | Total events for CPT 97110 |

### **2.2 Query Templates** (`nlsql_query_templates` table)

**18 active query templates** that provide SQL patterns for common question types.

**Structure:**
```sql
CREATE TABLE nlsql_query_templates (
    template_id INTEGER PRIMARY KEY,
    natural_language_pattern TEXT NOT NULL,  -- NL pattern with placeholders
    sql_template TEXT NOT NULL,              -- SQL template
    category VARCHAR(50),                    -- Query category
    description TEXT,                        -- Template description
    example_input TEXT,                      -- Example NL query
    example_output TEXT,                     -- Example SQL output
    is_active BOOLEAN DEFAULT TRUE
);
```

**Template Categories:**
| Category | Pattern | Example |
|----------|---------|---------|
| COUNT | How many {entity} [with {condition}]? | How many patients with diabetes? |
| DEMOGRAPHICS | {entity} by {dimension1} and {dimension2} | Patients by gender and age |
| COST | Total cost [of {population}] by {grouping} | Total cost by month |
| TOP_N | Top {N} {entity} [by {metric}] | Top 100 most expensive patients |
| PATIENT_DETAIL | {entity} {id} {metric} for {codes} | Patient 528 events for CPT 97110 |
| UTILIZATION | {entity} most often {action} | Patients most often admitted to ER |
| PREVALENCE | How many {entity} have {condition}? | How many have diabetes? |
| QUALITY | Percentage of {population} who received {measure} | Women 65-75 osteoporosis screening |
| GEOGRAPHIC | Top {N} {entity} by {metric} for each {geography} | Top patients per county |

---

## 3. QUERY GENERATION PIPELINE

### **3.1 Entry Point: API Request**

**Endpoint:** `POST /api/query`

**Request Body:**
```json
{
  "question": "Show me high-cost patients",
  "include_explanation": true,
  "model": "gpt-4o",
  "skip_spell_check": false,
  "force_chart_type": null
}
```

**Flow starts at:** `app/main.py` → `@app.post("/api/query")`

---

### **3.2 Stage 1: Initialization & Context Loading**

**File:** `app/agents/nl_to_sql_agent.py` → `NLToSQLAgent.__init__()`

**Steps:**

1. **Initialize OpenAI Client**
   ```python
   self.client = OpenAI(
       api_key=settings.OPENAI_API_KEY,
       base_url=settings.OPENAI_API_BASE_URL
   )
   ```

2. **Load Database Context** (`_load_context()`)
   ```python
   self.view_schemas = db_service.get_view_schemas()        # Get column schemas
   self.semantic_dictionary = db_service.get_semantic_dictionary()  # Get 84 semantic terms
   self.query_templates = db_service.get_query_templates()  # Get 18 templates
   ```

3. **Initialize Sub-Modules**
   - `AmbiguityChecker` - Detects unclear queries
   - `SQLGenerator` - Generates SQL
   - `VisualizationRecommender` - Recommends charts

**What Gets Loaded:**

**View Schemas Example:**
```python
{
  "vw_patients_2025": [
    {"column": "patient_id", "type": "character varying"},
    {"column": "age_years", "type": "integer"},
    {"column": "gender", "type": "character varying"},
    {"column": "state", "type": "character varying"},
    ...
  ],
  "vw_patient_monthly_costs_2025": [
    {"column": "patient_id", "type": "character varying"},
    {"column": "total_cost", "type": "numeric"},
    {"column": "month", "type": "integer"},
    ...
  ]
}
```

---

### **3.3 Stage 2: Ambiguity Detection**

**File:** `app/agents/ambiguity_checker.py` → `AmbiguityChecker.check_for_ambiguity()`

**Purpose:** Detect vague or unclear queries before SQL generation.

**LLM Prompt:**
```
You are an ULTRA-STRICT expert at identifying ambiguous healthcare analytics queries.

CRITICAL AMBIGUITIES TO ALWAYS FLAG:
1. "Top/best/frequent" WITHOUT specific metric - ALWAYS FLAG
2. "Show me ER frequent flyers" - Frequent by what? Visits? Cost? AMBIGUOUS!
3. "Top 10 patients" - Top by what metric? Cost? Visits? Age? AMBIGUOUS!
4. ANY ranking/superlative without explicit criteria - AMBIGUOUS!

Return ONLY a JSON object:
{
  "is_ambiguous": true/false,
  "reason": "why it's ambiguous",
  "clarification_options": [
    {"text": "Top 10 by total cost", "refined_query": "..."},
    {"text": "Top 10 by ER visits", "refined_query": "..."}
  ]
}
```

**Example:**

**Input:** "Show me high-cost patients"

**LLM Response:**
```json
{
  "is_ambiguous": true,
  "reason": "High-cost by what threshold or criteria? And for which condition or overall?",
  "clarification_options": [
    {
      "text": "Patients with costs above $50,000 annually",
      "refined_query": "Show me patients with annual costs above $50,000"
    },
    {
      "text": "Top 10 highest cost patients",
      "refined_query": "Show me the top 10 highest cost patients overall"
    }
  ]
}
```

**Decision:**
- If `is_ambiguous: true` → Return error with clarification options
- If `is_ambiguous: false` → Proceed to SQL generation

---

### **3.4 Stage 3: SQL Generation**

**File:** `app/agents/sql_generator.py` → `SQLGenerator.generate_sql()`

This is the **CORE** of the system.

#### **3.4.1 System Prompt Construction**

**File:** `app/agents/prompts.py` → `PromptBuilder.build_sql_generation_prompt()`

**Prompt Structure:**

```
You are a healthcare analytics SQL expert. Convert natural language to PostgreSQL.

IMPORTANT RULES:
1. ONLY generate SELECT queries
2. Use the views below - reference ONLY columns that exist
3. Use exact column names - do not invent column names
4. For year filtering, use WHERE on year columns
5. Return patient_id, never patient names (PHI protection)
6. LIMIT clause: NEVER add LIMIT unless user specifies (e.g., "top 10")
7. ORDER BY: ALWAYS use intelligent ordering:
   - Rankings/top → ORDER BY metric DESC
   - Lists → ORDER BY relevant column
   - Time-series → ORDER BY date ASC
8. Generate ONLY SQL, no explanations

FORMATTING:
- Percentages: ROUND(value, 2) and multiply by 100
- Money: ROUND(value, 2)
- Counts: Keep as integers

CONDITION QUERIES:
- "Show me [condition] patients" → vw_patient_conditions_2025
- Cancer types: Lung, Prostate, Colorectal, Breast, Other
- "Any cancer" → WHERE condition_name LIKE '%cancer%'

STATE HANDLING:
- States stored as 2-letter codes (CA, FL, TX, NY)
- Convert full names to codes: California → CA

AVAILABLE VIEWS:
vw_patients_2025:
  patient_id (character varying), age_years (integer), gender (character varying), ...

vw_patient_monthly_costs_2025:
  patient_id (character varying), total_cost (numeric), month (integer), ...

vw_patient_conditions_2025:
  patient_id (character varying), condition_name (character varying), ...

[... more views ...]

QUERY TEMPLATES:
- Pattern: How many {entity} [with {condition}]?
  SQL: SELECT COUNT(*) FROM ...
  Example: "How many patients with diabetes?" → SELECT COUNT(DISTINCT patient_id) ...

[... 10 templates included ...]

EXAMPLE QUERIES:
Q: "How many patients do we have?"
A: SELECT COUNT(*) AS patient_count FROM vw_patients_2025;

Q: "Show me patients in Florida"
A: SELECT patient_id, age_years, gender FROM vw_patients_2025 WHERE state = 'FL' LIMIT 100;

Q: "Top 10 most expensive patients"
A: SELECT patient_id, SUM(total_cost) as total_cost_2025
   FROM vw_patient_monthly_costs_2025
   GROUP BY patient_id
   ORDER BY total_cost_2025 DESC
   LIMIT 10;

[... more examples ...]

Now generate the SQL query for the user's question. Return ONLY the SQL query.
```

#### **3.4.2 LLM Call**

**OpenAI API Call:**
```python
response = self.client.chat.completions.create(
    model="gpt-4o",  # or user-specified model
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": "Show me patients with diabetes over 65"}
    ],
    temperature=0.0,
    max_tokens=2000
)
```

**LLM Response:**
```sql
SELECT p.patient_id, p.age_years, c.condition_name
FROM vw_patient_conditions_2025 c
JOIN vw_patients_2025 p ON p.patient_sk = c.patient_sk
WHERE c.condition_name IN ('Type 2 diabetes', 'Type 1 diabetes')
  AND p.age_years > 65
LIMIT 100;
```

#### **3.4.3 SQL Post-Processing**

**Steps:**

1. **Extract SQL** from response
2. **Clean markdown** (remove ```sql blocks)
   ```python
   if sql.startswith("```sql"):
       sql = sql.replace("```sql", "").replace("```", "").strip()
   ```

3. **Validate SQL** for security
   ```python
   is_valid, error_msg = db_service.validate_query(sql)
   # Blocks: INSERT, UPDATE, DELETE, DROP, etc.
   ```

4. **Return result**
   ```python
   return {
       "success": True,
       "sql": sql,
       "model": "gpt-4o",
       "tokens_used": 1234
   }
   ```

---

### **3.5 Stage 4: Conversational Context (Optional)**

**File:** `app/agents/prompts.py` → `build_conversational_context_prompt()`

**Purpose:** Handle drill-down/follow-up queries.

**Example:**

**Previous Query:** "Show me patients with 3 or more ER visits"
**Previous SQL:**
```sql
SELECT patient_id, er_visits_2025
FROM vw_patient_er_summary_2025
WHERE er_visits_2025 >= 3;
```

**Follow-up Query:** "What are the common diagnoses for these patients?"

**Additional Context Added to System Prompt:**
```
CONVERSATIONAL CONTEXT:
You are in a drill-down conversation. The user previously asked: "Show me patients with 3 or more ER visits"

Previous SQL:
SELECT patient_id, er_visits_2025
FROM vw_patient_er_summary_2025
WHERE er_visits_2025 >= 3;

FOLLOW-UP DETECTION:
- If current question contains: "these", "those", "them", "their", "what", "which", "breakdown"
- AND builds on previous query
- THEN use CTE pattern:

WITH previous_cohort AS (
  [previous SQL]
)
SELECT ...
FROM relevant_table
WHERE patient_id IN (SELECT patient_id FROM previous_cohort)
```

**Generated SQL:**
```sql
WITH previous_cohort AS (
  SELECT patient_id, er_visits_2025
  FROM vw_patient_er_summary_2025
  WHERE er_visits_2025 >= 3
)
SELECT c.condition_name, COUNT(*) as patient_count
FROM vw_patient_conditions_2025 c
WHERE c.patient_id IN (SELECT patient_id FROM previous_cohort)
GROUP BY c.condition_name
ORDER BY patient_count DESC;
```

---

### **3.6 Stage 5: SQL Execution**

**File:** `app/database.py` → `DatabaseService.execute_query()`

**Steps:**

1. **Establish Connection**
   ```python
   with self.get_session() as session:
   ```

2. **Set Query Timeout**
   ```sql
   SET statement_timeout = '30s';
   ```

3. **Execute SQL**
   ```python
   result = session.execute(text(sql))
   rows = result.fetchall()
   columns = result.keys()
   ```

4. **Format Results**
   ```python
   formatted_rows = [
       {columns[i]: row[i] for i in range(len(columns))}
       for row in rows
   ]
   ```

5. **Return Data**
   ```python
   return {
       "success": True,
       "columns": list(columns),
       "rows": formatted_rows,
       "row_count": len(formatted_rows),
       "truncated": len(formatted_rows) >= max_results
   }
   ```

---

### **3.7 Stage 6: Visualization Recommendation**

**File:** `app/agents/visualization_recommender.py` → `recommend_visualization()`

**Purpose:** Automatically select the best chart type based on query results.

**Decision Logic:**

```python
# Single value → Metric Card
if num_columns == 1 and row_count == 1:
    return {
        "recommended_chart": "metric",
        "chart_config": {"value_column": columns[0]},
        "reason": "Single metric value"
    }

# 3 columns (2 categorical + 1 numeric) → Grouped Bar Chart
if num_columns == 3 and value_col and row_count <= 50:
    return {
        "recommended_chart": "grouped_bar",
        "chart_config": {...},
        "reason": "Two groupings with numeric value"
    }

# 2 columns (1 categorical + 1 numeric, ≤10 rows) → Pie Chart
if num_columns == 2 and row_count <= 10:
    return {
        "recommended_chart": "pie",
        "chart_config": {...},
        "reason": "Small categorical breakdown"
    }

# Time series → Line Chart
if has_date_column:
    return {
        "recommended_chart": "line",
        "chart_config": {...},
        "reason": "Time-based trend"
    }

# Default categorical → Bar Chart
return {
    "recommended_chart": "bar",
    "chart_config": {...},
    "reason": "Categorical comparison"
}
```

**Number Format Detection:**
```python
def detect_number_format(question, columns, results):
    # Detect currency
    currency_keywords = ['cost', 'price', 'amount', 'revenue', 'payment', 'dollar']
    is_currency = any(kw in question.lower() for kw in currency_keywords)

    # Detect K/M notation need
    numeric_values = [extract_numbers_from_rows(results)]
    max_value = max(numeric_values)
    use_short_numbers = max_value >= 10000  # Use K/M for values ≥10K

    # Detect decimal places
    has_decimals = any(val != int(val) for val in numeric_values)
    decimal_places = 2 if has_decimals else 0

    return {
        "isCurrency": is_currency,
        "useShortNumbers": use_short_numbers,
        "decimalPlaces": decimal_places
    }
```

---

### **3.8 Stage 7: Final Response**

**File:** `app/agents/nl_to_sql_agent.py` → Returns combined response

**Response Structure:**
```json
{
  "success": true,
  "natural_language_query": "Show me patients with diabetes over 65",
  "sql": "SELECT p.patient_id, p.age_years, c.condition_name FROM vw_patient_conditions_2025 c JOIN vw_patients_2025 p ON p.patient_sk = c.patient_sk WHERE c.condition_name IN ('Type 2 diabetes', 'Type 1 diabetes') AND p.age_years > 65 LIMIT 100;",
  "explanation": "This query joins patient conditions with patient demographics to find diabetic patients over 65 years old",
  "columns": ["patient_id", "age_years", "condition_name"],
  "rows": [
    {"patient_id": "P12345", "age_years": 67, "condition_name": "Type 2 diabetes"},
    {"patient_id": "P67890", "age_years": 72, "condition_name": "Type 1 diabetes"},
    ...
  ],
  "row_count": 47,
  "truncated": false,
  "model": "gpt-4o",
  "tokens_used": 1234,
  "visualization": {
    "recommended_chart": "table",
    "chart_config": {
      "columns": ["patient_id", "age_years", "condition_name"],
      "page_size": 20
    },
    "reason": "Record-level data best shown as table",
    "number_format": {
      "isCurrency": false,
      "useShortNumbers": false,
      "decimalPlaces": 0
    }
  },
  "execution_time_ms": 142.5
}
```

---

## 4. KEY COMPONENTS SUMMARY

### **4.1 Data Flow Diagram**

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INPUT                              │
│           "Show me patients with diabetes over 65"              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  STAGE 1: INITIALIZATION                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Load Context:                                            │  │
│  │  • View schemas (9 views, columns with types)           │  │
│  │  • Semantic dictionary (84 terms)                       │  │
│  │  • Query templates (18 patterns)                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               STAGE 2: AMBIGUITY DETECTION                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ LLM Call: Check if query is vague/unclear               │  │
│  │ Result: is_ambiguous = false                            │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  STAGE 3: SQL GENERATION                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Build System Prompt:                                     │  │
│  │  • Rules (LIMIT, ORDER BY, PHI, etc.)                   │  │
│  │  • View schemas with columns                            │  │
│  │  • Query templates                                       │  │
│  │  • Example queries                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ LLM Call (OpenAI GPT-4o):                               │  │
│  │  messages = [                                            │  │
│  │    {role: "system", content: system_prompt},            │  │
│  │    {role: "user", content: user_query}                  │  │
│  │  ]                                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SQL Response:                                            │  │
│  │  SELECT p.patient_id, p.age_years, c.condition_name    │  │
│  │  FROM vw_patient_conditions_2025 c                      │  │
│  │  JOIN vw_patients_2025 p ON p.patient_sk = c.patient_sk│  │
│  │  WHERE c.condition_name IN ('Type 2 diabetes',         │  │
│  │        'Type 1 diabetes') AND p.age_years > 65         │  │
│  │  LIMIT 100;                                             │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Validation: Check for blocked keywords (INSERT, DROP)   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   STAGE 4: SQL EXECUTION                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Execute against PostgreSQL:                              │  │
│  │  • SET statement_timeout = '30s'                        │  │
│  │  • Execute SQL                                           │  │
│  │  • Fetch results                                         │  │
│  │  • Format as JSON                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│            STAGE 5: VISUALIZATION RECOMMENDATION                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Analyze Results:                                         │  │
│  │  • 3 columns (patient_id, age_years, condition_name)   │  │
│  │  • 47 rows                                               │  │
│  │  • Has ID column → recommend "table"                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Number Format Detection:                                 │  │
│  │  • No currency keywords → isCurrency: false             │  │
│  │  • No large numbers → useShortNumbers: false            │  │
│  │  • Integer values → decimalPlaces: 0                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FINAL RESPONSE                             │
│  {                                                              │
│    "success": true,                                             │
│    "sql": "SELECT ...",                                         │
│    "columns": [...],                                            │
│    "rows": [{...}, {...}],                                      │
│    "visualization": {                                           │
│      "recommended_chart": "table",                              │
│      "number_format": {...}                                     │
│    }                                                            │
│  }                                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. OPTIMIZATION OPPORTUNITIES FOR SCALE

### **5.1 Current Limitations**

1. **Hardcoded View Names**
   - Only 9 views explicitly mentioned in prompt
   - Doesn't auto-discover new views

2. **Limited Semantic Dictionary**
   - Only 84 terms
   - Manual maintenance required

3. **Template Limitation**
   - Only 10 templates used (first 10 of 18)
   - No dynamic template selection

4. **No Query Caching**
   - Same queries regenerate SQL every time

5. **Single-Shot Generation**
   - No iterative refinement if SQL fails

### **5.2 Recommendations to Scale**

#### **A. Dynamic Schema Discovery**

**Current:** Hardcoded view list
```python
key_views = ['vw_patients_2025', 'vw_patient_monthly_costs_2025', ...]
```

**Improved:** Auto-discover all views
```python
def build_sql_generation_prompt(view_schemas, query_templates):
    # Include ALL views dynamically
    schemas_text = ""
    for view_name, columns in view_schemas.items():
        if view_name.startswith('vw_'):  # All views
            columns_str = ", ".join([f"{col['column']} ({col['type']})"
                                    for col in columns])
            schemas_text += f"\n{view_name}:\n  {columns_str}\n"
    ...
```

**Benefits:**
- New views automatically included
- No code changes needed when schema evolves
- Supports unlimited views

#### **B. RAG (Retrieval-Augmented Generation)**

**Problem:** Current prompt includes ALL schemas/templates → Token waste

**Solution:** Use vector embeddings to retrieve only relevant schemas

**Implementation:**

1. **Create Embeddings Database**
   ```python
   # Store embeddings for each view + description
   view_embeddings = {
       "vw_patients_2025": {
           "embedding": [0.123, 0.456, ...],  # Vector embedding
           "description": "Patient demographics including age, gender, state",
           "columns": ["patient_id", "age_years", "gender", "state", ...]
       },
       ...
   }
   ```

2. **Query-Time Retrieval**
   ```python
   def get_relevant_views(question: str, top_k=3):
       question_embedding = embed(question)

       # Find most similar views
       similarities = []
       for view_name, data in view_embeddings.items():
           similarity = cosine_similarity(question_embedding, data['embedding'])
           similarities.append((view_name, similarity))

       # Return top K most relevant
       return sorted(similarities, key=lambda x: x[1], reverse=True)[:top_k]
   ```

3. **Build Focused Prompt**
   ```python
   relevant_views = get_relevant_views(question, top_k=3)
   # Include only these 3 views in prompt → Saves tokens!
   ```

**Benefits:**
- Reduce prompt size 70-80%
- Faster LLM response
- Lower cost
- Can handle 100+ views

#### **C. Query Caching Layer**

**Problem:** Same queries generate SQL repeatedly

**Solution:** Cache SQL for common queries

**Implementation:**

```python
import hashlib
import redis

class QueryCache:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379)
        self.ttl = 3600  # 1 hour

    def get_cached_sql(self, question: str) -> Optional[str]:
        """Get cached SQL for question"""
        cache_key = f"nlsql:{hashlib.md5(question.encode()).hexdigest()}"
        cached = self.redis_client.get(cache_key)
        return cached.decode() if cached else None

    def cache_sql(self, question: str, sql: str):
        """Cache SQL for question"""
        cache_key = f"nlsql:{hashlib.md5(question.encode()).hexdigest()}"
        self.redis_client.setex(cache_key, self.ttl, sql)
```

**Usage:**
```python
def generate_sql(question):
    # Check cache first
    cached_sql = query_cache.get_cached_sql(question)
    if cached_sql:
        return {"success": True, "sql": cached_sql, "cached": True}

    # Generate if not cached
    result = llm_generate_sql(question)

    # Cache result
    if result['success']:
        query_cache.cache_sql(question, result['sql'])

    return result
```

**Benefits:**
- 10x faster for repeat queries
- Reduce LLM costs 80%+
- Consistent results

#### **D. Iterative SQL Refinement**

**Problem:** If SQL fails, give up immediately

**Solution:** Auto-retry with error feedback

**Implementation:**

```python
def generate_sql_with_retry(question, max_retries=3):
    for attempt in range(max_retries):
        # Generate SQL
        result = generate_sql(question)

        if not result['success']:
            return result

        sql = result['sql']

        # Validate SQL
        is_valid, error_msg = validate_query(sql)
        if not is_valid:
            if attempt < max_retries - 1:
                # Retry with error feedback
                question_with_feedback = f"""{question}

Previous attempt generated invalid SQL:
{sql}

Error: {error_msg}

Please fix the SQL and try again."""
                continue
            else:
                return {"success": False, "error": error_msg}

        # Execute SQL
        try:
            result = execute_query(sql)
            return result
        except Exception as e:
            if attempt < max_retries - 1:
                # Retry with execution error
                question_with_feedback = f"""{question}

Previous SQL:
{sql}

Execution error: {str(e)}

Please fix and retry."""
                continue
            else:
                return {"success": False, "error": str(e)}

    return {"success": False, "error": "Max retries exceeded"}
```

**Benefits:**
- 30-40% fewer failures
- Self-correcting system
- Better user experience

#### **E. Semantic Layer Enrichment**

**Problem:** Only 84 semantic terms is limiting

**Solution:** Auto-generate semantic mappings from schema

**Implementation:**

```python
def enrich_semantic_dictionary():
    """Auto-generate semantic aliases from database schema"""
    new_terms = []

    # Get all views and columns
    view_schemas = get_view_schemas()

    for view_name, columns in view_schemas.items():
        for col in columns:
            column_name = col['column']

            # Generate natural language variants
            variants = generate_nl_variants(column_name)
            # e.g., "total_cost" → ["total cost", "cost", "spending", "expenditure"]

            for variant in variants:
                new_terms.append({
                    "term": variant,
                    "term_type": "ATTRIBUTE",
                    "view_name": view_name,
                    "column_name": column_name,
                    "example_usage": f"Show me patients by {variant}"
                })

    # Insert into nlsql_semantic_alias table
    batch_insert(new_terms)

    logger.info(f"Added {len(new_terms)} semantic terms")
```

**Benefits:**
- 10x more semantic coverage
- Automated maintenance
- Better NL understanding

#### **F. Multi-Model Fallback**

**Problem:** Single model (GPT-4o) failure = total failure

**Solution:** Fallback chain

**Implementation:**

```python
MODEL_CHAIN = [
    ("gpt-4o", "primary"),           # Best quality
    ("gpt-4o-mini", "fast"),         # Faster, cheaper
    ("claude-3-sonnet", "backup")    # Different provider
]

def generate_sql_with_fallback(question):
    last_error = None

    for model_name, tier in MODEL_CHAIN:
        try:
            logger.info(f"Trying {model_name} ({tier})")

            result = generate_sql(question, model=model_name)

            if result['success']:
                result['model_tier'] = tier
                return result

            last_error = result.get('error')

        except Exception as e:
            logger.warning(f"{model_name} failed: {str(e)}")
            last_error = str(e)
            continue

    return {
        "success": False,
        "error": f"All models failed. Last error: {last_error}"
    }
```

**Benefits:**
- 99.9% uptime
- Cost optimization (try cheap first)
- Vendor redundancy

---

## 6. COMPLETE FILE REFERENCE

| File | Purpose |
|------|---------|
| `app/main.py` | API entry point |
| `app/agents/nl_to_sql_agent.py` | Main orchestrator |
| `app/agents/sql_generator.py` | SQL generation logic |
| `app/agents/ambiguity_checker.py` | Ambiguity detection |
| `app/agents/prompts.py` | System prompts |
| `app/agents/visualization_recommender.py` | Chart selection |
| `app/database.py` | Database operations |
| `app/config.py` | Configuration |

---

## 7. MONITORING & OBSERVABILITY

To scale, add logging at each stage:

```python
# Log query flow
logger.info(f"=== Query Flow Started ===")
logger.info(f"Question: {question}")
logger.info(f"Stage 1: Context loaded - {len(view_schemas)} views, {len(semantic_dictionary)} terms")
logger.info(f"Stage 2: Ambiguity check - is_ambiguous: {ambiguity_result['is_ambiguous']}")
logger.info(f"Stage 3: SQL generated - {len(sql)} chars, {tokens_used} tokens")
logger.info(f"Stage 4: SQL executed - {row_count} rows in {execution_time}ms")
logger.info(f"Stage 5: Visualization - {recommended_chart}")
logger.info(f"=== Query Flow Complete - Total: {total_time}ms ===")
```

**Key Metrics to Track:**
- Query success rate (%)
- Average generation time (ms)
- Token usage per query
- Cache hit rate (%)
- Model fallback frequency
- Most common failure reasons

---

This is your complete NL-SQL query generation flow! 🎉
