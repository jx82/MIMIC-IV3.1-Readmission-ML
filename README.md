# 30-Day Readmission Prediction (MIMIC‑IV v3.1, XGBoost)

**TL;DR:** I built an end‑to‑end machine‑learning pipeline that estimates a patient’s **risk of being readmitted within 30 days** of discharge. It uses the publicly available, **de‑identified** hospital dataset **MIMIC‑IV v3.1** and an **XGBoost** model. The goal: help care teams focus follow‑up resources on higher‑risk patients *before* they bounce back to the hospital.

> This README serves **two audiences**: a short **plain‑English overview** for non‑technical readers (e.g., HR / recruiters) and a **technical appendix** for hiring managers.

---

## 🧭 Executive Summary 

- **Problem in one sentence:** Some patients come back to the hospital soon after discharge. This “30‑day readmission” is costly and stressful for patients and hospitals.
- **What I built:** A model that gives each discharged patient a **risk score** for being readmitted within 30 days, so care teams can plan **follow‑up calls, meds reconciliation, or clinic visits**.
- **Data used:** **MIMIC‑IV v3.1**, a large **de‑identified** dataset of real hospital stays used in research. No private patient information is stored in this repo.
- **Why it matters:** If hospitals can see who’s at higher risk, they can **prioritize support** and potentially **reduce avoidable readmissions**.
- **What the number means:** The model outputs a **probability** (0–1). Higher means more likely to be readmitted.
- **How I judge success:** I track standard ML quality measures (AUROC, AUPRC, calibration) and simple action metrics like “**recall@k**” (among the top‑k% highest‑risk patients, how many readmissions did we correctly flag?). Results are recorded in `docs/EXPERIMENT_TEMPLATE.md` entries and `docs/LOG.md`.
- **Privacy & ethics:** Data is **de‑identified** and gated by credentialed access. I don’t commit raw data. I check model calibration and error rates across key groups (e.g., age/sex) to avoid unfair bias.
- **Tooling:** Python, SQL/PostgreSQL, XGBoost, SHAP for explanations, and optional dashboards in Tableau/Power BI.

> If you only read one thing: this project shows I can **frame a real clinical problem**, **build a production‑style ML pipeline**, and **communicate results** for both non‑technical and technical stakeholders.

---

## 👩‍⚕️ What the Model Enables (Examples)

- **Discharge planning:** Flag high‑risk patients for enhanced transition plans.
- **Care management:** Prioritize post‑discharge **phone calls** and **follow‑up appointments**.
- **Quality reporting:** Track readmission risk by service line or diagnosis.

---

## 🧰 How to Review This Project (Quick Guide)

- **Non‑technical readers:** Start with this README and skim `docs/LOG.md` to see progress updates.
- **Hiring managers:** See **Technical Appendix** below and the SQL in `sql/readmission_label.sql`.
- **Artifacts:** Notebooks (EDA/modeling) live in `notebooks/`; dashboards (optional) in `reports/` (gitignored placeholders).

---

## 🧪 Current Status

- Repo & environment ✅
- Cohort and label (30‑day readmission) ✅
- Feature engineering (demographics, DRG, comorbidities, prior utilization) 🔄
- Baseline XGBoost training 🔄
- Explainability (SHAP) & calibration checks ⏳
- Dashboard and write‑up ⏳

(Updated: 2025-10-07)

---

## 🧑‍💼 Quick Facts for Recruiters

- **Domain:** Healthcare analytics (hospital quality / outcomes)
- **Use‑case:** Predict 30‑day readmissions at discharge
- **Data:** Public, de‑identified research dataset (MIMIC‑IV v3.1)
- **Skills demonstrated:** SQL data modeling, Python ML, feature engineering, experiment tracking, MLOps basics (reproducible runs), stakeholder‑friendly storytelling
- **Stack:** PostgreSQL, Python (pandas / scikit‑learn / xgboost / shap), Jupyter; Tableau/Power BI optional
- **Hiring relevance:** Shows end‑to‑end capability from **data ingestion → feature engineering → modeling → evaluation → explainability → communication**

---

## 📂 Repo Structure (what to look at)

```
sql/                     # SQL for labels/features (see readmission_label.sql)
notebooks/               # EDA & modeling notebooks
src/                     # (optional) pipeline code
docs/                    # LOG.md (work log), experiments, decisions
.github/ISSUE_TEMPLATE/  # templates to track tasks & experiments
data/, models/, reports/ # gitignored artifacts & data outside version control
```

---

# 🧪 Technical Appendix

### 1) Dataset & Tables (MIMIC‑IV v3.1)
- **Location changes (v3.1):** The historical `core` module was removed; **`patients`**, **`admissions`**, and **`transfers`** now live in **`hosp`**.
- **Primary tables used:**
  - `mimic_hosp.patients` — demographics, death info
  - `mimic_hosp.admissions` — hospital admissions/discharges
  - `mimic_hosp.diagnoses_icd` — ICD‑9/10 codes by admission
  - `mimic_hosp.drgcodes` — DRG categories/severity (optional early)
  - *(later)* `mimic_hosp.labevents` for lab‑based features; ICU module if focusing on ICU cohorts

### 2) Cohort & Label
- **Cohort:** Adult index admissions after basic QC.
- **Label:** **30‑day readmission** if the **next hospital admission for the same patient** occurs within **30 days** of discharge.
- **Implementation:** `LEAD(admittime) OVER (PARTITION BY subject_id ORDER BY admittime)` and compare with `dischtime`. See `sql/readmission_label.sql`.

### 3) Features (incremental)
- **Demographics:** age, sex
- **Utilization:** number of prior admits/ED visits in past 6 months, prior LOS
- **Clinical severity:** DRG category; **Elixhauser comorbidity flags** derived from ICD
- **Stay descriptors:** length of stay, discharge disposition, weekend discharge
- **(Optional)** Labs & vitals aggregates, service line indicators

### 4) Modeling
- **Algorithm:** XGBoost classifier (class imbalance via `scale_pos_weight`)
- **Split:** Temporal holdout (e.g., train early years → validate → test later year)
- **Evaluation:** AUROC, AUPRC, **calibration (Brier score)**, **recall@k**
- **Explainability:** **SHAP** value summaries and per‑patient force plots
- **Risk thresholding:** choose operating points by precision/recall trade‑off and team capacity

### 5) Reproducibility & Ops
- **Data governance:** No raw MIMIC files in repo; de‑identified dataset; paths via `.env`.
- **Make targets:** `make setup`, `make label`, `make train` (placeholders provided)
- **Tracking:** `docs/LOG.md` for daily progress; issue templates for tasks/experiments
- **Dependencies:** see `requirements.txt`

### 6) Limitations & Next Steps
- **Generalization:** Trained on one institution’s data (MIMIC); external validation TBD
- **Fairness:** Continue calibration/error audits across age/sex; document mitigations
- **Clinical integration:** Prospective evaluation & workflow alignment needed before deployment

---

## 🗣 Interview Talking Points (high‑level)

- Framed a real, measurable outcome (**30‑day readmission**)
- Used robust label logic and a temporal split to reduce leakage
- Built interpretable features and **explainable** XGBoost with SHAP
- Measured both **discrimination** (AUROC/AUPRC) and **calibration**
- Communicated results to **non‑technical** and **technical** stakeholders

---

## 🚦 How to Run (local)

1) Create `.env` from `env.example` and confirm PostgreSQL connectivity.  
2) Install: `make setup` (or `pip install -r requirements.txt`).  
3) Labels: run SQL in `sql/readmission_label.sql` to materialize the target.  
4) Modeling: notebooks in `notebooks/` (add your runs and log them via `docs/EXPERIMENT_TEMPLATE.md`).

---

**Contact:** Feel free to open an issue in this repo with questions or suggestions.
