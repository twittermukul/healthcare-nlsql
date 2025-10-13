-- ============================================================================
-- Populate patient_attribution table
-- ============================================================================
-- This table tracks patient-organization-payer relationships over time
-- Each patient is attributed to an organization and payer plan for a period

\c healthcare_analytics;

-- Clear existing data (if any)
TRUNCATE TABLE patient_attribution;

-- Insert patient attributions
-- Strategy: Assign each patient to a payer plan with attribution period
INSERT INTO patient_attribution (
    patient_sk,
    org_id,
    payer_plan_sk,
    attribution_start_date,
    attribution_end_date,
    is_current
)
SELECT
    p.patient_sk,
    -- Use a simple org_id pattern (ORG-001, ORG-002, etc.)
    'ORG-' || LPAD((p.patient_sk % 50 + 1)::text, 3, '0') as org_id,
    -- Assign payer plan based on patient demographics
    -- Distribute patients across 5 major payers
    CASE (p.patient_sk % 5)
        WHEN 0 THEN (SELECT payer_plan_sk FROM dim_payer_plan WHERE payer_name = 'Blue Cross Blue Shield' LIMIT 1)
        WHEN 1 THEN (SELECT payer_plan_sk FROM dim_payer_plan WHERE payer_name = 'Aetna' LIMIT 1)
        WHEN 2 THEN (SELECT payer_plan_sk FROM dim_payer_plan WHERE payer_name = 'United Healthcare' LIMIT 1)
        WHEN 3 THEN (SELECT payer_plan_sk FROM dim_payer_plan WHERE payer_name = 'Cigna' LIMIT 1)
        ELSE (SELECT payer_plan_sk FROM dim_payer_plan WHERE payer_name = 'Humana' LIMIT 1)
    END as payer_plan_sk,
    -- Attribution starts January 1, 2024
    '2024-01-01'::date as attribution_start_date,
    -- Most attributions are current (no end date), some expired
    CASE
        WHEN p.patient_sk % 20 = 0 THEN '2024-06-30'::date  -- 5% expired mid-year
        WHEN p.patient_sk % 25 = 0 THEN '2024-12-31'::date  -- 4% expire end of year
        ELSE NULL  -- 91% are current
    END as attribution_end_date,
    -- Mark as current if no end date or end date is in future
    CASE
        WHEN p.patient_sk % 20 = 0 THEN false  -- Expired
        WHEN p.patient_sk % 25 = 0 THEN false  -- Will expire
        ELSE true
    END as is_current
FROM
    dim_patient p
WHERE
    EXISTS (SELECT 1 FROM dim_payer_plan)  -- Only insert if payer plans exist
;

-- Add some historical attributions (patients who changed payers/organizations)
-- About 10% of patients have a prior attribution
INSERT INTO patient_attribution (
    patient_sk,
    org_id,
    payer_plan_sk,
    attribution_start_date,
    attribution_end_date,
    is_current
)
SELECT
    p.patient_sk,
    'ORG-' || LPAD(((p.patient_sk % 50 + 25) % 50 + 1)::text, 3, '0') as org_id,  -- Different org than current
    -- Assign a different payer than their current one
    CASE (p.patient_sk % 3)
        WHEN 0 THEN (SELECT payer_plan_sk FROM dim_payer_plan WHERE payer_name = 'Blue Cross Blue Shield' LIMIT 1)
        WHEN 1 THEN (SELECT payer_plan_sk FROM dim_payer_plan WHERE payer_name = 'Aetna' LIMIT 1)
        ELSE (SELECT payer_plan_sk FROM dim_payer_plan WHERE payer_name = 'Humana' LIMIT 1)
    END as payer_plan_sk,
    '2023-01-01'::date as attribution_start_date,
    '2023-12-31'::date as attribution_end_date,
    false as is_current
FROM
    dim_patient p
WHERE
    p.patient_sk % 10 = 0  -- 10% of patients have historical attribution
    AND EXISTS (SELECT 1 FROM dim_payer_plan)
;

-- Display summary statistics
SELECT
    'Total attributions' as metric,
    COUNT(*) as count
FROM patient_attribution

UNION ALL

SELECT
    'Current attributions' as metric,
    COUNT(*) as count
FROM patient_attribution
WHERE is_current = true

UNION ALL

SELECT
    'Historical attributions' as metric,
    COUNT(*) as count
FROM patient_attribution
WHERE is_current = false

UNION ALL

SELECT
    'Unique patients' as metric,
    COUNT(DISTINCT patient_sk) as count
FROM patient_attribution

UNION ALL

SELECT
    'Unique organizations' as metric,
    COUNT(DISTINCT org_id) as count
FROM patient_attribution

UNION ALL

SELECT
    'Unique payer plans' as metric,
    COUNT(DISTINCT payer_plan_sk) as count
FROM patient_attribution
WHERE payer_plan_sk IS NOT NULL
;

-- Show sample of attributions by payer
SELECT
    pp.payer_name,
    COUNT(*) as patient_count,
    COUNT(CASE WHEN pa.is_current THEN 1 END) as current_count,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(p.birth_date)))) as avg_age
FROM
    patient_attribution pa
    JOIN dim_payer_plan pp ON pa.payer_plan_sk = pp.payer_plan_sk
    JOIN dim_patient p ON pa.patient_sk = p.patient_sk
WHERE
    pa.is_current = true
GROUP BY
    pp.payer_name
ORDER BY
    patient_count DESC
;

ANALYZE patient_attribution;

\echo '✅ Patient attribution table populated successfully'
