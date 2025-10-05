-- ============================================================================
-- NL→SQL Semantic Ontology & Dictionary
-- LLM-friendly reference tables for translating natural language to SQL
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SEMANTIC ALIAS TABLE (term → table.column mappings)
-- ----------------------------------------------------------------------------

CREATE TABLE nlsql_semantic_alias (
  alias_id SERIAL PRIMARY KEY,
  term VARCHAR(200) NOT NULL,
  term_type VARCHAR(50),
  table_name VARCHAR(100),
  column_name VARCHAR(100),
  view_name VARCHAR(100),
  filter_logic TEXT,
  aggregation VARCHAR(50),
  description TEXT,
  synonyms TEXT[],
  example_usage TEXT,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_semantic_alias_term ON nlsql_semantic_alias(LOWER(term));

-- ----------------------------------------------------------------------------
-- POPULATE SEMANTIC ALIASES
-- ----------------------------------------------------------------------------

INSERT INTO nlsql_semantic_alias (term, term_type, table_name, column_name, view_name, filter_logic, aggregation, description, synonyms, example_usage) VALUES

-- PATIENT DEMOGRAPHICS
('patient', 'ENTITY', 'dim_patient', NULL, 'vw_patients_current', NULL, NULL, 'Patient entity; primary subject for queries', ARRAY['member', 'individual', 'person'], 'How many patients do we have?'),
('patient id', 'ATTRIBUTE', 'dim_patient', 'patient_id', 'vw_patients_current', NULL, NULL, 'Unique patient identifier', ARRAY['member id', 'patient number', 'MRN'], 'Show me patient 528'),
('age', 'ATTRIBUTE', 'dim_patient', 'birth_date', 'vw_patients_current', 'EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))', NULL, 'Patient age in years', ARRAY['years old', 'age in years'], 'Patients over 65'),
('age bucket', 'ATTRIBUTE', NULL, 'age_bucket_10yr', 'vw_patients_current', NULL, NULL, '10-year age ranges', ARRAY['age group', 'age range'], 'Show patients by age bucket'),
('gender', 'ATTRIBUTE', 'dim_patient', 'sex_at_birth', 'vw_patients_current', NULL, NULL, 'Patient gender/sex', ARRAY['sex', 'male', 'female', 'women', 'men'], 'How many women aged 65-75?'),
('county', 'ATTRIBUTE', 'dim_patient', 'county_fips', 'vw_patients_current', NULL, NULL, 'County FIPS code', ARRAY['county name', 'geographic area'], 'Patients by county'),
('state', 'ATTRIBUTE', 'dim_patient', 'state', 'vw_patients_current', NULL, NULL, 'State abbreviation', ARRAY['state name'], 'Patients in California'),
('zip', 'ATTRIBUTE', 'dim_patient', 'zip5', 'vw_patients_current', NULL, NULL, '5-digit ZIP code', ARRAY['zip code', 'postal code'], NULL),

-- COSTS
('cost', 'METRIC', 'fact_claim_line', 'allowed_amt', 'vw_patient_monthly_costs', NULL, 'SUM', 'Allowed amount (primary cost metric)', ARRAY['spend', 'spending', 'total cost', 'expenses', 'allowed amount'], 'Total cost in 2025'),
('paid amount', 'METRIC', 'fact_claim_line', 'paid_amt', 'vw_patient_monthly_costs', NULL, 'SUM', 'Amount paid by payer', ARRAY['paid', 'reimbursed'], 'Total paid amount'),
('patient responsibility', 'METRIC', 'fact_claim_line', 'patient_responsibility', 'vw_patient_monthly_costs', NULL, 'SUM', 'Amount patient owes', ARRAY['patient cost', 'out of pocket', 'copay'], NULL),
('average cost', 'METRIC', 'fact_claim_line', 'allowed_amt', 'vw_patient_monthly_costs', NULL, 'AVG', 'Average cost per patient', ARRAY['mean cost', 'avg spend'], 'What is the average cost per patient?'),
('most expensive', 'METRIC', 'fact_claim_line', 'allowed_amt', 'vw_patient_annual_costs_2025', 'ORDER BY total_cost_2025 DESC', NULL, 'Highest cost patients', ARRAY['highest cost', 'top spenders', 'costliest'], 'Most expensive patients'),

-- UTILIZATION
('ER visit', 'EVENT', 'fact_encounter', 'encounter_type', 'vw_er_visits_2025', 'encounter_type = ''ER''', 'COUNT', 'Emergency room visit', ARRAY['emergency visit', 'emergency room', 'ER', 'ED visit'], 'How many ER visits?'),
('admission', 'EVENT', 'fact_encounter', 'encounter_type', 'vw_ip_admissions_2025', 'encounter_type = ''IP''', 'COUNT', 'Inpatient admission', ARRAY['inpatient', 'hospitalization', 'IP admit', 'hospital admission'], 'Total admissions in 2025'),
('outpatient visit', 'EVENT', 'fact_claim_line', 'is_outpatient', 'vw_claim_lines_2025', 'is_outpatient = TRUE', 'COUNT', 'Outpatient visit', ARRAY['OP visit', 'clinic visit'], NULL),
('preventive visit', 'EVENT', 'fact_claim_line', 'is_preventive', 'vw_claim_lines_2025', 'is_preventive = TRUE', 'COUNT', 'Preventive care visit', ARRAY['wellness visit', 'screening'], NULL),
('frequent flyers', 'METRIC', NULL, NULL, 'vw_patient_er_summary_2025', 'ORDER BY er_visits_2025 DESC', NULL, 'Patients with high ER utilization', ARRAY['high utilizers', 'most ER visits'], 'Show me frequent ER users'),

-- PROCEDURES / SERVICES
('procedure', 'EVENT', 'fact_claim_line', 'cpt_hcpcs', 'vw_claim_lines_2025', NULL, 'COUNT', 'Medical procedure (CPT/HCPCS)', ARRAY['service', 'CPT', 'HCPCS', 'treatment'], 'How many procedures did patient 528 have?'),
('CPT code', 'ATTRIBUTE', 'fact_claim_line', 'cpt_hcpcs', 'vw_claim_lines_2025', NULL, NULL, 'CPT/HCPCS procedure code', ARRAY['procedure code', 'service code'], 'Total events for CPT 97110'),

-- CONDITIONS / DIAGNOSES
('condition', 'ATTRIBUTE', 'dim_condition_group', 'group_name', 'vw_patient_conditions_2025', NULL, NULL, 'Clinical condition/diagnosis', ARRAY['diagnosis', 'disease', 'illness'], 'How many patients have diabetes?'),
('diabetes', 'CONDITION', NULL, 'group_name', 'vw_patient_conditions_2025', 'condition_name IN (''Type 2 diabetes'', ''Type 1 diabetes'')', NULL, 'Diabetes mellitus (all types)', ARRAY['diabetic', 'DM'], 'Patients with diabetes'),
('type 2 diabetes', 'CONDITION', NULL, 'group_name', 'vw_patient_conditions_2025', 'condition_name = ''Type 2 diabetes''', NULL, 'Type 2 diabetes mellitus', ARRAY['T2DM', 'type 2 DM'], NULL),
('cancer', 'CONDITION', NULL, 'parent_group', 'vw_patient_conditions_2025', 'parent_group = ''Any cancer''', NULL, 'Any cancer diagnosis', ARRAY['malignancy', 'neoplasm'], 'How many patients have cancer?'),
('breast cancer', 'CONDITION', NULL, 'group_name', 'vw_patient_conditions_2025', 'condition_name = ''Breast cancer''', NULL, 'Breast cancer', NULL, NULL),
('lung cancer', 'CONDITION', NULL, 'group_name', 'vw_patient_conditions_2025', 'condition_name = ''Lung cancer''', NULL, 'Lung cancer', NULL, NULL),
('heart failure', 'CONDITION', NULL, 'group_name', 'vw_patient_conditions_2025', 'condition_name = ''Congestive heart failure''', NULL, 'Congestive heart failure', ARRAY['CHF', 'HF'], NULL),
('COPD', 'CONDITION', NULL, 'group_name', 'vw_patient_conditions_2025', 'condition_name = ''COPD''', NULL, 'Chronic obstructive pulmonary disease', ARRAY['chronic obstructive pulmonary disease'], NULL),
('hypertension', 'CONDITION', NULL, 'group_name', 'vw_patient_conditions_2025', 'condition_name = ''Hypertension''', NULL, 'High blood pressure', ARRAY['HTN', 'high blood pressure'], NULL),

-- QUALITY MEASURES
('osteoporosis screening', 'MEASURE', 'dim_quality_measure', 'measure_id', 'vw_osteoporosis_screening_2025', 'measure_id = ''OSTOP_SCREEN_65_75''', NULL, 'Osteoporosis screening (DEXA)', ARRAY['bone density test', 'DEXA scan'], 'Women 65-75 who received osteoporosis screening'),
('mammogram', 'MEASURE', 'dim_quality_measure', 'measure_id', NULL, 'measure_id = ''BCS_MAMMO_50_74''', NULL, 'Breast cancer screening (mammogram)', ARRAY['breast cancer screening'], NULL),
('colonoscopy', 'MEASURE', 'dim_quality_measure', 'measure_id', NULL, 'measure_id = ''COL_SCREEN_50_75''', NULL, 'Colorectal cancer screening', ARRAY['colon screening'], NULL),
('HbA1c control', 'MEASURE', 'dim_quality_measure', 'measure_id', 'vw_diabetes_a1c_control_2025', 'measure_id = ''HBD_A1C_CONTROL''', NULL, 'Diabetes HbA1c <8%', ARRAY['A1c control', 'diabetes control'], NULL),

-- TIME PERIODS
('2025', 'TIME', 'dim_date', 'year', 'vw_patients_2025', 'year = 2025', NULL, 'Year 2025', ARRAY['this year', 'current year'], 'Costs in 2025'),
('month', 'TIME', 'dim_date', 'month', 'vw_patient_monthly_costs', NULL, NULL, 'Calendar month', ARRAY['monthly'], 'Total cost by month'),
('year', 'TIME', 'dim_date', 'year', NULL, NULL, NULL, 'Calendar year', ARRAY['annual', 'yearly'], NULL),

-- AGGREGATIONS
('total', 'AGGREGATION', NULL, NULL, NULL, NULL, 'SUM', 'Sum of all values', ARRAY['sum', 'add up'], 'Total cost'),
('average', 'AGGREGATION', NULL, NULL, NULL, NULL, 'AVG', 'Mean value', ARRAY['avg', 'mean'], 'Average cost per patient'),
('count', 'AGGREGATION', NULL, NULL, NULL, NULL, 'COUNT', 'Number of records', ARRAY['how many', 'number of'], 'Count of patients'),
('top', 'AGGREGATION', NULL, NULL, NULL, 'ORDER BY ... DESC LIMIT N', NULL, 'Top N records', ARRAY['highest', 'most', 'largest'], 'Top 100 patients'),

-- GEOGRAPHIC
('by county', 'GROUPING', 'dim_patient', 'county_fips', 'vw_patient_count_by_county_2025', 'GROUP BY county_fips', NULL, 'Group by county', ARRAY['per county', 'each county'], 'Top patients by county'),
('by state', 'GROUPING', 'dim_patient', 'state', NULL, 'GROUP BY state', NULL, 'Group by state', ARRAY['per state'], NULL);

-- ----------------------------------------------------------------------------
-- QUERY PATTERN TEMPLATES (common NL query structures)
-- ----------------------------------------------------------------------------

CREATE TABLE nlsql_query_templates (
  template_id SERIAL PRIMARY KEY,
  natural_language_pattern TEXT NOT NULL,
  sql_template TEXT NOT NULL,
  category VARCHAR(50),
  description TEXT,
  example_input TEXT,
  example_output TEXT,
  placeholders JSONB,
  is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO nlsql_query_templates (natural_language_pattern, sql_template, category, description, example_input, example_output, placeholders) VALUES

-- POPULATION COUNTS
('How many {entity} [with {condition}] [in {year}]?',
 'SELECT COUNT(*) AS patient_count FROM {view} WHERE {filter};',
 'COUNT', 'Count patients with optional filters',
 'How many patients with diabetes in 2025?',
 'SELECT COUNT(*) FROM vw_patient_conditions_2025 WHERE condition_name IN (''Type 2 diabetes'', ''Type 1 diabetes'');',
 '{"entity": "patients", "view": "vw_patient_conditions_2025", "filter": "condition clause"}'),

-- DEMOGRAPHICS
('{entity} by {dimension1} and {dimension2}',
 'SELECT {dim1}, {dim2}, COUNT(*) FROM {view} GROUP BY {dim1}, {dim2};',
 'DEMOGRAPHICS', 'Population stratification',
 'Patients by gender and age bucket',
 'SELECT gender, age_bucket_10yr, COUNT(*) FROM vw_patients_2025 GROUP BY gender, age_bucket_10yr;',
 '{"view": "vw_patients_2025", "dim1": "gender", "dim2": "age_bucket"}'),

-- COST QUERIES
('Total cost [of {population}] in {year} [by {grouping}]',
 'SELECT {grouping}, SUM(allowed_amt) AS total_cost FROM {view} WHERE year = {year} GROUP BY {grouping};',
 'COST', 'Aggregate cost with optional grouping',
 'Total cost in 2025 by month',
 'SELECT month, SUM(total_cost) FROM vw_patient_monthly_costs_2025 GROUP BY month ORDER BY month;',
 '{"year": 2025, "grouping": "month", "view": "vw_patient_monthly_costs_2025"}'),

-- TOP-N
('Top {N} [most expensive] {entity} [in {year}] [by {grouping}]',
 'SELECT {entity_id}, SUM({metric}) AS total FROM {view} GROUP BY {entity_id} ORDER BY total DESC LIMIT {N};',
 'TOP_N', 'Top N ranking by metric',
 'Top 100 most expensive patients in 2025',
 'SELECT patient_id, total_cost_2025 FROM vw_patient_annual_costs_2025 ORDER BY total_cost_2025 DESC LIMIT 100;',
 '{"N": 100, "entity": "patients", "metric": "cost", "view": "vw_patient_annual_costs_2025"}'),

-- PATIENT-SPECIFIC
('{entity} {id} {metric} for {codes} in {year}',
 'SELECT patient_id, SUM(units) AS total_events FROM {view} WHERE patient_id = ''{id}'' AND cpt_code IN ({codes}) AND year = {year};',
 'PATIENT_DETAIL', 'Patient-specific procedure counts',
 'Patient 528 total number of events for CPT 97110, 95992 in 2025',
 'SELECT patient_id, SUM(units) FROM vw_patient_procedure_events_2025 WHERE patient_id = ''528'' AND cpt_code IN (''97110'',''95992'');',
 '{"id": "528", "codes": "CPT list", "year": 2025}'),

-- UTILIZATION
('{entity} most often admitted to the {encounter_type}',
 'SELECT patient_id, COUNT(*) AS visit_count FROM {view} GROUP BY patient_id ORDER BY visit_count DESC;',
 'UTILIZATION', 'High utilizers by encounter type',
 'Patients most often admitted to the ER',
 'SELECT patient_id, er_visits_2025 FROM vw_patient_er_summary_2025 ORDER BY er_visits_2025 DESC;',
 '{"encounter_type": "ER", "view": "vw_patient_er_summary_2025"}'),

-- PREVALENCE
('How many {entity} have {condition} [in {year}]?',
 'SELECT COUNT(*) FROM {view} WHERE condition_name = ''{condition}'' AND year = {year};',
 'PREVALENCE', 'Disease prevalence count',
 'How many patients have type 2 diabetes in 2025?',
 'SELECT COUNT(*) FROM vw_patient_conditions_2025 WHERE condition_name = ''Type 2 diabetes'';',
 '{"condition": "Type 2 diabetes", "year": 2025}'),

-- QUALITY MEASURES
('Percentage of {population} who received {measure} in {year}',
 'SELECT COUNT(*) FILTER (WHERE is_numerator) / COUNT(*)::DECIMAL AS rate FROM {view};',
 'QUALITY', 'Quality measure rate calculation',
 'Percentage of women 65-75 who received osteoporosis screening in 2025',
 'SELECT COUNT(*) FILTER (WHERE is_screened)::DECIMAL / COUNT(*) AS pct FROM vw_osteoporosis_screening_2025;',
 '{"population": "women 65-75", "measure": "osteoporosis screening", "year": 2025}'),

-- GEOGRAPHIC
('Top {N} {entity} [with highest {metric}] for each {geography} in {year}',
 'WITH ranked AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY {geo_col} ORDER BY {metric} DESC) AS rn FROM {view}) SELECT * FROM ranked WHERE rn <= {N};',
 'GEOGRAPHIC', 'Top N per geography',
 'Top 100 patients with highest costs for each county in 2025',
 'SELECT * FROM vw_top100_patients_by_county_2025;',
 '{"N": 100, "geography": "county", "metric": "cost", "year": 2025}');

-- ----------------------------------------------------------------------------
-- ENTITY & RELATIONSHIP METADATA (for query planner)
-- ----------------------------------------------------------------------------

CREATE TABLE nlsql_entity_relationships (
  relationship_id SERIAL PRIMARY KEY,
  parent_entity VARCHAR(100),
  child_entity VARCHAR(100),
  join_key VARCHAR(100),
  relationship_type VARCHAR(50),
  description TEXT
);

INSERT INTO nlsql_entity_relationships (parent_entity, child_entity, join_key, relationship_type, description) VALUES
('dim_patient', 'fact_claim_line', 'patient_sk', 'ONE_TO_MANY', 'Patient has many claim lines'),
('dim_patient', 'fact_encounter', 'patient_sk', 'ONE_TO_MANY', 'Patient has many encounters'),
('dim_patient', 'bridge_patient_condition_year', 'patient_sk', 'ONE_TO_MANY', 'Patient has many conditions'),
('dim_patient', 'fact_patient_monthly_cost', 'patient_sk', 'ONE_TO_MANY', 'Patient has monthly cost records'),
('dim_date', 'fact_claim_line', 'date_sk', 'ONE_TO_MANY', 'Date has many claim lines'),
('dim_provider', 'fact_claim_line', 'provider_sk', 'ONE_TO_MANY', 'Provider has many claim lines'),
('dim_condition_group', 'bridge_patient_condition_year', 'condition_group_sk', 'ONE_TO_MANY', 'Condition group has many patient-years'),
('dim_quality_measure', 'fact_quality_event', 'measure_sk', 'ONE_TO_MANY', 'Measure has many quality events'),
('dim_code', 'fact_diagnosis', 'code_sk', 'ONE_TO_MANY', 'Code has many diagnosis events');

-- ----------------------------------------------------------------------------
-- QUERY GUARDRAILS (prevent bad queries)
-- ----------------------------------------------------------------------------

CREATE TABLE nlsql_query_guardrails (
  guardrail_id SERIAL PRIMARY KEY,
  rule_name VARCHAR(100),
  rule_type VARCHAR(50),
  rule_logic TEXT,
  error_message TEXT,
  severity VARCHAR(20),
  is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO nlsql_query_guardrails (rule_name, rule_type, rule_logic, error_message, severity) VALUES
('REQUIRE_YEAR_FILTER', 'PERFORMANCE', 'fact_claim_line queries must include year filter', 'Large tables require year filter for performance. Please specify a year.', 'ERROR'),
('LIMIT_TOP_N', 'PERFORMANCE', 'TOP N queries should have LIMIT <= 10000', 'TOP N queries limited to 10,000 results. Use export for larger datasets.', 'WARNING'),
('NO_FULL_TABLE_SCAN', 'PERFORMANCE', 'Queries on fact tables must include patient_sk, date_sk, or other indexed column', 'Full table scans not allowed. Filter by patient, date, or indexed dimension.', 'ERROR'),
('AGGREGATE_LARGE_RESULTS', 'PERFORMANCE', 'Queries returning >100k rows should use aggregation', 'Large result sets should be aggregated. Consider GROUP BY or summary views.', 'WARNING'),
('USE_VIEWS_NOT_TABLES', 'BEST_PRACTICE', 'Prefer semantic views over raw fact tables', 'Use vw_* views instead of fact tables for cleaner, faster queries.', 'INFO'),
('PATIENT_PRIVACY', 'SECURITY', 'Do not expose patient names or DOB in results', 'Patient names and DOB are PHI. Use patient_id only.', 'ERROR');

-- ----------------------------------------------------------------------------
-- COMMON STOPWORDS (to ignore in NL parsing)
-- ----------------------------------------------------------------------------

CREATE TABLE nlsql_stopwords (
  stopword VARCHAR(50) PRIMARY KEY
);

INSERT INTO nlsql_stopwords (stopword) VALUES
('the'), ('a'), ('an'), ('and'), ('or'), ('but'), ('in'), ('on'), ('at'), ('to'), ('for'),
('of'), ('with'), ('by'), ('from'), ('as'), ('is'), ('was'), ('are'), ('were'), ('been'),
('be'), ('have'), ('has'), ('had'), ('do'), ('does'), ('did'), ('will'), ('would'), ('should'),
('could'), ('may'), ('might'), ('must'), ('can'), ('please'), ('show'), ('me'), ('get'),
('find'), ('list'), ('give'), ('tell'), ('what'), ('which'), ('who'), ('when'), ('where'),
('how'), ('why'), ('many'), ('much');

-- ----------------------------------------------------------------------------
-- VIEW: LLM Context Builder (full semantic dictionary)
-- ----------------------------------------------------------------------------

-- This view provides all semantic mappings in one place for LLM context
CREATE OR REPLACE VIEW vw_nlsql_dictionary AS
SELECT
    term,
    term_type,
    COALESCE(view_name, table_name) AS primary_source,
    column_name,
    filter_logic,
    aggregation,
    description,
    synonyms,
    example_usage
FROM nlsql_semantic_alias
WHERE is_active = TRUE
ORDER BY term_type, term;

COMMENT ON VIEW vw_nlsql_dictionary IS 'Complete NL→SQL semantic dictionary for LLM context injection';

-- ----------------------------------------------------------------------------
-- EXAMPLE LLM PROMPT TEMPLATE (for NL→SQL agent)
-- ----------------------------------------------------------------------------

/*
SYSTEM PROMPT FOR NL→SQL AGENT:

You are a healthcare analytics SQL generator. Use the following semantic dictionary to translate natural language queries to SQL:

{SELECT * FROM vw_nlsql_dictionary;}

RULES:
1. Always prefer semantic views (vw_*) over raw fact tables
2. Use the exact column/table names from the dictionary
3. Apply filters from filter_logic when specified
4. For condition queries, use vw_patient_conditions_2025
5. For cost queries, use vw_patient_monthly_costs or vw_patient_annual_costs_2025
6. For utilization, use vw_er_visits_2025, vw_ip_admissions_2025, or vw_patient_er_summary_2025
7. Always include year filters for performance
8. Use FILTER (WHERE ...) for conditional aggregations
9. Return patient_id, never patient names (PHI protection)

QUERY TEMPLATES:
{SELECT * FROM nlsql_query_templates WHERE is_active = TRUE;}

EXAMPLE:
User: "How many patients have type 2 diabetes in 2025?"
SQL: SELECT COUNT(*) AS patient_count FROM vw_patient_conditions_2025 WHERE condition_name = 'Type 2 diabetes';

User: "Top 10 most expensive patients"
SQL: SELECT patient_id, total_cost_2025 FROM vw_patient_annual_costs_2025 ORDER BY total_cost_2025 DESC LIMIT 10;

Now translate the user's query:
User: {user_input}
SQL:
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- List all semantic terms
SELECT term_type, COUNT(*) AS term_count
FROM nlsql_semantic_alias
WHERE is_active = TRUE
GROUP BY term_type
ORDER BY term_count DESC;

-- Show all query templates
SELECT category, COUNT(*) AS template_count
FROM nlsql_query_templates
WHERE is_active = TRUE
GROUP BY category;

-- Entity relationships
SELECT * FROM nlsql_entity_relationships;
