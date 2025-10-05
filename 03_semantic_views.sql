-- ============================================================================
-- Healthcare Analytics - Semantic Views for NL→SQL
-- Simplified, LLM-friendly views that abstract common query patterns
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PATIENT VIEWS (demographics with computed age)
-- ----------------------------------------------------------------------------

-- Current patient population with age as of today
CREATE OR REPLACE VIEW vw_patients_current AS
SELECT
    p.patient_sk,
    p.patient_id,
    p.birth_date,
    p.death_date,
    EXTRACT(YEAR FROM AGE(COALESCE(p.death_date, CURRENT_DATE), p.birth_date))::INT AS age_years,
    FLOOR(EXTRACT(YEAR FROM AGE(COALESCE(p.death_date, CURRENT_DATE), p.birth_date)) / 10) * 10 AS age_bucket_10yr,
    CASE
        WHEN EXTRACT(YEAR FROM AGE(COALESCE(p.death_date, CURRENT_DATE), p.birth_date)) < 18 THEN '0-17'
        WHEN EXTRACT(YEAR FROM AGE(COALESCE(p.death_date, CURRENT_DATE), p.birth_date)) BETWEEN 18 AND 34 THEN '18-34'
        WHEN EXTRACT(YEAR FROM AGE(COALESCE(p.death_date, CURRENT_DATE), p.birth_date)) BETWEEN 35 AND 49 THEN '35-49'
        WHEN EXTRACT(YEAR FROM AGE(COALESCE(p.death_date, CURRENT_DATE), p.birth_date)) BETWEEN 50 AND 64 THEN '50-64'
        WHEN EXTRACT(YEAR FROM AGE(COALESCE(p.death_date, CURRENT_DATE), p.birth_date)) BETWEEN 65 AND 74 THEN '65-74'
        ELSE '75+'
    END AS age_bucket_category,
    p.sex_at_birth AS gender,
    p.gender_identity,
    p.race,
    p.ethnicity,
    p.zip3,
    p.zip5,
    p.county_fips,
    p.county_name,
    p.state,
    CASE WHEN p.death_date IS NULL THEN TRUE ELSE FALSE END AS is_living
FROM dim_patient p
WHERE p.is_current = TRUE;

COMMENT ON VIEW vw_patients_current IS 'Current patient roster with computed age and demographics; use for population counts and stratification';

-- Patient population as of specific year-end
CREATE OR REPLACE VIEW vw_patients_2025 AS
SELECT
    p.patient_sk,
    p.patient_id,
    p.birth_date,
    p.death_date,
    EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date))::INT AS age_years,
    FLOOR(EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) / 10) * 10 AS age_bucket_10yr,
    CASE
        WHEN EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) < 18 THEN '0-17'
        WHEN EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) BETWEEN 18 AND 34 THEN '18-34'
        WHEN EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) BETWEEN 35 AND 49 THEN '35-49'
        WHEN EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) BETWEEN 50 AND 64 THEN '50-64'
        WHEN EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) BETWEEN 65 AND 74 THEN '65-74'
        ELSE '75+'
    END AS age_bucket_category,
    p.sex_at_birth AS gender,
    p.county_fips,
    p.county_name,
    p.state
FROM dim_patient p
WHERE p.is_current = TRUE
  AND (p.death_date IS NULL OR p.death_date >= DATE '2025-12-31');

COMMENT ON VIEW vw_patients_2025 IS 'Patient population as of 2025-12-31; use for year-specific queries';

-- ----------------------------------------------------------------------------
-- CONDITION VIEWS (prevalence & incidence)
-- ----------------------------------------------------------------------------

-- Current patient conditions (all years, latest flags)
CREATE OR REPLACE VIEW vw_patient_conditions_current AS
SELECT
    pc.patient_sk,
    p.patient_id,
    cg.condition_group_sk,
    cg.group_id,
    cg.group_name,
    cg.parent_group,
    cg.clinical_category,
    pc.year,
    pc.has_condition,
    pc.first_dx_date,
    pc.last_dx_date
FROM bridge_patient_condition_year pc
JOIN dim_patient p ON p.patient_sk = pc.patient_sk AND p.is_current = TRUE
JOIN dim_condition_group cg ON cg.condition_group_sk = pc.condition_group_sk AND cg.is_active = TRUE
WHERE pc.has_condition = TRUE;

COMMENT ON VIEW vw_patient_conditions_current IS 'All patient-condition flags; filter by year for prevalence counts';

-- 2025 patient conditions (prevalence)
CREATE OR REPLACE VIEW vw_patient_conditions_2025 AS
SELECT
    pc.patient_sk,
    p.patient_id,
    cg.group_name AS condition_name,
    cg.parent_group,
    cg.clinical_category,
    pc.first_dx_date,
    pc.last_dx_date,
    pc.dx_count
FROM bridge_patient_condition_year pc
JOIN dim_patient p ON p.patient_sk = pc.patient_sk AND p.is_current = TRUE
JOIN dim_condition_group cg ON cg.condition_group_sk = pc.condition_group_sk AND cg.is_active = TRUE
WHERE pc.year = 2025
  AND pc.has_condition = TRUE;

COMMENT ON VIEW vw_patient_conditions_2025 IS 'Patient conditions in 2025; join to vw_patients_2025 for prevalence analysis';

-- ----------------------------------------------------------------------------
-- COST & UTILIZATION VIEWS
-- ----------------------------------------------------------------------------

-- Monthly patient costs (all years)
CREATE OR REPLACE VIEW vw_patient_monthly_costs AS
SELECT
    m.patient_sk,
    p.patient_id,
    d.date AS month_start_date,
    d.year,
    d.month,
    d.month_name,
    m.allowed_amt AS total_cost,
    m.paid_amt,
    m.billed_amt,
    m.patient_responsibility,
    m.er_visits,
    m.ip_admits,
    m.op_visits,
    m.preventive_visits,
    m.pcp_visits,
    m.specialist_visits
FROM fact_patient_monthly_cost m
JOIN dim_patient p ON p.patient_sk = m.patient_sk AND p.is_current = TRUE
JOIN dim_date d ON d.date_sk = m.month_start_date_sk;

COMMENT ON VIEW vw_patient_monthly_costs IS 'Patient costs and utilization by month; aggregate by year/patient for trends';

-- 2025 monthly costs
CREATE OR REPLACE VIEW vw_patient_monthly_costs_2025 AS
SELECT *
FROM vw_patient_monthly_costs
WHERE year = 2025;

COMMENT ON VIEW vw_patient_monthly_costs_2025 IS 'Patient monthly costs for 2025; aggregate to get YTD totals';

-- Annual patient cost summary (2025)
CREATE OR REPLACE VIEW vw_patient_annual_costs_2025 AS
SELECT
    m.patient_sk,
    p.patient_id,
    SUM(m.allowed_amt) AS total_cost_2025,
    SUM(m.paid_amt) AS total_paid_2025,
    SUM(m.er_visits) AS total_er_visits_2025,
    SUM(m.ip_admits) AS total_ip_admits_2025,
    SUM(m.op_visits) AS total_op_visits_2025,
    ROUND(SUM(m.allowed_amt) / NULLIF(SUM(m.er_visits + m.ip_admits + m.op_visits), 0), 2) AS cost_per_visit
FROM vw_patient_monthly_costs_2025 m
JOIN dim_patient p ON p.patient_sk = m.patient_sk
GROUP BY m.patient_sk, p.patient_id;

COMMENT ON VIEW vw_patient_annual_costs_2025 IS 'Total 2025 costs per patient; use for top-N and cost distribution queries';

-- ----------------------------------------------------------------------------
-- UTILIZATION VIEWS (ER, IP, encounters)
-- ----------------------------------------------------------------------------

-- ER visits (2025)
CREATE OR REPLACE VIEW vw_er_visits_2025 AS
SELECT
    e.encounter_sk,
    e.patient_sk,
    p.patient_id,
    d.date AS visit_date,
    d.year,
    d.month,
    e.primary_dx_code,
    e.discharge_status,
    pr.provider_name,
    f.facility_name
FROM fact_encounter e
JOIN dim_patient p ON p.patient_sk = e.patient_sk AND p.is_current = TRUE
JOIN dim_date d ON d.date_sk = e.start_date_sk
LEFT JOIN dim_provider pr ON pr.provider_sk = e.provider_sk
LEFT JOIN dim_facility f ON f.facility_sk = e.facility_sk
WHERE e.encounter_type = 'ER'
  AND d.year = 2025;

COMMENT ON VIEW vw_er_visits_2025 IS 'All ER encounters in 2025; count by patient_sk for frequent flyers';

-- Inpatient admissions (2025)
CREATE OR REPLACE VIEW vw_ip_admissions_2025 AS
SELECT
    e.encounter_sk,
    e.patient_sk,
    p.patient_id,
    d.date AS admit_date,
    d_end.date AS discharge_date,
    e.length_of_stay_days,
    e.primary_dx_code,
    e.discharge_status,
    pr.provider_name,
    f.facility_name
FROM fact_encounter e
JOIN dim_patient p ON p.patient_sk = e.patient_sk AND p.is_current = TRUE
JOIN dim_date d ON d.date_sk = e.start_date_sk
LEFT JOIN dim_date d_end ON d_end.date_sk = e.end_date_sk
LEFT JOIN dim_provider pr ON pr.provider_sk = e.provider_sk
LEFT JOIN dim_facility f ON f.facility_sk = e.facility_sk
WHERE e.encounter_type = 'IP'
  AND d.year = 2025;

COMMENT ON VIEW vw_ip_admissions_2025 IS 'All IP admissions in 2025; join to claims for cost analysis';

-- Patient ER utilization summary (2025)
CREATE OR REPLACE VIEW vw_patient_er_summary_2025 AS
SELECT
    patient_sk,
    patient_id,
    COUNT(*) AS er_visits_2025,
    MIN(visit_date) AS first_er_visit,
    MAX(visit_date) AS last_er_visit
FROM vw_er_visits_2025
GROUP BY patient_sk, patient_id;

COMMENT ON VIEW vw_patient_er_summary_2025 IS 'ER visit counts per patient in 2025; order by er_visits_2025 DESC for high utilizers';

-- ----------------------------------------------------------------------------
-- CLAIM LINE VIEWS (procedure/service detail)
-- ----------------------------------------------------------------------------

-- All claim lines (2025)
CREATE OR REPLACE VIEW vw_claim_lines_2025 AS
SELECT
    cl.claim_line_sk,
    cl.patient_sk,
    p.patient_id,
    d.date AS service_date,
    d.year,
    d.month,
    cl.cpt_hcpcs AS cpt_code,
    c.short_desc AS cpt_description,
    cl.dx_p AS primary_dx,
    cl.is_er,
    cl.is_inpatient,
    cl.is_outpatient,
    cl.is_preventive,
    cl.allowed_amt AS cost,
    cl.paid_amt,
    cl.units,
    pr.provider_name,
    pr.specialty AS provider_specialty,
    f.facility_name
FROM fact_claim_line cl
JOIN dim_patient p ON p.patient_sk = cl.patient_sk AND p.is_current = TRUE
JOIN dim_date d ON d.date_sk = cl.from_date_sk
LEFT JOIN dim_code c ON c.code_system = 'CPT' AND c.code = cl.cpt_hcpcs
LEFT JOIN dim_provider pr ON pr.provider_sk = cl.provider_sk
LEFT JOIN dim_facility f ON f.facility_sk = cl.facility_sk
WHERE d.year = 2025;

COMMENT ON VIEW vw_claim_lines_2025 IS 'All claim lines in 2025 with CPT descriptions; filter by cpt_code or patient_id';

-- Patient procedure summary (2025, specific CPT list)
CREATE OR REPLACE VIEW vw_patient_procedure_events_2025 AS
SELECT
    patient_sk,
    patient_id,
    cpt_code,
    cpt_description,
    COUNT(*) AS event_count,
    SUM(units) AS total_units,
    SUM(cost) AS total_cost
FROM vw_claim_lines_2025
WHERE cpt_code IS NOT NULL
GROUP BY patient_sk, patient_id, cpt_code, cpt_description;

COMMENT ON VIEW vw_patient_procedure_events_2025 IS 'Aggregated procedure counts per patient in 2025; filter by patient_id and cpt_code IN (...)';

-- ----------------------------------------------------------------------------
-- QUALITY MEASURE VIEWS
-- ----------------------------------------------------------------------------

-- Osteoporosis screening (women 65-75, 2025)
CREATE OR REPLACE VIEW vw_osteoporosis_screening_2025 AS
WITH denominator AS (
    SELECT patient_sk, patient_id, age_years
    FROM vw_patients_2025
    WHERE gender = 'F'
      AND age_years BETWEEN 65 AND 75
),
numerator AS (
    SELECT DISTINCT qe.patient_sk
    FROM fact_quality_event qe
    JOIN dim_quality_measure m ON m.measure_sk = qe.measure_sk
    JOIN dim_date d ON d.date_sk = qe.event_date_sk
    WHERE m.measure_id = 'OSTOP_SCREEN_65_75'
      AND d.year = 2025
      AND qe.is_numerator = TRUE
)
SELECT
    d.patient_sk,
    d.patient_id,
    d.age_years,
    CASE WHEN n.patient_sk IS NOT NULL THEN TRUE ELSE FALSE END AS is_screened
FROM denominator d
LEFT JOIN numerator n ON n.patient_sk = d.patient_sk;

COMMENT ON VIEW vw_osteoporosis_screening_2025 IS 'Osteoporosis screening measure for 2025; COUNT(*) FILTER (WHERE is_screened) / COUNT(*) for rate';

-- Diabetes HbA1c control (2025)
CREATE OR REPLACE VIEW vw_diabetes_a1c_control_2025 AS
WITH diabetics AS (
    SELECT DISTINCT pc.patient_sk, p.patient_id
    FROM vw_patient_conditions_2025 pc
    JOIN vw_patients_2025 p ON p.patient_sk = pc.patient_sk
    WHERE pc.condition_name IN ('Type 2 diabetes', 'Type 1 diabetes')
      AND p.age_years BETWEEN 18 AND 75
),
controlled AS (
    SELECT DISTINCT qe.patient_sk
    FROM fact_quality_event qe
    JOIN dim_quality_measure m ON m.measure_sk = qe.measure_sk
    JOIN dim_date d ON d.date_sk = qe.event_date_sk
    WHERE m.measure_id = 'HBD_A1C_CONTROL'
      AND d.year = 2025
      AND qe.is_numerator = TRUE
)
SELECT
    dm.patient_sk,
    dm.patient_id,
    CASE WHEN c.patient_sk IS NOT NULL THEN TRUE ELSE FALSE END AS is_controlled
FROM diabetics dm
LEFT JOIN controlled c ON c.patient_sk = dm.patient_sk;

COMMENT ON VIEW vw_diabetes_a1c_control_2025 IS 'Diabetes HbA1c control (<8%) for 2025';

-- ----------------------------------------------------------------------------
-- GEOGRAPHIC VIEWS (county-level rollups)
-- ----------------------------------------------------------------------------

-- Patient counts by county (2025)
CREATE OR REPLACE VIEW vw_patient_count_by_county_2025 AS
SELECT
    p.county_fips,
    p.county_name,
    p.state,
    COUNT(*) AS patient_count,
    COUNT(*) FILTER (WHERE p.gender = 'F') AS female_count,
    COUNT(*) FILTER (WHERE p.gender = 'M') AS male_count,
    ROUND(AVG(p.age_years), 1) AS avg_age
FROM vw_patients_2025 p
GROUP BY p.county_fips, p.county_name, p.state;

COMMENT ON VIEW vw_patient_count_by_county_2025 IS 'Patient counts and demographics by county in 2025';

-- Top 100 patients by cost per county (2025)
CREATE OR REPLACE VIEW vw_top100_patients_by_county_2025 AS
WITH patient_costs AS (
    SELECT
        c.patient_sk,
        c.patient_id,
        p.county_fips,
        p.county_name,
        p.state,
        c.total_cost_2025
    FROM vw_patient_annual_costs_2025 c
    JOIN vw_patients_2025 p ON p.patient_sk = c.patient_sk
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY county_fips ORDER BY total_cost_2025 DESC) AS rank_in_county
    FROM patient_costs
)
SELECT *
FROM ranked
WHERE rank_in_county <= 100;

COMMENT ON VIEW vw_top100_patients_by_county_2025 IS 'Top 100 highest-cost patients per county in 2025; ready for export or drill-down';

-- ----------------------------------------------------------------------------
-- POPULATION HEALTH SUMMARY VIEWS
-- ----------------------------------------------------------------------------

-- Population summary by gender and age bucket (2025)
CREATE OR REPLACE VIEW vw_population_summary_2025 AS
SELECT
    gender,
    age_bucket_10yr,
    COUNT(*) AS member_count,
    ROUND(AVG(age_years), 1) AS avg_age
FROM vw_patients_2025
GROUP BY gender, age_bucket_10yr
ORDER BY gender, age_bucket_10yr;

COMMENT ON VIEW vw_population_summary_2025 IS 'Population counts by gender and 10-year age buckets (2025)';

-- Cancer prevalence by type (2025)
CREATE OR REPLACE VIEW vw_cancer_prevalence_2025 AS
SELECT
    condition_name AS cancer_type,
    COUNT(*) AS patient_count,
    MIN(first_dx_date) AS earliest_diagnosis,
    MAX(last_dx_date) AS latest_diagnosis
FROM vw_patient_conditions_2025
WHERE parent_group = 'Any cancer'
GROUP BY condition_name
ORDER BY patient_count DESC;

COMMENT ON VIEW vw_cancer_prevalence_2025 IS 'Cancer patient counts by cancer type in 2025; ordered by prevalence';

-- ----------------------------------------------------------------------------
-- COST TREND VIEWS
-- ----------------------------------------------------------------------------

-- Total population cost by month (2025)
CREATE OR REPLACE VIEW vw_total_cost_by_month_2025 AS
SELECT
    year,
    month,
    month_name,
    SUM(total_cost) AS total_allowed_amt,
    SUM(paid_amt) AS total_paid_amt,
    COUNT(DISTINCT patient_sk) AS unique_patients,
    SUM(er_visits) AS total_er_visits,
    SUM(ip_admits) AS total_ip_admits
FROM vw_patient_monthly_costs_2025
GROUP BY year, month, month_name
ORDER BY year, month;

COMMENT ON VIEW vw_total_cost_by_month_2025 IS 'Total population cost and utilization by month (2025); use for trend charts';

-- Average cost per patient by month (2025)
CREATE OR REPLACE VIEW vw_avg_cost_per_patient_by_month_2025 AS
SELECT
    year,
    month,
    month_name,
    COUNT(DISTINCT patient_sk) AS unique_patients,
    SUM(total_cost) AS total_cost,
    ROUND(SUM(total_cost) / COUNT(DISTINCT patient_sk), 2) AS avg_cost_per_patient
FROM vw_patient_monthly_costs_2025
GROUP BY year, month, month_name
ORDER BY year, month;

COMMENT ON VIEW vw_avg_cost_per_patient_by_month_2025 IS 'Average cost per patient by month (2025)';

-- ============================================================================
-- MATERIALIZED VIEW EXAMPLE (for performance)
-- ============================================================================

-- For very large datasets, materialize frequently-accessed views
-- Uncomment and run manually when needed:

/*
CREATE MATERIALIZED VIEW mvw_patient_annual_costs_2025 AS
SELECT * FROM vw_patient_annual_costs_2025;

CREATE INDEX idx_mvw_annual_cost ON mvw_patient_annual_costs_2025(total_cost_2025 DESC);
CREATE INDEX idx_mvw_annual_patient ON mvw_patient_annual_costs_2025(patient_id);

-- Refresh monthly or after data loads:
REFRESH MATERIALIZED VIEW mvw_patient_annual_costs_2025;
*/
