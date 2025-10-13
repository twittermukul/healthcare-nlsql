# Healthcare Analytics Star Schema for NL→SQL

Production-ready star schema with **intelligent NL→SQL FastAPI application** powered by OpenAI GPT. Features context-aware spell checking, ambiguity detection, and dynamic schema inspection for healthcare analytics.

## ✨ Key Features

### 🤖 **Intelligent NL→SQL Translation**
- **Dynamic Schema Inspection**: Auto-loads actual view schemas from database - no hardcoded mappings
- **Multi-Model Support**: Switch between GPT-4o, GPT-4o-mini, and GPT-5 on-the-fly
- **State-Smart Queries**: Handles both "Florida" and "FL" automatically

### 🎯 **Smart Query Understanding**
- **LLM-Powered Spell Checking**: Context-aware corrections (e.g., "florda" → "florida", "diabtes" → "diabetes")
- **Ambiguity Detection**: Asks for clarification when queries are vague
  - "Show me top 10 t2dm patients" → Prompts: "Top by cost? ER visits? Complications?"
- **Interactive Clarification**: Click options or type custom clarifications

### 🎨 **Beautiful Web UI**
- Gradient purple interface with real-time results
- Model selection dropdown
- Copy-to-clipboard for SQL queries
- Example queries sidebar
- Spell check confirmations with side-by-side comparison
- Smart clarification prompts with clickable options

### 🏗️ **Production-Ready Architecture**
- Star schema optimized for population health, cost analysis, and quality measures
- 20+ semantic views for natural language queries
- Row-level security ready
- Query validation and PHI protection

## 📦 Package Contents

```
NLSQL/
├── README.md                       # This file - overview & documentation
├── SETUP.md                        # 📖 Step-by-step setup guide (START HERE)
├── SUMMARY.md                      # Executive summary
├── .env.example                    # Configuration template
├── .env                            # Your database config (edit this)
├── .gitignore                      # Git ignore file (protects .env)
├── deploy.sh                       # Automated deployment script
├── 00_test_queries.sql             # Quick validation tests (run after setup)
├── 01_schema_ddl.sql               # Core schema DDL (tables, indexes, sequences)
├── 02_seed_data.sql                # Reference data & code mappings
├── 03_semantic_views.sql           # LLM-friendly semantic views
├── 04_nlsql_ontology.sql           # NL→SQL dictionary & query templates
├── 05_example_queries.sql          # Production queries for all 9 use cases
├── 06_sample_data_generator.sql    # Sample data (1000 patients, 50k+ claims)
└── app/                            # 🚀 FastAPI NL→SQL Application
    ├── main.py                     # FastAPI server with intelligent routing
    ├── nl_to_sql_agent.py          # LLM-powered SQL generation with ambiguity detection
    ├── spell_checker.py            # Context-aware spell checking
    ├── database.py                 # Dynamic schema inspection & query execution
    ├── config.py                   # Settings with env var loading
    ├── models.py                   # Pydantic request/response models
    ├── requirements.txt            # Python dependencies
    ├── run.sh                      # Launch script
    ├── .env                        # API configuration (OpenAI key, model, DB)
    ├── .env.example                # Template for API config
    └── static/
        └── index.html              # Beautiful web UI with spell check & clarifications
```

## 🎯 Design Principles

1. **Star-first architecture**: Wide, denormalized dimensions + additive fact tables
2. **Semantic layer**: Views with human-readable names for NL→SQL agents
3. **One obvious place for each answer**: Costs in claims/monthly rollups, conditions in bridges
4. **Code maps**: Decouple ICD/CPT from clinical groupings (e.g., "diabetes", "cancer")
5. **Performance**: Targeted indexes, materialized aggregates, year-based partitioning ready

## 🚀 Quick Start

> **📖 New User?** See [SETUP.md](SETUP.md) for detailed step-by-step instructions

### Option A: Full Application Stack (Recommended)

#### 1. Deploy Database Schema

Edit [`.env`](.env) with your database credentials:
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=healthcare_analytics
DB_USER=postgres
DB_PASSWORD=your_password_here
LOAD_SAMPLE_DATA=yes
RUN_TESTS=yes
```

```bash
# One-command database deployment (uses .env settings)
./deploy.sh
```

This loads:
- ✅ Star schema (9 dims, 7 facts, 2 aggregates)
- ✅ 20+ semantic views
- ✅ Sample data (1000 patients, 50k claims, 1100 patient attributions)
- ✅ NL→SQL ontology

**Database Setup Scripts:**
- `01_schema_ddl.sql` - Table structures
- `02_seed_data.sql` - Reference data
- `03_semantic_views.sql` - Pre-built views
- `04_nlsql_ontology.sql` - Semantic layer
- `05_example_queries.sql` - Test queries
- `06_sample_data_generator.sql` - Patient & claims data
- `07_populate_patient_attribution.sql` - Patient-org-payer attribution

#### 2. Configure FastAPI Application

Edit `app/.env`:
```bash
# OpenAI Configuration
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-4o  # or gpt-4o-mini, gpt-5
OPENAI_MAX_TOKENS=16384

# Database (same as main .env)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=healthcare_analytics
DB_USER=postgres
DB_PASSWORD=your_password
```

#### 3. Launch Application

```bash
cd app
./run.sh
```

Open browser to `http://localhost:8000` 🎉

**Features you'll see:**
- 🎨 Beautiful gradient UI with example queries
- 🔍 LLM-powered spell checking ("florda" → "florida")
- 🤔 Ambiguity detection ("top 10 patients" → asks for clarification)
- 📊 Real-time SQL generation and execution
- 🔄 Model switching (GPT-4o, GPT-4o-mini, GPT-5)

### Option B: Database Only

**Option B: Manual deployment**
```bash
# PostgreSQL 12+ (recommended)
psql -U your_user -d your_database -f 01_schema_ddl.sql
psql -U your_user -d your_database -f 02_seed_data.sql
psql -U your_user -d your_database -f 03_semantic_views.sql
psql -U your_user -d your_database -f 04_nlsql_ontology.sql
psql -U your_user -d your_database -f 06_sample_data_generator.sql  # Optional: test data
```

**What gets loaded:**
- **02_seed_data.sql**: Reference data (condition groups, quality measures, code mappings, counties, dim_date 2020-2030)
- **06_sample_data_generator.sql**: 1000 patients, 20 providers, 10 facilities, ~50k claim lines, conditions, encounters

**Compatibility**: PostgreSQL 12+, Snowflake, BigQuery (minimal adaptation needed for sequences/data types)

### 2. Verify Installation

```bash
# Run comprehensive test suite (validates all 9 use cases)
psql -U your_user -d your_database -f 00_test_queries.sql
```

This will test:
- ✅ All 9 use cases return data
- ✅ Semantic views work correctly
- ✅ Sample data loaded properly
- ✅ Performance statistics

Or run individual checks:
```sql
-- Quick data check
SELECT COUNT(*) FROM dim_patient;           -- Should be 1000
SELECT COUNT(*) FROM fact_claim_line;       -- Should be ~50,000
SELECT COUNT(*) FROM vw_patients_2025;      -- Should be ~980 (excluding deceased)
```

### 3. Run Example Queries

```sql
-- Population by gender and age
SELECT gender, age_bucket_10yr, COUNT(*)
FROM vw_patients_2025
GROUP BY gender, age_bucket_10yr;

-- Osteoporosis screening rate
SELECT COUNT(*) FILTER (WHERE is_screened) / COUNT(*)::DECIMAL AS rate
FROM vw_osteoporosis_screening_2025;

-- See 05_example_queries.sql for all 9 use cases
```

## 📊 Core Data Model

### Dimensions
- `dim_patient` – Demographics, geography, age
- `dim_provider` – NPI, taxonomy, specialty
- `dim_facility` – POS, facility type, location
- `dim_payer_plan` – Payer, plan, LOB
- `dim_date` – Standard date dimension (2020-2030)
- `dim_code` – ICD-10, CPT, HCPCS, LOINC
- `dim_condition_group` – Semantic disease groupings
- `dim_quality_measure` – HEDIS, CMS Stars, custom

### Facts
- `fact_claim_line` – Grain: one claim line (billing, cost, dx codes)
- `fact_encounter` – Grain: one visit/admission
- `fact_diagnosis` – Grain: patient × code × date
- `fact_quality_event` – Grain: patient × measure × event
- `fact_medication` – Grain: patient × RxNorm × date (optional)
- `fact_lab_result` – Grain: patient × LOINC × date (optional)

### Aggregates (for performance)
- `fact_patient_monthly_cost` – Materialized monthly rollup
- `bridge_patient_condition_year` – Patient-condition flags by year

### Mappings
- `code_map_condition_group` – ICD/CPT → semantic conditions
- `measure_map_evidence` – CPT/LOINC → quality measures

## 🔍 Semantic Views (NL→SQL Friendly)

### Patient Views
- `vw_patients_current` – Active patients with age
- `vw_patients_2025` – Population as of 2025-12-31

### Condition Views
- `vw_patient_conditions_2025` – Patient-condition flags
- `vw_cancer_prevalence_2025` – Cancer by type

### Cost & Utilization
- `vw_patient_monthly_costs_2025` – Monthly costs per patient
- `vw_patient_annual_costs_2025` – Annual cost rollup
- `vw_er_visits_2025` – ER encounters
- `vw_patient_er_summary_2025` – ER utilization counts

### Claim Detail
- `vw_claim_lines_2025` – All claim lines with CPT descriptions
- `vw_patient_procedure_events_2025` – Procedure counts per patient

### Quality
- `vw_osteoporosis_screening_2025` – DEXA screening measure
- `vw_diabetes_a1c_control_2025` – HbA1c control

### Geographic
- `vw_patient_count_by_county_2025` – County demographics
- `vw_top100_patients_by_county_2025` – Top spenders per county

### Population Health
- `vw_population_summary_2025` – Gender × age buckets
- `vw_total_cost_by_month_2025` – Monthly cost trends

## 🤖 Intelligent NL→SQL System

### Architecture

```
User Query
    ↓
Spell Check (LLM-powered, context-aware)
    ↓
Ambiguity Detection (identifies vague queries)
    ↓
SQL Generation (uses dynamic schema inspection)
    ↓
Query Validation (security checks)
    ↓
Execution & Results
```

### Smart Features in Action

#### 1. **Spell Checking**
```
User types: "show patients in florda with diabtes"
System: "Did you mean 'florida' instead of 'florda', 'diabetes' instead of 'diabtes'?"
User clicks: ✓ Use Corrected Version
→ Executes: "show patients in florida with diabetes"
```

#### 2. **Ambiguity Detection**
```
User types: "Show me the top 10 most t2dm patients"
System: "🤔 Your query needs clarification - Top 10 by what criteria?"

Options:
┌─────────────────────────────────┐
│ Top 10 by total cost            │
├─────────────────────────────────┤
│ Top 10 by ER visits             │
├─────────────────────────────────┤
│ Top 10 by number of conditions  │
└─────────────────────────────────┘
Or type your own clarification...

User clicks: "Top 10 by total cost"
→ Refines to: "Show me the top 10 most expensive t2dm patients"
```

#### 3. **State Name Handling**
```
"Show patients in Florida" → WHERE state = 'FL'
"Show patients in FL"      → WHERE state = 'FL'
Both work automatically!
```

### Example NL→SQL Translations

| Natural Language | Generated SQL | Intelligence Feature |
|-----------------|---------------|---------------------|
| "How many patients with diabetes?" | `SELECT COUNT(*) FROM vw_patient_conditions_2025 WHERE condition_name IN ('Type 2 diabetes', 'Type 1 diabetes')` | ✅ Direct |
| "Top 10 most expensive patients" | `SELECT patient_id, total_cost_2025 FROM vw_patient_annual_costs_2025 ORDER BY total_cost_2025 DESC LIMIT 10` | ✅ Direct |
| "Top 10 t2dm patients" | *Asks for clarification* | 🤔 Ambiguity detected |
| "patients in florda" | *Suggests: "florida"* | 🔍 Spell check |
| "Show patients in California" | `WHERE state = 'CA'` | 🗺️ State conversion |

### Dynamic Schema Inspection

The system **automatically loads actual view schemas** from the database:

```python
# No hardcoded mappings - reads from information_schema
schemas = db.get_view_schemas()
# Returns: {"vw_patients_2025": [{"column": "patient_id", "type": "varchar"}, ...]}

# LLM sees real columns:
"""
vw_patients_2025:
  patient_id (varchar), age_years (integer), gender (varchar), state (char)
"""
```

**Benefits:**
- ✅ No sync issues between code and database
- ✅ Schema changes auto-reflect in queries
- ✅ LLM can't hallucinate non-existent columns

## 📋 Use Cases Covered

All 9 original use cases work via **natural language** or **direct SQL**:

1. ✅ **Population by gender & age bucket**
   - NL: "Show me patients by gender and age group"
   - SQL: `SELECT gender, age_bucket_10yr, COUNT(*) FROM vw_patients_2025 GROUP BY 1,2`

2. ✅ **Osteoporosis screening rate**
   - NL: "What's the osteoporosis screening rate for women 65-75?"
   - SQL: Available in `05_example_queries.sql`

3. ✅ **Type 2 diabetes prevalence**
   - NL: "How many patients have diabetes?"
   - SQL: `SELECT COUNT(*) FROM vw_patient_conditions_2025 WHERE condition_name = 'Type 2 diabetes'`

4. ✅ **ER frequent flyers**
   - NL: "Show me ER frequent flyers" *(will ask: top by visits or by cost?)*
   - SQL: `SELECT * FROM vw_patient_er_summary_2025 ORDER BY er_visits_2025 DESC`

5. ✅ **Patient-specific procedure counts**
   - NL: "What procedures did patient PAT000528 have?"
   - SQL: `SELECT * FROM vw_patient_procedure_events_2025 WHERE patient_id = 'PAT000528'`

6. ✅ **Most expensive patients**
   - NL: "Top 10 most expensive patients"
   - SQL: `SELECT * FROM vw_patient_annual_costs_2025 ORDER BY total_cost_2025 DESC LIMIT 10`

7. ✅ **Cancer prevalence by type**
   - NL: "Show me cancer patients by cancer type"
   - SQL: `SELECT * FROM vw_cancer_prevalence_2025`

8. ✅ **Total cost by month**
   - NL: "What's the total cost by month in 2025?"
   - SQL: `SELECT month, SUM(allowed_amt) FROM vw_total_cost_by_month_2025 GROUP BY month`

9. ✅ **Top 100 patients per county**
   - NL: "Top 10 patients in Los Angeles by cost"
   - SQL: `SELECT * FROM vw_top100_patients_by_county_2025 WHERE county_name = 'Los Angeles' LIMIT 10`

## 📥 Data Loading

### Order of Operations
1. Load dimensions (patient, provider, facility, payer, date)
2. Load reference data (codes, condition groups, quality measures)
3. Load facts (claims, encounters, diagnoses)
4. Build aggregates (monthly costs, condition flags)
5. Create indexes (automatically via DDL)

### Sample Loading Pattern

```sql
-- 1. Load patients
INSERT INTO dim_patient (patient_sk, patient_id, birth_date, sex_at_birth, county_fips, state)
SELECT nextval('seq_patient_sk'), mrn, dob, gender, county, state
FROM staging.patients;

-- 2. Load claims
INSERT INTO fact_claim_line (claim_line_sk, patient_sk, from_date_sk, cpt_hcpcs, allowed_amt, ...)
SELECT nextval('seq_claim_line_sk'), p.patient_sk, d.date_sk, s.cpt, s.allowed, ...
FROM staging.claims s
JOIN dim_patient p ON p.patient_id = s.mrn
JOIN dim_date d ON d.date = s.service_date;

-- 3. Build monthly rollup
INSERT INTO fact_patient_monthly_cost (patient_sk, month_start_date_sk, allowed_amt, er_visits, ...)
SELECT patient_sk, month_start_date_sk, SUM(allowed_amt), SUM(CASE WHEN is_er THEN 1 ELSE 0 END), ...
FROM fact_claim_line
JOIN dim_date ON ...
WHERE year = 2025
GROUP BY patient_sk, month_start_date_sk;

-- 4. Build condition flags
INSERT INTO bridge_patient_condition_year (patient_sk, condition_group_sk, year, has_condition, ...)
SELECT fd.patient_sk, cm.condition_group_sk, d.year, TRUE, MIN(d.date), MAX(d.date)
FROM fact_diagnosis fd
JOIN dim_code dc ON dc.code_sk = fd.code_sk
JOIN code_map_condition_group cm ON cm.code_system = dc.code_system AND cm.code = dc.code
JOIN dim_date d ON d.date_sk = fd.date_sk
GROUP BY fd.patient_sk, cm.condition_group_sk, d.year;
```

## 🔒 Security & Governance

### Row-Level Security (RLS)
Use `patient_attribution` table to restrict access by organization/payer.

The `patient_attribution` table is fully populated with:
- **1,100 attribution records** (1,000 current + 100 historical)
- **50 organizations** (ORG-001 to ORG-050)
- **5 payer plans** (Blue Cross Blue Shield, Aetna, United Healthcare, Cigna, Humana)
- **Time-based attribution** tracking (start/end dates)

```sql
-- Example RLS policy (PostgreSQL)
CREATE POLICY patient_rls ON dim_patient
FOR SELECT
USING (
  patient_sk IN (
    SELECT patient_sk FROM patient_attribution
    WHERE org_id = current_setting('app.org_id')
      AND is_current = TRUE
  )
);
```

### PHI Protection
- Store patient_id only (no names, addresses in analytics layer)
- birth_date can be stored but use age in queries
- Audit all queries via `query_audit_log`

### Query Audit
```sql
INSERT INTO query_audit_log (query_id, user_id, org_id, natural_language_query, generated_sql, query_timestamp)
VALUES (nextval('seq_query_id'), :user, :org, :nl_query, :sql, CURRENT_TIMESTAMP);
```

## ⚡ Performance Tuning

### Indexes (already included)
- All FKs indexed
- High-cardinality filters (patient_sk, date_sk, cpt_code)
- Utilization flags (is_er, is_inpatient)
- Cost DESC indexes for top-N queries

### Materialization
Pre-built aggregates:
- `fact_patient_monthly_cost` (rebuild monthly)
- `bridge_patient_condition_year` (rebuild quarterly)

Optional materialized views:
```sql
CREATE MATERIALIZED VIEW mvw_patient_annual_costs_2025 AS
SELECT * FROM vw_patient_annual_costs_2025;

CREATE INDEX idx_mvw_cost ON mvw_patient_annual_costs_2025(total_cost_2025 DESC);

-- Refresh after data loads
REFRESH MATERIALIZED VIEW mvw_patient_annual_costs_2025;
```

### Partitioning (for 100M+ row tables)
```sql
-- Example: partition claims by year
CREATE TABLE fact_claim_line (...)
PARTITION BY RANGE (from_date_sk);

CREATE TABLE fact_claim_line_2024 PARTITION OF fact_claim_line
FOR VALUES FROM (20240101) TO (20250101);

CREATE TABLE fact_claim_line_2025 PARTITION OF fact_claim_line
FOR VALUES FROM (20250101) TO (20260101);
```

## 🧩 Extending the Schema

### Adding a New Condition Group
```sql
-- 1. Add condition
INSERT INTO dim_condition_group (condition_group_sk, group_id, group_name, parent_group, ...)
VALUES (100, 'NEW_COND', 'New condition name', 'Parent group', ...);

-- 2. Map ICD codes
INSERT INTO code_map_condition_group (code_system, code, condition_group_sk, mapping_logic)
VALUES ('ICD10CM', 'X00', 100, 'starts_with');

-- 3. Rebuild bridge
-- Run condition flag ETL for new group
```

### Adding a New Quality Measure
```sql
-- 1. Add measure
INSERT INTO dim_quality_measure (measure_sk, measure_id, title, spec_year, ...)
VALUES (100, 'CUSTOM_MEASURE', 'Custom measure title', 2025, ...);

-- 2. Map evidence codes
INSERT INTO measure_map_evidence (measure_sk, code_system, code, role, spec_year)
VALUES (100, 'CPT', '99999', 'numerator', 2025);

-- 3. Populate quality events
-- ETL claims → fact_quality_event
```

### Adding a New Semantic View
```sql
CREATE OR REPLACE VIEW vw_custom_analysis AS
SELECT ...
FROM fact_claim_line cl
JOIN vw_patients_2025 p ON ...
WHERE ...;

-- Add to NL dictionary
INSERT INTO nlsql_semantic_alias (term, term_type, view_name, description, ...)
VALUES ('custom analysis', 'VIEW', 'vw_custom_analysis', 'Description...', ...);
```

## 📝 Maintenance

### Monthly Tasks
- Refresh `fact_patient_monthly_cost` for new month
- VACUUM ANALYZE fact tables
- Update quality measure numerators/denominators

### Quarterly Tasks
- Rebuild `bridge_patient_condition_year`
- Review and update code mappings (new ICD codes)
- Archive old query audit logs

### Annual Tasks
- Add new year to `dim_date`
- Review condition group definitions
- Update quality measure specs

## 🐛 Troubleshooting

### Application Issues

#### "Address already in use" when starting app
```bash
# Kill existing process on port 8000
lsof -ti:8000 | xargs kill -9
cd app && ./run.sh
```

#### "Relation vw_* does not exist"
```bash
# Database schema not deployed yet
cd .. && ./deploy.sh
```

#### "OPENAI_API_KEY not set"
Edit `app/.env` and add your OpenAI API key:
```bash
OPENAI_API_KEY=sk-your-key-here
```

#### Spell checker too aggressive
The LLM-based spell checker is conservative, but if needed:
```javascript
// In UI, skip spell check:
skip_spell_check: true
```

#### Query seems ambiguous but shouldn't be
The ambiguity detector is tuned to only flag truly vague queries. To bypass:
```javascript
// In UI, skip ambiguity check:
skip_ambiguity_check: true
```

### Database Issues

#### Query is slow
1. Check for year filter on fact tables
2. Use EXPLAIN ANALYZE to see plan
3. Consider materialized views for complex aggregates
4. Check index usage

#### NL→SQL generating wrong queries
1. The system uses **dynamic schema inspection** - no manual updates needed
2. Check view exists: `SELECT * FROM information_schema.views WHERE table_name = 'vw_...'`
3. Restart app to reload schemas: `cd app && ./run.sh`
4. Check system prompt examples in `nl_to_sql_agent.py:103-137`

#### Missing data
1. Verify ETL loaded all dimensions first
2. Check FK constraints (should fail if orphaned records)
3. Review `dim_date` population (2020-2030)
4. Validate code mappings loaded

## 🎓 Learning Resources

### Query Examples
See `05_example_queries.sql` for:
- Multiple alternatives for each use case
- Performance notes
- Best practices

### Data Dictionary
```sql
-- List all tables with comments
SELECT schemaname, tablename,
       obj_description((schemaname||'.'||tablename)::regclass) AS description
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- List all columns
SELECT table_name, column_name, data_type,
       col_description((table_schema||'.'||table_name)::regclass, ordinal_position) AS description
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;
```

## 🤝 Contributing

To extend this schema for your organization:

1. **Fork the baseline**: Copy all 5 SQL files
2. **Add organization-specific conditions**: Update `dim_condition_group` and mappings
3. **Add custom quality measures**: Update `dim_quality_measure`
4. **Create custom views**: Add to `03_semantic_views.sql`
5. **Update NL dictionary**: Add terms to `nlsql_semantic_alias`

## 📄 License

This schema is provided as-is for healthcare analytics use. Adapt as needed for your organization.

## ✅ Deployment Checklist

### Database Setup
- [ ] PostgreSQL 12+ installed and running
- [ ] Edit `.env` with database credentials
- [ ] Run `./deploy.sh` (deploys all schemas + sample data)
- [ ] Verify sample data: `SELECT COUNT(*) FROM dim_patient;` (should be 1000)
- [ ] Test queries from `05_example_queries.sql`

### Application Setup
- [ ] Python 3.9+ installed
- [ ] Edit `app/.env` with OpenAI API key and DB credentials
- [ ] Install dependencies: `cd app && pip3 install -r requirements.txt`
- [ ] Run application: `./run.sh`
- [ ] Open browser to `http://localhost:8000`
- [ ] Test spell check: Type "patients in florda"
- [ ] Test ambiguity: Type "show me top 10 t2dm patients"
- [ ] Test query: "How many patients do we have?"

### Production Readiness (Optional)
- [ ] Load production data (dimensions → facts → aggregates)
- [ ] Set up row-level security policies
- [ ] Configure query audit logging
- [ ] Schedule monthly/quarterly maintenance jobs
- [ ] Set up SSL/TLS for API
- [ ] Configure authentication (JWT, OAuth, etc.)
- [ ] Set up monitoring and logging

## 📞 Support

For questions or issues with this schema implementation, refer to:
- `05_example_queries.sql` for query patterns
- `vw_nlsql_dictionary` for semantic mappings
- Table/column comments for metadata

---

**Version**: 1.0
**Last Updated**: 2025
**Compatibility**: PostgreSQL 12+, Snowflake, BigQuery (with minor adaptations)
