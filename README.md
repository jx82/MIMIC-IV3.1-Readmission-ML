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

Below is an **updated README-style ML pipeline section** that incorporates the step you just realized you missed (**removing in-hospital deaths**) and aligns with the features you’ve already built (`diagnosis_count`, `procedure_count`, `icu_flag`, etc.).

You can paste this directly into your **project README**.

---

# Machine Learning Pipeline

## Overview

This project builds a **30-day hospital readmission prediction model** using the **MIMIC-IV dataset**.
The prediction unit is a **hospital admission (`hadm_id`)**, meaning each row in the modeling dataset represents **one hospitalization event**.

All features must therefore be aggregated at the **admission level** before training the model.

---

# Pipeline Structure

```text
Raw EHR Tables (MIMIC-IV)
        │
        ├── admissions
        ├── patients
        ├── diagnoses_icd
        ├── procedures_icd
        ├── icustays
        ├── labevents
        └── chartevents
                │
                ▼
Step 1 — Cohort Construction
Select eligible hospital admissions
                │
                ▼
Step 2 — Apply Cohort Filters
Remove admissions not eligible for readmission prediction
                │
                ▼
Step 3 — Generate Readmission Labels
Determine whether each admission is followed by a readmission within 30 days
                │
                ▼
Step 4 — Feature Engineering
Aggregate clinical information to admission level
                │
                ▼
Step 5 — Build Modeling Dataset
Create feature matrix X and label vector y
                │
                ▼
Step 6 — Model Training
Logistic Regression, Random Forest, XGBoost
                │
                ▼
Step 7 — Model Evaluation
ROC-AUC, feature importance, SHAP analysis
```

---

# Step 1 — Cohort Construction

The **admissions table** defines the base cohort.

Each row represents a **single hospital admission**:

| subject_id | hadm_id | admittime | dischtime |
| ---------- | ------- | --------- | --------- |

Prediction unit:

```text
1 row = 1 hospital admission
```

---

# Step 2 — Cohort Filters

Certain admissions are removed because they **cannot experience a future readmission**.

### Exclusion Criteria

1. **In-hospital deaths**

Patients who died during hospitalization cannot be readmitted.

Filtered using:

```python
hospital_expire_flag == 0
```

2. **(Optional) Hospice discharges**

Hospice patients are typically excluded in readmission studies.

3. **(Optional) Pediatric admissions**

Many readmission studies restrict to **adult patients**.

---

### Example Implementation

```python
admissions = admissions[admissions["hospital_expire_flag"] == 0]
```

---

# Step 3 — Readmission Label Construction

The target variable is:

```text
readmitted_30d
```

Definition:

```text
1 = patient readmitted within 30 days of discharge
0 = no readmission within 30 days
```

This is calculated by comparing:

* discharge time of the current admission
* admission time of the next hospitalization for the same patient.

---

# Step 4 — Feature Engineering

Clinical data from multiple tables are aggregated into **admission-level features**.

Example:

| Source Table   | Feature            |
| -------------- | ------------------ |
| diagnoses_icd  | diagnosis_count    |
| procedures_icd | procedure_count    |
| diagnoses_icd  | charlson_score     |
| icustays       | icu_flag           |
| admissions     | los_days           |
| admissions     | discharge_location |

---

## Tier 1 — Baseline Administrative Features

```text
age
gender
ethnicity
insurance
prior_admission_count
prior_30d_admits
admission_type
```

---

## Tier 2 — Clinical Burden & Care Intensity

```text
charlson_score
diagnosis_count
procedure_count
los_days
icu_flag
discharge_location
```

These features capture:

* chronic disease severity
* hospitalization complexity
* treatment intensity

---

## Tier 3 — Physiologic Signals (Advanced)

Future features derived from:

* vital signs
* laboratory results
* medication data
* temporal trends

Examples:

```text
vital_sign_summary
lab_summary
medication_count
lab_trend_features
```

---

# Step 5 — Modeling Dataset

After feature engineering, the final dataset is constructed.

Example structure:

| hadm_id | age | diagnosis_count | procedure_count | icu_flag | readmitted_30d |
| ------- | --- | --------------- | --------------- | -------- | -------------- |

Feature matrix and label vector:

```python
X = admissions[feature_columns]
y = admissions["readmitted_30d"]
```

---

# Step 6 — Model Training

Models used for comparison:

* Logistic Regression
* Random Forest
* XGBoost

These models balance:

* interpretability
* nonlinear modeling capability
* predictive performance

---

# Step 7 — Model Evaluation

Performance metrics:

* ROC-AUC
* Precision / Recall
* Feature importance
* SHAP interpretation

---

# Key Design Principles

### Admission-Level Aggregation

All features are aggregated to:

```text
hadm_id
```

to maintain consistent modeling units.

---

### Leakage Prevention

Features are constructed using only information **available during the admission**.

Future events are excluded.

---

### Interpretability

Feature design prioritizes **clinically interpretable variables**, allowing clinicians to understand the model predictions.

---

# Summary

The pipeline follows a structured workflow:

```text
Cohort Selection
        ↓
Cohort Filtering (remove deaths)
        ↓
Readmission Labeling
        ↓
Feature Engineering
        ↓
Model Dataset Creation
        ↓
Model Training & Evaluation
```

This approach ensures a **clean, leakage-free, admission-level dataset suitable for hospital readmission prediction**.

---

Great — a **visual pipeline diagram** will make your GitHub project look much more professional and easier for reviewers (recruiters, hiring managers, or collaborators) to understand.

Below is a **README-ready architecture diagram** plus a short explanation.

---

# Project Architecture

## Readmission Prediction Pipeline

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
                 Define prediction unit = hospital admission
                                │
                                ▼
                      Step 2 — Cohort Filtering
             Remove admissions not eligible for prediction
                       • in-hospital deaths
                       • (optional) hospice discharge
                       • (optional) pediatric patients
                                │
                                ▼
                     Step 3 — Readmission Label
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

---

# Feature Engineering Flow

This diagram explains **how raw tables become features**.

```text
diagnoses_icd.csv
        │
        ▼
 groupby(hadm_id)
        │
        ▼
diagnosis_count
        │
        ▼
merge → admissions cohort


procedures_icd.csv
        │
        ▼
 groupby(hadm_id)
        │
        ▼
procedure_count
        │
        ▼
merge → admissions cohort


icustays.csv
        │
        ▼
unique hadm_id
        │
        ▼
icu_flag
        │
        ▼
merge → admissions cohort
```

Final dataset:

```text
1 row = 1 hospital admission
```

---

# Final Modeling Table Example

| hadm_id | age | diagnosis_count | procedure_count | icu_flag | readmitted_30d |
| ------- | --- | --------------- | --------------- | -------- | -------------- |
| 20001   | 72  | 7               | 3               | 1        | 1              |
| 20005   | 64  | 3               | 1               | 0        | 0              |
| 20009   | 58  | 5               | 2               | 1        | 0              |

---

# Design Principles

### Admission-Level Aggregation

All features are computed at:

```text
hadm_id
```

because the prediction target is **readmission after a hospital admission**.

---

### Leakage Prevention

Features are built using only information **available during the admission**, avoiding future information leakage.

---

### Interpretability

The model uses clinically interpretable features such as:

* comorbidity burden
* care intensity
* discharge disposition

which allow clinicians to understand model predictions.

---

# Pipeline Summary

```text
Raw MIMIC Data
        ↓
Cohort Construction
        ↓
Remove In-Hospital Deaths
        ↓
Readmission Label Creation
        ↓
Feature Engineering (Tier 1 → Tier 2 → Tier 3)
        ↓
Model Training
        ↓
Evaluation & Interpretation
```

---

💡 **Next improvement (very helpful for GitHub):**

I can also give you a **much nicer diagram version used in research papers** like this:

```
Raw EHR → Cohort → Feature Store → ML Model → Evaluation
```

It looks **much cleaner and more “data science portfolio ready.”**

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

## Cohort Overview and Data Splits

The final cohort consisted of **546,028 index admissions** with **11 variables**. Admissions were split at the **patient (subject) level** into training, validation, and test sets to prevent information leakage across encounters.

| Split | Admissions (n) | Readmission Prevalence | Positive Cases |
|------|---------------:|-----------------------:|---------------:|
| Training (working sample) | 382,595 | 0.193 | 73,909 |
| Validation | 81,303 | 0.193 | 15,722 |
| Test | 82,130 | 0.193 | 15,870 |

The **training set (n = 382,595)** served as the **working sample** for all exploratory analysis, feature engineering, and model fitting. The validation set was used for model selection and tuning, while the test set was reserved for final, unbiased performance evaluation.


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

## Stratification, Modeling, and Analytical Roadmap

### Stratification Strategy
Because 30-day readmission is a **class-imbalanced outcome**, a **stratified subject-level split** is used.

- Stratification is performed at the **patient (subject) level**, based on whether a patient ever experienced a readmission.
- This preserves **readmission prevalence** across training, validation, and test sets.
- All admissions for a given patient are assigned to the **same split**, preventing patient-level data leakage.
- Admission-level label balance may vary slightly due to differing numbers of admissions per patient.

This approach balances **evaluation stability** with **strict leakage prevention**, which is critical in healthcare modeling.

---
## Prior Hospital Utilization Features (6–12 Month Look-back)

This project derives Tier-1 prior utilization features from **MIMIC-IV `hosp.admissions`** to capture recent and historical hospital use while avoiding feature redundancy.

---

### Variables

- **`admits_past_6m`**  
  Number of inpatient hospital admissions for the same patient (`subject_id`) occurring within **180 days** prior to the index admission’s `admittime`.

- **`admits_past_12m`**  
  Number of inpatient hospital admissions for the same patient occurring within **365 days** prior to the index admission’s `admittime`.

These two variables are **overlapping by definition**, because the 6-month window is fully contained within the 12-month window:


Including both `admits_past_6m` and `admits_past_12m` directly in a regression-style model can introduce **multicollinearity**, leading to unstable coefficients and reduced interpretability.

---

### Collinearity Handling: Decomposition into Non-Overlapping Windows

To reduce redundancy while preserving temporal information, we decompose the 12-month count into two components:

- **Recent utilization:** `admits_past_6m`
- **Earlier utilization:** `admits_6to12m` (admissions occurring **6–12 months** prior)

admits_6to12m = admits_past_12m − admits_past_6m

This approach:
- Removes deterministic overlap between features  
- Preserves clinically meaningful timing of utilization  
- Improves stability and interpretability in linear and logistic models  

### Correlation Between Prior Utilization Features

After decomposing prior hospital utilization into recent (past 6 months) and earlier (6–12 months) windows, we examined the correlation between the two variables:

|                    | admits_past_6m | admits_6to12m |
|--------------------|---------------:|--------------:|
| **admits_past_6m** | 1.000          | 0.537         |
| **admits_6to12m**  | 0.537          | 1.000         |

A moderate correlation remains because patients with recent hospital utilization are more likely to have had admissions earlier in the year as well. This correlation reflects **true patient**


---


### Admission-Level Modeling and Use of Prior Admissions

Although each patient (`subject_id`) may have multiple hospital admissions, the model is trained and evaluated at the **admission level**. Each row in the modeling dataset represents a single **index admission**, for which the model predicts the probability of 30-day readmission following discharge.

Prior admissions for the same patient are **not used as prediction rows**. Instead, they are used exclusively to derive historical utilization features (e.g., admissions in the past 6 months or 6–12 months) for the index admission. All such features are computed using admission timestamps strictly preceding the index admission to prevent temporal leakage.

### Illustration: How Prior Admissions Are Used in Admission-Level Modeling

Although each patient (`subject_id`) may have multiple hospital admissions, the model is trained and evaluated at the **admission level**. Each row in the modeling dataset represents a single **index admission**, and the prediction target corresponds to the outcome following that admission (e.g., 30-day readmission).

Prior admissions are **never used as prediction rows** for the same index admission. Instead, they are used **only to derive historical utilization features** for the index admission.

---

#### Example Patient Timeline

**Raw admissions table**

| subject_id | hadm_id | admittime   |
|-----------:|--------:|-------------|
| 101        | A1      | 2019-01-01  |
| 101        | A2      | 2019-06-01  |
| 101        | A3      | 2020-01-10  |

---

#### Admission-Level Modeling View

Each admission becomes its own modeling row. Historical features are computed using **only admissions that occurred before the index admission**.

| hadm_id (index) | admits_past_6m | admits_6to12m | label (30-day readmission) |
|----------------:|---------------:|--------------:|---------------------------:|
| A1              | 0              | 0             | readmit_30d(A1)            |
| A2              | 1              | 0             | readmit_30d(A2)            |
| A3              | 0              | 1             | readmit_30d(A3)            |

---

#### Key Points

- Each row corresponds to a **current (index) admission**.
- `admits_past_6m` counts admissions within 180 days **before** the index admission.
- `admits_6to12m` counts admissions occurring 6–12 months **before** the index admission.
- Prior admissions (e.g., A1, A2) are used **only as feature history** for later admissions and are **never used to predict outcomes for other rows**.
- This design prevents temporal leakage and aligns with standard readmission modeling practice.

---

#### Summary

> Even though a patient may have multiple admissions, predictions are always made at the admission level. Historical admissions contribute information to feature construction, but the model’s prediction target is always tied to the current admission only.


---


### Modeling Approach
Baseline machine learning models include:
- **Random Forest**
- **XGBoost**

#### Modeling Characteristics
- Predictions are made at the **admission level**.
- Patients may appear multiple times due to repeat admissions.
- Repeated patients are **expected and appropriate**, as readmission risk is reassessed at every discharge.
- Patient-level leakage is prevented through **subject-based splitting**.

These models serve as **baseline performance benchmarks** prior to incorporating higher-impact clinical features.

---

### Model Interpretation and Explainability (Planned)
Planned explainability methods include:
- Feature importance analysis (tree-based models)
- SHAP value analysis
- Partial dependence plots for key risk factors

These methods will be used to:
- Validate **clinical plausibility**
- Improve **model transparency**
- Support **trustworthy deployment**

Interpretability tools are applied for **insight and validation**, not to imply causal relationships.


---

### Future Work: Causal Inference Extension
While the current models are **predictive**, future work will explore **causal inference questions**, such as:

- Does longer length of stay causally reduce readmission risk?
- Do certain discharge dispositions reduce unplanned returns?
- Are high-utilization patterns a cause of readmission or a marker of underlying patient complexity?

#### Planned Methods
Potential causal approaches include:
- Propensity score matching or weighting
- Targeted Maximum Likelihood Estimation (TMLE)
- Doubly robust estimators
- Sensitivity analysis for unmeasured confounding

#### Important Note
Causal inference analyses will be conducted **separately from predictive modeling**, with explicit assumptions and limitations clearly documented.  
**No causal claims are made in the current version of this project.**

---

### What This Project Does Not Claim
For transparency, this project does **not**:
- Estimate patient-lifetime readmission risk
- Perform survival or recurrent-event modeling
- Model pediatric readmissions
- Predict elective admissions
- Make causal claims without formal identification strategies

---

### Key Takeaway
> *This project models 30-day unplanned readmission risk at the admission level using clinically aligned definitions, leakage-safe patient-level splitting, stratified evaluation, and a clear roadmap toward interpretable and causal healthcare analytics.*


| Notebook | Purpose |
|--------|--------|
| **00_setup.ipynb** | Step 0 — Project setup, imports, paths, random seeds, and global configuration |
| **01_cohort.ipynb** | Steps 1–3 — Load raw data, define cohort & labels, and perform patient-level train/validation/test split |
| **02_features.ipynb** | Steps 4–5 — Define working sample, feature lists, and perform feature engineering |
| **03_modeling.ipynb** | Steps 6–11 — Build preprocessing pipelines, train models, validate performance, compare feature sets, and evaluate on test data |
| **04_diagnostics.ipynb** | Step 12 — Model diagnostics, interpretation, calibration, and error analysis |
| **README.md** | Pipeline overview, results summary, and key findings |


## 🧱 Data Architecture: Why We Separate Cohort, Labels, and Features

This project follows a modular, production-style ML pipeline where:

- **Cohort (S + Y)** defines the study population and outcome.
- **Features (X)** define the model inputs.
- The modeling stage consumes both artifacts without modifying them.

Separating these components improves reproducibility, prevents leakage, and mirrors real-world ML system design.

---

### 1️⃣ Cohort (S + Y)

**Location:** `data/processed/mimic_readmission_cohort.csv`

The cohort table defines:

- `hadm_id`
- `subject_id`
- Admission & discharge timestamps
- `label_readmit_30d`
- `split` (train / validation / test)

**Purpose**

The cohort answers:

> Who is included in the study and what was the outcome?

This is study design logic — not feature engineering.

The cohort should remain stable unless:

- Inclusion criteria change  
- Label logic changes  
- Data split strategy changes  

---

### 2️⃣ Features (X)

**Location:** `data/features/mimic_readmission_features.parquet`

The feature table contains:

- Demographics (e.g., age)
- Utilization history
- Engineered temporal signals
- Derived model inputs

**Purpose**

The feature table answers:

> What information is available at prediction time?

Features must:

- Be timestamp-safe  
- Avoid future information  
- Exclude the target label  
- Exclude split indicators  

---

### 🚫 Why We Do NOT Combine Them

#### Prevent Data Leakage

Keeping `label_readmit_30d` outside the feature table ensures:

- The model never accidentally trains on the target.
- Split information does not leak into training.
- Feature engineering remains prediction-time safe.

---

#### Enable Modular Development

This structure allows:

- Updating feature logic without recreating the cohort.
- Testing multiple feature sets against the same cohort.
- Running alternative models without redefining labels.

---

#### Improve Reproducibility

Each pipeline stage produces a deterministic artifact:

| Stage | Output |
|-------|--------|
| Step 3 | Cohort (S + Y) |
| Step 4 | Features (X) |
| Step 5 | Model artifacts |

Downstream steps read artifacts from disk rather than relying on notebook memory.

---

#### Mirror Production ML Systems

In real-world ML systems:

- Label construction is separate from feature computation.
- Features are stored independently.
- Models consume standardized inputs.

This project mirrors that architecture intentionally.

---

### 🧠 Modeling Workflow

During training:

```python
X = features_df
y = cohort["label_readmit_30d"]

```

## 🧱 Tier 1 Features — Baseline Model

Tier 1 features form the foundational baseline model.  
They include simple, high-signal variables that are fully available at or before discharge and require minimal feature engineering.

The purpose of Tier 1 is to establish a strong, leakage-safe performance baseline before introducing more complex clinical features in later tiers.

---

### 📊 Tier 1 Feature Set

| Feature | Description | Why It Matters |
|----------|-------------|----------------|
| `age_at_admission` | Patient age at index admission | Age is one of the strongest and most stable predictors of readmission risk |
| `gender` | Patient biological sex | Captures baseline demographic differences |
| `los_days` | Length of stay for index admission | Proxy for illness severity and hospitalization complexity |
| `prior_admission_count` | Total number of admissions before index admission | Measures long-term healthcare utilization intensity |
| `prior_30d_admits` | Admissions within 30 days prior to index admission | Captures short-term instability and acute deterioration |

---

### 🎯 Design Principles

Tier 1 features are intentionally:

- Leakage-safe  
- Timestamp-aware  
- Low engineering complexity  
- Clinically interpretable  
- Strong baseline predictors  

No diagnosis groupings, comorbidity indices, ICU flags, medication counts, or discharge disposition variables are included at this stage.

---

### 🧠 Modeling Objective

Tier 1 answers the question:

> How well can we predict 30-day readmission using only demographics and prior utilization history?

This baseline provides a reference point for measuring incremental performance gains from more advanced feature tiers.

---

### 📈 Expected Signal

Utilization-based variables (`prior_admission_count`, `prior_30d_admits`) are typically among the strongest predictors of readmission.  
Tier 2 will evaluate whether additional clinical severity features improve performance beyond this baseline.

Here is a **clean README version** you can put directly in your **GitHub repository or documentation folder** for your MIMIC readmission project.

---

# Charlson Comorbidity Index vs Diagnosis Count

## Overview

In healthcare predictive modeling, especially for **hospital readmission prediction**, two commonly used features that capture **patient disease burden** are:

* **Diagnosis Count**
* **Charlson Comorbidity Index (CCI)**

Although both relate to patient diagnoses, they measure **different aspects of clinical risk**. Using both features together improves model performance and interpretability.

---

# 1. Diagnosis Count

## Definition

Diagnosis Count measures the **total number of diagnosis codes (ICD-9 or ICD-10)** assigned to a patient during a hospital admission.

```text
diagnosis_count = number of diagnosis codes for an admission
```

These diagnoses include:

* Primary diagnosis
* Secondary diagnoses
* Complications discovered during hospitalization

---

## Example

| ICD Code | Condition      |
| -------- | -------------- |
| J18.9    | Pneumonia      |
| I10      | Hypertension   |
| E78.5    | Hyperlipidemia |
| K21.9    | GERD           |
| M54.5    | Low back pain  |
| E11.9    | Diabetes       |

```
diagnosis_count = 6
```

---

## Interpretation

Diagnosis count captures **clinical complexity**.

Higher diagnosis counts often indicate:

* multiple comorbid conditions
* complicated treatment
* increased care coordination
* higher readmission risk

Example interpretation:

| Diagnosis Count | Clinical Meaning    |
| --------------- | ------------------- |
| 1–2             | Low complexity      |
| 3–5             | Moderate complexity |
| 6+              | High complexity     |

---

# 2. Charlson Comorbidity Index (CCI)

## Definition

The **Charlson Comorbidity Index** measures **severity of chronic diseases** known to increase mortality risk.

Unlike diagnosis count, Charlson **does not count every diagnosis**.
It only includes **a predefined list of serious chronic diseases**.

Each condition is assigned a **weight** based on its mortality risk.

---

## Example Charlson Conditions

| Condition                | Weight |
| ------------------------ | ------ |
| Myocardial infarction    | 1      |
| Congestive heart failure | 1      |
| COPD                     | 1      |
| Diabetes                 | 1      |
| Moderate renal disease   | 2      |
| Cancer                   | 2      |
| Severe liver disease     | 3      |
| Metastatic cancer        | 6      |
| HIV/AIDS                 | 6      |

Charlson score is the **sum of all condition weights**.

---

## Example Patient

Suppose a patient has the following diagnoses:

| ICD Code | Condition      | Charlson Included |
| -------- | -------------- | ----------------- |
| J18.9    | Pneumonia      | No                |
| I10      | Hypertension   | No                |
| E78.5    | Hyperlipidemia | No                |
| K21.9    | GERD           | No                |
| M54.5    | Low back pain  | No                |
| E11.9    | Diabetes       | Yes (weight = 1)  |

Result:

```
diagnosis_count = 6
charlson_score = 1
```

Although the patient has **six diagnoses**, only **diabetes** is included in the Charlson index.

---

# Key Differences

| Feature         | Measures                     | Interpretation              |
| --------------- | ---------------------------- | --------------------------- |
| Diagnosis Count | Number of diagnoses          | Overall clinical complexity |
| Charlson Score  | Severity of chronic diseases | Mortality risk              |

Example comparison:

| Patient   | Diagnosis Count   | Charlson Score |
| --------- | ----------------- | -------------- |
| Patient A | 6 minor diagnoses | 1              |
| Patient B | 2 severe diseases | 6              |

Patient B has **higher clinical risk**, even with fewer diagnoses.

---

# Why Models Use Both Features

Modern healthcare predictive models often include both variables because they capture **different signals**.

### Diagnosis Count captures

* coding complexity
* disease burden
* clinical workload
* multi-condition patients

### Charlson Index captures

* severity of chronic disease
* long-term health risk
* mortality risk

Using both features improves:

* predictive accuracy
* model interpretability
* clinical relevance

---

# Usage in Readmission Models

In a typical **hospital readmission prediction model**, these features appear in the **Clinical Burden (Tier 2)** group.

Example feature set:

```text
Tier 2 — Clinical Burden

charlson_score
diagnosis_count
procedure_count
los_days
icu_flag
```

These variables represent:

* chronic disease severity
* hospitalization complexity
* care intensity

---

# Key Takeaway

Diagnosis Count and Charlson Index are **complementary features**:

* **Diagnosis Count → complexity**
* **Charlson Index → severity**

Together they provide a more complete picture of patient health and are widely used in **hospital analytics, payer risk models, and readmission prediction systems**.

---

If you want, I can also give you a **very professional README section for your entire Tier-2 feature block**, including:

* Charlson
* diagnosis_count
* procedure_count
* ICU indicators
* LOS

This would look **very strong in your GitHub portfolio for healthcare data science roles**.

Here is a **clean README section** explaining the ML pipeline and the reason for the confusion. You can paste this directly into your **project documentation or GitHub README**.

---

# Machine Learning Pipeline and Feature Merging Strategy

## Overview

In this project, the prediction task is **30-day hospital readmission prediction**.
The fundamental modeling unit is a **hospital admission**.

This means:

```text
1 row in the modeling dataset = 1 hospital admission (hadm_id)
```

Because of this design, all engineered features must eventually be aligned at the **admission level**.

---

# ML Pipeline Structure

The machine learning pipeline follows a structured workflow that separates **cohort creation**, **feature engineering**, and **model training**.

```
Raw EHR Tables
    │
    ├── patients
    ├── admissions
    ├── diagnoses_icd
    ├── procedures_icd
    ├── chartevents
    └── labevents
          │
          ▼
Step 1 — Cohort Construction
(admissions table becomes prediction unit)
          │
          ▼
Step 2 — Feature Engineering
aggregate clinical tables into admission-level features
          │
          ▼
Step 3 — Feature Dataset
cohort + engineered features
          │
          ▼
Step 4 — Modeling Dataset
X = feature matrix
y = readmission label
          │
          ▼
Step 5 — Model Training
(Logistic Regression, Random Forest, XGBoost)
```

---

# Why Features Are Merged Into the Cohort Table

During feature engineering, information from multiple EHR tables must be **aggregated to the admission level** before modeling.

Example:

**Diagnoses Table**

| subject_id | hadm_id | icd_code |
| ---------- | ------- | -------- |
| 1001       | 20001   | I50.9    |
| 1001       | 20001   | E11.9    |
| 1001       | 20001   | N18.3    |

This table contains **multiple rows per admission**.

To convert this information into a modeling feature, we aggregate it:

```
diagnosis_count = number of diagnosis codes per hadm_id
```

Result:

| hadm_id | diagnosis_count |
| ------- | --------------- |
| 20001   | 3               |
| 20005   | 5               |

This feature is then merged into the **cohort (admissions) table**.

---

# Cohort After Feature Engineering

| hadm_id | age | diagnosis_count | charlson_score | readmitted_30d |
| ------- | --- | --------------- | -------------- | -------------- |
| 20001   | 72  | 7               | 4              | 1              |
| 20005   | 74  | 3               | 1              | 0              |

At this stage, we have a **complete feature dataset aligned at the admission level**.

---

# Creating the Model Inputs

Only after all features are added do we create the model inputs:

```python
feature_cols = [
    "age",
    "diagnosis_count",
    "charlson_score",
    "los_days",
    "icu_flag"
]

X = admissions[feature_cols]
y = admissions["readmitted_30d"]
```

Here:

* **X** = feature matrix
* **y** = prediction target

---

# Why the Confusion Happens

The confusion often arises because in some notebooks **`X` is created early as a copy of the cohort table**.

Example:

```python
X = cohort.copy()
```

Then features are added directly:

```python
X = X.merge(charlson_table, on="hadm_id", how="left")
```

Conceptually, this is equivalent to merging features into the **cohort table**, but the variable name (`X`) makes it appear as if features are being added to the modeling matrix prematurely.

---

# Recommended Naming for Clarity

To avoid confusion, many production pipelines use this structure:

```
cohort
   ↓
features
   ↓
model_dataset
   ↓
X / y
```

Example:

```python
features = cohort.copy()

features = features.merge(diagnosis_count, on="hadm_id", how="left")
features = features.merge(charlson_table, on="hadm_id", how="left")

X = features[feature_columns]
y = features[target]
```

This makes the workflow clearer and separates **feature engineering** from **model input construction**.

---

# Key Takeaway

In healthcare machine learning pipelines:

* The **cohort table defines the prediction unit** (one row per admission).
* All features must be **aggregated to that same level**.
* Features are usually merged into the **cohort table first**, and the modeling matrix `X` is created afterward.

Diagnosis count, Charlson score, and other clinical features therefore follow the same process:

```
raw clinical table
        ↓
aggregate by hadm_id
        ↓
merge into cohort
        ↓
construct X and y
```

This structure ensures consistent data alignment, avoids duplicated records, and produces a clean feature dataset for model training.

---

# Missing Data Strategy for Physiologic Features

## 1. Why Missing Data Matters in This Project

In this readmission prediction project, some Tier 3 physiologic variables such as SpO2, heart rate, respiratory rate, and blood pressure are derived from `chartevents`.

These variables may have high missingness because chart-event monitoring is not equally available for all admissions. For example, SpO2 values are often collected mainly for ICU or closely monitored patients. Therefore, missingness is not always a random data quality problem. It may reflect a real clinical process:

> Patients without charted SpO2 values may be non-ICU or lower-acuity patients who were not continuously monitored.

This type of missingness is called **informative missingness**.

---

## 2. Why We Do Not Drop Missing Rows

A simple approach would be:

```python
cohort = cohort.dropna()
````

However, this is not appropriate here because SpO2 and other chart-event variables may be missing for a large portion of admissions.

Dropping rows with missing physiologic values would:

* remove many non-ICU patients
* reduce sample size dramatically
* bias the dataset toward ICU patients
* make the final model less representative of hospital admissions

Therefore, we keep these patients and handle missingness explicitly.

---

## 3. Why We Use Imputation

Many machine learning models cannot accept missing values directly.

For example:

| Model                                    | Can Handle NaN Directly? | Need Imputation? |
| ---------------------------------------- | -----------------------: | ---------------: |
| Logistic Regression                      |                       No |              Yes |
| Decision Tree / Random Forest in sklearn |               Usually no |              Yes |
| XGBoost                                  |                      Yes |         Optional |

For logistic regression, decision tree, and random forest, missing values must be filled before modeling.

Median imputation is commonly used because it is simple, stable, and less sensitive to outliers than mean imputation.

Example:

```python
median_spo2 = X_train["spo2_mean"].median()

X_train["spo2_mean"] = X_train["spo2_mean"].fillna(median_spo2)
X_val["spo2_mean"] = X_val["spo2_mean"].fillna(median_spo2)
X_test["spo2_mean"] = X_test["spo2_mean"].fillna(median_spo2)
```

---

## 4. Why Median Imputation Alone Is Not Enough

Median imputation alone can be misleading.

If SpO2 is mostly observed among ICU patients, then the median SpO2 comes mainly from monitored patients. Filling non-ICU missing values with the ICU median does not mean those patients truly had that oxygen saturation.

Therefore, the imputed value should be interpreted as a **computational placeholder**, not as a real measured value.

---

## 5. Why We Add Missingness Flags

To preserve the information contained in missingness, we create missing indicators before imputation.

Example:

```python
X_train["spo2_mean_missing"] = X_train["spo2_mean"].isna().astype(int)
X_val["spo2_mean_missing"] = X_val["spo2_mean"].isna().astype(int)
X_test["spo2_mean_missing"] = X_test["spo2_mean"].isna().astype(int)
```

Then we impute the numeric value.

This allows the model to distinguish between:

| Patient Type                      | SpO2 Value | Missing Flag | Meaning                      |
| --------------------------------- | ---------: | -----------: | ---------------------------- |
| ICU patient with real SpO2        |         89 |            0 | true low oxygen saturation   |
| ICU patient with normal SpO2      |         96 |            0 | true measured normal value   |
| non-ICU patient with missing SpO2 | 96 imputed |            1 | value was not truly measured |

The missing flag tells the model:

> This value was imputed, not observed.

This is especially important in healthcare data because missingness may reflect clinical decisions, monitoring intensity, or illness severity.

---

## 6. Difference Across Models

### Logistic Regression

Logistic regression cannot handle missing values directly. It also assumes a mostly linear relationship between features and outcome.

Therefore, for logistic regression we need:

* median imputation
* missingness flags
* optional clinically meaningful interaction terms

Example:

```python
spo2_mean
spo2_mean_missing
icu_flag
icu_flag * spo2_mean
```

The missing flag helps logistic regression separate patients with real SpO2 values from patients whose values were imputed.

---

### Decision Tree and Random Forest

Scikit-learn decision trees and random forests usually require complete numeric input, so imputation is still needed.

Tree models can learn nonlinear relationships and interactions more naturally than logistic regression, but missing flags are still useful because they preserve information about whether the value was originally observed.

Recommended approach:

* median imputation
* missingness flags
* usually no need for manual interaction terms

---

### XGBoost

XGBoost can handle missing values internally. It can learn a default direction for missing values during tree splitting.

Therefore, XGBoost does not strictly require median imputation.

However, for this project, we may still use the same imputed dataset with missingness flags for all models to make model comparison cleaner.

Using the same preprocessing pipeline helps ensure that performance differences are due to model structure, not different missing-data handling.

---

## 7. When to Create Missing Flags

Missing flags can be created before or after splitting because they are row-level transformations.

Safe before split:

```python
cohort["spo2_mean_missing"] = cohort["spo2_mean"].isna().astype(int)
```

This does not use information from other patients.

---

## 8. When to Impute Missing Values

Imputation should be done **after train / validation / test split**.

The imputation value should be learned from the training data only.

Correct workflow:

```python
median_spo2 = X_train["spo2_mean"].median()

X_train["spo2_mean"] = X_train["spo2_mean"].fillna(median_spo2)
X_val["spo2_mean"] = X_val["spo2_mean"].fillna(median_spo2)
X_test["spo2_mean"] = X_test["spo2_mean"].fillna(median_spo2)
```

Incorrect workflow:

```python
median_spo2 = cohort["spo2_mean"].median()
cohort["spo2_mean"] = cohort["spo2_mean"].fillna(median_spo2)
```

This is incorrect because it uses validation and test data to calculate the median, which creates preprocessing leakage.

---

## 9. Why Imputation After Split Prevents Leakage

The test set represents future unseen patients.

If we calculate the median using the full dataset before splitting, then the training process indirectly uses information from validation and test patients.

This violates the real-world prediction setting.

In production, the hospital would only have historical training data available when building the model. Future patients should not influence preprocessing decisions.

Therefore:

> Any transformation that learns a population-level statistic must be fit on the training set only.

Examples include:

* median imputation
* mean imputation
* standardization
* normalization
* PCA
* SMOTE
* feature selection

---

## 10. Recommended Strategy for This Project

For Tier 3 physiologic variables, this project uses the following strategy:

1. Create missingness flags for variables with meaningful missingness.
2. Split the data into train, validation, and test sets at the subject level.
3. Fit median imputation using the training set only.
4. Apply the same imputation values to validation and test sets.
5. Use the processed data for logistic regression, decision tree, random forest, and XGBoost.
6. Document missingness as clinically informative rather than purely random.

---

## 11. Example Code

```python
# ------------------------------------------------------------
# Missing Data Strategy for Physiologic Features
# ------------------------------------------------------------

physio_cols = [
    "spo2_mean",
    "spo2_min",
    "heart_rate_mean",
    "resp_rate_mean",
    "sbp_min"
]

# 1. Create missingness flags
for col in physio_cols:
    X_train[f"{col}_missing"] = X_train[col].isna().astype(int)
    X_val[f"{col}_missing"] = X_val[col].isna().astype(int)
    X_test[f"{col}_missing"] = X_test[col].isna().astype(int)

# 2. Fit imputation values on training data only
imputation_values = {}

for col in physio_cols:
    imputation_values[col] = X_train[col].median()

# 3. Apply training-set medians to train, validation, and test
for col in physio_cols:
    X_train[col] = X_train[col].fillna(imputation_values[col])
    X_val[col] = X_val[col].fillna(imputation_values[col])
    X_test[col] = X_test[col].fillna(imputation_values[col])
```

---

## 12. Project Interpretation

In this project, missing physiologic values are treated as clinically meaningful. For ICU-related chart-event variables, missingness may indicate that the patient was not in an ICU or did not require intensive monitoring.

Median imputation is used only to make the dataset usable for machine learning models. Missingness flags are added so that the model can distinguish observed physiologic values from imputed placeholders.

This approach preserves sample size, avoids excluding non-ICU patients, reduces bias, and supports fair comparison across logistic regression, decision tree, random forest, and XGBoost models.

---

# ============================================================
# Step 4 Summary: Master Feature Dataset Completed
# ============================================================

## Purpose

By the end of Step 4, we created the master admission-level feature dataset for readmission modeling.

Each row represents one hospital admission (`hadm_id`), with patient identifier (`subject_id`) retained for subject-level splitting.

This dataset includes:

- Tier 1 administrative baseline features
- Tier 2 clinical burden and care intensity features
- Tier 3 lab, vital sign, and medication features
- the target outcome: `label_readmit_30d`
- audit variables used to validate label creation

---

## Important Modeling Rule

The Step 4 dataset is NOT yet the final machine learning matrix.

It is a master modeling table used for:

- validation
- audit trail
- reproducibility
- subject-level train / validation / test split
- later error analysis

Therefore, we keep key identifiers and audit variables in Step 4.

---

## Variables Kept in Step 4 But Excluded From Modeling

The following variables are kept in the Step 4 master dataset but must NOT be used as model predictors:

### Identifiers

- `subject_id`
- `hadm_id`

Reason:

These are needed for splitting and tracing admissions, but should not be learned by the model.

### Label construction / leakage variables

- `next_admittime`
- `days_to_next_admit`

Reason:

These variables were used to create `label_readmit_30d`.

They contain future information and would create target leakage if used as predictors.

### Raw timestamp variables

- `admittime`
- `dischtime`
- `edregtime`
- `edouttime`
- `deathtime`

Reason:

Raw datetime values are not directly used in modeling.

If needed, they should first be converted into derived features such as weekend admission, night admission, or ED length of stay.

### Cohort audit variables

- `hospital_expire_flag`
- `hospice_flag`

Reason:

These were used for cohort validation / exclusion logic and should not be used as predictors in the final model.

### Raw categorical variables replaced by grouped versions

- `race`
- `insurance`
- `admission_type`
- `discharge_location`

Reason:

Grouped versions are more stable and modeling-friendly:

- `race_grouped`
- `insurance_grouped`
- `admission_type_grouped`
- `discharge_group`

---

## Tier 3 Missingness Strategy

Lab and vital sign variables were aggregated to admission level using summary statistics such as:

- minimum
- maximum
- mean
- last value

Example:

- `creatinine_min`
- `creatinine_max`
- `creatinine_mean`
- `creatinine_last`

Chart-event variables such as SpO2 may have high missingness because they are often collected mainly for ICU or closely monitored patients.

Therefore, missingness is treated as clinically informative rather than only as a data quality problem.

Missingness flags such as:

- `spo2_missing_flag`
- `heart_rate_missing_flag`
- `resp_rate_missing_flag`

are retained as model features.

Median imputation should be done later in Step 5, after train / validation / test splitting, using the training set only.

---

## Why Imputation Happens in Step 5

Imputation should not be fit on the full Step 4 dataset.

If we calculate medians before splitting, then validation and test patients influence preprocessing.

That would create preprocessing leakage.

Correct logic:

1. Split the data by `subject_id`
2. Fit imputation values on `X_train` only
3. Apply the same imputation values to `X_val` and `X_test`

This simulates real-world deployment, where future patients are not available when the model is trained.

---

## Step 4 Output

The Step 4 output should be saved as a complete master feature table.

This table should still include:

- `subject_id`
- `hadm_id`
- `label_readmit_30d`
- `next_admittime`
- `days_to_next_admit`

These variables are useful for audit and reproducibility, but will be excluded from `X` in Step 5.

---

## Transition to Step 5

In Step 5, we will:

1. Load the Step 4 master dataset
2. Split admissions by `subject_id`
3. Separate predictors `X` from target `y`
4. Exclude identifiers and leakage variables
5. Fit preprocessing using training data only
6. Train baseline models:
   - Logistic Regression
   - Decision Tree
   - Random Forest
   - XGBoost
7. Evaluate models on validation and test sets


# Step 5 — Modeling Data Preparation & Leakage Prevention

This step prepares the final feature-engineered cohort for machine learning modeling while ensuring **strict leakage prevention**.

In healthcare prediction tasks, avoiding data leakage is critical because the goal is to simulate **real-world prediction at discharge time**. Any information unavailable at discharge must be excluded from model training.

---

# Why Leakage Awareness Matters

In a hospital setting, the model is expected to answer:

> **“At discharge, what is this patient's risk of readmission within 30 days?”**

Therefore, the model can only use information that is known **on or before discharge**.

If future information accidentally enters the model, performance becomes artificially inflated and clinically unrealistic.

For example:

❌ Wrong approach:

Using the patient's **future admission date** to predict readmission.

```python
days_to_next_admit
```

This variable directly contains the answer.

A model trained with this feature would appear highly accurate but would fail in production because hospitals do not know future admissions.

---

# Leakage Prevention Principle

A feature is considered **leakage** if it:

- occurs **after discharge**
- contains **future information**
- is directly involved in **outcome creation**
- would be unavailable in a real hospital workflow

Our project follows a strict rule:

> **Only information available at or before discharge may enter the model.**

---

# Step 5 Pipeline Overview

The following workflow was used to prepare modeling datasets.

```text
Step 4 Final Features
        ↓
Step 5A Load Dataset
        ↓
Step 5B Remove Leakage Variables
        ↓
Step 5C Define Target (Y)
        ↓
Step 5D Subject-Level Split
        ↓
Step 5E Final Predictor Cleanup
        ↓
Step 5F Feature Type Identification
        ↓
Step 5G Missing Value Imputation
        ↓
Step 5H Categorical Encoding
        ↓
Step 5I Scaling (Optional)
        ↓
Step 5J Preprocessing Pipeline
        ↓
Step 5K Save Modeling Datasets
```

---

# Step 5B — Remove Leakage Variables

## Purpose

Remove variables containing **future information** or unavailable at discharge.

These variables are excluded **before modeling begins**.

### Variables Removed

| Variable | Why Dropped |
|----------|--------------|
| `next_admittime` | Future hospital admission |
| `next_hadm_id` | Future admission identifier |
| `days_to_next_admit` | Directly derived from outcome |
| `next_admission_type` | Future hospitalization context |
| `deathtime` | Post-discharge event |

### Why `deathtime` Was Dropped

`deathtime` is mostly missing in MIMIC-IV because only deceased patients have a value.

Since our cohort excludes in-hospital deaths:

```python
hospital_expire_flag == 0
```

Nearly all values are missing by design.

Additionally, death time would not be known at discharge, making it inappropriate for prediction.

---

# Step 5C — Define Outcome Variable

The prediction target is:

```python
label_readmit_30d
```

Definition:

```text
1 = readmitted within 30 days
0 = no readmission within 30 days
```

This variable remains in the dataset until final feature matrix creation.

---

# Step 5D — Subject-Level Split (Leakage Prevention)

## Why Subject-Level Splitting Matters

Patients in MIMIC-IV may have **multiple admissions**.

If admission rows are randomly split:

```text
Patient A Admission 1 → Training
Patient A Admission 2 → Test
```

The model indirectly sees the same patient in both datasets.

This creates **patient leakage**.

### Correct Approach

We split using:

```python
subject_id
```

via:

```python
GroupShuffleSplit()
```

This guarantees:

> **No patient appears in both training and test datasets.**

This design better simulates real-world deployment.

---

# Step 5E — Final Predictor Cleanup

After splitting is complete, we create the final predictor matrix (**X**).

## Variables Removed in Step 5E

### IDs

Removed because they uniquely identify patients rather than represent clinical information.

```python
subject_id
hadm_id
```

---

### Outcome Variable

Removed from predictors to prevent target leakage.

```python
label_readmit_30d
```

---

### Administrative / Timestamp Variables

These are useful for auditing but not meaningful predictors.

```python
admittime
dischtime
edregtime
edouttime
admit_provider_id
hospital_expire_flag
```

---

### Raw Duplicate Variables

Raw variables are removed **only if engineered versions exist**.

Example:

```python
race → removed
race_grouped → retained
```

```python
insurance → removed
insurance_grouped → retained
```

```python
discharge_location → removed
discharge_location_clean → removed
discharge_grouped → retained
```

Why?

Grouped variables:

- reduce sparsity
- improve interpretability
- simplify modeling
- better reflect production healthcare analytics workflows

---

# Practical Rule Used in This Project

### Step 5B

**Prevent cheating**

Remove future information.

---

### Step 5E

**Clean the predictor set**

Remove IDs, timestamps, targets, and redundant variables.

---

# Final Modeling Dataset

After Step 5:

### Features (X)

Administrative + clinical + physiologic variables available at discharge.

### Target (Y)

```python
label_readmit_30d
```

### Final Split

- **Training set**
- **Validation set**
- **Test set**

using **patient-level separation**.

This creates a clinically realistic and leakage-safe modeling framework.

---

## Key Takeaway

A high-performing healthcare model is not useful if it relies on future information.

In this project:

> **Predictive realism was prioritized over artificially inflated performance.**

The model only uses information that would realistically be available to clinicians **at discharge time**.
