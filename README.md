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



### Project Architecture - Readmission Prediction Pipeline

```text
                     MIMIC-IV Raw Tables
 ┌──────────────────────────────────────────────────────────────┐
 │                                                              │
 │  admissions.csv        diagnoses_icd.csv     procedures_icd  │
 │  patients.csv          icustays.csv          labevents.csv   │
 │  chartevents.csv                                             │
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
                                │
                                ▼
                     Step 1 — Cohort Construction
                 Define prediction unit = hospital admission (n= 546,028)
                                │
                                ▼
                      Step 2 — Cohort Filtering
             Remove admissions not eligible for prediction
                       • in-hospital deaths = 11,801
                       • in-hospital alive & discharge_location_died = 227
                       • hospice discharge = 5,375
                       • pediatric patients = 0
                                │
                                ▼
                     Step 3 — Readmission Label (final cohort = 528,625)
               Determine if next admission occurs ≤ 30 days
                                │
                                ▼
                    Step 4 — Feature Engineering
            Aggregate clinical tables to admission-level
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼

   Tier 1 Features        Tier 2 Features        Tier 3 Features
   (Administrative)      (Clinical Burden)     (Physiologic Signals)

   age                   diagnosis_count       vital summaries
   gender                procedure_count       lab summaries
   ethnicity             charlson_score        medication features
   insurance             los_days              temporal trends
   prior_admits          icu_flag
                         discharge_location
                                │
                                ▼
                     Step 5 — Modeling Dataset
               Final admission-level feature table
                                │
                                ▼
                         Feature Matrix
                         X  (features)
                         y  (readmission)
                                │
                                ▼
                        Step 6 — Modeling
             Logistic Regression | Random Forest | XGBoost
                                │
                                ▼
                       Step 7 — Evaluation
                     ROC-AUC | SHAP | Diagnostics
```
The exact cohort rules and results are being checked against the analysis code as this README is completed.
High-priority verification item: I require survival for 30 days after discharge, and need to verify how the variable of "discharge_location = died" is measured and defined. 

## 2. Clinical & Operational Motivation

- **Patient and family needs:** Recovery, rehabilitation, and support after discharge.
- **Clinical and hospital priorities:** Care coordination and identifying patients who may need closer review.
- **Potential operational use:** Using risk estimates to prioritize discharge planning and follow-up.
  
### Patient and Family Perspective

For many patients, leaving the hospital is not the end of treatment. It begins another stage of recovery, rehabilitation, and ongoing care in daily life. Someone recovering from a heart attack or stroke may need rehabilitation; a person living with diabetes may need continued support with medication and self-management; and a person treated for cancer may need further treatment or monitoring. Families and caregivers often help patients navigate this transition.

At home, questions may arise that were difficult to anticipate in the hospital. Which medicines should the patient start, stop, or change? Is a new symptom expected, or should the family contact the care team? How will the patient get to follow-up appointments? Can they move around safely or manage daily tasks? Patients and caregivers may also need help with equipment, home health services, lifestyle changes, and the anxiety that comes with recovery. A check-in after discharge can reveal concerns that become clear only in the patient’s usual living environment.

From a patient’s perspective, readmission is one part of a broader health journey. My long-term interest is in using data and AI to better understand how health needs develop after hospitalization. Future research could combine clinical history with relevant demographic, environmental, and potentially genetic information to study these trajectories. If carefully validated and used with clinical judgment, AI tools might help care teams recognize changing needs and discuss more personalized support with patients and families.

This project takes a focused first step: it evaluates whether MIMIC-IV data can predict a qualifying hospital readmission within 30 days. It does not yet predict other health problems, determine which services a patient needs, or measure whether follow-up care improves recovery or quality of life.

### Clinical and Hospital Perspective

For a clinical team, discharge requires more than deciding that a patient is ready to leave a hospital bed. The team must communicate the care plan, reconcile medications, arrange follow-up, and identify needs that could make recovery at home difficult. Nurses, physicians, pharmacists, social workers, and care managers may each hold part of the information needed for that transition.

For a hospital, studying readmissions can reveal patterns that deserve closer attention. Are patients returning after particular kinds of admissions? Are follow-up and care coordination needs being identified before discharge? Which patients might benefit from a more detailed review by the care team? A readmission prediction model could help organize these questions and prioritize further assessment. Its risk score should prompt investigation and conversation, rather than serve as an automatic decision about a patient’s care.

As health data and AI tools develop, hospitals may be able to combine information across the care journey and recognize changing needs more effectively. The value of such tools would depend on reliable data, careful evaluation across patient groups, integration into clinical work, and evidence that using them actually improves care. This project examines the earlier step: whether information available by discharge can predict 30-day readmission with useful performance.

### Potential Operational Use

In a future hospital workflow, a validated readmission model could help create a discharge worklist for nurses and care managers. Staff could review patients with higher estimated risk before discharge, discuss barriers with the patient and family, and coordinate support matched to each person’s needs. After discharge, the team could track whether planned follow-up occurred and evaluate both patient outcomes and the workload required. The model would support prioritization; it would not determine treatment or services automatically. This project develops and evaluates a prediction model using historical data and does not test that operational workflow.

## 3. Research Question & Prediction Task
- Research question
- Unit of observation
- Target
- Prediction point
- Intended use

Research question: Among eligible MIMIC-IV hospital admissions, how well can information available by discharge identify admissions at higher risk of readmission within 30 days, and which measured factors contribute most to those predictions?

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
