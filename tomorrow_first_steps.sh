#!/usr/bin/env bash
# tomorrow_first_steps.sh — Fill YOUR_MAC_USERNAME and YOUR_PG_USER, then run:
#   bash tomorrow_first_steps.sh

set -euo pipefail

MAC_USER="<YOUR_MAC_USERNAME>"
PG_USER="<YOUR_PG_USER>"
DATA_DIR="/Users/${MAC_USER}/MIMIC/mimic-iv-3.1/hosp"

echo "Unzipping (keeping originals) ..."
cd "${DATA_DIR}"
gunzip -k patients.csv.gz admissions.csv.gz diagnoses_icd.csv.gz drgcodes.csv.gz || true

echo "Starting psql... (you may be prompted for your DB password)"
psql -U "${PG_USER}" -h localhost -d mimic <<'PSQL'
CREATE SCHEMA IF NOT EXISTS mimic_hosp;
SET search_path TO mimic_hosp, public;

\copy mimic_hosp.patients       FROM '${DATA_DIR}/patients.csv'       WITH (FORMAT csv, HEADER true);
\copy mimic_hosp.admissions     FROM '${DATA_DIR}/admissions.csv'     WITH (FORMAT csv, HEADER true);
\copy mimic_hosp.diagnoses_icd  FROM '${DATA_DIR}/diagnoses_icd.csv'  WITH (FORMAT csv, HEADER true);
\copy mimic_hosp.drgcodes       FROM '${DATA_DIR}/drgcodes.csv'       WITH (FORMAT csv, HEADER true);

\i sql_first_exploration_v31.sql
PSQL

echo "Done. Check the printed rates and counts above."
