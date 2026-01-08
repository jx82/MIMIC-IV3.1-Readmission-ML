# 30-Day Unplanned Hospital Readmission Analysis

## Project Overview
This project analyzes and predicts **30-day unplanned hospital readmissions** using electronic health record (EHR) data. Readmissions are a critical healthcare quality and cost metric, often reflecting care coordination gaps, discharge planning issues, or unmanaged chronic conditions.

The goal of this project is to:
- Define a clinically aligned readmission outcome
- Construct a leakage-safe modeling dataset
- Build baseline machine learning models for readmission risk
- Provide a foundation for future analytics and BI reporting

This project is designed to mirror **real-world healthcare analytics workflows** used by hospitals, payers, and consulting firms.

---

## Data Sources
The analysis uses two core EHR tables:

- **Admissions table**  
  Encounter-level records representing inpatient hospitalizations.
- **Patients table**  
  Patient-level demographics, including age and gender.

A single patient may have **multiple admissions** over time.

---

## Unit of Analysis
**Unit of analysis = hospital admission (index admission)**

- Each row represents one hospital admission.
- The prediction question is:  
  > *Will this admission be followed by an unplanned readmission within 30 days?*
- Patients may appear multiple times if they have multiple admissions.
- Patient-level aggregation was intentionally not used, as readmission risk is assessed at each discharge event.

---

## Cohort Construction
The modeling cohort is constructed starting from the **admissions table**.

- Only patients with **at least one inpatient admission** are included.
- Patients without admissions are excluded by definition, as readmission requires an index hospitalization.

### Cohort Size Clarification
| Metric | Approximate Count |
|------|------------------|
| Unique patients with demographics | ~360K |
| Unique patients with admissions | ~223K |
| Total admission records | ~546K |

The difference between patient counts and admission counts reflects **repeat hospitalizations** for the same patient.

---

## Age Handling
- Patient age is derived from `patients.anchor_age`.
- The full age distribution was inspected prior to filtering.
- The final modeling cohort is restricted to **adults (anchor_age ≥ 18)**.

Pediatric cases were excluded intentionally, as pediatric and adult readmission patterns differ substantially in clinical drivers and care pathways.

---

## Admission Sequencing
Admissions are sorted chronologically by:
- `subject_id`
- `admittime`

For each admission, the following are derived:
- `next_hadm_id`
- `next_admission_type`
- `days_to_next` (time from discharge to next admission)

Only the **immediate subsequent admission** is considered when evaluating readmission.

---

## Readmission Label Definition
An admission is labeled as a **30-day unplanned readmission (`label_readmit_30d = 1`)** if **all** of the following conditions are met:

1. A subsequent admission exists
2. The subsequent admission occurs within **30 days**
3. The subsequent admission is **not ELECTIVE**
4. The index admission did **not end in death**

All other admissions are labeled as `0`.

This definition aligns with common CMS and healthcare quality reporting standards.

---

## Why Some Short Gaps Are Not Readmissions
A short time interval alone does not imply a readmission.

The following admission types are **explicitly excluded** from readmission labeling:

- **ELECTIVE**  
  Planned or scheduled admissions (e.g., surgeries, chemotherapy cycles)
- **DIRECT EMER.**  
  Emergency Department routing for administrative intake or bed assignment
- **Observation workflows**  
  Short stays that do not represent new inpatient episodes

### ED Routing Explanation
Some admissions pass through the Emergency Department as an operational pathway rather than due to acute clinical deterioration. These cases do not represent failures in care transitions and are therefore excluded.

---

## Handling Multiple Admissions per Patient
- All admissions for a patient are retained.
- Each admission is treated as a **new prediction opportunity**.
- Later admissions are not merged with or dropped due to prior admissions.

This reflects real-world hospital operations, where readmission risk is reassessed at every discharge.

---

## Interpretation of `days_to_next`
- `days_to_next = NaN` indicates **no observed subsequent admission** in the dataset.
- These admissions represent **right-censored observations**.
- They are correctly labeled as non-readmissions.

NaN values are not imputed or altered.

---

## Train / Validation / Test Split
To prevent patient-level data leakage:

- Data is split by **`subject_id`**, not by admission rows.
- All admissions for a patient belong to **exactly one split**.
- A stratified subject-level split is used to preserve readmission prevalence across splits.

Leakage check:
```python
(df.groupby("subject_id")["split"].nunique() > 1).sum() == 0
