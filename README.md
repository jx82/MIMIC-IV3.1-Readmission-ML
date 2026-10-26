# Predicting 30-Day Hospital Readmission Using MIMIC-IV

> **Project Status: Active Reconstruction & Documentation**
>
> This project is being systematically reviewed and documented after
> completion of the initial modeling workflow. I am currently validating
> cohort construction, outcome definition, feature engineering, leakage
> prevention, and model evaluation against the original analysis code.
>
## Project Progress

- [ ] Project question and objectives
- [ ] Cohort definition
- [ ] 30-day readmission outcome
- [x] Feature engineering
- [ ] Leakage prevention
- [ ] Train/validation/test strategy
- [ ] Logistic Regression
- [ ] Random Forest
- [ ] XGBoost
- [ ] Model evaluation
- [ ] SHAP interpretation
- [ ] Limitations and reproducibility

**Last updated:** October 26, 2026

## Documentation Progress

This project is currently undergoing a structured review and documentation update.
Each stage is being verified against the original analysis code before being
incorporated into the final README.

**Last updated:** October 26, 2026  
**Target README v1.0 publication:** November 11, 2026

| Review / Target Date | Focus | Status |
|---------------------|-------|--------|
| Oct 10, 2026 | README structure & project overview | ✅ Completed |
| Oct 12, 2026 | Cohort definition | ✅ Completed |
| Oct 20, 2026 | 30-day readmission outcome | ✅ Completed |
| Oct 22, 2026 | Cohort edge cases & exclusions | ✅ Completed |
| Oct 26, 2026 | Tier 1 features | 🔄 In progress |
| Oct 27, 2026 | Tier 2 features | ⬜ Planned |
| Oct 28, 2026 | Tier 3 features | ⬜ Planned |
| Oct 29, 2026 | Data leakage review | ⬜ Planned |
| Oct 30, 2026 | Patient-level data splitting | ⬜ Planned |
| Oct 31, 2026 | Preprocessing pipeline | ⬜ Planned |
| Nov 1, 2026 | Logistic Regression | ⬜ Planned |
| Nov 2, 2026 | Random Forest | ⬜ Planned |
| Nov 3, 2026 | XGBoost | ⬜ Planned |
| Nov 4, 2026 | Evaluation metrics | ⬜ Planned |
| Nov 5, 2026 | Model results | ⬜ Planned |
| Nov 6, 2026 | SHAP & model interpretation | ⬜ Planned |
| Nov 7, 2026 | Key findings | ⬜ Planned |
| Nov 8, 2026 | Limitations & future work | ⬜ Planned |
| Nov 9, 2026 | Repository cleanup & reproducibility | ⬜ Planned |
| Nov 10, 2026 | Final README review | ⬜ Planned |
| Nov 11, 2026 | README v1.0 publication | ⬜ Planned |

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
 │  admissions.csv      diagnoses_icd.csv    procedures_icd.csv │
 │  patients.csv        icustays.csv         labevents.csv      │
 │  chartevents.csv                                             │
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
                                │
                                ▼
                 Step 1 — Load and Validate Data
                    546,028 admission records
                    223,452 unique patients
                                │
                                ▼
                 Step 2 — Cohort Definition
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
                     No recorded return (Y = 0): 418,198
                                │
                                ▼
                    Step 4 — Feature Engineering
                            In progress
            Construct predictors available by discharge
            Aggregate clinical tables to admission-level
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼

   Tier 1 Features        Tier 2 Features        Tier 3 Features
   (Administrative)      (Clinical Burden)     (Physiologic Signals)

   age                   diagnosis_count       vital summaries
   gender                procedure_count       lab summaries
   race/ethnicity        charlson_score        temporal trends
   insurance             icu_flag
   los_days
   discharge_location
   prior_admits
          │                     │                     │
          └─────────────────────┼─────────────────────┘
                                │
                                ▼
               Step 5 — Modeling Dataset and Split
                             Planned
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
                             Planned
             Logistic Regression | Random Forest | XGBoost
                                │
                                ▼
               Step 7 — Evaluation and Interpretation
                             Planned
              ROC-AUC | PR-AUC | Calibration | SHAP

Note: Y = 0 means no qualifying readmission was recorded within
30 days; it does not establish complete follow-up or survival.
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

This section summarizes the research question, admission-level observations, outcome definition, prediction point, and potential application of the completed analysis.

- **Research question:** Predicting 30-day readmission and interpreting model predictions.
- **Unit of observation:** One eligible hospital admission.
- **Target:** An observed hospital readmission within 30 days after discharge.
- **Prediction point:** Hospital discharge.
- **Intended use:** Supporting assessment and prioritization of discharge and follow-up needs.

### Research Question

The analysis examined the following question:

Among eligible MIMIC-IV hospital admissions, how well could information available by discharge identify admissions at higher risk of readmission within 30 days, and which measured factors contributed most to those predictions?

Logistic regression, random forest, and XGBoost were compared using ROC-AUC and PR-AUC. Model interpretation included SHAP analysis to examine feature contributions.

Feature contributions describe how the model formed its predictions. They do not establish that a feature caused readmission or that changing it would reduce risk.

### Unit of Observation

The analysis used one eligible hospital admission, identified by `hadm_id`, as one observation. The patient identifier, `subject_id`, linked admissions belonging to the same person.

Patients could contribute multiple eligible admissions. Each admission served as an index admission with its own discharge time, features, and outcome label. An admission that counted as a readmission after an earlier stay could also serve as an index admission if it met the eligibility criteria.

The modeling data were split by patient. Admissions belonging to the same patient were kept in the same partition, preventing the same person from appearing in both training and test data.

### Target

The analysis constructed a binary outcome indicating whether an index admission was followed by an observed hospital readmission within 30 days after discharge:

- **1 — Readmission:** A subsequent admission met the implemented readmission criteria within the 30-day window.
- **0 — No observed readmission:** No subsequent admission met those criteria within the window.

The interval was calculated from the index admission’s discharge time to the subsequent admission’s admission time.

The exact eligibility, timing, and exclusion rules will be documented from the labeling code in Section 5. A label of 0 represents the absence of a qualifying readmission in the available data; it does not establish complete recovery or the absence of care elsewhere.

### Prediction Point

The analysis was framed as prediction at hospital discharge, using patient characteristics, prior utilization, and information from the index hospitalization.

Variables that directly revealed the future admission, including the next admission time and days until the next admission, were excluded from the modeling inputs.

The availability of the remaining predictors at discharge is being checked against their source and construction logic. Database records may contain information finalized after discharge, so retrospective availability does not automatically establish availability in a live hospital workflow.

The results describe a discharge-time prediction task. Predictions made at admission or earlier during the stay would require a different set of available features.

### Intended Use

The completed analysis assessed readmission prediction using historical data. Its potential application is to support care teams in prioritizing closer review of discharge and follow-up needs.

In a future hospital workflow, a validated model could help nurses and care managers identify patients who may need additional assessment. Staff could then discuss medication understanding, follow-up arrangements, transportation, caregiver support, mobility, and home services with the patient and family.

The study did not evaluate clinical deployment or whether acting on predictions improved outcomes. Those questions would require further validation and an evaluation of the model within an actual care workflow.


## 4. Dataset & Cohort Definition

### Data Sources and Unit of Analysis

Cohort construction used the MIMIC-IV admissions and patients tables.

- **Admissions:** 546,028 hospital admission records representing
  223,452 unique patients.
- **Patients:** 364,627 patient records containing demographic and
  age-reference information.

The unit of analysis was one hospital admission, identified by `hadm_id`.
A patient, identified by `subject_id`, could contribute multiple admissions.

Source validation found no missing patient or admission identifiers,
no duplicate admission IDs, and no duplicate patient IDs in the patients
table. All admissions matched a patient record.

### Eligibility and Exclusion Rules

We retained adult admissions with usable admission and discharge
timestamps and discharge occurring at or after admission.

Admissions were excluded if either `hospital_expire_flag = 1` or
`discharge_location = "DIED"` indicated in-hospital death, or if the
discharge location indicated hospice. These criteria applied to individual
admissions rather than all admissions belonging to a patient.

Age at admission was estimated as:

`age_at_admission = anchor_age + admission_year - anchor_year`

The patient-information merge preserved the admission count. No admissions
had missing estimated age or an estimated age below 18.

All admission types were retained, including 13,019 elective admissions.
Admission type described how the starting stay began and was not used
as an exclusion criterion.

### Cohort Flow

Exclusions were applied sequentially so each removed admission was
counted once.

| Stage | Admissions excluded at stage | Admissions remaining |
|---|---:|---:|
| Initial admissions | — | 546,028 |
| Require usable timestamps | 0 | 546,028 |
| Exclude discharge before admission | 175 | 545,853 |
| Exclude death or hospice | 17,302 | 528,551 |
| Require estimated age ≥18 | 0 | 528,551 |
| Review admission types; retain all categories | 0 | 528,551 |

The validated **Step 2 cohort contained 528,551 admissions from
216,762 unique patients**.

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

### Saved Outputs and Handoff

The cohort was saved as `cohort_step2.csv`, with 19 columns:
the 16 original admission fields plus `anchor_age`, `anchor_year`,
and `age_at_admission`. The aggregate cohort flow was saved as
`cohort_step2_flow.csv`.

Final checks confirmed unique admission IDs, valid identifiers and
timestamp ordering, adult eligibility, absence of admissions meeting
the death/hospice exclusions, and reconciliation of exclusion counts.
Read-back checks verified the exported admission IDs and patient count.

This is the cohort of potential prediction observations, not yet the
final labeled modeling sample. Step 3 will define qualifying 30-day
returns and address overlapping encounters, transfers, and follow-up
limitations. Any additional outcome-related exclusions will be documented
separately.


### Verification Checklist for Sections 4–7

The analysis has been completed. This checklist tracks the review of its implementation while the documentation is finalized. Each item should be supported by a notebook cell, script, or saved output.

#### Section 4 — Dataset & Cohort Definition

- [ ] Confirm the MIMIC-IV version and source tables actually used.
- [ ] Recover the starting admission count and unique patient count.
- [ ] Confirm how adult eligibility and age were calculated.
- [ ] Identify each exclusion rule, its order, and the number of admissions removed.
- [ ] Distinguish exclusions applied to index admissions from exclusions applied to subsequent readmissions.
- [ ] Confirm handling of in-hospital deaths, hospice discharges, elective admissions, and transfers.
- [ ] Confirm removal of duplicates and inconsistent admission or discharge timestamps.
- [ ] Recover final admission and patient counts and reconcile them with the cohort flow.

#### Section 5 — 30-Day Readmission Outcome

- [ ] Confirm that admissions were ordered correctly within each patient.
- [ ] Confirm whether labeling used the immediately next admission or the next qualifying admission.
- [ ] Verify that the interval began at discharge rather than admission.
- [ ] Check whether timing used exact elapsed time or rounded/truncated day values.
- [ ] Confirm the treatment of same-day admissions, transfers, overlaps, and the 30-day boundary.
- [ ] Confirm how planned or elective subsequent admissions were handled.
- [ ] Check whether death exclusions applied only to the index stay, to the following 30 days, or to anyone with a recorded death.
- [ ] Confirm how last admissions and uncertain follow-up were labeled.
- [ ] Manually inspect several patients with multiple admissions to validate the labels.
- [ ] Recover positive and negative label counts and the final readmission prevalence.

#### Section 6 — Feature Engineering

- [ ] Recover the final feature list from the dataset actually used for modeling.
- [ ] Document each feature’s source table, calculation, and aggregation window.
- [ ] Confirm that prior-utilization features used only events preceding the index admission.
- [ ] Check that measurements and summaries did not include information from subsequent stays.
- [ ] Verify age calculations, comorbidity scores, and diagnosis or procedure counts.
- [ ] Confirm laboratory and vital-sign summaries, units, and missingness.
- [ ] Verify missing-value indicators and categorical grouping rules.
- [ ] Confirm whether raw discharge location, a grouped discharge feature, or neither was retained.
- [ ] Review whether features could realistically have been available by discharge.
- [ ] Reconcile the pipeline diagram with the features and tables actually used.

#### Section 7 — Data Preparation & Leakage Prevention

- [ ] Confirm which feature dataset and outcome labels were loaded for modeling.
- [ ] Recover the patient-level split settings and train/test sizes.
- [ ] Verify that no `subject_id` appeared in both training and test data.
- [ ] Confirm that identifiers, outcome labels, next-admission fields, and other future information were excluded from predictors.
- [ ] Confirm how numeric, categorical, and binary features were assigned to preprocessing steps.
- [ ] Check that learned preprocessing, such as imputation, scaling, and encoding, was fitted on training data only.
- [ ] If resampling or feature selection was used, confirm that it did not use test data.
- [ ] Confirm that model or threshold selection did not repeatedly use the final test set.
- [ ] Check that saved preprocessing and model artifacts match the reported analysis.

**Review record:** For each resolved item, note the supporting code or output and whether the documentation alone changed or the analysis required correction.

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
