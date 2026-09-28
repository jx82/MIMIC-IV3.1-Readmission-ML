# Predicting 30-Day Hospital Readmission Using MIMIC-IV

> **Project Status: Active Reconstruction & Documentation**
>
> This project is being systematically reviewed and documented after
> completion of the initial modeling workflow. I am currently validating
> cohort construction, outcome definition, feature engineering, leakage
> prevention, and model evaluation against the original analysis code.
>
> **Target for documented v1.0: October 15, 2026.**

## Project Progress

- [x] Project question and objectives
- [ ] Cohort definition
- [ ] 30-day readmission outcome
- [ ] Feature engineering
- [ ] Leakage prevention
- [ ] Train/validation/test strategy
- [ ] Logistic Regression
- [ ] Random Forest
- [ ] XGBoost
- [ ] Model evaluation
- [ ] SHAP interpretation
- [ ] Limitations and reproducibility

**Last updated:** September 25, 2026

## Documentation Progress

This project is currently undergoing a structured review and documentation update.
Each stage is being verified against the original analysis code before being
incorporated into the final README.

**Target v1.0 publication: October 15, 2026**

| Date | Focus | Status |
|------|-------|--------|
| Sep 25 | README structure & project overview | 🔄 In progress |
| Sep 26 | Cohort definition | ⬜ Planned |
| Sep 27 | 30-day readmission outcome | ⬜ Planned |
| Sep 28 | Cohort edge cases & exclusions | ⬜ Planned |
| Sep 29 | Tier 1 features | ⬜ Planned |
| Sep 30 | Tier 2 features | ⬜ Planned |
| Oct 1 | Tier 3 features | ⬜ Planned |
| Oct 2 | Data leakage review | ⬜ Planned |
| Oct 3 | Patient-level data splitting | ⬜ Planned |
| Oct 4 | Preprocessing pipeline | ⬜ Planned |
| Oct 5 | Logistic Regression | ⬜ Planned |
| Oct 6 | Random Forest | ⬜ Planned |
| Oct 7 | XGBoost | ⬜ Planned |
| Oct 8 | Evaluation metrics | ⬜ Planned |
| Oct 9 | Model results | ⬜ Planned |
| Oct 10 | SHAP & model interpretation | ⬜ Planned |
| Oct 11 | Key findings | ⬜ Planned |
| Oct 12 | Limitations & future work | ⬜ Planned |
| Oct 13 | Repository cleanup & reproducibility | ⬜ Planned |
| Oct 14 | Final README review | ⬜ Planned |
| Oct 15 | README v1.0 publication | ⬜ Planned |

# Predicting 30-Day Hospital Readmission Using MIMIC-IV

> **Project Status: Active Reconstruction & Documentation**
>
> This project is currently being systematically reviewed and documented.
> Each section is being verified against the original analysis code and
> results before final publication.
>
> **Target README v1.0: October 15, 2026**

---

## Documentation Progress

- 🔄 Current focus: Dataset & Cohort Definition
- ⬜ Next: 30-Day Readmission Outcome
- ⬜ Feature Engineering
- ⬜ Data Preparation & Leakage Prevention
- ⬜ Modeling
- ⬜ Evaluation
- ⬜ Results & Interpretation
- ⬜ Limitations
- ⬜ Reproducibility

---

# README Outline

## 1. Project Overview
- Project goal
- Dataset
- Prediction task
- Models
- Main project workflow

This project uses MIMIC-IV hospital data to study the risk of readmission within 30 days after discharge. It aims to identify admissions with higher readmission risk using information available by the time of discharge.

Each eligible hospital admission is one observation, so a patient may contribute more than one admission. The modeling work compares logistic regression, random forest, and XGBoost. The project workflow covers cohort and outcome construction, feature preparation, model training, and evaluation.

The exact cohort rules and results are being checked against the analysis code as this README is completed.

## 2. Clinical & Operational Motivation
- Why 30-day readmission matters
- Potential clinical use
- Potential operational use

## 3. Research Question & Prediction Task
- Research question
- Unit of observation
- Target
- Prediction point
- Intended use

## 4. Dataset & Cohort Definition 🔄
- MIMIC-IV data
- Source tables
- Starting population
- Inclusion criteria
- Exclusion criteria
- Final number of admissions
- Final number of patients
- Cohort flow

## 5. 30-Day Readmission Outcome
- Index admission
- Next admission
- 30-day window
- Definition of 1 vs. 0
- Transfers
- Deaths
- Elective/planned admissions
- Follow-up
- Other edge cases
- Readmission prevalence

## 6. Feature Engineering

### Tier 1 — Administrative / Demographic
- Demographics
- Insurance
- Admission information
- Prior utilization

### Tier 2 — Clinical Burden / Care Intensity
- Comorbidities
- Diagnoses
- Length of stay
- ICU utilization
- Procedures
- Discharge information

### Tier 3 — Physiologic / Treatment
- Laboratory results
- Vital signs
- Medications
- Polypharmacy
- Missingness indicators

## 7. Data Preparation & Leakage Prevention
- Missing data
- Imputation
- Encoding
- Scaling
- Leakage variables removed
- Patient-level splitting
- Train / validation / test sets
- Preprocessing pipeline

## 8. Modeling Approach

### Logistic Regression
- Purpose
- Pipeline
- Main settings

### Random Forest
- Purpose
- Main settings

### XGBoost
- Purpose
- Main settings

### Model Tuning
- Tuning performed
- Final model selection approach

## 9. Evaluation Strategy
- ROC-AUC
- PR-AUC
- Precision
- Recall / Sensitivity
- Specificity
- Confusion matrix
- Threshold analysis
- Calibration

## 10. Results & Model Interpretation
- Model comparison
- Tier comparison
- ROC / PR results
- SHAP
- Important predictors
- Key findings

## 11. Limitations & Future Work
- Dataset limitations
- Outcome limitations
- Missingness
- Generalizability
- Modeling limitations
- Prediction vs. causation
- Future improvements

## 12. Repository Structure & Reproducibility
- Repository organization
- Notebook execution order
- Environment / requirements
- MIMIC-IV access requirements
- Reproduction workflow
