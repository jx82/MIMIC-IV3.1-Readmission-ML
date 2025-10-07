# MIMIC‑IV v3.1 — What to Download & First Exploration Commands
_Last updated: 2025-10-07_

This document is designed to live in your GitHub repo (e.g., `docs/`). It tells future‑you **what to download** and gives **ready‑to‑run commands** for a clean first exploration.

---

## ✅ What to download (now → later)

### Must‑have now (for 30‑day readmission label + baseline features)
From **`mimic-iv-3.1/hosp/`** on PhysioNet:
1. `patients.csv.gz` — demographics (anchor_age, anchor_year, dod)
2. `admissions.csv.gz` — admit/discharge timestamps (for readmission label)
3. `diagnoses_icd.csv.gz` — ICD codes per admission (comorbidities)
4. `drgcodes.csv.gz` — DRG categories (severity proxy)

### Nice‑to‑have next (quality checks & richer features)
From **`mimic-iv-3.1/hosp/`**:
- `transfers.csv.gz` — helps distinguish true readmissions from same‑day service moves
- `labevents.csv.gz` — lab signals (large file; add when ready)

### Optional later (use only if needed)
- **ICU module** (`mimic-iv-3.1/icu/`): `icustays.csv.gz`, etc. for ICU‑focused cohorts
- **ED module** (`mimic-iv-3.1/ed/`): ED revisits
- **Note module** (`mimic-iv-3.1/note/`): discharge notes for NLP features

> 🛡️ **Data safety:** Don’t commit any of these files to GitHub. Keep them outside the repo (e.g., `/Volumes/data/mimic-iv-3.1`). The project’s `.gitignore` already blocks data files.

---

## 🗂 Recommended local folder layout
```
/Users/<YOUR_MAC_USERNAME>/MIMIC/mimic-iv-3.1/hosp/
    patients.csv.gz
    admissions.csv.gz
    diagnoses_icd.csv.gz
    drgcodes.csv.gz
    transfers.csv.gz    (optional now)
    labevents.csv.gz    (optional now)
```

---

## ▶️ Commands for **tomorrow** (first exploration)

> Assumes PostgreSQL is running and the **official MIMIC v3.1 tables** already exist in schema `mimic_hosp`. If not, create tables with the official SQL before running `\copy`.

### 1) In Terminal (Mac): unzip files
```bash
cd /Users/<YOUR_MAC_USERNAME>/MIMIC/mimic-iv-3.1/hosp
gunzip -k patients.csv.gz admissions.csv.gz diagnoses_icd.csv.gz drgcodes.csv.gz
# (optional) gunzip -k transfers.csv.gz labevents.csv.gz
```
`-k` keeps the `.gz` files; remove `-k` if you don’t need them.

### 2) Start `psql` and set schema
```bash
psql -U <YOUR_PG_USER> -h localhost -d mimic
```
Inside `psql`:
```sql
CREATE SCHEMA IF NOT EXISTS mimic_hosp;
SET search_path TO mimic_hosp, public;
```

### 3) Load the four core tables (client‑side **\copy**; works without superuser)
```sql
\copy mimic_hosp.patients       FROM '/Users/<YOUR_MAC_USERNAME>/MIMIC/mimic-iv-3.1/hosp/patients.csv'       WITH (FORMAT csv, HEADER true);
\copy mimic_hosp.admissions     FROM '/Users/<YOUR_MAC_USERNAME>/MIMIC/mimic-iv-3.1/hosp/admissions.csv'     WITH (FORMAT csv, HEADER true);
\copy mimic_hosp.diagnoses_icd  FROM '/Users/<YOUR_MAC_USERNAME>/MIMIC/mimic-iv-3.1/hosp/diagnoses_icd.csv'  WITH (FORMAT csv, HEADER true);
\copy mimic_hosp.drgcodes       FROM '/Users/<YOUR_MAC_USERNAME>/MIMIC/mimic-iv-3.1/hosp/drgcodes.csv'       WITH (FORMAT csv, HEADER true);
-- Optional next:
-- \copy mimic_hosp.transfers   FROM '/Users/<YOUR_MAC_USERNAME>/MIMIC/mimic-iv-3.1/hosp/transfers.csv'      WITH (FORMAT csv, HEADER true);
-- \copy mimic_hosp.labevents   FROM '/Users/<YOUR_MAC_USERNAME>/MIMIC/mimic-iv-3.1/hosp/labevents.csv'      WITH (FORMAT csv, HEADER true);
```

### 4) Run the **first exploration script** (ships with this doc)
From within `psql`:
```sql
\i sql_first_exploration_v31.sql
```
This script:
- checks row counts and date ranges,
- builds a **30‑day readmission label** using a window function,
- reports overall readmission rate,
- shows rates by **age group**, **principal diagnosis** (ICD, `seq_num=1`), and **DRG code**.

> You can open the `.sql` file in any editor to see/modify the queries.

---

## 🧪 What to expect
- A small table/printout of counts and min/max dates
- An overall 30‑day readmission rate (ballpark only; varies by filters)
- Simple breakdowns that confirm joins and label logic are working

---

## 📝 After you run this
- Add a row in `docs/LOG.md` (What I did / Next / Blockers)
- Open a **Task** issue: “Add DRG + demographics features and train baseline XGB”
- Keep real data out of Git; commit only SQL/notes/notebooks

---

## 📌 Paths to change
Replace **`<YOUR_MAC_USERNAME>`** and **`<YOUR_PG_USER>`** with your actual values before running.
