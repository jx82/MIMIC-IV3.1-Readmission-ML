-- sql_first_exploration_v31.sql
-- First exploration for MIMIC-IV v3.1 (admissions/patients/diagnoses_icd/drgcodes in schema mimic_hosp)

SET search_path TO mimic_hosp, public;

-- 1) Sanity checks
SELECT 'patients' AS table, COUNT(*) AS rows FROM patients
UNION ALL
SELECT 'admissions', COUNT(*) FROM admissions
UNION ALL
SELECT 'diagnoses_icd', COUNT(*) FROM diagnoses_icd
UNION ALL
SELECT 'drgcodes', COUNT(*) FROM drgcodes;

-- Date ranges to confirm time coverage
SELECT MIN(admittime) AS min_admit, MAX(dischtime) AS max_discharge FROM admissions;

-- 2) Build 30-day readmission label (one row per admission)
WITH ordered AS (
  SELECT
      subject_id,
      hadm_id,
      admittime,
      dischtime,
      LEAD(admittime) OVER (PARTITION BY subject_id ORDER BY admittime) AS next_admittime
  FROM admissions
),
labels AS (
  SELECT o.*,
         CASE
           WHEN next_admittime IS NOT NULL
            AND next_admittime - dischtime <= INTERVAL '30 days'
           THEN 1 ELSE 0 END AS readmitted_30d
  FROM ordered o
)
-- 3) Overall rate
SELECT ROUND(AVG(readmitted_30d)::numeric, 4) AS overall_readmit_rate_30d
FROM labels;

-- 4) By age group (estimate age at admit using anchor fields)
WITH ordered AS (
  SELECT
      subject_id, hadm_id, admittime, dischtime,
      LEAD(admittime) OVER (PARTITION BY subject_id ORDER BY admittime) AS next_admittime
  FROM admissions
),
labels AS (
  SELECT o.*,
         CASE
           WHEN next_admittime IS NOT NULL
            AND next_admittime - dischtime <= INTERVAL '30 days'
           THEN 1 ELSE 0 END AS readmitted_30d
  FROM ordered o
),
joined AS (
  SELECT l.*, p.anchor_age, p.anchor_year,
         (EXTRACT(YEAR FROM l.admittime)::int - p.anchor_year + p.anchor_age) AS age_at_admit
  FROM labels l
  JOIN patients p USING(subject_id)
)
SELECT
  CASE
    WHEN age_at_admit < 40 THEN '<40'
    WHEN age_at_admit < 60 THEN '40-59'
    WHEN age_at_admit < 80 THEN '60-79'
    ELSE '80+'
  END AS age_bin,
  ROUND(AVG(readmitted_30d)::numeric, 4) AS readmit_rate
FROM joined
GROUP BY 1
ORDER BY 1;

-- 5) By principal diagnosis (ICD) — seq_num = 1
WITH ordered AS (
  SELECT
      subject_id, hadm_id, admittime, dischtime,
      LEAD(admittime) OVER (PARTITION BY subject_id ORDER BY admittime) AS next_admittime
  FROM admissions
),
labels AS (
  SELECT o.*,
         CASE
           WHEN next_admittime IS NOT NULL
            AND next_admittime - dischtime <= INTERVAL '30 days'
           THEN 1 ELSE 0 END AS readmitted_30d
  FROM ordered o
),
principal_dx AS (
  SELECT hadm_id, icd_code, icd_version
  FROM diagnoses_icd
  WHERE seq_num = 1
)
SELECT d.icd_code, d.icd_version,
       COUNT(*) AS admits,
       ROUND(AVG(l.readmitted_30d)::numeric, 4) AS readmit_rate
FROM labels l
JOIN principal_dx d USING (hadm_id)
GROUP BY d.icd_code, d.icd_version
ORDER BY admits DESC
LIMIT 20;

-- 6) By DRG code
WITH ordered AS (
  SELECT
      subject_id, hadm_id, admittime, dischtime,
      LEAD(admittime) OVER (PARTITION BY subject_id ORDER BY admittime) AS next_admittime
  FROM admissions
),
labels AS (
  SELECT o.*,
         CASE
           WHEN next_admittime IS NOT NULL
            AND next_admittime - dischtime <= INTERVAL '30 days'
           THEN 1 ELSE 0 END AS readmitted_30d
  FROM ordered o
)
SELECT d.drg_code,
       COUNT(*) AS admits,
       ROUND(AVG(l.readmitted_30d)::numeric, 4) AS readmit_rate
FROM labels l
JOIN drgcodes d USING (hadm_id)
GROUP BY d.drg_code
ORDER BY admits DESC
LIMIT 20;

-- Optional: If you loaded transfers, exclude same-day internal transfers by requiring at least 24h between discharges and next admits, or add logic with transfers to filter continuous stays.
