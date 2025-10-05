-- ============================================================================
-- Quick Test Queries - Verify Sample Data & All 9 Use Cases
-- Run this after loading schema + sample data to validate everything works
-- ============================================================================

\echo '======================================================================'
\echo 'TEST 1: Population by Gender & Age Bucket'
\echo '======================================================================'

SELECT
    gender,
    age_bucket_10yr AS age_bucket,
    COUNT(*) AS patient_count
FROM vw_patients_2025
GROUP BY gender, age_bucket_10yr
ORDER BY gender, age_bucket_10yr;

\echo ''
\echo '======================================================================'
\echo 'TEST 2: Osteoporosis Screening Rate (Women 65-75, 2025)'
\echo '======================================================================'

SELECT
    COUNT(*) AS denominator,
    COUNT(*) FILTER (WHERE is_screened = TRUE) AS numerator,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_screened = TRUE) / NULLIF(COUNT(*), 0), 2) AS pct_screened
FROM vw_osteoporosis_screening_2025;

\echo ''
\echo '======================================================================'
\echo 'TEST 3: Type 2 Diabetes Prevalence'
\echo '======================================================================'

SELECT COUNT(*) AS patients_with_t2dm
FROM vw_patient_conditions_2025
WHERE condition_name = 'Type 2 diabetes';

\echo ''
\echo '======================================================================'
\echo 'TEST 4: ER Frequent Flyers (Top 10)'
\echo '======================================================================'

SELECT
    patient_id,
    er_visits_2025,
    first_er_visit,
    last_er_visit
FROM vw_patient_er_summary_2025
ORDER BY er_visits_2025 DESC
LIMIT 10;

\echo ''
\echo '======================================================================'
\echo 'TEST 5: Patient 528 - CPT Event Counts'
\echo '======================================================================'

SELECT
    patient_id,
    cpt_code,
    cpt_description,
    event_count,
    total_cost
FROM vw_patient_procedure_events_2025
WHERE patient_id = 'PAT000528'
  AND cpt_code IN ('95992', '97112', '95117', '71046', '97110')
ORDER BY cpt_code;

-- Summary
SELECT
    patient_id,
    SUM(event_count) AS total_events,
    SUM(total_cost) AS total_cost
FROM vw_patient_procedure_events_2025
WHERE patient_id = 'PAT000528'
  AND cpt_code IN ('95992', '97112', '95117', '71046', '97110');

\echo ''
\echo '======================================================================'
\echo 'TEST 6: Most Expensive Patients & Average Cost (Top 10)'
\echo '======================================================================'

SELECT
    patient_id,
    total_cost_2025,
    total_er_visits_2025,
    total_ip_admits_2025
FROM vw_patient_annual_costs_2025
ORDER BY total_cost_2025 DESC
LIMIT 10;

-- Average cost
SELECT
    COUNT(*) AS total_patients,
    ROUND(AVG(total_cost_2025), 2) AS avg_cost_per_patient,
    ROUND(SUM(total_cost_2025), 2) AS total_population_cost
FROM vw_patient_annual_costs_2025;

\echo ''
\echo '======================================================================'
\echo 'TEST 7: Cancer Prevalence by Type'
\echo '======================================================================'

SELECT
    cancer_type,
    patient_count,
    ROUND(100.0 * patient_count / SUM(patient_count) OVER (), 2) AS pct_of_cancer_patients
FROM vw_cancer_prevalence_2025
ORDER BY patient_count DESC;

\echo ''
\echo '======================================================================'
\echo 'TEST 8: Total Cost by Month (2025)'
\echo '======================================================================'

SELECT
    month,
    month_name,
    total_allowed_amt AS total_cost,
    unique_patients,
    ROUND(total_allowed_amt / NULLIF(unique_patients, 0), 2) AS cost_per_member
FROM vw_total_cost_by_month_2025
ORDER BY month;

\echo ''
\echo '======================================================================'
\echo 'TEST 9: Top 10 Patients Per County (Sample: 3 counties)'
\echo '======================================================================'

SELECT
    county_name,
    state,
    patient_id,
    ROUND(total_cost_2025, 2) AS total_cost,
    rank_in_county
FROM vw_top100_patients_by_county_2025
WHERE rank_in_county <= 10
  AND county_name IN ('Los Angeles', 'Cook', 'San Diego')
ORDER BY county_name, rank_in_county;

\echo ''
\echo '======================================================================'
\echo 'BONUS: Data Summary Statistics'
\echo '======================================================================'

SELECT
    'Patients' AS entity,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE sex_at_birth = 'F') AS female,
    COUNT(*) FILTER (WHERE sex_at_birth = 'M') AS male,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))), 1) AS avg_age
FROM dim_patient
WHERE is_current = TRUE

UNION ALL

SELECT
    'Claim Lines' AS entity,
    COUNT(*) AS total_count,
    COUNT(DISTINCT patient_sk) AS unique_patients,
    NULL,
    ROUND(AVG(allowed_amt), 2) AS avg_allowed
FROM fact_claim_line

UNION ALL

SELECT
    'ER Visits' AS entity,
    COUNT(*) AS total_count,
    COUNT(DISTINCT patient_sk) AS unique_patients,
    NULL,
    NULL
FROM fact_encounter
WHERE encounter_type = 'ER'

UNION ALL

SELECT
    'IP Admits' AS entity,
    COUNT(*) AS total_count,
    COUNT(DISTINCT patient_sk) AS unique_patients,
    NULL,
    NULL
FROM fact_encounter
WHERE encounter_type = 'IP'

UNION ALL

SELECT
    'Chronic Conditions' AS entity,
    COUNT(*) AS total_count,
    COUNT(DISTINCT patient_sk) AS unique_patients,
    NULL,
    NULL
FROM bridge_patient_condition_year
WHERE has_condition = TRUE AND year = 2025;

\echo ''
\echo '======================================================================'
\echo 'Top 10 Conditions by Prevalence'
\echo '======================================================================'

SELECT
    condition_name,
    COUNT(*) AS patient_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT patient_sk) FROM vw_patients_2025), 2) AS prevalence_pct
FROM vw_patient_conditions_2025
GROUP BY condition_name
ORDER BY patient_count DESC
LIMIT 10;

\echo ''
\echo '======================================================================'
\echo 'Cost Distribution (Percentiles)'
\echo '======================================================================'

SELECT
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_cost_2025), 2) AS p25_cost,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_cost_2025), 2) AS median_cost,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_cost_2025), 2) AS p75_cost,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_cost_2025), 2) AS p90_cost,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_cost_2025), 2) AS p95_cost,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_cost_2025), 2) AS p99_cost
FROM vw_patient_annual_costs_2025;

\echo ''
\echo '======================================================================'
\echo '✅ ALL TESTS COMPLETE!'
\echo '======================================================================'
\echo 'If all queries returned results, your schema is working correctly.'
\echo 'You can now:'
\echo '  1. Load production data using the same patterns'
\echo '  2. Build your NL→SQL agent using the semantic dictionary'
\echo '  3. Query using the semantic views (vw_*)'
\echo '======================================================================'
