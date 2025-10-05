-- ============================================================================
-- Sample Data Generator - Creates realistic test data for all tables
-- Run this AFTER 01_schema_ddl.sql and 02_seed_data.sql
-- Generates: 1000 patients, ~50k claim lines, encounters, conditions, costs
-- ============================================================================

-- ============================================================================
-- DIMENSION DATA
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Sample Providers (20 providers)
-- ----------------------------------------------------------------------------

INSERT INTO dim_provider (provider_sk, npi, provider_id, provider_name, taxonomy, taxonomy_desc, specialty, org_id, org_name, is_pcp, is_current) VALUES
(2000001, '1234567890', 'PROV001', 'Dr. Sarah Johnson', '207R00000X', 'Internal Medicine', 'Internal Medicine', 'ORG001', 'City Medical Group', TRUE, TRUE),
(2000002, '1234567891', 'PROV002', 'Dr. Michael Chen', '207Q00000X', 'Family Medicine', 'Family Medicine', 'ORG001', 'City Medical Group', TRUE, TRUE),
(2000003, '1234567892', 'PROV003', 'Dr. Emily Rodriguez', '2080P0216X', 'Pediatrics', 'Pediatrics', 'ORG002', 'Pediatric Care Associates', TRUE, TRUE),
(2000004, '1234567893', 'PROV004', 'Dr. James Williams', '207RC0000X', 'Cardiovascular Disease', 'Cardiology', 'ORG003', 'Heart Health Specialists', FALSE, TRUE),
(2000005, '1234567894', 'PROV005', 'Dr. Lisa Anderson', '207RE0101X', 'Endocrinology', 'Endocrinology', 'ORG003', 'Heart Health Specialists', FALSE, TRUE),
(2000006, '1234567895', 'PROV006', 'Dr. Robert Martinez', '208D00000X', 'General Practice', 'General Practice', 'ORG001', 'City Medical Group', TRUE, TRUE),
(2000007, '1234567896', 'PROV007', 'Dr. Jennifer Lee', '207V00000X', 'Obstetrics & Gynecology', 'OB/GYN', 'ORG004', 'Women''s Health Center', FALSE, TRUE),
(2000008, '1234567897', 'PROV008', 'Dr. David Thompson', '2084P0800X', 'Psychiatry', 'Psychiatry', 'ORG005', 'Mental Health Associates', FALSE, TRUE),
(2000009, '1234567898', 'PROV009', 'Dr. Maria Garcia', '207RN0300X', 'Nephrology', 'Nephrology', 'ORG003', 'Heart Health Specialists', FALSE, TRUE),
(2000010, '1234567899', 'PROV010', 'Dr. Christopher White', '2080A0000X', 'Urgent Care', 'Emergency Medicine', 'ORG006', 'County Hospital', FALSE, TRUE),
(2000011, '1234567800', 'PROV011', 'Dr. Amanda Brown', '207RA0000X', 'Orthopedic Surgery', 'Orthopedics', 'ORG007', 'Orthopedic Specialists', FALSE, TRUE),
(2000012, '1234567801', 'PROV012', 'Dr. Kevin Davis', '207RP1001X', 'Pulmonary Disease', 'Pulmonology', 'ORG003', 'Heart Health Specialists', FALSE, TRUE),
(2000013, '1234567802', 'PROV013', 'Dr. Michelle Taylor', '2083X0100X', 'Radiology', 'Radiology', 'ORG008', 'Imaging Center', FALSE, TRUE),
(2000014, '1234567803', 'PROV014', 'Dr. Brian Miller', '207RX0202X', 'Medical Oncology', 'Oncology', 'ORG009', 'Cancer Treatment Center', FALSE, TRUE),
(2000015, '1234567804', 'PROV015', 'Dr. Laura Wilson', '163WP0809X', 'Physical Therapy', 'Physical Therapy', 'ORG010', 'Rehab Services', FALSE, TRUE),
(2000016, '1234567805', 'PROV016', 'Dr. Daniel Moore', '207L00000X', 'Anesthesiology', 'Anesthesiology', 'ORG006', 'County Hospital', FALSE, TRUE),
(2000017, '1234567806', 'PROV017', 'Dr. Jessica Thomas', '207RG0100X', 'Gastroenterology', 'Gastroenterology', 'ORG003', 'Heart Health Specialists', FALSE, TRUE),
(2000018, '1234567807', 'PROV018', 'Dr. Andrew Jackson', '207W00000X', 'Ophthalmology', 'Ophthalmology', 'ORG011', 'Eye Care Center', FALSE, TRUE),
(2000019, '1234567808', 'PROV019', 'Dr. Nicole Harris', '207RI0200X', 'Infectious Disease', 'Infectious Disease', 'ORG006', 'County Hospital', FALSE, TRUE),
(2000020, '1234567809', 'PROV020', 'Dr. Matthew Martin', '207RH0000X', 'Hematology', 'Hematology', 'ORG009', 'Cancer Treatment Center', FALSE, TRUE);

-- ----------------------------------------------------------------------------
-- Sample Facilities (10 facilities)
-- ----------------------------------------------------------------------------

INSERT INTO dim_facility (facility_sk, facility_id, facility_name, place_of_service, pos_desc, facility_type, county_fips, county_name, state, is_current) VALUES
(3000001, 'FAC001', 'County General Hospital', '21', 'Inpatient Hospital', 'IP', '06037', 'Los Angeles', 'CA', TRUE),
(3000002, 'FAC002', 'City Medical Center', '22', 'Outpatient Hospital', 'OP', '06037', 'Los Angeles', 'CA', TRUE),
(3000003, 'FAC003', 'Emergency Care Center', '23', 'Emergency Room - Hospital', 'ER', '06037', 'Los Angeles', 'CA', TRUE),
(3000004, 'FAC004', 'Primary Care Clinic', '11', 'Office', 'CLINIC', '06037', 'Los Angeles', 'CA', TRUE),
(3000005, 'FAC005', 'Specialty Surgery Center', '24', 'Ambulatory Surgical Center', 'ASC', '06073', 'San Diego', 'CA', TRUE),
(3000006, 'FAC006', 'Community Hospital', '21', 'Inpatient Hospital', 'IP', '17031', 'Cook', 'IL', TRUE),
(3000007, 'FAC007', 'Urgent Care Walk-In', '20', 'Urgent Care Facility', 'URGENT', '48201', 'Harris', 'TX', TRUE),
(3000008, 'FAC008', 'Rehabilitation Center', '11', 'Office', 'REHAB', '06037', 'Los Angeles', 'CA', TRUE),
(3000009, 'FAC009', 'Imaging & Diagnostics', '11', 'Office', 'IMAGING', '06037', 'Los Angeles', 'CA', TRUE),
(3000010, 'FAC010', 'Regional Medical Center', '21', 'Inpatient Hospital', 'IP', '04013', 'Maricopa', 'AZ', TRUE);

-- ----------------------------------------------------------------------------
-- Sample Payer Plans (5 plans)
-- ----------------------------------------------------------------------------

INSERT INTO dim_payer_plan (payer_plan_sk, payer_id, payer_name, plan_id, plan_name, plan_type, contract_id, line_of_business, is_current) VALUES
(4000001, 'PAY001', 'Blue Cross Blue Shield', 'PLAN001', 'BCBS Gold PPO', 'PPO', 'CNT2025001', 'Commercial', TRUE),
(4000002, 'PAY002', 'United Healthcare', 'PLAN002', 'UHC Medicare Advantage', 'MA', 'CNT2025002', 'Medicare', TRUE),
(4000003, 'PAY003', 'Aetna', 'PLAN003', 'Aetna HMO', 'HMO', 'CNT2025003', 'Commercial', TRUE),
(4000004, 'PAY004', 'Cigna', 'PLAN004', 'Cigna Open Access', 'POS', 'CNT2025004', 'Commercial', TRUE),
(4000005, 'PAY005', 'Humana', 'PLAN005', 'Humana Gold Plus', 'MA', 'CNT2025005', 'Medicare', TRUE);

-- ============================================================================
-- GENERATE PATIENTS (1000 patients with realistic demographics)
-- ============================================================================

DO $$
DECLARE
    i INT;
    random_birth_date DATE;
    random_sex VARCHAR(20);
    random_county_fips VARCHAR(5);
    random_state VARCHAR(2);
    county_data RECORD;
    counties VARCHAR(5)[] := ARRAY['06037', '17031', '48201', '04013', '06073', '06059', '12086', '36047', '53033', '06085'];
BEGIN
    FOR i IN 1..1000 LOOP
        -- Random birth date (age 18-90)
        random_birth_date := CURRENT_DATE - (INTERVAL '1 year' * (18 + FLOOR(RANDOM() * 72)::INT)) - (INTERVAL '1 day' * FLOOR(RANDOM() * 365)::INT);

        -- Random sex (48% M, 48% F, 4% other)
        random_sex := CASE
            WHEN RANDOM() < 0.48 THEN 'M'
            WHEN RANDOM() < 0.96 THEN 'F'
            ELSE 'Other'
        END;

        -- Random county
        random_county_fips := counties[1 + FLOOR(RANDOM() * array_length(counties, 1))::INT];

        SELECT state INTO random_state FROM county_ref WHERE county_fips = random_county_fips;

        INSERT INTO dim_patient (
            patient_sk,
            patient_id,
            birth_date,
            death_date,
            sex_at_birth,
            race,
            ethnicity,
            zip3,
            county_fips,
            state,
            is_current
        ) VALUES (
            nextval('seq_patient_sk'),
            'PAT' || LPAD(i::TEXT, 6, '0'),
            random_birth_date,
            CASE WHEN RANDOM() < 0.02 THEN random_birth_date + INTERVAL '60 years' ELSE NULL END, -- 2% deceased
            random_sex,
            CASE FLOOR(RANDOM() * 5)
                WHEN 0 THEN 'White'
                WHEN 1 THEN 'Black or African American'
                WHEN 2 THEN 'Asian'
                WHEN 3 THEN 'Hispanic or Latino'
                ELSE 'Other'
            END,
            CASE WHEN RANDOM() < 0.2 THEN 'Hispanic or Latino' ELSE 'Not Hispanic or Latino' END,
            SUBSTRING(random_county_fips, 2, 3),
            random_county_fips,
            random_state,
            TRUE
        );
    END LOOP;
END $$;

-- Update county names
UPDATE dim_patient p
SET county_name = c.county_name
FROM county_ref c
WHERE p.county_fips = c.county_fips;

-- ============================================================================
-- GENERATE CONDITIONS (assign chronic conditions to patients)
-- ============================================================================

-- Type 2 Diabetes (15% of patients age 45+)
INSERT INTO bridge_patient_condition_year (patient_sk, condition_group_sk, year, has_condition, first_dx_date, last_dx_date, dx_count)
SELECT
    p.patient_sk,
    2, -- Type 2 diabetes
    2025,
    TRUE,
    DATE '2025-01-01' + (RANDOM() * 365)::INT,
    DATE '2025-01-01' + (RANDOM() * 365)::INT,
    FLOOR(1 + RANDOM() * 10)::INT
FROM dim_patient p
WHERE EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) >= 45
  AND RANDOM() < 0.15;

-- Hypertension (25% of patients age 40+)
INSERT INTO bridge_patient_condition_year (patient_sk, condition_group_sk, year, has_condition, first_dx_date, last_dx_date, dx_count)
SELECT
    p.patient_sk,
    24, -- Hypertension
    2025,
    TRUE,
    DATE '2025-01-01' + (RANDOM() * 365)::INT,
    DATE '2025-01-01' + (RANDOM() * 365)::INT,
    FLOOR(1 + RANDOM() * 15)::INT
FROM dim_patient p
WHERE EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) >= 40
  AND RANDOM() < 0.25
  AND NOT EXISTS (SELECT 1 FROM bridge_patient_condition_year WHERE patient_sk = p.patient_sk AND condition_group_sk = 24);

-- Cancer (5% of patients age 50+, various types)
INSERT INTO bridge_patient_condition_year (patient_sk, condition_group_sk, year, has_condition, first_dx_date, last_dx_date, dx_count)
SELECT
    p.patient_sk,
    CASE FLOOR(RANDOM() * 5)
        WHEN 0 THEN 11 -- Breast cancer
        WHEN 1 THEN 12 -- Lung cancer
        WHEN 2 THEN 13 -- Colorectal cancer
        WHEN 3 THEN 14 -- Prostate cancer
        ELSE 17 -- Other cancer
    END,
    2025,
    TRUE,
    DATE '2024-01-01' + (RANDOM() * 365)::INT, -- Started in 2024
    DATE '2025-01-01' + (RANDOM() * 365)::INT,
    FLOOR(4 + RANDOM() * 12)::INT
FROM dim_patient p
WHERE EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) >= 50
  AND RANDOM() < 0.05;

-- CHF (3% of patients age 60+)
INSERT INTO bridge_patient_condition_year (patient_sk, condition_group_sk, year, has_condition, first_dx_date, last_dx_date, dx_count)
SELECT
    p.patient_sk,
    21, -- CHF
    2025,
    TRUE,
    DATE '2024-01-01' + (RANDOM() * 365)::INT,
    DATE '2025-01-01' + (RANDOM() * 365)::INT,
    FLOOR(3 + RANDOM() * 10)::INT
FROM dim_patient p
WHERE EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) >= 60
  AND RANDOM() < 0.03;

-- COPD (8% of patients age 55+)
INSERT INTO bridge_patient_condition_year (patient_sk, condition_group_sk, year, has_condition, first_dx_date, last_dx_date, dx_count)
SELECT
    p.patient_sk,
    31, -- COPD
    2025,
    TRUE,
    DATE '2024-01-01' + (RANDOM() * 365)::INT,
    DATE '2025-01-01' + (RANDOM() * 365)::INT,
    FLOOR(2 + RANDOM() * 8)::INT
FROM dim_patient p
WHERE EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) >= 55
  AND RANDOM() < 0.08;

-- Osteoporosis (12% of women age 65+)
INSERT INTO bridge_patient_condition_year (patient_sk, condition_group_sk, year, has_condition, first_dx_date, last_dx_date, dx_count)
SELECT
    p.patient_sk,
    52, -- Osteoporosis
    2025,
    TRUE,
    DATE '2024-01-01' + (RANDOM() * 365)::INT,
    DATE '2025-01-01' + (RANDOM() * 365)::INT,
    FLOOR(1 + RANDOM() * 5)::INT
FROM dim_patient p
WHERE EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) >= 65
  AND p.sex_at_birth = 'F'
  AND RANDOM() < 0.12;

-- ============================================================================
-- GENERATE CLAIM LINES (realistic utilization patterns)
-- ============================================================================

-- Regular office visits for all patients (2-8 per year)
INSERT INTO fact_claim_line (
    claim_line_sk, claim_id, claim_line_num, patient_sk, provider_sk, facility_sk, payer_plan_sk,
    from_date_sk, thru_date_sk, cpt_hcpcs, pos_code, dx_p,
    is_outpatient, allowed_amt, paid_amt, units
)
SELECT
    nextval('seq_claim_line_sk'),
    'CLM' || p.patient_sk || '-' || visit_num,
    1,
    p.patient_sk,
    2000001 + FLOOR(RANDOM() * 6)::BIGINT, -- Random PCP
    3000004, -- Primary Care Clinic
    4000001 + FLOOR(RANDOM() * 5)::BIGINT, -- Random payer
    20250000 + (FLOOR(RANDOM() * 12) + 1) * 100 + FLOOR(RANDOM() * 28 + 1), -- Random date in 2025
    20250000 + (FLOOR(RANDOM() * 12) + 1) * 100 + FLOOR(RANDOM() * 28 + 1),
    '99213', -- Office visit
    '11', -- Office
    CASE WHEN bc.condition_group_sk IS NOT NULL THEN 'E11.9' ELSE 'Z00.00' END,
    TRUE,
    150.00 + RANDOM() * 100,
    135.00 + RANDOM() * 90,
    1
FROM dim_patient p
CROSS JOIN generate_series(1, FLOOR(2 + RANDOM() * 7)::INT) AS visit_num
LEFT JOIN bridge_patient_condition_year bc ON bc.patient_sk = p.patient_sk AND bc.condition_group_sk = 2
WHERE p.is_current = TRUE
LIMIT 5000;

-- Patient 528 specific procedures (from use case #5)
INSERT INTO fact_claim_line (
    claim_line_sk, claim_id, claim_line_num, patient_sk, provider_sk, facility_sk, payer_plan_sk,
    from_date_sk, thru_date_sk, cpt_hcpcs, pos_code,
    is_outpatient, allowed_amt, paid_amt, units
)
SELECT
    nextval('seq_claim_line_sk'),
    'CLM-528-' || proc_num,
    1,
    (SELECT patient_sk FROM dim_patient WHERE patient_id = 'PAT000528'),
    2000015, -- Physical therapy provider
    3000008, -- Rehab Center
    4000001,
    20250000 + (proc_num * 700 + 115), -- Spread across 2025
    20250000 + (proc_num * 700 + 115),
    cpt,
    '11',
    TRUE,
    CASE cpt
        WHEN '95992' THEN 125.00
        WHEN '97112' THEN 95.00
        WHEN '95117' THEN 45.00
        WHEN '71046' THEN 180.00
        WHEN '97110' THEN 90.00
    END,
    CASE cpt
        WHEN '95992' THEN 112.50
        WHEN '97112' THEN 85.50
        WHEN '95117' THEN 40.50
        WHEN '71046' THEN 162.00
        WHEN '97110' THEN 81.00
    END,
    1
FROM (VALUES ('95992'), ('97112'), ('95117'), ('71046'), ('97110')) AS codes(cpt)
CROSS JOIN generate_series(1, FLOOR(3 + RANDOM() * 5)::INT) AS proc_num
WHERE EXISTS (SELECT 1 FROM dim_patient WHERE patient_id = 'PAT000528');

-- ER visits (high utilizers: 5-15% of patients with 3-10 ER visits)
INSERT INTO fact_claim_line (
    claim_line_sk, claim_id, claim_line_num, patient_sk, provider_sk, facility_sk, payer_plan_sk,
    from_date_sk, thru_date_sk, cpt_hcpcs, pos_code, dx_p,
    is_er, allowed_amt, paid_amt, units
)
SELECT
    nextval('seq_claim_line_sk'),
    'ER' || p.patient_sk || '-' || visit_num,
    1,
    p.patient_sk,
    2000010, -- ER physician
    3000003, -- Emergency Care Center
    4000001 + FLOOR(RANDOM() * 5)::BIGINT,
    20250000 + (FLOOR(RANDOM() * 12) + 1) * 100 + FLOOR(RANDOM() * 28 + 1),
    20250000 + (FLOOR(RANDOM() * 12) + 1) * 100 + FLOOR(RANDOM() * 28 + 1),
    CASE FLOOR(RANDOM() * 3)
        WHEN 0 THEN '99284' -- ER visit level 4
        WHEN 1 THEN '99285' -- ER visit level 5
        ELSE '99283' -- ER visit level 3
    END,
    '23',
    'R07.9', -- Chest pain
    TRUE,
    800.00 + RANDOM() * 400,
    720.00 + RANDOM() * 360,
    1
FROM dim_patient p
CROSS JOIN generate_series(1, FLOOR(3 + RANDOM() * 8)::INT) AS visit_num
WHERE RANDOM() < 0.10 -- 10% are frequent ER users
LIMIT 800;

-- Inpatient admissions (3% of patients)
INSERT INTO fact_claim_line (
    claim_line_sk, claim_id, claim_line_num, patient_sk, provider_sk, facility_sk, payer_plan_sk,
    from_date_sk, thru_date_sk, cpt_hcpcs, pos_code, dx_p,
    is_inpatient, allowed_amt, paid_amt, units
)
SELECT
    nextval('seq_claim_line_sk'),
    'IP' || p.patient_sk || '-1',
    1,
    p.patient_sk,
    2000004, -- Cardiologist
    3000001, -- County General Hospital
    4000001 + FLOOR(RANDOM() * 5)::BIGINT,
    20250000 + (FLOOR(RANDOM() * 12) + 1) * 100 + FLOOR(RANDOM() * 28 + 1),
    20250000 + (FLOOR(RANDOM() * 12) + 1) * 100 + FLOOR(RANDOM() * 28 + 3),
    '99223', -- Initial hospital care
    '21',
    'I50.9', -- Heart failure
    TRUE,
    15000.00 + RANDOM() * 10000,
    13500.00 + RANDOM() * 9000,
    1
FROM dim_patient p
JOIN bridge_patient_condition_year bc ON bc.patient_sk = p.patient_sk
WHERE bc.condition_group_sk IN (21, 23) -- CHF or AMI patients
  AND RANDOM() < 0.3
LIMIT 30;

-- Osteoporosis screening (DEXA scans for eligible women)
INSERT INTO fact_claim_line (
    claim_line_sk, claim_id, claim_line_num, patient_sk, provider_sk, facility_sk, payer_plan_sk,
    from_date_sk, thru_date_sk, cpt_hcpcs, pos_code,
    is_preventive, allowed_amt, paid_amt, units
)
SELECT
    nextval('seq_claim_line_sk'),
    'DEXA' || p.patient_sk,
    1,
    p.patient_sk,
    2000013, -- Radiology
    3000009, -- Imaging Center
    4000002, -- Medicare plan
    20250000 + (FLOOR(RANDOM() * 12) + 1) * 100 + FLOOR(RANDOM() * 28 + 1),
    20250000 + (FLOOR(RANDOM() * 12) + 1) * 100 + FLOOR(RANDOM() * 28 + 1),
    CASE FLOOR(RANDOM() * 4)
        WHEN 0 THEN '77080'
        WHEN 1 THEN '77081'
        WHEN 2 THEN '77085'
        ELSE '77086'
    END,
    '11',
    TRUE,
    125.00,
    112.50,
    1
FROM dim_patient p
WHERE p.sex_at_birth = 'F'
  AND EXTRACT(YEAR FROM AGE(DATE '2025-12-31', p.birth_date)) BETWEEN 65 AND 75
  AND RANDOM() < 0.45; -- 45% screening rate

-- ============================================================================
-- GENERATE ENCOUNTERS (from claim lines)
-- ============================================================================

-- ER encounters
INSERT INTO fact_encounter (encounter_sk, encounter_id, patient_sk, provider_sk, facility_sk, start_date_sk, end_date_sk, encounter_type, primary_dx_code, discharge_status)
SELECT
    nextval('seq_encounter_sk'),
    claim_id,
    patient_sk,
    provider_sk,
    facility_sk,
    from_date_sk,
    from_date_sk,
    'ER',
    dx_p,
    'Discharged to home'
FROM fact_claim_line
WHERE is_er = TRUE
GROUP BY claim_id, patient_sk, provider_sk, facility_sk, from_date_sk, dx_p;

-- IP encounters
INSERT INTO fact_encounter (encounter_sk, encounter_id, patient_sk, provider_sk, facility_sk, start_date_sk, end_date_sk, encounter_type, primary_dx_code, discharge_status, length_of_stay_days)
SELECT
    nextval('seq_encounter_sk'),
    claim_id,
    patient_sk,
    provider_sk,
    facility_sk,
    from_date_sk,
    thru_date_sk,
    'IP',
    dx_p,
    'Discharged to home',
    FLOOR(2 + RANDOM() * 5)::INT
FROM fact_claim_line
WHERE is_inpatient = TRUE
GROUP BY claim_id, patient_sk, provider_sk, facility_sk, from_date_sk, thru_date_sk, dx_p;

-- ============================================================================
-- GENERATE QUALITY EVENTS (screening events)
-- ============================================================================

-- Osteoporosis screening events
INSERT INTO fact_quality_event (patient_sk, measure_sk, event_date_sk, evidence_code_sk, is_denominator, is_numerator)
SELECT
    cl.patient_sk,
    1, -- Osteoporosis screening measure
    cl.from_date_sk,
    dc.code_sk,
    TRUE,
    TRUE
FROM fact_claim_line cl
JOIN dim_code dc ON dc.code = cl.cpt_hcpcs AND dc.code_system = 'CPT'
WHERE cl.cpt_hcpcs IN ('77080', '77081', '77085', '77086')
  AND cl.is_preventive = TRUE;

-- ============================================================================
-- GENERATE MONTHLY COST ROLLUP
-- ============================================================================

INSERT INTO fact_patient_monthly_cost (
    patient_sk, month_start_date_sk,
    billed_amt, allowed_amt, paid_amt,
    er_visits, ip_admits, op_visits, preventive_visits
)
SELECT
    cl.patient_sk,
    (d.year * 10000 + d.month * 100 + 1)::INT AS month_start_date_sk,
    SUM(cl.billed_amt) AS billed_amt,
    SUM(cl.allowed_amt) AS allowed_amt,
    SUM(cl.paid_amt) AS paid_amt,
    COUNT(*) FILTER (WHERE cl.is_er = TRUE) AS er_visits,
    COUNT(*) FILTER (WHERE cl.is_inpatient = TRUE) AS ip_admits,
    COUNT(*) FILTER (WHERE cl.is_outpatient = TRUE) AS op_visits,
    COUNT(*) FILTER (WHERE cl.is_preventive = TRUE) AS preventive_visits
FROM fact_claim_line cl
JOIN dim_date d ON d.date_sk = cl.from_date_sk
WHERE d.year = 2025
GROUP BY cl.patient_sk, d.year, d.month;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Summary stats
SELECT
    'Patients' AS entity,
    COUNT(*) AS count,
    COUNT(*) FILTER (WHERE sex_at_birth = 'F') AS female,
    COUNT(*) FILTER (WHERE sex_at_birth = 'M') AS male,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))), 1) AS avg_age
FROM dim_patient
UNION ALL
SELECT
    'Claim Lines' AS entity,
    COUNT(*) AS count,
    COUNT(DISTINCT patient_sk) AS unique_patients,
    NULL,
    ROUND(AVG(allowed_amt), 2) AS avg_allowed
FROM fact_claim_line
UNION ALL
SELECT
    'Encounters' AS entity,
    COUNT(*) AS count,
    COUNT(*) FILTER (WHERE encounter_type = 'ER') AS er_count,
    COUNT(*) FILTER (WHERE encounter_type = 'IP') AS ip_count,
    NULL
FROM fact_encounter
UNION ALL
SELECT
    'Conditions' AS entity,
    COUNT(*) AS count,
    COUNT(DISTINCT patient_sk) AS unique_patients,
    NULL,
    NULL
FROM bridge_patient_condition_year
WHERE has_condition = TRUE;

-- Test key queries
SELECT 'Test 1: Population by gender/age' AS test_name,
       COUNT(*) AS result
FROM vw_patients_2025
GROUP BY gender, age_bucket_10yr
UNION ALL
SELECT 'Test 2: Osteo screening eligible',
       COUNT(*)
FROM vw_osteoporosis_screening_2025
UNION ALL
SELECT 'Test 3: T2DM patients',
       COUNT(*)
FROM vw_patient_conditions_2025
WHERE condition_name = 'Type 2 diabetes'
UNION ALL
SELECT 'Test 4: ER visits',
       COUNT(*)
FROM vw_er_visits_2025
UNION ALL
SELECT 'Test 5: Patient 528 exists',
       COUNT(*)
FROM dim_patient
WHERE patient_id = 'PAT000528';

-- Show sample data
SELECT 'Sample patients:' AS info;
SELECT patient_id, birth_date, sex_at_birth, county_name, state
FROM dim_patient
LIMIT 10;

SELECT 'Sample claim lines:' AS info;
SELECT cl.cpt_hcpcs, COUNT(*) AS count, ROUND(AVG(cl.allowed_amt), 2) AS avg_cost
FROM fact_claim_line cl
GROUP BY cl.cpt_hcpcs
ORDER BY count DESC
LIMIT 10;

SELECT 'Sample conditions:' AS info;
SELECT cg.group_name, COUNT(DISTINCT b.patient_sk) AS patient_count
FROM bridge_patient_condition_year b
JOIN dim_condition_group cg ON cg.condition_group_sk = b.condition_group_sk
WHERE b.has_condition = TRUE AND b.year = 2025
GROUP BY cg.group_name
ORDER BY patient_count DESC;

ANALYZE dim_patient;
ANALYZE fact_claim_line;
ANALYZE fact_encounter;
ANALYZE bridge_patient_condition_year;
ANALYZE fact_patient_monthly_cost;

SELECT '✅ Sample data generation complete!' AS status;
SELECT 'Now run queries from 05_example_queries.sql to test' AS next_step;
