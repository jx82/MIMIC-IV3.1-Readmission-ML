-- MIMIC-IV v3.1 (no core module): use mimic_hosp.admissions
WITH ordered AS (
  SELECT subject_id, hadm_id, admittime, dischtime,
         LEAD(admittime) OVER (PARTITION BY subject_id ORDER BY admittime) AS next_admittime
  FROM mimic_hosp.admissions
)
SELECT *,
  (next_admittime IS NOT NULL AND next_admittime - dischtime <= INTERVAL '30 days')::int AS readmitted_30d,
  EXTRACT(EPOCH FROM (next_admittime - dischtime))/86400 AS days_until_next_admit
FROM ordered;
