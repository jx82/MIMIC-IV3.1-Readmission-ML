# Predicting 30-Day Hospital Readmission Using MIMIC-IV

This project studies whether information available by hospital discharge can identify admissions at higher risk of a qualifying recorded readmission within 30 days. The workflow covers cohort validation, outcome labeling, three tiers of predictors, and comparison of logistic regression, random forest, and XGBoost.

**Current status:** Cohort construction and readmission labeling have been reviewed and completed. Tier 1 feature engineering is in progress. The initial modeling workflow was previously completed; its features, splitting, preprocessing, and results are being rechecked before final reporting.

**Last updated:** October 26, 2026  
**Target README v1.0 publication:** November 11, 2026

## Contents

- [1. Motivation and Intended Use](#1-motivation-and-intended-use)
- [2. Research Question and Prediction Task](#2-research-question-and-prediction-task)
- [3. Analysis Pipeline](#3-analysis-pipeline)
- [4. Data Sources and Cohort Construction](#4-data-sources-and-cohort-construction)
- [5. Readmission Outcome](#5-readmission-outcome)
- [6. Feature Engineering](#6-feature-engineering)
- [7. Data Preparation and Leakage Prevention](#7-data-preparation-and-leakage-prevention)
- [8. Modeling and Evaluation](#8-modeling-and-evaluation)
- [9. Limitations and Future Work](#9-limitations-and-future-work)
- [10. Outputs and Reproducibility](#10-outputs-and-reproducibility)
- [11. Documentation Progress](#11-documentation-progress)

## 1. Motivation and Intended Use

Leaving the hospital begins another stage of recovery. Patients and families may need help understanding medications, arranging follow-up, recognizing concerning symptoms, and managing rehabilitation, transportation, or care at home. These needs motivate my interest in using health data to understand the period after discharge.

A validated readmission model could help nurses and care managers prioritize patients for closer assessment and discharge planning. A risk estimate would support discussion with patients and families; clinical judgment and individual circumstances would guide care.

This project examines prediction using historical hospital data. It does not evaluate deployment, determine which services a patient needs, or demonstrate that acting on predictions improves recovery or reduces readmissions.

## 2. Research Question and Prediction Task

**Research question:** Among eligible MIMIC-IV hospital admissions, how well can information available by discharge identify admissions at higher risk of readmission within 30 days, and which measured factors contribute most to those predictions?

| Component | Definition |
|-----------|------------|
| Unit of observation | One eligible hospital admission, identified by `hadm_id` |
| Patient linkage | `subject_id` links admissions belonging to the same patient |
| Prediction point | Discharge from the index admission |
| Target | `label_readmit_30d`, indicating a qualifying recorded return within 30 days after discharge |
| Candidate predictors | Demographics, prior utilization, and information from the index hospitalization |
| Model comparison | Logistic regression, random forest, and XGBoost; results pending review |

A patient may contribute multiple eligible index admissions. A stay counted as a return after an earlier admission may itself serve as an index admission if eligible. Patient-level splitting is the intended evaluation strategy; its implementation remains to be verified during the current review.

## 3. Analysis Pipeline

The detailed flowchart summarizes cohort accounting and the analysis workflow. Steps 1–3 are complete; Tier 1 feature engineering is in progress. Later stages and the candidate feature tiers remain subject to the current review.

```text
                    
MIMIC-IV Raw Tables
 ┌──────────────────────────────────────────────────────────────┐
 │                                                              │
 │  admissions.csv      diagnoses_icd.csv    procedures_icd.csv │
 │  patients.csv        icustays.csv         labevents.csv      │
 │  chartevents.csv                                             │
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
                                │
                                ▼
                 Step 1 — Load and Validate Data
                            Completed
                    546,028 admission records
                    223,452 unique patients
                                │
                                ▼
                 Step 2 — Cohort Definition
                            Completed
              Apply sequential eligibility criteria

              • Unusable timestamps excluded:           0
              • Reversed timestamps excluded:         175
              • Death or hospice excluded:         17,302
              • Estimated age below 18 excluded:       0
              • Admission-type exclusions:             0

              Death/hospice exclusion:
              11,927 death-indicated admissions
               5,397 hospice-indicated admissions
                  22 meeting both criteria
              11,927 + 5,397 − 22 = 17,302

              Elective and observation admissions retained
                                │
                                ▼
                   Validated Step 2 Cohort
                     528,551 admissions
                     216,762 unique patients
                     19 columns
                                │
                                ▼
              Step 3 — Readmission Label Construction
                            Completed
              Identify qualifying recorded returns
                 within 30 days after discharge
              using the full source admission history

              Additional exclusions:
              • Overlapping/touching admissions:     4,194
              • Uncertain returns:                      23
              • Unresolved mortality chronology:        25

              528,551 − 4,194 − 23 − 25 = 524,309
                                │
                                ▼
                    Final Step 3 Labeled Cohort
                     524,309 admissions
                     216,032 unique patients
                     19 cohort columns + outcome label

                     Readmission (Y = 1):       106,111
                     No qualifying return (Y = 0): 418,198
                                │
                                ▼
                    Step 4 — Feature Engineering
                     Tier 1 in progress
            Construct predictors available by discharge
            Aggregate clinical tables to admission-level
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼

   Tier 1 Features        Tier 2 Features        Tier 3 Features
    (In progress)        (Pending review)      (Pending review)
   (Administrative)      (Clinical Burden)     (Physiologic Signals)

   age                   diagnosis_count       vital summaries
   gender                procedure_count       lab summaries
   race/ethnicity        charlson_score        temporal trends
   insurance             icu_flag
   discharge_location    los_days
   prior_admits

          │                     │                     │
          └─────────────────────┼─────────────────────┘
                                │
                                ▼
               Step 5 — Modeling Dataset and Split
                        Pending review
               Final admission-level feature table
               Patient-level train/validation/test split
               Fit preprocessing on training data only
                                │
                                ▼
                         Feature Matrix
                         X  (features)
                         y  (readmission)
                                │
                                ▼
                        Step 6 — Modeling
                        Pending review
             Logistic Regression | Random Forest | XGBoost
                                │
                                ▼
               Step 7 — Evaluation and Interpretation
                        Pending review
              ROC-AUC | PR-AUC | Calibration | SHAP

Note: Y = 0 means no qualifying readmission was recorded within
30 days; it does not establish complete follow-up or survival.
```

## 4. Data Sources and Cohort Construction

**Status: ✅ Completed**

### Source Tables

Cohort construction used the MIMIC-IV v3.1 `admissions` and `patients` tables. The source admissions table contained **546,028 admissions from 223,452 unique patients**. The patients table contained **364,627 patient records** with demographic and age-reference information.

Source validation found no missing patient or admission identifiers, no duplicate admission IDs, and no duplicate patient IDs in the patients table. All admissions matched a patient record.

Additional tables identified for feature engineering are `diagnoses_icd`, `procedures_icd`, `icustays`, `labevents`, and `chartevents`. Their use and derived features will be confirmed during feature review.

### Eligibility Rules

Eligible index admissions required usable admission and discharge timestamps, discharge at or after admission, and estimated age of at least 18 years. Age was calculated as:

```python
age_at_admission = anchor_age + admission_year - anchor_year
```

Admissions were excluded when either `hospital_expire_flag = 1` or `discharge_location = "DIED"` indicated in-hospital death, or when discharge location indicated hospice. These exclusions applied to individual index admissions, rather than removing every admission belonging to that patient.

No admissions had missing estimated age or estimated age below 18. All admission types were retained, including observation admissions and 13,019 elective admissions in the Step 2 cohort. Admission type described how the index stay began and was not an index exclusion criterion.

### Cohort Flow

Exclusions were applied sequentially so each removed admission was counted once. Step 2 established index eligibility; Step 3 applied additional exclusions needed for outcome construction.

| Step | Stage | Admissions excluded | Admissions remaining |
|------|-------|--------------------:|---------------------:|
| 1 | Initial admissions | — | 546,028 |
| 2 | Require usable timestamps | 0 | 546,028 |
| 2 | Exclude discharge before admission | 175 | 545,853 |
| 2 | Exclude death or hospice | 17,302 | 528,551 |
| 2 | Require estimated age ≥18 | 0 | 528,551 |
| 2 | Review admission types; retain all categories | 0 | 528,551 |
| 3 | Exclude overlapping or touching admissions | 4,194 | 524,357 |
| 3 | Exclude uncertain returns | 23 | 524,334 |
| 3 | Exclude unresolved mortality chronology | 25 | 524,309 |

| Cohort | Admissions | Unique patients |
|--------|-----------:|----------------:|
| Validated Step 2 cohort | 528,551 | 216,762 |
| Final Step 3 labeled cohort | 524,309 | 216,032 |

### Data-Quality Findings

**Timestamp ordering.** Both admission and discharge timestamps were
present and parseable for all source admissions. We excluded 175 records
with discharge preceding admission without altering their original
timestamps. Five records with identical admission and discharge timestamps
were retained at this stage; none indicated death or hospice discharge.

**Mortality-field agreement.** Among the 545,853 admissions evaluated
after timestamp exclusions, 227 had a mortality flag of 0 with discharge
location `DIED`, and 143 had a mortality flag of 1 with another recorded
location. These 370 disagreements did not establish which field was
correct. Another 161 admissions had a mortality flag of 1 with a missing
discharge location and were reported separately as incomplete information.

Using either mortality indicator identified 11,927 admissions.
Hospice was indicated for 5,397 admissions, including 22 also identified
by the death rule. The combined exclusion therefore removed
17,302 unique admissions.


## 5. Readmission Outcome

**Status: ✅ Completed**

### Label Construction

Step 3 used two tables: the eligible Step 2 cohort supplied index admissions, and the full source admission history supplied candidate returns. This avoided losing candidate returns merely because those stays were ineligible as index observations.

The outcome window began at the index discharge, with the interval measured to the candidate return's admission time. Overlapping or touching encounters, uncertain returns, and unresolved mortality chronology were reviewed before finalizing the labeled cohort; their exclusion counts are recorded in the cohort-flow table.

| Label | Meaning | Admissions | Percentage |
|-------|---------|-----------:|-----------:|
| `1` | Qualifying recorded readmission within 30 days | 106,111 | 20.24% |
| `0` | No qualifying recorded readmission within 30 days | 418,198 | 79.76% |
| **Total** | | **524,309** | **100.00%** |

A negative label indicates no qualifying readmission recorded within 30 days. It does not establish complete follow-up, survival, recovery, or the absence of hospitalization elsewhere. The cohort should not be described as requiring survival for 30 days after discharge.

The detailed timing boundary, candidate-selection logic, and handling of elective returns and transfers should be traceable to the labeling notebook. Retaining elective **index admissions** does not by itself specify the eligibility of elective **returns**.

## 6. Feature Engineering

**Status:** Tier 1 is in progress. The table describes candidate feature groups, rather than a verified final model matrix.

| Tier | Focus | Candidate features |
|------|-------|--------------------|
| 1 | Administrative and demographic | Age, gender, race/ethnicity, insurance, admission information, length of stay, discharge location, prior admission history |
| 2 | Clinical burden and care intensity | Diagnosis count, procedure count, Charlson comorbidity score, ICU exposure |
| 3 | Physiologic signals | Laboratory summaries, vital-sign summaries, temporal trends, relevant missingness indicators |

Features will be aggregated to the admission level using information available by index discharge. Prior-utilization features must use only history available before the index prediction point, with the lookback and inclusion rules documented explicitly.

For each implemented feature, documentation will record its source table, calculation, time window, missingness, categorical grouping, and availability at prediction time. Medication and polypharmacy features require confirmed source tables and are not yet part of the verified feature specification.

## 7. Data Preparation and Leakage Prevention

The following checks remain part of the review of the modeling workflow:

- Keep all admissions from a patient in a single train, validation, or test partition; verify no `subject_id` crosses partitions.
- Exclude identifiers, future admission fields, mortality information occurring after the prediction point, and other label-construction fields from predictors.
- Fit imputation, scaling, encoding, and any learned feature selection on training data only.
- Restrict resampling, tuning, and threshold selection to the appropriate training and validation data; reserve the test set for final evaluation.
- Confirm that database fields used as predictors could have been available by discharge, including diagnoses and procedures that may be finalized later.
- Record split settings, partition sizes, preprocessing choices, and saved artifact versions.

Patient-level splitting prevents patient overlap between partitions. Repeated admissions within a partition still require consideration when estimating uncertainty and interpreting results.

## 8. Modeling and Evaluation

The initial workflow included logistic regression, random forest, and XGBoost. Settings, tuning procedures, and model comparisons are pending verification against the code and saved outputs. Performance estimates will be added after that review.

| Area | Planned reporting |
|------|-------------------|
| Discrimination | ROC-AUC and PR-AUC |
| Threshold performance | Precision, recall/sensitivity, specificity, and confusion matrices |
| Calibration | Agreement between predicted risks and observed outcomes |
| Model and tier comparisons | Performance across models and verified feature sets |
| Interpretation | SHAP and other model diagnostics, where applicable |

Feature contributions explain model predictions. They do not establish causes of readmission or show that changing a feature would reduce risk.

## 9. Limitations and Future Work

- **Outcome ascertainment:** Recorded returns do not capture all care outside the source system; a negative label does not guarantee full observation of the outcome window.
- **Mortality and encounter chronology:** Conflicting records and overlapping encounters required explicit review and exclusions.
- **Repeated admissions:** Multiple admissions from one patient are correlated; evaluation and uncertainty estimates must account for this structure.
- **Availability and missingness:** Retrospective database information may differ from what a clinical team could access at discharge. Missingness may reflect care processes as well as patient condition.
- **Generalizability:** Performance on this historical cohort does not establish performance in another hospital, time period, or patient population.
- **Clinical impact:** Prediction performance does not establish preventability of readmission or benefit from an intervention.

Future work includes verifying the complete modeling pipeline, examining calibration and performance across relevant patient groups, and evaluating transportability before considering operational use.

## 10. Outputs and Reproducibility

### Cohort and Label Outputs

| File | Purpose |
|------|---------|
| `cohort_step2.csv` | Validated eligible index admissions; 19 columns: 16 admission fields plus `anchor_age`, `anchor_year`, and `age_at_admission` |
| `cohort_step2_flow.csv` | Aggregate Step 2 cohort accounting |
| `cohort_step3.csv` | Input for Step 4; 19 cohort columns plus `label_readmit_30d` |
| `label_audit_step3.csv` | Label-validation details, including future-event information; excluded from model inputs |

Step 2 export checks confirmed unique admission IDs, identifier and timestamp validity, adult eligibility, exclusion-count reconciliation, and matching admission IDs and patient counts after read-back.

### Review Samples

Selected notebooks are available in [publication_review](https://github.com/jx82/MIMIC-IV3.1-Readmission-ML/tree/main/publication_review).

### Reproduction Status

The execution order follows Steps 1–7 in the pipeline. Exact notebook paths, environment requirements, feature-output filenames, and execution instructions will be finalized during repository cleanup. Reproduction requires authorized access to MIMIC-IV; source clinical data are not included in this README.

## 11. Documentation Progress

### Current Analysis Progress

| Section | Contents | Status |
|---------|----------|--------|
| **4. Data Sources and Cohort Construction** | Source-table validation; identifiers; timestamp checks; adult eligibility; death/hospice exclusions; admission-type review; cohort flow and quality checks. | ✅ Completed |
| **5. Readmission Outcome** | Index admissions linked to full admission history; discharge-to-return intervals; qualifying 30-day returns; overlap and mortality chronology review; final labels and audit outputs. | ✅ Completed |
| **6. Feature Engineering — Tier 1** | Administrative and demographic predictors; length of stay; categorical grouping; missingness review; prior admission history. | ✅ Completed |
| **6. Feature Engineering — Tier 2** | Clinical burden and care intensity features. | 🔄 In progress |
| **6. Feature Engineering — Tier 3** | Laboratory and vital-sign summaries. | ⬜ Pending review |
| **7. Data Preparation and Leakage Prevention** | Patient-level splitting; preprocessing; predictor availability and leakage checks. | ⬜ Pending review |
| **8. Modeling and Evaluation** | Model comparison; discrimination; calibration; threshold diagnostics; interpretation. | ⬜ Pending review |

### Review Schedule

The detailed schedule below tracks the current reconstruction and documentation review. Completed dates reflect the supplied review record; future dates are targets. Pending review does not imply the initial modeling work was never performed.

| Review / Target Date | Focus | Review status |
|---------------------|-------|--------|
| Oct 10, 2026 | README structure & project overview | ✅ Completed |
| Oct 12, 2026 | Cohort definition | ✅ Completed |
| Oct 20, 2026 | 30-day readmission outcome | ✅ Completed |
| Oct 22, 2026 | Cohort edge cases & exclusions | ✅ Completed |
| Oct 26, 2026 | Tier 1 features | ✅ Completed|
| Oct 27, 2026 | Tier 2 features | 🔄 In progress |
| Oct 28, 2026 | Tier 3 features | ⬜ Pending review |
| Oct 29, 2026 | Data leakage review | ⬜ Pending review |
| Oct 30, 2026 | Patient-level data splitting | ⬜ Pending review |
| Oct 31, 2026 | Preprocessing pipeline | ⬜ Pending review |
| Nov 1, 2026 | Logistic Regression | ⬜ Pending review |
| Nov 2, 2026 | Random Forest | ⬜ Pending review |
| Nov 3, 2026 | XGBoost | ⬜ Pending review |
| Nov 4, 2026 | Evaluation metrics | ⬜ Pending review |
| Nov 5, 2026 | Model results | ⬜ Pending review |
| Nov 6, 2026 | SHAP & model interpretation | ⬜ Pending review |
| Nov 7, 2026 | Key findings | ⬜ Pending review |
| Nov 8, 2026 | Limitations & future work | ⬜ Pending review |
| Nov 9, 2026 | Repository cleanup & reproducibility | ⬜ Pending review |
| Nov 10, 2026 | Final README review | ⬜ Pending review |
| Nov 11, 2026 | README v1.0 publication | ⬜ Pending review |
