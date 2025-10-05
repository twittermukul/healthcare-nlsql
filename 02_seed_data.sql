-- ============================================================================
-- Healthcare Analytics - Seed Data & Code Mappings
-- Loads reference data for condition groups, quality measures, and code maps
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONDITION GROUPS (hierarchical disease taxonomy)
-- ----------------------------------------------------------------------------

INSERT INTO dim_condition_group (condition_group_sk, group_id, group_name, parent_group, group_type, clinical_category, definition_version, is_chronic, is_active) VALUES
-- Diabetes hierarchy
(1, 'DM_ALL', 'Any diabetes', NULL, 'PARENT', 'Endocrine', 'v2025.1', TRUE, TRUE),
(2, 'DM_T2', 'Type 2 diabetes', 'Any diabetes', 'CONDITION', 'Endocrine', 'v2025.1', TRUE, TRUE),
(3, 'DM_T1', 'Type 1 diabetes', 'Any diabetes', 'CONDITION', 'Endocrine', 'v2025.1', TRUE, TRUE),
(4, 'DM_UNSPEC', 'Diabetes unspecified', 'Any diabetes', 'CONDITION', 'Endocrine', 'v2025.1', TRUE, TRUE),
(5, 'DM_COMPL', 'Diabetes with complications', 'Any diabetes', 'CONDITION', 'Endocrine', 'v2025.1', TRUE, TRUE),

-- Cancer hierarchy
(10, 'CANCER_ALL', 'Any cancer', NULL, 'PARENT', 'Oncology', 'v2025.1', TRUE, TRUE),
(11, 'CANCER_BREAST', 'Breast cancer', 'Any cancer', 'CONDITION', 'Oncology', 'v2025.1', TRUE, TRUE),
(12, 'CANCER_LUNG', 'Lung cancer', 'Any cancer', 'CONDITION', 'Oncology', 'v2025.1', TRUE, TRUE),
(13, 'CANCER_COLON', 'Colorectal cancer', 'Any cancer', 'CONDITION', 'Oncology', 'v2025.1', TRUE, TRUE),
(14, 'CANCER_PROSTATE', 'Prostate cancer', 'Any cancer', 'CONDITION', 'Oncology', 'v2025.1', TRUE, TRUE),
(15, 'CANCER_SKIN', 'Skin cancer (melanoma)', 'Any cancer', 'CONDITION', 'Oncology', 'v2025.1', TRUE, TRUE),
(16, 'CANCER_LYMPH', 'Lymphoma/leukemia', 'Any cancer', 'CONDITION', 'Oncology', 'v2025.1', TRUE, TRUE),
(17, 'CANCER_OTHER', 'Other cancer', 'Any cancer', 'CONDITION', 'Oncology', 'v2025.1', TRUE, TRUE),

-- Cardiovascular
(20, 'CVD_ALL', 'Cardiovascular disease', NULL, 'PARENT', 'Cardiovascular', 'v2025.1', TRUE, TRUE),
(21, 'CVD_CHF', 'Congestive heart failure', 'Cardiovascular disease', 'CONDITION', 'Cardiovascular', 'v2025.1', TRUE, TRUE),
(22, 'CVD_CAD', 'Coronary artery disease', 'Cardiovascular disease', 'CONDITION', 'Cardiovascular', 'v2025.1', TRUE, TRUE),
(23, 'CVD_AMI', 'Acute myocardial infarction', 'Cardiovascular disease', 'CONDITION', 'Cardiovascular', 'v2025.1', FALSE, TRUE),
(24, 'CVD_HTN', 'Hypertension', 'Cardiovascular disease', 'CONDITION', 'Cardiovascular', 'v2025.1', TRUE, TRUE),
(25, 'CVD_STROKE', 'Stroke/TIA', 'Cardiovascular disease', 'CONDITION', 'Cardiovascular', 'v2025.1', TRUE, TRUE),

-- Respiratory
(30, 'RESP_ALL', 'Respiratory disease', NULL, 'PARENT', 'Respiratory', 'v2025.1', TRUE, TRUE),
(31, 'RESP_COPD', 'COPD', 'Respiratory disease', 'CONDITION', 'Respiratory', 'v2025.1', TRUE, TRUE),
(32, 'RESP_ASTHMA', 'Asthma', 'Respiratory disease', 'CONDITION', 'Respiratory', 'v2025.1', TRUE, TRUE),

-- Mental health
(40, 'MH_ALL', 'Mental health', NULL, 'PARENT', 'Mental Health', 'v2025.1', TRUE, TRUE),
(41, 'MH_DEPRESSION', 'Depression', 'Mental health', 'CONDITION', 'Mental Health', 'v2025.1', TRUE, TRUE),
(42, 'MH_ANXIETY', 'Anxiety disorder', 'Mental health', 'CONDITION', 'Mental Health', 'v2025.1', TRUE, TRUE),
(43, 'MH_SUBSTANCE', 'Substance use disorder', 'Mental health', 'CONDITION', 'Mental Health', 'v2025.1', TRUE, TRUE),

-- Musculoskeletal
(50, 'MSK_ALL', 'Musculoskeletal disease', NULL, 'PARENT', 'Musculoskeletal', 'v2025.1', TRUE, TRUE),
(51, 'MSK_OSTEO', 'Osteoarthritis', 'Musculoskeletal disease', 'CONDITION', 'Musculoskeletal', 'v2025.1', TRUE, TRUE),
(52, 'MSK_OSTEOPOROSIS', 'Osteoporosis', 'Musculoskeletal disease', 'CONDITION', 'Musculoskeletal', 'v2025.1', TRUE, TRUE),
(53, 'MSK_BACK', 'Chronic back pain', 'Musculoskeletal disease', 'CONDITION', 'Musculoskeletal', 'v2025.1', TRUE, TRUE),

-- Kidney
(60, 'CKD_ALL', 'Chronic kidney disease', NULL, 'PARENT', 'Renal', 'v2025.1', TRUE, TRUE),
(61, 'CKD_STAGE3', 'CKD Stage 3', 'Chronic kidney disease', 'CONDITION', 'Renal', 'v2025.1', TRUE, TRUE),
(62, 'CKD_STAGE4', 'CKD Stage 4', 'Chronic kidney disease', 'CONDITION', 'Renal', 'v2025.1', TRUE, TRUE),
(63, 'CKD_STAGE5', 'CKD Stage 5/ESRD', 'Chronic kidney disease', 'CONDITION', 'Renal', 'v2025.1', TRUE, TRUE);

-- ----------------------------------------------------------------------------
-- CODE → CONDITION MAPPINGS (ICD-10-CM)
-- ----------------------------------------------------------------------------

INSERT INTO code_map_condition_group (code_system, code, condition_group_sk, mapping_logic, is_primary) VALUES
-- Type 2 Diabetes (E11.*)
('ICD10CM', 'E11', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.0', 2, 'exact', TRUE),
('ICD10CM', 'E11.00', 2, 'exact', TRUE),
('ICD10CM', 'E11.01', 2, 'exact', TRUE),
('ICD10CM', 'E11.1', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.2', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.3', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.4', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.5', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.6', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.7', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.8', 2, 'starts_with', TRUE),
('ICD10CM', 'E11.9', 2, 'starts_with', TRUE),

-- Type 1 Diabetes (E10.*)
('ICD10CM', 'E10', 3, 'starts_with', TRUE),

-- Diabetes complications
('ICD10CM', 'E11.2', 5, 'starts_with', TRUE),  -- with kidney complications
('ICD10CM', 'E11.3', 5, 'starts_with', TRUE),  -- with ophthalmic complications
('ICD10CM', 'E11.4', 5, 'starts_with', TRUE),  -- with neurological complications
('ICD10CM', 'E11.5', 5, 'starts_with', TRUE),  -- with circulatory complications

-- Breast cancer (C50.*)
('ICD10CM', 'C50', 11, 'starts_with', TRUE),

-- Lung cancer (C34.*)
('ICD10CM', 'C34', 12, 'starts_with', TRUE),

-- Colorectal cancer (C18-C20)
('ICD10CM', 'C18', 13, 'starts_with', TRUE),
('ICD10CM', 'C19', 13, 'exact', TRUE),
('ICD10CM', 'C20', 13, 'exact', TRUE),

-- Prostate cancer (C61)
('ICD10CM', 'C61', 14, 'exact', TRUE),

-- Melanoma (C43.*)
('ICD10CM', 'C43', 15, 'starts_with', TRUE),

-- Lymphoma/Leukemia (C81-C95)
('ICD10CM', 'C81', 16, 'starts_with', TRUE),
('ICD10CM', 'C82', 16, 'starts_with', TRUE),
('ICD10CM', 'C83', 16, 'starts_with', TRUE),
('ICD10CM', 'C84', 16, 'starts_with', TRUE),
('ICD10CM', 'C85', 16, 'starts_with', TRUE),
('ICD10CM', 'C90', 16, 'starts_with', TRUE),
('ICD10CM', 'C91', 16, 'starts_with', TRUE),
('ICD10CM', 'C92', 16, 'starts_with', TRUE),
('ICD10CM', 'C93', 16, 'starts_with', TRUE),
('ICD10CM', 'C94', 16, 'starts_with', TRUE),
('ICD10CM', 'C95', 16, 'starts_with', TRUE),

-- Other cancers (C00-C80, excluding specific ones above)
('ICD10CM', 'C00', 17, 'starts_with', TRUE),
('ICD10CM', 'C01', 17, 'starts_with', TRUE),
('ICD10CM', 'C15', 17, 'starts_with', TRUE),
('ICD10CM', 'C16', 17, 'starts_with', TRUE),
('ICD10CM', 'C17', 17, 'starts_with', TRUE),
('ICD10CM', 'C21', 17, 'starts_with', TRUE),
('ICD10CM', 'C22', 17, 'starts_with', TRUE),
('ICD10CM', 'C25', 17, 'starts_with', TRUE),
('ICD10CM', 'C56', 17, 'starts_with', TRUE),
('ICD10CM', 'C64', 17, 'starts_with', TRUE),
('ICD10CM', 'C67', 17, 'starts_with', TRUE),

-- Congestive Heart Failure (I50.*)
('ICD10CM', 'I50', 21, 'starts_with', TRUE),

-- Coronary Artery Disease (I25.1*)
('ICD10CM', 'I25.1', 22, 'starts_with', TRUE),
('ICD10CM', 'I25.11', 22, 'starts_with', TRUE),

-- Acute MI (I21.*)
('ICD10CM', 'I21', 23, 'starts_with', TRUE),

-- Hypertension (I10-I15)
('ICD10CM', 'I10', 24, 'exact', TRUE),
('ICD10CM', 'I11', 24, 'starts_with', TRUE),
('ICD10CM', 'I12', 24, 'starts_with', TRUE),
('ICD10CM', 'I13', 24, 'starts_with', TRUE),
('ICD10CM', 'I15', 24, 'starts_with', TRUE),

-- Stroke (I63.*)
('ICD10CM', 'I63', 25, 'starts_with', TRUE),
('ICD10CM', 'I64', 25, 'exact', TRUE),
('ICD10CM', 'G45', 25, 'starts_with', TRUE),  -- TIA

-- COPD (J44.*)
('ICD10CM', 'J44', 31, 'starts_with', TRUE),

-- Asthma (J45.*)
('ICD10CM', 'J45', 32, 'starts_with', TRUE),

-- Depression (F32-F33)
('ICD10CM', 'F32', 41, 'starts_with', TRUE),
('ICD10CM', 'F33', 41, 'starts_with', TRUE),

-- Anxiety (F41.*)
('ICD10CM', 'F41', 42, 'starts_with', TRUE),

-- Substance use disorder (F10-F19)
('ICD10CM', 'F10', 43, 'starts_with', TRUE),
('ICD10CM', 'F11', 43, 'starts_with', TRUE),
('ICD10CM', 'F12', 43, 'starts_with', TRUE),
('ICD10CM', 'F13', 43, 'starts_with', TRUE),
('ICD10CM', 'F14', 43, 'starts_with', TRUE),
('ICD10CM', 'F15', 43, 'starts_with', TRUE),

-- Osteoarthritis (M15-M19)
('ICD10CM', 'M15', 51, 'starts_with', TRUE),
('ICD10CM', 'M16', 51, 'starts_with', TRUE),
('ICD10CM', 'M17', 51, 'starts_with', TRUE),
('ICD10CM', 'M18', 51, 'starts_with', TRUE),
('ICD10CM', 'M19', 51, 'starts_with', TRUE),

-- Osteoporosis (M80-M81)
('ICD10CM', 'M80', 52, 'starts_with', TRUE),
('ICD10CM', 'M81', 52, 'starts_with', TRUE),

-- Chronic back pain (M54.5)
('ICD10CM', 'M54.5', 53, 'exact', TRUE),

-- CKD Stage 3 (N18.3*)
('ICD10CM', 'N18.3', 61, 'starts_with', TRUE),

-- CKD Stage 4 (N18.4*)
('ICD10CM', 'N18.4', 62, 'starts_with', TRUE),

-- CKD Stage 5/ESRD (N18.5*, N18.6)
('ICD10CM', 'N18.5', 63, 'starts_with', TRUE),
('ICD10CM', 'N18.6', 63, 'exact', TRUE);

-- ----------------------------------------------------------------------------
-- QUALITY MEASURES (HEDIS-style + custom)
-- ----------------------------------------------------------------------------

INSERT INTO dim_quality_measure (measure_sk, measure_id, measure_set, title, short_name, measure_type, denominator_spec, numerator_spec, spec_year, is_active) VALUES
(1, 'OSTOP_SCREEN_65_75', 'HEDIS', 'Osteoporosis screening in older women', 'Osteoporosis Screening', 'PROCESS',
 'Women age 65-75 years', 'BMD test (DEXA) or treatment for osteoporosis in measurement year', 2025, TRUE),

(2, 'BCS_MAMMO_50_74', 'HEDIS', 'Breast cancer screening', 'Breast Cancer Screening', 'PROCESS',
 'Women age 50-74 years', 'Mammogram in past 27 months', 2025, TRUE),

(3, 'COL_SCREEN_50_75', 'HEDIS', 'Colorectal cancer screening', 'Colorectal Screening', 'PROCESS',
 'Adults age 50-75 years', 'Colonoscopy, FIT, or Cologuard per schedule', 2025, TRUE),

(4, 'HBD_A1C_CONTROL', 'HEDIS', 'Diabetes HbA1c control (<8%)', 'HbA1c Control', 'INTERMEDIATE_OUTCOME',
 'Patients with diabetes age 18-75', 'Most recent HbA1c <8%', 2025, TRUE),

(5, 'CBP_CONTROL', 'HEDIS', 'Blood pressure control (<140/90)', 'BP Control', 'INTERMEDIATE_OUTCOME',
 'Patients with hypertension age 18-85', 'Most recent BP <140/90', 2025, TRUE),

(6, 'AMR_ADMIT_RATE', 'CUSTOM', 'All-cause acute hospital admission rate', 'Admission Rate', 'UTILIZATION',
 'All attributed members', 'IP admits per 1000 member months', 2025, TRUE),

(7, 'FUH_7DAY', 'HEDIS', 'Follow-up after hospitalization for mental illness (7 days)', 'Mental Health Follow-up', 'PROCESS',
 'Mental health IP discharge', 'Ambulatory visit within 7 days', 2025, TRUE);

-- ----------------------------------------------------------------------------
-- MEASURE CODE MAPPINGS (CPT/HCPCS/LOINC → numerator/denominator)
-- ----------------------------------------------------------------------------

INSERT INTO measure_map_evidence (measure_sk, code_system, code, role, spec_year, age_min, age_max) VALUES
-- Osteoporosis screening (DEXA scan CPT codes)
(1, 'CPT', '77080', 'numerator', 2025, 65, 75),
(1, 'CPT', '77081', 'numerator', 2025, 65, 75),
(1, 'CPT', '77085', 'numerator', 2025, 65, 75),
(1, 'CPT', '77086', 'numerator', 2025, 65, 75),
(1, 'HCPCS', 'G0130', 'numerator', 2025, 65, 75),

-- Breast cancer screening (mammogram CPT)
(2, 'CPT', '77065', 'numerator', 2025, 50, 74),
(2, 'CPT', '77066', 'numerator', 2025, 50, 74),
(2, 'CPT', '77067', 'numerator', 2025, 50, 74),
(2, 'HCPCS', 'G0202', 'numerator', 2025, 50, 74),

-- Colorectal screening
(3, 'CPT', '45378', 'numerator', 2025, 50, 75),  -- Colonoscopy
(3, 'CPT', '45380', 'numerator', 2025, 50, 75),
(3, 'CPT', '45384', 'numerator', 2025, 50, 75),
(3, 'CPT', '45385', 'numerator', 2025, 50, 75),
(3, 'CPT', '82270', 'numerator', 2025, 50, 75),  -- FIT
(3, 'HCPCS', 'G0328', 'numerator', 2025, 50, 75), -- Cologuard

-- HbA1c lab tests
(4, 'LOINC', '4548-4', 'numerator', 2025, 18, 75),  -- HbA1c
(4, 'LOINC', '17856-6', 'numerator', 2025, 18, 75),
(4, 'CPT', '83036', 'numerator', 2025, 18, 75);

-- ----------------------------------------------------------------------------
-- SAMPLE DIM_CODE ENTRIES (for demo purposes)
-- ----------------------------------------------------------------------------

INSERT INTO dim_code (code_sk, code_system, code, short_desc, long_desc, code_category, is_active) VALUES
-- CPT codes for osteoporosis screening
(5000001, 'CPT', '77080', 'DEXA bone density', 'Dual-energy X-ray absorptiometry (DXA), bone density study, 1 or more sites; axial skeleton', 'IMAGING', TRUE),
(5000002, 'CPT', '77081', 'DEXA bone density peripheral', 'Dual-energy X-ray absorptiometry (DXA), bone density study, 1 or more sites; appendicular skeleton', 'IMAGING', TRUE),
(5000003, 'CPT', '77085', 'DEXA bone density axial', 'Dual-energy X-ray absorptiometry (DXA), bone density study, 1 or more sites; axial skeleton (eg, hips, pelvis, spine)', 'IMAGING', TRUE),
(5000004, 'CPT', '77086', 'DEXA bone density axial', 'Dual-energy X-ray absorptiometry (DXA), bone density study, 1 or more sites; axial skeleton (eg, hips, pelvis, spine), including vertebral fracture assessment', 'IMAGING', TRUE),

-- CPT codes from user examples
(5000010, 'CPT', '95992', 'Canalith repositioning', 'Canalith repositioning procedure(s) (eg, Epley maneuver, Semont maneuver)', 'PROCEDURE', TRUE),
(5000011, 'CPT', '97112', 'Neuromuscular reeducation', 'Therapeutic procedure, 1 or more areas, neuromuscular reeducation', 'THERAPY', TRUE),
(5000012, 'CPT', '95117', 'Allergy immunotherapy', 'Professional services for allergen immunotherapy in the office or institution', 'IMMUNOTHERAPY', TRUE),
(5000013, 'CPT', '71046', 'Chest X-ray', 'Radiologic examination, chest; 2 views', 'IMAGING', TRUE),
(5000014, 'CPT', '97110', 'Therapeutic exercise', 'Therapeutic procedure, 1 or more areas, therapeutic exercises', 'THERAPY', TRUE),

-- Mammography CPT
(5000020, 'CPT', '77067', 'Mammogram screening', 'Screening mammography, bilateral (2-view study of each breast)', 'IMAGING', TRUE),

-- HbA1c LOINC
(5000030, 'LOINC', '4548-4', 'Hemoglobin A1c', 'Hemoglobin A1c/Hemoglobin.total in Blood', 'LAB', TRUE),

-- Common ICD-10 diagnoses
(5001000, 'ICD10CM', 'E11.9', 'Type 2 diabetes', 'Type 2 diabetes mellitus without complications', 'DIAGNOSIS', TRUE),
(5001001, 'ICD10CM', 'E11.65', 'Type 2 DM with hyperglycemia', 'Type 2 diabetes mellitus with hyperglycemia', 'DIAGNOSIS', TRUE),
(5001002, 'ICD10CM', 'I10', 'Essential hypertension', 'Essential (primary) hypertension', 'DIAGNOSIS', TRUE),
(5001003, 'ICD10CM', 'C50.911', 'Breast cancer', 'Malignant neoplasm of unspecified site of right female breast', 'DIAGNOSIS', TRUE),
(5001004, 'ICD10CM', 'C34.90', 'Lung cancer', 'Malignant neoplasm of unspecified part of unspecified bronchus or lung', 'DIAGNOSIS', TRUE),
(5001005, 'ICD10CM', 'I50.9', 'Heart failure', 'Heart failure, unspecified', 'DIAGNOSIS', TRUE),
(5001006, 'ICD10CM', 'J44.9', 'COPD', 'Chronic obstructive pulmonary disease, unspecified', 'DIAGNOSIS', TRUE),
(5001007, 'ICD10CM', 'M81.0', 'Osteoporosis', 'Age-related osteoporosis without current pathological fracture', 'DIAGNOSIS', TRUE);

-- ----------------------------------------------------------------------------
-- SAMPLE COUNTY REFERENCE DATA
-- ----------------------------------------------------------------------------

INSERT INTO county_ref (county_fips, county_name, state_fips, state, state_name, region, population, median_income) VALUES
('06037', 'Los Angeles', '06', 'CA', 'California', 'West', 10014009, 68044),
('17031', 'Cook', '17', 'IL', 'Illinois', 'Midwest', 5275541, 64721),
('48201', 'Harris', '48', 'TX', 'Texas', 'South', 4731145, 60440),
('04013', 'Maricopa', '04', 'AZ', 'Arizona', 'West', 4485414, 65686),
('06073', 'San Diego', '06', 'CA', 'California', 'West', 3298634, 83454),
('06059', 'Orange', '06', 'CA', 'California', 'West', 3186989, 94441),
('12086', 'Miami-Dade', '12', 'FL', 'Florida', 'South', 2716940, 50815),
('36047', 'Kings (Brooklyn)', '36', 'NY', 'New York', 'Northeast', 2736074, 70139),
('53033', 'King (Seattle)', '53', 'WA', 'Washington', 'West', 2269675, 99158),
('06085', 'Santa Clara', '06', 'CA', 'California', 'West', 1936259, 140258);

-- ============================================================================
-- HELPER FUNCTION: Populate dim_date
-- ============================================================================

-- Run this to populate dim_date for 2020-2030
DO $$
DECLARE
    start_date DATE := '2020-01-01';
    end_date DATE := '2030-12-31';
    current_date_val DATE;
    sk INT;
BEGIN
    current_date_val := start_date;
    sk := 20200101;

    WHILE current_date_val <= end_date LOOP
        INSERT INTO dim_date (
            date_sk, date, year, quarter, month, month_name, day, day_of_week, day_name,
            is_month_start, is_month_end, is_quarter_start, is_quarter_end, is_year_start, is_year_end,
            fiscal_year, fiscal_quarter
        ) VALUES (
            sk,
            current_date_val,
            EXTRACT(YEAR FROM current_date_val)::INT,
            EXTRACT(QUARTER FROM current_date_val)::INT,
            EXTRACT(MONTH FROM current_date_val)::INT,
            TO_CHAR(current_date_val, 'Month'),
            EXTRACT(DAY FROM current_date_val)::INT,
            EXTRACT(DOW FROM current_date_val)::INT,
            TO_CHAR(current_date_val, 'Day'),
            (EXTRACT(DAY FROM current_date_val) = 1),
            (current_date_val = (DATE_TRUNC('MONTH', current_date_val) + INTERVAL '1 MONTH - 1 day')::DATE),
            (EXTRACT(DOY FROM current_date_val) IN (1, 91, 182, 274)),
            (current_date_val IN (
                MAKE_DATE(EXTRACT(YEAR FROM current_date_val)::INT, 3, 31),
                MAKE_DATE(EXTRACT(YEAR FROM current_date_val)::INT, 6, 30),
                MAKE_DATE(EXTRACT(YEAR FROM current_date_val)::INT, 9, 30),
                MAKE_DATE(EXTRACT(YEAR FROM current_date_val)::INT, 12, 31)
            )),
            (EXTRACT(DOY FROM current_date_val) = 1),
            (EXTRACT(DOY FROM current_date_val) = 365 OR EXTRACT(DOY FROM current_date_val) = 366),
            EXTRACT(YEAR FROM current_date_val)::INT,
            EXTRACT(QUARTER FROM current_date_val)::INT
        );

        current_date_val := current_date_val + INTERVAL '1 day';
        sk := TO_CHAR(current_date_val, 'YYYYMMDD')::INT;
    END LOOP;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check condition groups
SELECT parent_group, COUNT(*) AS condition_count
FROM dim_condition_group
WHERE is_active = TRUE
GROUP BY parent_group
ORDER BY condition_count DESC;

-- Check code mappings
SELECT cg.group_name, COUNT(*) AS code_count
FROM code_map_condition_group cm
JOIN dim_condition_group cg ON cg.condition_group_sk = cm.condition_group_sk
GROUP BY cg.group_name
ORDER BY code_count DESC;

-- Check quality measures
SELECT measure_set, COUNT(*) AS measure_count
FROM dim_quality_measure
WHERE is_active = TRUE
GROUP BY measure_set;

-- Check date dimension
SELECT
    MIN(date) AS start_date,
    MAX(date) AS end_date,
    COUNT(*) AS date_count
FROM dim_date;
