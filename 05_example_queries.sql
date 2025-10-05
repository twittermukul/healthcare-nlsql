-- ============================================================================
-- Healthcare Analytics - Example Query Library
-- Production-ready SQL for all 9 use cases from requirements
-- ============================================================================

-- ============================================================================
-- POPULATION HEALTH QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1: Gender & Age Buckets (10-year bins)
-- "Show me the population by gender and age bucket"
-- ----------------------------------------------------------------------------

-- Using semantic view
SELECT
    gender,
    age_bucket_10yr AS age_bucket,
    COUNT(*) AS patient_count,
    ROUND(AVG(age_years), 1) AS avg_age,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_population
FROM vw_patients_2025
GROUP BY gender, age_bucket_10yr
ORDER BY gender, age_bucket_10yr;

-- Alternative: with descriptive age labels
SELECT
    gender,
    age_bucket_category AS age_group,
    COUNT(*) AS patient_count
FROM vw_patients_2025
GROUP BY gender, age_bucket_category
ORDER BY gender, age_bucket_category;

-- Alternative: direct from base table (if view not available)
SELECT
    sex_at_birth AS gender,
    FLOOR(EXTRACT(YEAR FROM AGE(DATE '2025-12-31', birth_date)) / 10) * 10 AS age_bucket,
    COUNT(*) AS patient_count
FROM dim_patient
WHERE is_current = TRUE
  AND (death_date IS NULL OR death_date >= DATE '2025-12-31')
GROUP BY sex_at_birth, FLOOR(EXTRACT(YEAR FROM AGE(DATE '2025-12-31', birth_date)) / 10) * 10
ORDER BY gender, age_bucket;

-- ----------------------------------------------------------------------------
-- Q2: Osteoporosis Screening (Women 65-75 in 2025)
-- "What percent of women aged 65-75 received osteoporosis screening in 2025?"
-- ----------------------------------------------------------------------------

-- Using pre-built view
SELECT
    COUNT(*) AS denominator,
    COUNT(*) FILTER (WHERE is_screened = TRUE) AS numerator,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_screened = TRUE) / COUNT(*), 2) AS pct_screened
FROM vw_osteoporosis_screening_2025;

-- Detailed breakdown with patient list
SELECT
    patient_id,
    age_years,
    is_screened,
    CASE WHEN is_screened THEN 'Met measure' ELSE 'Gap in care' END AS status
FROM vw_osteoporosis_screening_2025
ORDER BY is_screened DESC, patient_id;

-- Alternative: built from scratch using measure events
WITH denominator AS (
    SELECT p.patient_sk, p.patient_id, p.age_years
    FROM vw_patients_2025 p
    WHERE p.gender = 'F'
      AND p.age_years BETWEEN 65 AND 75
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
    d.patient_id,
    d.age_years,
    CASE WHEN n.patient_sk IS NOT NULL THEN TRUE ELSE FALSE END AS is_screened
FROM denominator d
LEFT JOIN numerator n ON n.patient_sk = d.patient_sk
ORDER BY is_screened DESC;

-- Alternative: using CPT codes directly (if quality events not populated)
WITH denominator AS (
    SELECT p.patient_sk, p.patient_id
    FROM vw_patients_2025 p
    WHERE p.gender = 'F' AND p.age_years BETWEEN 65 AND 75
),
numerator AS (
    SELECT DISTINCT cl.patient_sk
    FROM fact_claim_line cl
    JOIN dim_date d ON d.date_sk = cl.from_date_sk
    WHERE d.year = 2025
      AND cl.cpt_hcpcs IN ('77080', '77081', '77085', '77086', 'G0130')  -- DEXA CPT codes
)
SELECT
    COUNT(*) AS denominator,
    COUNT(n.patient_sk) AS numerator,
    ROUND(100.0 * COUNT(n.patient_sk) / COUNT(*), 2) AS pct_screened
FROM denominator d
LEFT JOIN numerator n ON n.patient_sk = d.patient_sk;

-- ----------------------------------------------------------------------------
-- Q3: Type 2 Diabetes Prevalence
-- "How many patients have had type 2 diabetes?"
-- ----------------------------------------------------------------------------

-- Using condition view (2025)
SELECT COUNT(*) AS patients_with_t2dm
FROM vw_patient_conditions_2025
WHERE condition_name = 'Type 2 diabetes';

-- With demographic breakdown
SELECT
    p.gender,
    p.age_bucket_category,
    COUNT(*) AS t2dm_patient_count
FROM vw_patient_conditions_2025 c
JOIN vw_patients_2025 p ON p.patient_sk = c.patient_sk
WHERE c.condition_name = 'Type 2 diabetes'
GROUP BY p.gender, p.age_bucket_category
ORDER BY p.gender, p.age_bucket_category;

-- Alternative: using bridge table directly
SELECT COUNT(DISTINCT patient_sk) AS patients_with_t2dm
FROM bridge_patient_condition_year
WHERE condition_group_sk = 2  -- Type 2 diabetes
  AND year = 2025
  AND has_condition = TRUE;

-- Alternative: using diagnosis fact table with code mapping
SELECT COUNT(DISTINCT fd.patient_sk) AS patients_with_t2dm
FROM fact_diagnosis fd
JOIN dim_code dc ON dc.code_sk = fd.code_sk
JOIN dim_date dd ON dd.date_sk = fd.date_sk
WHERE dc.code_system = 'ICD10CM'
  AND dc.code LIKE 'E11%'
  AND dd.year = 2025;

-- ============================================================================
-- PATIENT ANALYSIS QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q4: ER Frequent Flyers
-- "Show me patients most often admitted to the ER"
-- ----------------------------------------------------------------------------

-- Using ER summary view (2025)
SELECT
    patient_id,
    er_visits_2025,
    first_er_visit,
    last_er_visit
FROM vw_patient_er_summary_2025
ORDER BY er_visits_2025 DESC
LIMIT 50;

-- With patient demographics and total cost
SELECT
    e.patient_id,
    e.er_visits_2025,
    p.age_years,
    p.gender,
    p.county_name,
    c.total_cost_2025,
    ROUND(c.total_cost_2025 / NULLIF(e.er_visits_2025, 0), 2) AS cost_per_er_visit
FROM vw_patient_er_summary_2025 e
JOIN vw_patients_2025 p ON p.patient_id = e.patient_id
LEFT JOIN vw_patient_annual_costs_2025 c ON c.patient_id = e.patient_id
ORDER BY e.er_visits_2025 DESC
LIMIT 100;

-- Alternative: built from encounters
SELECT
    p.patient_id,
    COUNT(*) AS er_visits_2025
FROM fact_encounter e
JOIN dim_patient p ON p.patient_sk = e.patient_sk AND p.is_current = TRUE
JOIN dim_date d ON d.date_sk = e.start_date_sk
WHERE e.encounter_type = 'ER'
  AND d.year = 2025
GROUP BY p.patient_id
ORDER BY er_visits_2025 DESC
LIMIT 50;

-- Alternative: using claim lines (if encounters not available)
SELECT
    p.patient_id,
    COUNT(DISTINCT cl.claim_id) AS er_visits_2025
FROM fact_claim_line cl
JOIN dim_patient p ON p.patient_sk = cl.patient_sk AND p.is_current = TRUE
JOIN dim_date d ON d.date_sk = cl.from_date_sk
WHERE cl.is_er = TRUE
  AND d.year = 2025
GROUP BY p.patient_id
ORDER BY er_visits_2025 DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- Q5: Patient 528 - Specific CPT Event Counts (2025)
-- "Patient 528 in 2025 total number of events for CPTs 95992, 97112, 95117, 71046, 97110"
-- ----------------------------------------------------------------------------

-- Using procedure events view
SELECT
    patient_id,
    cpt_code,
    cpt_description,
    event_count,
    total_units,
    total_cost
FROM vw_patient_procedure_events_2025
WHERE patient_id = '528'
  AND cpt_code IN ('95992', '97112', '95117', '71046', '97110')
ORDER BY cpt_code;

-- Total across all specified CPTs
SELECT
    patient_id,
    SUM(event_count) AS total_events,
    SUM(total_units) AS total_units,
    SUM(total_cost) AS total_cost
FROM vw_patient_procedure_events_2025
WHERE patient_id = '528'
  AND cpt_code IN ('95992', '97112', '95117', '71046', '97110');

-- Alternative: detailed line-by-line
SELECT
    cl.cpt_hcpcs AS cpt_code,
    c.short_desc AS description,
    d.date AS service_date,
    cl.units,
    cl.allowed_amt AS cost,
    pr.provider_name
FROM fact_claim_line cl
JOIN dim_patient p ON p.patient_sk = cl.patient_sk AND p.is_current = TRUE
JOIN dim_date d ON d.date_sk = cl.from_date_sk
LEFT JOIN dim_code c ON c.code_system = 'CPT' AND c.code = cl.cpt_hcpcs
LEFT JOIN dim_provider pr ON pr.provider_sk = cl.provider_sk
WHERE p.patient_id = '528'
  AND d.year = 2025
  AND cl.cpt_hcpcs IN ('95992', '97112', '95117', '71046', '97110')
ORDER BY d.date, cl.cpt_hcpcs;

-- Alternative: aggregate from claim lines
SELECT
    p.patient_id,
    cl.cpt_hcpcs AS cpt_code,
    COUNT(*) AS line_count,
    SUM(cl.units) AS total_units,
    SUM(cl.allowed_amt) AS total_cost
FROM fact_claim_line cl
JOIN dim_patient p ON p.patient_sk = cl.patient_sk
JOIN dim_date d ON d.date_sk = cl.from_date_sk
WHERE p.patient_id = '528'
  AND d.year = 2025
  AND cl.cpt_hcpcs IN ('95992', '97112', '95117', '71046', '97110')
GROUP BY p.patient_id, cl.cpt_hcpcs
ORDER BY cl.cpt_hcpcs;

-- ----------------------------------------------------------------------------
-- Q6: Most Expensive Patients & Average Cost (2025)
-- "Show me the most expensive patients in 2025 and their average cost"
-- ----------------------------------------------------------------------------

-- Top 100 most expensive patients
SELECT
    patient_id,
    total_cost_2025,
    total_er_visits_2025,
    total_ip_admits_2025,
    total_op_visits_2025
FROM vw_patient_annual_costs_2025
ORDER BY total_cost_2025 DESC
LIMIT 100;

-- Average cost across the top 100
WITH top100 AS (
    SELECT total_cost_2025
    FROM vw_patient_annual_costs_2025
    ORDER BY total_cost_2025 DESC
    LIMIT 100
)
SELECT
    COUNT(*) AS patient_count,
    ROUND(AVG(total_cost_2025), 2) AS avg_cost,
    ROUND(MIN(total_cost_2025), 2) AS min_cost,
    ROUND(MAX(total_cost_2025), 2) AS max_cost,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_cost_2025), 2) AS median_cost
FROM top100;

-- Average cost across entire population
SELECT
    COUNT(*) AS total_patients,
    ROUND(AVG(total_cost_2025), 2) AS avg_cost_per_patient,
    ROUND(SUM(total_cost_2025), 2) AS total_population_cost
FROM vw_patient_annual_costs_2025;

-- Alternative: with patient demographics
SELECT
    p.patient_id,
    p.age_years,
    p.gender,
    p.county_name,
    c.total_cost_2025,
    c.total_er_visits_2025,
    c.total_ip_admits_2025
FROM vw_patient_annual_costs_2025 c
JOIN vw_patients_2025 p ON p.patient_id = c.patient_id
ORDER BY c.total_cost_2025 DESC
LIMIT 100;

-- Alternative: built from monthly costs
SELECT
    m.patient_id,
    SUM(m.allowed_amt) AS total_cost_2025,
    SUM(m.er_visits) AS total_er_visits_2025,
    SUM(m.ip_admits) AS total_ip_admits_2025
FROM fact_patient_monthly_cost mc
JOIN dim_patient m ON m.patient_sk = mc.patient_sk AND m.is_current = TRUE
JOIN dim_date d ON d.date_sk = mc.month_start_date_sk
WHERE d.year = 2025
GROUP BY m.patient_id
ORDER BY total_cost_2025 DESC
LIMIT 100;

-- ============================================================================
-- PREDICTIONS & RISK QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q7: Cancer Prevalence by Type (2025)
-- "How many patients have any cancer in 2025, categorized by top cancer groups"
-- ----------------------------------------------------------------------------

-- Using cancer prevalence view
SELECT
    cancer_type,
    patient_count,
    ROUND(100.0 * patient_count / SUM(patient_count) OVER (), 2) AS pct_of_cancer_patients
FROM vw_cancer_prevalence_2025
ORDER BY patient_count DESC;

-- Alternative: with total cancer count
WITH cancer_detail AS (
    SELECT
        condition_name AS cancer_type,
        COUNT(*) AS patient_count
    FROM vw_patient_conditions_2025
    WHERE parent_group = 'Any cancer'
    GROUP BY condition_name
),
total AS (
    SELECT COUNT(DISTINCT patient_sk) AS total_cancer_patients
    FROM vw_patient_conditions_2025
    WHERE parent_group = 'Any cancer'
)
SELECT
    cd.cancer_type,
    cd.patient_count,
    ROUND(100.0 * cd.patient_count / t.total_cancer_patients, 2) AS pct_of_cancer_patients
FROM cancer_detail cd
CROSS JOIN total t
ORDER BY cd.patient_count DESC;

-- Alternative: built from bridge table
SELECT
    cg.group_name AS cancer_type,
    COUNT(DISTINCT b.patient_sk) AS patient_count
FROM bridge_patient_condition_year b
JOIN dim_condition_group cg ON cg.condition_group_sk = b.condition_group_sk
WHERE cg.parent_group = 'Any cancer'
  AND b.year = 2025
  AND b.has_condition = TRUE
GROUP BY cg.group_name
ORDER BY patient_count DESC;

-- Total cancer patients (any type)
SELECT COUNT(DISTINCT patient_sk) AS total_cancer_patients_2025
FROM vw_patient_conditions_2025
WHERE parent_group = 'Any cancer';

-- ----------------------------------------------------------------------------
-- Q8: Total Cost by Month (2025)
-- "Total cost of population in 2025 grouped by month"
-- ----------------------------------------------------------------------------

-- Using monthly cost rollup view
SELECT
    month,
    month_name,
    total_allowed_amt AS total_cost,
    unique_patients,
    total_er_visits,
    total_ip_admits,
    ROUND(total_allowed_amt / unique_patients, 2) AS cost_per_member
FROM vw_total_cost_by_month_2025
ORDER BY month;

-- With cumulative YTD
SELECT
    month,
    month_name,
    total_allowed_amt AS monthly_cost,
    SUM(total_allowed_amt) OVER (ORDER BY month) AS ytd_cost,
    unique_patients,
    ROUND(total_allowed_amt / unique_patients, 2) AS cost_pmpm
FROM vw_total_cost_by_month_2025
ORDER BY month;

-- Alternative: built from fact table
SELECT
    d.month,
    TO_CHAR(d.date, 'Month') AS month_name,
    SUM(m.allowed_amt) AS total_cost,
    COUNT(DISTINCT m.patient_sk) AS unique_patients
FROM fact_patient_monthly_cost m
JOIN dim_date d ON d.date_sk = m.month_start_date_sk
WHERE d.year = 2025
GROUP BY d.month, TO_CHAR(d.date, 'Month')
ORDER BY d.month;

-- Alternative: from claim lines (if monthly rollup not available)
SELECT
    d.month,
    TO_CHAR(d.date, 'Month') AS month_name,
    SUM(cl.allowed_amt) AS total_cost,
    COUNT(DISTINCT cl.patient_sk) AS unique_patients
FROM fact_claim_line cl
JOIN dim_date d ON d.date_sk = cl.from_date_sk
WHERE d.year = 2025
GROUP BY d.month, TO_CHAR(d.date, 'Month')
ORDER BY d.month;

-- ----------------------------------------------------------------------------
-- Q9: Top 100 Patients by Cost Per County (2025)
-- "Top 100 patients with highest costs for each county in 2025"
-- ----------------------------------------------------------------------------

-- Using pre-built view
SELECT
    county_fips,
    county_name,
    state,
    patient_id,
    total_cost_2025,
    rank_in_county
FROM vw_top100_patients_by_county_2025
ORDER BY county_fips, rank_in_county;

-- Summary: count of high-cost patients per county
SELECT
    county_name,
    state,
    COUNT(*) AS top100_patient_count,
    ROUND(SUM(total_cost_2025), 2) AS total_cost_top100,
    ROUND(AVG(total_cost_2025), 2) AS avg_cost_top100
FROM vw_top100_patients_by_county_2025
GROUP BY county_name, state
ORDER BY total_cost_top100 DESC;

-- Alternative: built from scratch with window function
WITH patient_costs AS (
    SELECT
        p.patient_sk,
        p.patient_id,
        p.county_fips,
        c.county_name,
        p.state,
        SUM(m.allowed_amt) AS total_cost_2025
    FROM fact_patient_monthly_cost m
    JOIN dim_date d ON d.date_sk = m.month_start_date_sk
    JOIN dim_patient p ON p.patient_sk = m.patient_sk AND p.is_current = TRUE
    LEFT JOIN county_ref c ON c.county_fips = p.county_fips
    WHERE d.year = 2025
    GROUP BY p.patient_sk, p.patient_id, p.county_fips, c.county_name, p.state
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY county_fips ORDER BY total_cost_2025 DESC) AS rank_in_county
    FROM patient_costs
)
SELECT
    county_fips,
    county_name,
    state,
    patient_id,
    total_cost_2025,
    rank_in_county
FROM ranked
WHERE rank_in_county <= 100
ORDER BY county_fips, rank_in_county;

-- Export-ready format (top 10 per county for demo)
SELECT
    county_name,
    state,
    patient_id,
    ROUND(total_cost_2025, 2) AS total_cost,
    rank_in_county
FROM vw_top100_patients_by_county_2025
WHERE rank_in_county <= 10
ORDER BY county_name, rank_in_county;

-- ============================================================================
-- BONUS QUERIES (common follow-ups)
-- ============================================================================

-- Chronic condition prevalence (top 10)
SELECT
    condition_name,
    COUNT(*) AS patient_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT patient_sk) FROM vw_patients_2025), 2) AS prevalence_pct
FROM vw_patient_conditions_2025
GROUP BY condition_name
ORDER BY patient_count DESC
LIMIT 10;

-- Cost distribution (percentiles)
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_cost_2025) AS p25_cost,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_cost_2025) AS median_cost,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_cost_2025) AS p75_cost,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_cost_2025) AS p90_cost,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_cost_2025) AS p95_cost,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_cost_2025) AS p99_cost
FROM vw_patient_annual_costs_2025;

-- ER visits by time of day (if timestamp available)
-- Placeholder - requires encounter timestamp data
/*
SELECT
    EXTRACT(HOUR FROM start_timestamp) AS hour_of_day,
    COUNT(*) AS er_visits
FROM fact_encounter
WHERE encounter_type = 'ER'
GROUP BY EXTRACT(HOUR FROM start_timestamp)
ORDER BY hour_of_day;
*/

-- Readmission rate (30-day)
-- Placeholder - requires encounter sequencing logic
/*
WITH admissions AS (
    SELECT
        patient_sk,
        start_date_sk,
        LEAD(start_date_sk) OVER (PARTITION BY patient_sk ORDER BY start_date_sk) AS next_admit_date_sk
    FROM fact_encounter
    WHERE encounter_type = 'IP'
)
SELECT
    COUNT(*) AS total_admissions,
    COUNT(*) FILTER (WHERE (next_admit_date_sk - start_date_sk) <= 30) AS readmissions_30day,
    ROUND(100.0 * COUNT(*) FILTER (WHERE (next_admit_date_sk - start_date_sk) <= 30) / COUNT(*), 2) AS readmission_rate
FROM admissions;
*/

-- ============================================================================
-- PERFORMANCE NOTES
-- ============================================================================

/*
For production use:
1. Always filter by year on fact tables (use indexes)
2. Use semantic views (vw_*) for cleaner, faster queries
3. Materialize expensive aggregates (fact_patient_monthly_cost, bridge_patient_condition_year)
4. For large exports (>100k rows), use COPY or bulk export tools
5. Apply row-level security via patient_attribution table for multi-tenant environments
6. Monitor query performance with EXPLAIN ANALYZE
7. Consider partitioning fact tables by year for very large datasets (100M+ rows)
*/
