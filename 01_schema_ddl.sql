-- ============================================================================
-- Healthcare Analytics Star Schema - Core DDL
-- Production-ready NL→SQL optimized schema for population health analytics
-- Compatible with PostgreSQL 12+, adaptable to Snowflake/BigQuery
-- ============================================================================

-- ----------------------------------------------------------------------------
-- DIMENSION TABLES
-- ----------------------------------------------------------------------------

-- Standard date dimension (pre-populate 10+ years)
CREATE TABLE dim_date (
  date_sk INT PRIMARY KEY,
  date DATE NOT NULL UNIQUE,
  year INT NOT NULL,
  quarter INT NOT NULL,
  month INT NOT NULL,
  month_name VARCHAR(9) NOT NULL,
  day INT NOT NULL,
  day_of_week INT NOT NULL,
  day_name VARCHAR(9) NOT NULL,
  is_month_start BOOLEAN NOT NULL,
  is_month_end BOOLEAN NOT NULL,
  is_quarter_start BOOLEAN NOT NULL,
  is_quarter_end BOOLEAN NOT NULL,
  is_year_start BOOLEAN NOT NULL,
  is_year_end BOOLEAN NOT NULL,
  fiscal_year INT,
  fiscal_quarter INT
);

CREATE INDEX idx_date_year_month ON dim_date(year, month);
CREATE INDEX idx_date_ym ON dim_date(year DESC, month DESC);

-- Patient dimension with demographic and geographic attributes
CREATE TABLE dim_patient (
  patient_sk BIGINT PRIMARY KEY,
  patient_id VARCHAR(64) NOT NULL UNIQUE,
  birth_date DATE,
  death_date DATE,
  sex_at_birth VARCHAR(20),
  gender_identity VARCHAR(50),
  race VARCHAR(50),
  ethnicity VARCHAR(50),
  preferred_language VARCHAR(50),
  zip3 CHAR(3),
  zip5 CHAR(5),
  county_fips CHAR(5),
  county_name VARCHAR(64),
  state CHAR(2),
  is_active BOOLEAN DEFAULT TRUE,
  effective_start_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  effective_end_ts TIMESTAMP,
  is_current BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_patient_id ON dim_patient(patient_id);
CREATE INDEX idx_patient_county ON dim_patient(county_fips) WHERE is_current = TRUE;
CREATE INDEX idx_patient_state ON dim_patient(state) WHERE is_current = TRUE;
CREATE INDEX idx_patient_birth_date ON dim_patient(birth_date);
CREATE INDEX idx_patient_demographics ON dim_patient(sex_at_birth, birth_date) WHERE is_current = TRUE;

-- Provider dimension
CREATE TABLE dim_provider (
  provider_sk BIGINT PRIMARY KEY,
  npi VARCHAR(15) UNIQUE,
  provider_id VARCHAR(64),
  provider_name VARCHAR(200),
  taxonomy VARCHAR(80),
  taxonomy_desc VARCHAR(255),
  specialty VARCHAR(100),
  org_id VARCHAR(64),
  org_name VARCHAR(200),
  is_pcp BOOLEAN DEFAULT FALSE,
  effective_start_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  effective_end_ts TIMESTAMP,
  is_current BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_provider_npi ON dim_provider(npi);
CREATE INDEX idx_provider_taxonomy ON dim_provider(taxonomy) WHERE is_current = TRUE;
CREATE INDEX idx_provider_org ON dim_provider(org_id) WHERE is_current = TRUE;

-- Facility dimension
CREATE TABLE dim_facility (
  facility_sk BIGINT PRIMARY KEY,
  facility_id VARCHAR(64) UNIQUE,
  facility_name VARCHAR(200),
  place_of_service VARCHAR(4),
  pos_desc VARCHAR(100),
  facility_type VARCHAR(30),
  county_fips CHAR(5),
  county_name VARCHAR(64),
  state CHAR(2),
  is_active BOOLEAN DEFAULT TRUE,
  effective_start_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  effective_end_ts TIMESTAMP,
  is_current BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_facility_pos ON dim_facility(place_of_service);
CREATE INDEX idx_facility_type ON dim_facility(facility_type);
CREATE INDEX idx_facility_county ON dim_facility(county_fips) WHERE is_current = TRUE;

-- Payer/plan dimension (for multi-payer environments)
CREATE TABLE dim_payer_plan (
  payer_plan_sk BIGINT PRIMARY KEY,
  payer_id VARCHAR(64),
  payer_name VARCHAR(200),
  plan_id VARCHAR(64),
  plan_name VARCHAR(200),
  plan_type VARCHAR(50),
  contract_id VARCHAR(64),
  line_of_business VARCHAR(50),
  effective_start_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  effective_end_ts TIMESTAMP,
  is_current BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_payer_plan_payer ON dim_payer_plan(payer_id) WHERE is_current = TRUE;
CREATE INDEX idx_payer_plan_type ON dim_payer_plan(plan_type) WHERE is_current = TRUE;

-- Medical code dimension (ICD, CPT, HCPCS, LOINC, etc.)
CREATE TABLE dim_code (
  code_sk BIGINT PRIMARY KEY,
  code_system VARCHAR(20) NOT NULL,
  code VARCHAR(20) NOT NULL,
  short_desc VARCHAR(255),
  long_desc TEXT,
  code_category VARCHAR(100),
  is_active BOOLEAN DEFAULT TRUE,
  effective_start_date DATE,
  effective_end_date DATE,
  UNIQUE(code_system, code)
);

CREATE INDEX idx_code_system_code ON dim_code(code_system, code);
CREATE INDEX idx_code_category ON dim_code(code_category) WHERE is_active = TRUE;

-- Condition/disease grouping dimension
CREATE TABLE dim_condition_group (
  condition_group_sk INT PRIMARY KEY,
  group_id VARCHAR(50) NOT NULL UNIQUE,
  group_name VARCHAR(100) NOT NULL,
  parent_group VARCHAR(100),
  group_type VARCHAR(50),
  clinical_category VARCHAR(100),
  definition_version VARCHAR(20),
  definition_desc TEXT,
  is_chronic BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_condition_group_parent ON dim_condition_group(parent_group) WHERE is_active = TRUE;
CREATE INDEX idx_condition_group_category ON dim_condition_group(clinical_category) WHERE is_active = TRUE;

-- Quality measure dimension (HEDIS, CMS Stars, custom)
CREATE TABLE dim_quality_measure (
  measure_sk INT PRIMARY KEY,
  measure_id VARCHAR(50) NOT NULL UNIQUE,
  measure_set VARCHAR(50),
  title VARCHAR(255) NOT NULL,
  short_name VARCHAR(100),
  measure_type VARCHAR(50),
  denominator_spec TEXT,
  numerator_spec TEXT,
  exclusion_spec TEXT,
  spec_year INT,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_measure_set_year ON dim_quality_measure(measure_set, spec_year) WHERE is_active = TRUE;

-- ----------------------------------------------------------------------------
-- FACT TABLES
-- ----------------------------------------------------------------------------

-- Grain: one claim line (line-level detail for billing/utilization)
CREATE TABLE fact_claim_line (
  claim_line_sk BIGINT PRIMARY KEY,
  claim_id VARCHAR(64),
  claim_line_num INT,
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  provider_sk BIGINT REFERENCES dim_provider(provider_sk),
  facility_sk BIGINT REFERENCES dim_facility(facility_sk),
  payer_plan_sk BIGINT REFERENCES dim_payer_plan(payer_plan_sk),
  from_date_sk INT NOT NULL REFERENCES dim_date(date_sk),
  thru_date_sk INT NOT NULL REFERENCES dim_date(date_sk),

  -- Billing codes
  cpt_hcpcs VARCHAR(10),
  modifier1 VARCHAR(4),
  modifier2 VARCHAR(4),
  modifier3 VARCHAR(4),
  modifier4 VARCHAR(4),
  rev_code VARCHAR(4),
  pos_code VARCHAR(4),

  -- Diagnoses on this line
  dx_p VARCHAR(10),
  dx1 VARCHAR(10),
  dx2 VARCHAR(10),
  dx3 VARCHAR(10),
  dx4 VARCHAR(10),
  dx5 VARCHAR(10),
  dx6 VARCHAR(10),
  dx7 VARCHAR(10),
  dx8 VARCHAR(10),

  -- Utilization flags
  is_er BOOLEAN DEFAULT FALSE,
  is_inpatient BOOLEAN DEFAULT FALSE,
  is_outpatient BOOLEAN DEFAULT FALSE,
  is_preventive BOOLEAN DEFAULT FALSE,
  is_telehealth BOOLEAN DEFAULT FALSE,

  -- Financial metrics (additive)
  billed_amt NUMERIC(12,2),
  allowed_amt NUMERIC(12,2),
  paid_amt NUMERIC(12,2),
  patient_responsibility NUMERIC(12,2),
  units NUMERIC(10,2),

  load_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_claim_line_patient ON fact_claim_line(patient_sk);
CREATE INDEX idx_claim_line_dates ON fact_claim_line(from_date_sk, thru_date_sk);
CREATE INDEX idx_claim_line_cpt ON fact_claim_line(cpt_hcpcs) WHERE cpt_hcpcs IS NOT NULL;
CREATE INDEX idx_claim_line_er ON fact_claim_line(is_er, from_date_sk) WHERE is_er = TRUE;
CREATE INDEX idx_claim_line_ip ON fact_claim_line(is_inpatient, from_date_sk) WHERE is_inpatient = TRUE;
CREATE INDEX idx_claim_line_provider ON fact_claim_line(provider_sk, from_date_sk);
CREATE INDEX idx_claim_line_payer ON fact_claim_line(payer_plan_sk, from_date_sk);

-- Grain: one encounter/visit
CREATE TABLE fact_encounter (
  encounter_sk BIGINT PRIMARY KEY,
  encounter_id VARCHAR(64) UNIQUE,
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  provider_sk BIGINT REFERENCES dim_provider(provider_sk),
  facility_sk BIGINT REFERENCES dim_facility(facility_sk),
  start_date_sk INT NOT NULL REFERENCES dim_date(date_sk),
  end_date_sk INT REFERENCES dim_date(date_sk),

  encounter_type VARCHAR(20),
  primary_dx_code VARCHAR(10),
  admit_source VARCHAR(20),
  discharge_status VARCHAR(20),
  discharge_disposition VARCHAR(50),
  length_of_stay_days INT,

  load_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_encounter_patient ON fact_encounter(patient_sk);
CREATE INDEX idx_encounter_dates ON fact_encounter(start_date_sk, end_date_sk);
CREATE INDEX idx_encounter_type ON fact_encounter(encounter_type, start_date_sk);
CREATE INDEX idx_encounter_provider ON fact_encounter(provider_sk, start_date_sk);

-- Grain: one diagnosis event (patient × code × date)
CREATE TABLE fact_diagnosis (
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  date_sk INT NOT NULL REFERENCES dim_date(date_sk),
  code_sk BIGINT NOT NULL REFERENCES dim_code(code_sk),
  source VARCHAR(20),
  dx_type VARCHAR(20),
  is_principal BOOLEAN DEFAULT FALSE,
  claim_id VARCHAR(64),
  encounter_id VARCHAR(64),
  load_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (patient_sk, date_sk, code_sk, source)
);

CREATE INDEX idx_diagnosis_code ON fact_diagnosis(code_sk, date_sk);
CREATE INDEX idx_diagnosis_patient_date ON fact_diagnosis(patient_sk, date_sk);

-- Grain: patient × quality measure × event date
CREATE TABLE fact_quality_event (
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  measure_sk INT NOT NULL REFERENCES dim_quality_measure(measure_sk),
  event_date_sk INT NOT NULL REFERENCES dim_date(date_sk),
  evidence_code_sk BIGINT REFERENCES dim_code(code_sk),

  is_denominator BOOLEAN DEFAULT FALSE,
  is_numerator BOOLEAN DEFAULT FALSE,
  is_exclusion BOOLEAN DEFAULT FALSE,

  claim_id VARCHAR(64),
  encounter_id VARCHAR(64),
  load_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (patient_sk, measure_sk, event_date_sk, COALESCE(evidence_code_sk, 0))
);

CREATE INDEX idx_quality_measure_date ON fact_quality_event(measure_sk, event_date_sk);
CREATE INDEX idx_quality_patient ON fact_quality_event(patient_sk, measure_sk);
CREATE INDEX idx_quality_denom ON fact_quality_event(measure_sk, event_date_sk, is_denominator) WHERE is_denominator = TRUE;
CREATE INDEX idx_quality_numer ON fact_quality_event(measure_sk, event_date_sk, is_numerator) WHERE is_numerator = TRUE;

-- Grain: patient × RxNorm × date (optional for Rx analytics)
CREATE TABLE fact_medication (
  medication_sk BIGINT PRIMARY KEY,
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  date_sk INT NOT NULL REFERENCES dim_date(date_sk),
  rxnorm_code VARCHAR(20),
  ndc VARCHAR(20),
  drug_name VARCHAR(255),
  drug_class VARCHAR(100),
  days_supply INT,
  quantity NUMERIC(10,2),
  fills INT,
  billed_amt NUMERIC(12,2),
  allowed_amt NUMERIC(12,2),
  paid_amt NUMERIC(12,2),
  load_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_medication_patient ON fact_medication(patient_sk, date_sk);
CREATE INDEX idx_medication_rxnorm ON fact_medication(rxnorm_code, date_sk);
CREATE INDEX idx_medication_class ON fact_medication(drug_class, date_sk);

-- Grain: patient × LOINC × date (optional for lab/screening)
CREATE TABLE fact_lab_result (
  lab_result_sk BIGINT PRIMARY KEY,
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  date_sk INT NOT NULL REFERENCES dim_date(date_sk),
  loinc_code VARCHAR(20),
  test_name VARCHAR(255),
  result_value VARCHAR(100),
  result_numeric NUMERIC(15,4),
  result_unit VARCHAR(50),
  reference_range VARCHAR(100),
  abnormal_flag VARCHAR(10),
  load_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_lab_patient ON fact_lab_result(patient_sk, date_sk);
CREATE INDEX idx_lab_loinc ON fact_lab_result(loinc_code, date_sk);

-- ----------------------------------------------------------------------------
-- AGGREGATE/BRIDGE TABLES (performance accelerators)
-- ----------------------------------------------------------------------------

-- Grain: patient × month (materialized rollup for cost trends)
CREATE TABLE fact_patient_monthly_cost (
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  month_start_date_sk INT NOT NULL REFERENCES dim_date(date_sk),

  billed_amt NUMERIC(12,2),
  allowed_amt NUMERIC(12,2),
  paid_amt NUMERIC(12,2),
  patient_responsibility NUMERIC(12,2),

  er_visits INT,
  ip_admits INT,
  op_visits INT,
  preventive_visits INT,
  pcp_visits INT,
  specialist_visits INT,

  last_updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (patient_sk, month_start_date_sk)
);

CREATE INDEX idx_monthly_cost_date ON fact_patient_monthly_cost(month_start_date_sk);
CREATE INDEX idx_monthly_cost_amount ON fact_patient_monthly_cost(allowed_amt DESC);
CREATE INDEX idx_monthly_cost_er ON fact_patient_monthly_cost(er_visits DESC) WHERE er_visits > 0;

-- Grain: patient × condition × year (semantic accelerator for prevalence)
CREATE TABLE bridge_patient_condition_year (
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  condition_group_sk INT NOT NULL REFERENCES dim_condition_group(condition_group_sk),
  year INT NOT NULL,

  has_condition BOOLEAN NOT NULL,
  first_dx_date DATE,
  last_dx_date DATE,
  dx_count INT,

  last_updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (patient_sk, condition_group_sk, year)
);

CREATE INDEX idx_cond_year_group ON bridge_patient_condition_year(condition_group_sk, year, has_condition) WHERE has_condition = TRUE;
CREATE INDEX idx_cond_year_patient ON bridge_patient_condition_year(patient_sk, year);

-- ----------------------------------------------------------------------------
-- MAPPING/REFERENCE TABLES
-- ----------------------------------------------------------------------------

-- Maps clinical codes → condition groups (e.g., ICD10 E11.* → Type 2 Diabetes)
CREATE TABLE code_map_condition_group (
  code_system VARCHAR(20) NOT NULL,
  code VARCHAR(20) NOT NULL,
  condition_group_sk INT NOT NULL REFERENCES dim_condition_group(condition_group_sk),
  mapping_logic VARCHAR(20),
  is_primary BOOLEAN DEFAULT TRUE,
  effective_start_date DATE,
  effective_end_date DATE,
  PRIMARY KEY (code_system, code, condition_group_sk)
);

CREATE INDEX idx_code_map_group ON code_map_condition_group(condition_group_sk);
CREATE INDEX idx_code_map_code ON code_map_condition_group(code_system, code);

-- Maps codes → quality measure roles (numerator/denominator/exclusion)
CREATE TABLE measure_map_evidence (
  measure_sk INT NOT NULL REFERENCES dim_quality_measure(measure_sk),
  code_system VARCHAR(20) NOT NULL,
  code VARCHAR(20) NOT NULL,
  role VARCHAR(20) NOT NULL,
  spec_year INT NOT NULL,
  age_min INT,
  age_max INT,
  additional_criteria TEXT,
  PRIMARY KEY (measure_sk, code_system, code, role, spec_year)
);

CREATE INDEX idx_measure_map_measure ON measure_map_evidence(measure_sk, spec_year);
CREATE INDEX idx_measure_map_code ON measure_map_evidence(code_system, code);

-- County reference (for geographic analytics)
CREATE TABLE county_ref (
  county_fips CHAR(5) PRIMARY KEY,
  county_name VARCHAR(64) NOT NULL,
  state_fips CHAR(2) NOT NULL,
  state CHAR(2) NOT NULL,
  state_name VARCHAR(64),
  region VARCHAR(20),
  population INT,
  median_income NUMERIC(12,2)
);

CREATE INDEX idx_county_state ON county_ref(state);

-- ----------------------------------------------------------------------------
-- SECURITY & AUDIT TABLES
-- ----------------------------------------------------------------------------

-- Row-level security: patient attribution to organizations/payers
CREATE TABLE patient_attribution (
  patient_sk BIGINT NOT NULL REFERENCES dim_patient(patient_sk),
  org_id VARCHAR(64) NOT NULL,
  payer_plan_sk BIGINT REFERENCES dim_payer_plan(payer_plan_sk),
  attribution_start_date DATE NOT NULL,
  attribution_end_date DATE,
  is_current BOOLEAN DEFAULT TRUE,
  PRIMARY KEY (patient_sk, org_id, attribution_start_date)
);

CREATE INDEX idx_attribution_org ON patient_attribution(org_id, is_current) WHERE is_current = TRUE;
CREATE INDEX idx_attribution_payer ON patient_attribution(payer_plan_sk, is_current) WHERE is_current = TRUE;

-- Query audit log (track NL→SQL queries for governance)
CREATE TABLE query_audit_log (
  query_id BIGINT PRIMARY KEY,
  user_id VARCHAR(64),
  org_id VARCHAR(64),
  natural_language_query TEXT,
  generated_sql TEXT,
  query_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  execution_duration_ms INT,
  rows_returned INT,
  error_message TEXT
);

CREATE INDEX idx_audit_user ON query_audit_log(user_id, query_timestamp);
CREATE INDEX idx_audit_org ON query_audit_log(org_id, query_timestamp);

-- ============================================================================
-- SEQUENCES for surrogate key generation
-- ============================================================================

CREATE SEQUENCE seq_patient_sk START 1000000;
CREATE SEQUENCE seq_provider_sk START 2000000;
CREATE SEQUENCE seq_facility_sk START 3000000;
CREATE SEQUENCE seq_payer_plan_sk START 4000000;
CREATE SEQUENCE seq_code_sk START 5000000;
CREATE SEQUENCE seq_claim_line_sk START 10000000;
CREATE SEQUENCE seq_encounter_sk START 20000000;
CREATE SEQUENCE seq_medication_sk START 30000000;
CREATE SEQUENCE seq_lab_result_sk START 40000000;
CREATE SEQUENCE seq_query_id START 1;

-- ============================================================================
-- COMMENTS (metadata for data catalog / LLM context)
-- ============================================================================

COMMENT ON TABLE dim_patient IS 'Patient demographics and geographic attributes; SCD Type 2 for history tracking';
COMMENT ON TABLE fact_claim_line IS 'Grain: one claim line; source for all financial and utilization metrics';
COMMENT ON TABLE bridge_patient_condition_year IS 'Materialized patient-condition flags by year; rebuilt monthly from diagnoses';
COMMENT ON TABLE fact_patient_monthly_cost IS 'Aggregated monthly cost/utilization rollup; query this for trends and top-N analysis';
COMMENT ON TABLE code_map_condition_group IS 'Maps ICD/CPT codes to semantic condition groups (e.g., diabetes, cancer)';

COMMENT ON COLUMN dim_patient.patient_sk IS 'Surrogate key; stable identifier for joins';
COMMENT ON COLUMN dim_patient.patient_id IS 'Business key (MRN/member ID)';
COMMENT ON COLUMN fact_claim_line.allowed_amt IS 'Primary cost metric; use for most financial analysis';
COMMENT ON COLUMN fact_claim_line.is_er IS 'TRUE if emergency room visit; derived from POS/rev codes';
COMMENT ON COLUMN bridge_patient_condition_year.has_condition IS 'TRUE if patient had this condition in this year';
