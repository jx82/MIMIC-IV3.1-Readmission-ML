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

## Step 5 — Modeling Dataset Preparation

After completing feature engineering (Step 4), the next objective was to transform the research cohort into **machine-learning-ready datasets** while maintaining strict **data leakage prevention** and **subject-level independence**.

This step focused on:

* separating predictors (**X**) and outcome (**y**)
* removing leakage variables
* performing **subject-level train/validation/test split**
* identifying feature types for preprocessing pipelines
* preparing clean datasets for modeling in Step 6

---

### Why Step 5 Is Necessary

At the end of Step 4, the cohort dataset still contained a mixture of:

1. **Predictor variables (X)**
   Demographics, utilization history, comorbidity burden, ICU exposure, procedures, vital/lab summaries, and medication-related features.

2. **Outcome variable (Y)**
   The target label:

```text
label_readmit_30d
```

3. **Research / tracking variables**

```text
subject_id
hadm_id
```

While this structure is ideal for **research, auditing, and validation**, it is not appropriate for machine learning pipelines.

A predictive model should learn:

```text
Predictors (X) → Outcome (Y)
```

not:

```text
Predictors + Outcome → Outcome
```

Keeping the target inside the predictor matrix would introduce **target leakage**, artificially inflating model performance.

---

## 5.1 Separating Predictors (X) and Target (Y)

Instead of permanently deleting variables, we followed an **industry-standard ML workflow** by separating predictors and outcomes into dedicated datasets.

### Before Separation

The master cohort contained:

| Variable Type | Examples                                     |
| ------------- | -------------------------------------------- |
| IDs           | `subject_id`, `hadm_id`                      |
| Target        | `label_readmit_30d`                          |
| Predictors    | demographics, utilization, clinical features |

Example structure:

```text
cohort
├── subject_id
├── hadm_id
├── label_readmit_30d
├── age_at_admission
├── prior_admission_count
├── charlson_score
├── icu_flag
└── ...
```

### Separation Process

We created:

#### Predictor dataset (X)

Contains only model inputs.

#### Target dataset (y)

Contains only the readmission label.

Example:

```python
TARGET = "label_readmit_30d"

y = cohort[TARGET]

X = cohort.drop(columns=[TARGET])
```

After separation:

### X

```text
subject_id
hadm_id
age_at_admission
prior_admission_count
charlson_score
icu_flag
...
```

### y

```text
label_readmit_30d
0
1
0
1
...
```

### Why Separation Is Better Than Deletion

This approach offers several advantages:

#### 1. Preserves the master cohort

The original cohort remains available for:

* descriptive statistics
* Table 1 creation
* cohort validation
* debugging
* reproducibility
* feature auditing

#### 2. Prevents target leakage

The model never sees the outcome variable during training.

This ensures realistic evaluation and production-style modeling.

#### 3. Supports reusable ML pipelines

Machine learning frameworks expect:

```text
X_train, y_train
X_val, y_val
X_test, y_test
```

This structure makes experimentation easier across multiple algorithms.

#### 4. Enables future experimentation

Separate X and y datasets simplify:

* model comparison
* threshold tuning
* ROC / PR curve evaluation
* SHAP interpretation
* calibration analysis

without modifying the master cohort.

---

## 5.2 Leakage Variable Removal

Variables directly related to label construction or unavailable at prediction time were removed before modeling.

Examples include:

```text
next_admittime
days_to_next_admit
next_hadm_id
next_admission_type
```

These variables contain **future information** and would leak knowledge of the outcome.

Additional raw timestamp variables were excluded:

```text
admittime
dischtime
edregtime
edouttime
deathtime
```

Instead, clinically meaningful derived features were retained:

```text
los_days
weekend_admission_flag
prior_30d_admits
```

This ensures the model only uses information realistically available **at discharge**.

---

## 5.3 Subject-Level Data Split

To avoid patient-level leakage, data splitting was performed at the **subject level** rather than admission level.

### Why This Matters

A single patient can have multiple hospitalizations.

If one admission appears in training and another appears in testing, the model may indirectly memorize patient-specific patterns.

This creates **overly optimistic performance estimates**.

### Incorrect Split

```text
Patient A Admission 1 → Train
Patient A Admission 2 → Test
```

### Correct Split

```text
Patient A → Train only
Patient B → Test only
```

We used:

```python
GroupShuffleSplit
```

with:

```text
groups = subject_id
```

Final split proportions:

| Dataset    | Approximate Size |
| ---------- | ---------------: |
| Training   |              64% |
| Validation |              16% |
| Testing    |              20% |

This approach better simulates real-world deployment to **new unseen patients**.

---

## 5.4 Removing ID Variables

Identifiers were temporarily retained for splitting:

```text
subject_id
hadm_id
```

After train/validation/test partitioning, these variables were removed from predictors because they contain no clinical meaning and could encourage memorization.

---

## 5.5 Feature Type Identification

The final modeling dataset included multiple feature types requiring different preprocessing strategies.

Features were automatically classified into:

### Numeric Features

Examples:

```text
age_at_admission
los_days
charlson_score
diagnosis_count
procedure_count
creatinine_mean
heart_rate_mean
```

Used for:

* median imputation
* scaling (for logistic regression)

---

### Categorical Features

Examples:

```text
gender
race_grouped
insurance_grouped
admission_type_grouped
discharge_group
```

Used for:

* missing handling
* one-hot encoding

---

### Binary Features (0/1)

Examples:

```text
icu_flag
polypharmacy_flag
creatinine_missing_flag
hemoglobin_missing_flag
```

Used for:

* direct pass-through
* minimal preprocessing

### Why Automatic Feature Detection?

Instead of manually listing all predictors, feature types were identified programmatically.

Benefits include:

* avoids missing variables
* automatically updates if features change
* reduces human error
* improves reproducibility
* supports scalable pipelines

---

## Step 5 Output

Final machine-learning-ready datasets:

```text
X_train, y_train
X_val, y_val
X_test, y_test
```

These datasets are:

✅ leakage-safe
✅ subject-independent
✅ preprocessing-ready
✅ reproducible
✅ production-style

and serve as the direct input for **Step 6 — Predictive Modeling (Logistic Regression, Random Forest, and XGBoost)**.

## Step 5 — Modeling Dataset Preparation

After completing feature engineering (Step 4), the next objective was to transform the research cohort into a **machine-learning-ready dataset** while maintaining strict **data leakage prevention**, **subject-level independence**, and **reproducible preprocessing workflows**.

The goals of Step 5 were to:

* remove leakage variables
* separate predictors (**X**) and outcome (**y**)
* perform **subject-level train/validation/test splitting**
* classify feature types for preprocessing
* design missing value strategies
* prepare clean datasets for predictive modeling

At the end of this step, the project produced:

```text
X_train, y_train
X_val,   y_val
X_test,  y_test
```

which serve as the direct input for **Step 6 — Predictive Modeling**.

---

# 5.1 Load Final Feature Dataset

The starting point for Step 5 was the **fully engineered cohort** generated in Step 4.

This dataset included:

### Research / Tracking Variables

* `subject_id`
* `hadm_id`

### Target Variable (Outcome)

* `label_readmit_30d`

### Predictor Variables

Features engineered across three tiers:

**Tier 1 — Administrative Baseline**

* demographics
* utilization history
* admission context

**Tier 2 — Clinical Burden & Care Intensity**

* comorbidity burden
* ICU exposure
* procedures
* discharge context

**Tier 3 — Physiologic Signals**

* laboratory summaries
* vital sign summaries
* medication complexity
* missingness indicators

At this stage, the dataset still represented a **research-ready master cohort**, rather than a modeling dataset.

---

# 5.2 Leakage Variable Removal

Before modeling, variables containing **future information** or unavailable at prediction time were removed.

### Label Construction Variables Removed

The following variables were used to define readmission labels and therefore could not be used as predictors:

```text
next_admittime
days_to_next_admit
next_hadm_id
next_admission_type
```

These variables contain direct information about future admissions and would introduce **target leakage**.

### Timestamp Variables Removed

Raw timestamps were also excluded:

```text
admittime
dischtime
edregtime
edouttime
deathtime
```

Instead of raw timestamps, clinically meaningful derived features were retained, such as:

```text
los_days
prior_30d_admits
```

This ensured the model only used information realistically available **at discharge**, aligning with real-world deployment conditions.

---

# 5.3 Separating Predictors (X) and Target (Y)

One important conceptual transition in Step 5 was understanding that the target variable (**Y**) was **not permanently deleted**.

Instead, an **industry-standard machine learning workflow** was used to separate predictors and outcomes into dedicated datasets.

### Before Separation

The master cohort contained:

```text
subject_id
hadm_id
label_readmit_30d
all engineered predictors
```

### After Separation

The dataset was divided into:

### Predictor Dataset (X)

Contains:

* engineered predictors
* identifier variables (temporarily retained)

### Target Dataset (y)

Contains:

```text
label_readmit_30d
```

This separation follows the core machine learning framework:

```text
f(X) → y
```

where the model learns relationships between predictors (**X**) and outcomes (**y**).

### Why Separation Is Better Than Deletion

Rather than permanently removing variables, separation provides several advantages:

#### Preserves the Master Cohort

The original cohort remains available for:

* descriptive statistics
* cohort validation
* debugging
* feature quality checks
* reproducibility

#### Prevents Target Leakage

Keeping the target outside of the predictor matrix prevents accidental inclusion during preprocessing or training.

Without separation, the target variable could mistakenly be:

* scaled
* encoded
* imputed
* used as a predictor

which would invalidate model performance.

#### Supports Standard ML Pipelines

Modern machine learning frameworks expect:

```text
X_train, y_train
X_val,   y_val
X_test,  y_test
```

This structure improves reproducibility and experimentation across multiple models.

---

# 5.4 Subject-Level Train / Validation / Test Split

Hospital readmission modeling presents a unique challenge:

A single patient may contribute **multiple admissions**.

If one admission appears in training and another appears in testing, the model may indirectly memorize patient-specific patterns.

### Incorrect Split (Patient Leakage)

```text
Patient A Admission 1 → Train
Patient A Admission 2 → Test
```

This can inflate performance metrics unrealistically.

### Correct Split (Subject-Level)

```text
Patient A → Train only
Patient B → Test only
```

To prevent leakage, splitting was performed using:

```python
GroupShuffleSplit(groups=subject_id)
```

This ensured that all admissions from the same patient remained within a single dataset.

### Final Dataset Allocation

| Dataset    | Approximate Share |
| ---------- | ----------------: |
| Training   |               64% |
| Validation |               16% |
| Testing    |               20% |

This approach better simulates **real-world deployment to unseen patients**.

---

# 5.5 Removing Identifier Variables

Identifiers were temporarily retained because they were required for subject-level splitting.

Retained initially:

```text
subject_id
hadm_id
```

After splitting, these variables were removed from predictors because:

* they are not clinical predictors
* they may encourage memorization
* they provide no real predictive value

This left only clinically meaningful predictors for model training.

---

# 5.6 Feature Type Identification

The final modeling dataset contained multiple variable types requiring different preprocessing strategies.

Instead of manually listing all predictors, feature types were identified **programmatically** to improve scalability and reproducibility.

Features were classified into three groups.

### Numeric Features

Examples:

```text
age_at_admission
los_days
charlson_score
diagnosis_count
procedure_count
creatinine_mean
heart_rate_mean
```

These variables will later receive:

* median imputation
* scaling (for logistic regression)

---

### Categorical Features

Examples:

```text
gender
race_grouped
insurance_grouped
admission_type_grouped
discharge_group
```

These variables will later receive:

* missing value handling
* one-hot encoding

---

### Binary Features (0/1)

Examples:

```text
icu_flag
polypharmacy_flag
hemoglobin_missing_flag
creatinine_missing_flag
```

These variables generally require minimal preprocessing and can often pass directly into models.

### Why Automatic Feature Detection?

Automatic classification was chosen over manual feature lists because it:

* reduces human error
* prevents forgotten variables
* automatically adapts to future feature engineering updates
* improves reproducibility
* supports scalable ML pipelines

Feature validation confirmed:

```text
Total predictors: 76
Successfully classified: 76
Missing predictors: 0
Duplicate predictors: 0
```

ensuring all variables were assigned to exactly one preprocessing group.

---

# 5.7 Missing Value Strategy

Because healthcare data frequently contain missing information, preprocessing strategies were defined before modeling.

### Numeric Features

Missing values will be handled using:

```text
Median Imputation
```

Median imputation was preferred because many clinical variables are highly skewed and susceptible to outliers.

Examples include:

* creatinine
* WBC
* LOS
* BUN

### Categorical Features

Missing categories will be filled with:

```text
"Unknown"
```

This preserves potentially meaningful missingness patterns.

### Binary Features

Binary variables will typically pass through without transformation.

### Special Consideration: ICU-Only Variables

Many Tier 3 physiologic features originate from ICU chart events.

Non-ICU patients naturally lack these measurements.

This missingness is **structural**, not random.

Rather than removing these patients, the project retained:

* imputed physiologic values
* explicit missingness indicators

This allows the model to learn whether the absence of measurements itself contains predictive information.

---

# Step 5 Output

At the completion of Step 5, the project produced:

### Final Modeling Datasets

```text
X_train, y_train
X_val,   y_val
X_test,  y_test
```

### Final Feature Groups

```text
numeric_features
categorical_features
binary_features
```

### Final Preprocessing Strategy

* leakage-safe
* subject-independent
* reproducible
* deployment-oriented

These outputs form the foundation for:

# Step 6 — Predictive Modeling

Models to be developed:

* Logistic Regression
* Random Forest
* XGBoost

with evaluation using:

* ROC-AUC
* PR-AUC
* threshold optimization
* confusion matrix analysis
* SHAP interpretation

## Project Data Organization & Workflow

To improve **reproducibility, modularity, and GitHub readability**, the project organizes datasets according to the machine learning lifecycle.

This structure separates:

* raw source data
* engineered features
* modeling-ready datasets
* model outputs

The organization mirrors how production healthcare ML pipelines are commonly structured.

---

# Project Folder Structure

```text
data/
│
├── raw/
│   ├── admissions.csv
│   ├── patients.csv
│   ├── diagnoses_icd.csv
│   ├── procedures_icd.csv
│   ├── labevents.csv
│   ├── chartevents.csv
│   └── other original MIMIC-IV source files
│
├── features/
│   ├── mimic_readmission_features.csv
│   └── mimic_readmission_features.parquet
│
├── processed/
│   ├── mimic_readmission_X_train.csv
│   ├── mimic_readmission_X_val.csv
│   ├── mimic_readmission_X_test.csv
│   ├── mimic_readmission_y_train.csv
│   ├── mimic_readmission_y_val.csv
│   └── mimic_readmission_y_test.csv
│
└── outputs/
    ├── model_results/
    ├── roc_curves/
    ├── confusion_matrix/
    ├── shap/
    └── threshold_analysis/
```

---

# Folder Purpose

## `raw/`

Stores **untouched original MIMIC-IV source files**.

Examples:

```text
admissions.csv
patients.csv
diagnoses_icd.csv
labevents.csv
chartevents.csv
```

### Purpose

Acts as the **source of truth** for the project.

### Rules

* never modify raw files
* read-only input source
* used for reproducibility

Think of this folder as:

> **Original clinical data source**

---

## `features/`

Stores **master feature-engineered datasets** produced after feature engineering.

Examples:

```text
mimic_readmission_features.csv
mimic_readmission_features.parquet
```

### Generated In

```text
Step 4 — Feature Engineering
```

### Characteristics

* one master cohort dataset
* contains engineered predictors
* includes target label
* before train/validation/test split
* before preprocessing

Think of this folder as:

> **Research-ready feature table**

---

## `processed/`

Stores **machine-learning-ready datasets**.

Examples:

```text
mimic_readmission_X_train.csv
mimic_readmission_X_val.csv
mimic_readmission_X_test.csv

mimic_readmission_y_train.csv
mimic_readmission_y_val.csv
mimic_readmission_y_test.csv
```

### Generated In

```text
Step 5 — Modeling Dataset Preparation
```

### Characteristics

* leakage-safe
* subject-level split
* train / validation / test datasets
* ready for modeling
* not yet imputed, scaled, or encoded

Preprocessing is intentionally deferred to:

```text
Step 6 — Modeling Pipeline
```

where transformations occur safely inside sklearn pipelines.

Think of this folder as:

> **Model-ready inputs**

---

## `outputs/`

Stores **modeling artifacts and evaluation results**.

Examples:

```text
ROC curves
confusion matrices
feature importance plots
SHAP visualizations
threshold analysis
performance comparison tables
```

### Generated In

```text
Step 6+ — Model Development & Evaluation
```

Think of this folder as:

> **Final modeling results**

---

# End-to-End Workflow

The overall project follows the workflow below:

```text
raw MIMIC-IV tables
        ↓
Step 1 — Load Data
        ↓
Step 2 — Cohort Definition
        ↓
Step 3 — Label Creation
        ↓
Step 4 — Feature Engineering
        ↓
features/
(mimic_readmission_features.csv)
        ↓
Step 5 — Modeling Dataset Preparation
        ↓
processed/
(X_train, X_val, X_test)
(y_train, y_val, y_test)
        ↓
Step 6 — Modeling Pipeline
(imputation + encoding + scaling)
        ↓
Logistic Regression
Random Forest
XGBoost
        ↓
outputs/
(ROC-AUC, SHAP, threshold tuning, evaluation)
```

---

# Why This Structure?

This organization improves:

### Reproducibility

Each project stage has a clearly defined output.

### Modularity

Step 6 can begin directly from Step 5 outputs without rerunning earlier notebooks.

### Debugging

Issues can be traced to the exact project stage.

### Fair Model Comparison

All models share the same leakage-safe train/validation/test split.

### Professional Portfolio Quality

The structure closely resembles real-world healthcare machine learning workflows used in:

* hospital analytics teams
* payer analytics
* health tech companies
* clinical AI development teams

This separation makes the project easier to maintain, reproduce, and explain to future employers or collaborators.

## Step 6 Design Note — Why Preprocessing Belongs Inside the Modeling Pipeline

### 1. What Transformers Do

In Step 6, preprocessing is handled by **transformers**. A transformer is a reusable object that learns a rule from the training data and then applies that same rule to training, validation, and test data.

Examples:

```text
SimpleImputer     → handles missing values
OneHotEncoder     → converts categorical variables into numeric columns
StandardScaler    → scales numeric variables
ColumnTransformer → applies different preprocessing rules to different feature groups
```

For this project, preprocessing will be organized by feature type:

```text
Numeric features
→ median imputation
→ scaling for Logistic Regression

Categorical features
→ fill missing values with "Unknown"
→ one-hot encoding

Binary features
→ pass through unchanged or simple imputation if needed
```

This allows each variable type to receive the correct preprocessing treatment.

---

### 2. Why Use Pipelines Instead of Preprocessing in Step 5?

Step 5 is used to **prepare and define** the modeling dataset.

Step 6 is where preprocessing is actually executed inside the model pipeline.

This separation is intentional.

#### Step 5

```text
Split data
Identify feature types
Design missing value strategy
Prepare X_train, X_val, X_test
```

#### Step 6

```text
Fit preprocessing on X_train only
Transform X_train, X_val, X_test consistently
Train models
Evaluate performance
```

A pipeline combines preprocessing and modeling into one workflow:

```text
Raw X
→ imputation
→ encoding
→ scaling
→ model
→ prediction
```

This is preferred because it:

* prevents data leakage
* keeps preprocessing consistent across models
* improves reproducibility
* supports fair comparison between Logistic Regression, Random Forest, and XGBoost
* works correctly with cross-validation and grid search
* reduces human error from manually transforming datasets

Without a pipeline, it is easy to accidentally use different preprocessing rules for different models. For example, Logistic Regression might receive scaled data, while Random Forest might receive differently imputed data. Then model performance would no longer be directly comparable.

With a pipeline, the same preprocessing recipe is reused across models, and only the model itself changes.

---

### 3. Missing Value Strategy in This Project

Healthcare data often contain missing values for meaningful reasons.

In this readmission project, missingness can occur because:

* a lab was not ordered
* a patient was not in the ICU
* a vital sign was not charted
* a variable comes from a source table with partial coverage
* a patient was clinically stable enough not to need certain measurements

Therefore, missingness is not always random. It may contain clinical information.

For example:

```text
Missing ICU vitals
```

may suggest:

```text
Patient was likely not ICU-level severity
```

So the project should not automatically drop high-missing variables. Instead, the preferred strategy is:

```text
Impute missing values
+
retain missingness indicators when available
```

This lets the model learn both:

```text
the imputed value
```

and

```text
whether the value was originally missing
```

---

### 4. Why Use Training Median for Validation and Test?

For numeric variables, the planned strategy is:

```text
Fit median imputer on X_train only
Apply the same median to X_train, X_val, and X_test
```

This means validation and test data do **not** calculate their own medians.

The assumption is:

> The training dataset represents the information available at model development time.

In real-world deployment, future patients arrive after the model is trained. We would not know the future population’s median creatinine, WBC, LOS, or other values ahead of time.

So validation and test sets should simulate future patients:

```text
Train data = historical data used to build model
Validation/test data = unseen future-like patients
```

Using validation/test medians would leak information from those datasets into preprocessing and make performance estimates too optimistic.

---

### 5. What If Validation/Test Distributions Are Different?

Validation and test distributions may differ from training. This is expected in healthcare.

Differences may occur because of:

* population drift
* seasonal illness patterns
* different ICU mix
* changing clinical practice
* different missingness patterns
* random sampling variation

This is not a reason to use validation/test medians. Instead, it is exactly why validation and test evaluation are important.

If the model performs well despite distribution differences, it suggests stronger generalization.

If performance drops, it may indicate:

```text
distribution shift
overfitting
unstable predictors
changed missingness patterns
poor calibration
```

---

### 6. What ROC-AUC Tells Us Here

ROC-AUC evaluates whether the model can correctly **rank** patients by readmission risk.

It asks:

> Are readmitted patients generally assigned higher predicted risk than non-readmitted patients?

ROC-AUC is useful when validation/test distributions differ because it focuses on ranking rather than exact predicted probability calibration.

Example:

```text
Patient A: not readmitted → predicted risk 0.20
Patient B: readmitted     → predicted risk 0.70
```

This is a correct ranking.

If the validation/test population is sicker overall, predicted probabilities may shift upward. ROC-AUC can still show whether the model preserves correct risk ordering.

However, ROC-AUC does not fully answer operational questions. A model may rank patients reasonably well but still have poorly calibrated probabilities or weak performance at a specific threshold.

Therefore, Step 6 should also evaluate:

```text
PR-AUC
confusion matrix
precision
recall
threshold performance
top-risk capture
calibration
```

---

### 7. Final Takeaway

This project uses a pipeline-based preprocessing approach because it is safer, more reproducible, and closer to real-world healthcare machine learning practice.

```text
Step 5 = define the dataset and preprocessing strategy

Step 6 = execute preprocessing inside pipelines and evaluate models
```

The pipeline approach ensures that:

```text
training data teaches the preprocessing rules
validation/test data only receive those rules
model performance reflects honest generalization
```

Got it — here is a **clean copy-paste GitHub README version** (plain text formatting, no markdown code fence around the whole thing).

# Step 6 — Modeling Pipeline & Baseline Models

## Purpose

The goal of Step 6 is to build a leakage-safe machine learning pipeline for predicting 30-day hospital readmission using engineered features from Step 5.

This step introduces:

* preprocessing pipelines
* baseline model training
* model evaluation
* threshold tuning
* final model comparison

The workflow follows a real-world healthcare analytics pipeline commonly used in:

* hospital analytics teams
* payer risk analytics
* readmission management programs
* healthcare AI applications

---

## Step 6 Objectives

In this step, we will:

### 1. Load Modeling Datasets

Load the leakage-safe datasets created in Step 5:

X_train
X_val
X_test

y_train
y_val
y_test

These datasets were split at the patient (subject_id) level to prevent leakage across admissions.

---

### 2. Build a Preprocessing Pipeline

Instead of preprocessing in Step 5, transformations are intentionally deferred to Step 6.

This ensures:

* No information leakage
* Reproducible preprocessing
* Consistent transformations across all models

The preprocessing pipeline includes:

#### Numeric Features

* median imputation
* feature scaling

#### Categorical Features

* missing category imputation
* one-hot encoding

Example workflow:

Numeric variables
↓
Median imputation
↓
Scaling

Categorical variables
↓
Most frequent imputation
↓
One-hot encoding

---

## Why Use a Pipeline?

In healthcare machine learning, preprocessing must be learned only from training data.

### Incorrect Approach ❌

Using the full dataset to calculate missing values:

median_age = whole_dataset["age"].median()

This leaks information from validation and test sets.

### Correct Approach ✅

The pipeline learns transformations only from training data:

median_age = X_train["age"].median()

Then applies the same transformation to:

X_val
X_test

This ensures the model behaves like a real hospital deployment scenario where future patient data is unknown.

---

## Step 6 Workflow

Step 5 Outputs
(X_train, X_val, X_test)
(y_train, y_val, y_test)

↓

Preprocessing Pipeline
(imputation + encoding + scaling)

↓

Train Baseline Models

↓

Validation Evaluation
(ROC-AUC, PR-AUC)

↓

Threshold Tuning

↓

Select Best Model

↓

Final Test Evaluation

---

## Modeling Strategy

Three baseline models will be trained.

### 1. Logistic Regression

#### Purpose

Establish a strong interpretable baseline model.

Benefits:

* easy to explain clinically
* interpretable coefficients
* widely used in healthcare analytics

Useful for:

* hospital quality teams
* payer analytics
* care management

---

### 2. Random Forest

#### Purpose

Capture nonlinear relationships and feature interactions.

Benefits:

* robust to noisy variables
* automatically models interactions
* handles mixed feature types well

Example interactions:

ICU stay + high Charlson score

Long LOS + prior readmissions

---

### 3. XGBoost

#### Purpose

Serve as the high-performance benchmark model.

Benefits:

* excellent tabular data performance
* strong predictive accuracy
* widely used in healthcare ML competitions and industry

XGBoost often performs best for:

* readmission prediction
* mortality prediction
* utilization risk prediction

---

## Feature Categories Used

The model uses features developed in earlier steps.

### Tier 1 — Administrative Baseline

Examples:

* age_at_admission
* gender
* race_grouped
* insurance_grouped
* prior_admission_count
* prior_30d_admits
* admission_type

---

### Tier 2 — Clinical Burden & Severity

Examples:

* charlson_score
* diagnosis_count
* los_days
* icu_flag
* procedure_count
* discharge_location_clean

---

### Tier 3 — Physiologic Signals

Examples:

* heart_rate_mean
* spo2_min
* creatinine_last
* wbc_max
* medication_count

These features are restricted to information available on or before discharge time to avoid target leakage.

---

## Validation Strategy

Model performance is evaluated on the validation dataset (X_val).

Why?

Because model selection is still occurring.

The test dataset remains untouched.

Evaluation metrics include:

### ROC-AUC

Measures the model’s ability to separate:

Readmitted vs Non-readmitted

Higher values indicate stronger discrimination.

---

### PR-AUC (Precision-Recall AUC)

Important for imbalanced healthcare outcomes.

Readmission prevalence is relatively low (~19%).

PR-AUC better reflects performance on the positive class.

---

### Confusion Matrix

Evaluates:

* True Positives
* False Positives
* False Negatives
* True Negatives

Helps understand operational tradeoffs.

---

### Classification Metrics

Including:

* precision
* recall
* F1-score

---

## Threshold Tuning

Healthcare prediction models rarely use the default threshold:

0.5

Instead, thresholds are selected based on clinical goals.

### High Recall Strategy

Goal:

Catch as many high-risk patients as possible.

Useful for:

* discharge intervention
* care coordination
* social worker referral

---

### High Precision Strategy

Goal:

Reduce unnecessary interventions.

Useful when resources are limited.

---

### Risk Ranking Strategy

Example:

Flag the top 15% highest-risk patients.

Threshold is selected based on the probability distribution of predictions.

---

## Final Test Evaluation

The test dataset is used only once.

This occurs after:

* Best model selected
* Threshold finalized

The final test evaluation provides an unbiased estimate of real-world performance.

---

## Expected Deliverables

At the end of Step 6, the project will produce:

### Model Performance Comparison

| Model               | ROC-AUC | PR-AUC |
| ------------------- | ------- | ------ |
| Logistic Regression | 0.69    | 0.32   |
| Random Forest       | 0.73    | 0.38   |
| XGBoost             | 0.77    | 0.44   |

*Illustrative example only*

---

### Feature Importance

Top predictors may include:

* length of stay
* prior admissions
* Charlson score
* ICU stay
* discharge location

---

### Threshold Recommendation

Example:

Threshold = 0.31
Recall = 72%
Precision = 38%

---

### Explainability (Later Step)

SHAP analysis will help explain:

Why a patient is predicted as high-risk.

Example:

↑ prior admissions
↑ LOS
↑ ICU exposure
↑ renal disease burden

This improves clinical interpretability and stakeholder trust.

---

## Key Takeaway

Step 6 transforms the project from a feature-engineering exercise into a real healthcare machine learning workflow using:

* leakage-safe preprocessing
* reproducible pipelines
* interpretable evaluation
* clinically meaningful threshold selection

This mirrors how hospital systems, payer organizations, and healthcare analytics teams deploy predictive models in production.

Yes — thank you for waiting. Here is the **full GitHub README-ready version** with diagrams, structure, code snippets, and explanations integrated into one clean section you can copy-paste directly into your project.

# Step 6 — Model Training Outputs (`.pkl`) and Step 7 Relationship

After model training in Step 6, the final trained model pipeline is saved as:

```python
best_readmission_model.pkl
```

This file is **not only an XGBoost model**.

Instead, it contains the **entire trained machine learning pipeline**, including:

* preprocessing rules
* transformation mappings
* trained XGBoost model
* learned tree structure
* hyperparameters

Think of the `.pkl` as a **frozen prediction engine** that can later score new patients consistently.

---

# Step 6 Training Architecture

The final pipeline saved in Step 6 has the following structure:

```text
best_readmission_model.pkl
│
└── Pipeline
    │
    ├── Step 1: preprocess
    │   └── ColumnTransformer
    │       │
    │       ├── Numeric pipeline
    │       │   ├── SimpleImputer
    │       │   │   └── training medians
    │       │   │
    │       │   └── StandardScaler
    │       │       ├── training means
    │       │       └── training standard deviations
    │       │
    │       └── Categorical pipeline
    │           ├── SimpleImputer
    │           │   └── most frequent categories
    │           │
    │           └── OneHotEncoder
    │               └── saved category mapping
    │
    └── Step 2: model
        └── XGBClassifier
            ├── hyperparameters
            ├── trained decision trees
            ├── split rules
            ├── feature interactions
            └── learned prediction structure
```

---

# What is Stored Inside the `.pkl`?

The `.pkl` file stores everything learned during training **from `X_train` only**.

This prevents data leakage and guarantees reproducible preprocessing.

---

## 1. Numeric Imputation Rules

For each numeric variable, the model stores the **median value learned from training data**.

Examples:

```text
creatinine_last median = 1.10
WBC_last median = 8.7
LOS_days median = 4
SBP_mean median = 118
```

When a future patient has missing data:

Example:

```text
creatinine_last = missing
```

The model automatically fills it using:

```text
training median only
```

rather than recalculating a new value.

This ensures future predictions remain consistent.

---

## 2. Numeric Scaling Rules

Because the pipeline includes:

```python
StandardScaler()
```

the model stores:

```text
mean
standard deviation
```

for every numeric feature.

Example:

```text
age_at_admission
mean = 63.4
std = 17.8

LOS_days
mean = 6.2
std = 8.4
```

The transformation formula is:

```text
scaled_value =
(original_value − training_mean)
/ training_std
```

This means:

Validation, test, and future deployment data are transformed using the **exact same training-derived scaling rules**.

---

## 3. Categorical Imputation Rules

For categorical variables, the pipeline stores the **most frequent category** from training data.

Examples:

```text
gender → M

insurance_grouped
→ Medicare

admission_type_grouped
→ Emergency
```

If a future patient is missing a category value, the pipeline fills it using these saved defaults.

---

## 4. One-Hot Encoding Mapping

The model remembers all categorical levels observed during training.

Example:

Original feature:

```text
gender
```

After encoding:

```text
gender_F
gender_M
```

Example:

```text
insurance_grouped
```

becomes:

```text
insurance_Medicare
insurance_Medicaid
insurance_Private
insurance_Other
```

The pipeline remembers this mapping permanently.

Because the model uses:

```python
OneHotEncoder(handle_unknown="ignore")
```

future unseen categories do not crash the model.

Instead:

```text
unknown category
→ encoded as zeros
```

for that feature group.

---

## 5. Final Feature Matrix Structure

After preprocessing, the original dataset is transformed into a fully numeric machine-learning matrix.

### Before preprocessing

```text
age_at_admission
LOS_days
gender
insurance_grouped
creatinine_last
```

### After preprocessing

```text
scaled_age_at_admission
scaled_LOS_days
scaled_creatinine_last
gender_F
gender_M
insurance_Medicare
insurance_Private
```

The `.pkl` stores the **exact transformed feature order**.

This matters because XGBoost learns patterns using transformed numeric matrices rather than raw DataFrames.

---

## 6. XGBoost Hyperparameters

The `.pkl` also stores the final model settings.

Example:

```python
n_estimators=500
max_depth=4
learning_rate=0.05
subsample=0.8
colsample_bytree=0.8
objective="binary:logistic"
eval_metric="auc"
scale_pos_weight=<training imbalance ratio>
tree_method="hist"
random_state=42
```

These parameters determine:

```text
how many trees
tree complexity
learning speed
imbalance handling
```

---

## 7. Trained XGBoost Trees

Most importantly, the `.pkl` stores the learned tree structure.

Conceptually, the model learns rules like:

```text
IF LOS_days > threshold
AND prior_admission_count > threshold
AND creatinine_last elevated

THEN:
higher readmission risk
```

The model contains **hundreds of boosted trees**.

Each tree contributes a small amount to prediction.

Conceptually:

```text
baseline risk
+ tree 1 contribution
+ tree 2 contribution
+ tree 3 contribution
...
=
final readmission probability
```

Example output:

```text
0.81
```

Meaning:

```text
81% predicted readmission risk
```

---

# What is NOT Stored in the `.pkl`?

The `.pkl` **does NOT contain patient datasets**.

It does not save:

```text
X_train
X_val
X_test
y_train
y_val
y_test
```

It also does not save:

```text
cohort building logic
feature engineering notebook
raw MIMIC tables
Step 4 datasets
```

The `.pkl` stores only:

```text
learned preprocessing
+
trained prediction logic
```

---

# Relationship Between Step 5, Step 6, and Step 7

## Step 5 — Modeling Dataset Preparation

Step 5 prepares leakage-safe datasets:

```text
X_train
X_val
X_test
```

These contain:

```text
patient feature values only
```

Example patient row:

| age | LOS | creatinine_last | ICU_flag |
| --- | --- | --------------- | -------- |
| 78  | 9   | 2.1             | 1        |

Step 5 does **not** know how to predict readmission.

It only contains patient records.

---

## Step 6 — Model Training

Step 6 uses:

```text
X_train
```

to learn:

```text
preprocessing rules
+
XGBoost model
```

Then validation data:

```text
X_val
```

is used for:

```text
model comparison
threshold tuning
```

Finally:

```text
X_test
```

is used **once only** for honest final evaluation.

Final outputs:

```text
best_readmission_model.pkl
validation_model_comparison.csv
threshold_tuning_validation.csv
final_test_performance.csv
```

---

## Step 7 — Model Interpretation

Step 7 combines:

```text
Step 5 data
+
Step 6 trained model (.pkl)
```

to answer:

```text
Why was this patient high risk?
Which variables mattered most?
How does the model behave clinically?
```

Step 7 uses:

```text
X_train
```

for SHAP background distribution.

Step 7 often uses:

```text
X_test
```

for explaining unseen patients.

---

# Why Step 7 Needs BOTH Step 5 Data and `.pkl`

A common question is:

> If Step 6 already used `X_test`, why reload Step 5 data?

Because:

### Step 6 USED `X_test`

but

### Step 6 did NOT SAVE `X_test`

inside the `.pkl`.

The `.pkl` contains:

```text
trained brain
```

not:

```text
patient charts
```

To explain predictions, Step 7 needs both.

---

## Mental Model

Think of the workflow like this:

### Step 5

```text
patient charts
```

### Step 6

```text
doctor studies patient charts
and learns patterns
```

### `.pkl`

```text
trained physician brain
```

### Step 7

```text
doctor brain
+
patient chart
=
clinical explanation
```

Without patient data:

```text
doctor cannot explain a patient
```

Without trained model:

```text
patient chart alone
cannot generate prediction
```

Both are required.

---

# Full Workflow Diagram

```text
Step 4
Master feature dataset
(all patients + all variables)
            ↓

Step 5
Leakage-safe modeling datasets
(drop IDs + split data)

X_train
X_val
X_test
            ↓

Step 6
Train model

X_train
→ learn preprocessing
→ train XGBoost

X_val
→ choose best model
→ threshold tuning

X_test
→ final honest evaluation
            ↓

best_readmission_model.pkl
(trained prediction engine)
            ↓

Step 7
Model interpretation

Load:
1. best_readmission_model.pkl
2. X_train / X_test

→ Feature importance
→ SHAP explanations
→ patient-level interpretation
```

## Example: Load Saved Model in Step 7

```python
import joblib

best_model = joblib.load(
    config.ARTIFACTS_DIR /
    "step6_modeling" /
    "best_readmission_model.pkl"
)

print("Model loaded successfully.")
```

## Example: Load Step 5 Data in Step 7

```python
X_train = pd.read_csv(
    PROCESSED_DIR /
    "mimic_readmission_X_train.csv"
)

X_test = pd.read_csv(
    PROCESSED_DIR /
    "mimic_readmission_X_test.csv"
)
```

These are then used for:

```text
SHAP
feature importance
patient explanations
```

# Why Do Some Features Appear Important in XGBoost Importance but Less Important in SHAP?

During model interpretation, some variables such as:

```python
missing_spo2_flag
race_grouped_UNKNOWN
```

appeared relatively important in XGBoost feature importance rankings, but were less prominent in SHAP plots.

This difference is expected because:

* XGBoost feature importance
* SHAP importance

measure different concepts.

---

# 1. XGBoost Importance vs SHAP Importance

## XGBoost Feature Importance

XGBoost importance typically measures:

* split frequency
* gain improvement
* how often a feature is used in decision trees

For example:

```python
missing_spo2_flag
```

may repeatedly appear in tree splits:

```text
IF missing_spo2_flag = 1
    → lower risk branch
```

Even if the actual impact on prediction probability is modest.

Thus, XGBoost interprets the feature as:

> Frequently useful for tree splitting.

---

## SHAP Importance

SHAP measures:

> Average contribution of a feature to prediction output.

SHAP asks:

> How much does this feature move the predicted readmission risk?

For example:

```text
prior_admission_count
```

may strongly shift prediction probability:

```text
0.10 → 0.70 readmission risk
```

while:

```text
missing_spo2_flag
```

may only slightly change prediction:

```text
0.30 → 0.34 risk
```

Thus:

* XGBoost importance measures feature usage
* SHAP importance measures prediction impact

---

# 2. Correlated Features Compete for Attribution

Several features in the model represent overlapping clinical severity signals.

Examples include:

```python
icu_flag
los_days
procedure_count
medication_count
spo2
missing_spo2_flag
```

These variables are clinically related.

For example:

* ICU patients are more likely to have SpO2 monitored
* ICU patients often have longer LOS
* ICU patients usually receive more medications and procedures

Once the model already captures severity using variables such as:

```python
icu_flag
los_days
medication_count
```

the additional contribution from:

```python
missing_spo2_flag
```

becomes smaller.

SHAP distributes attribution across correlated features.

This phenomenon is called:

> Feature attribution competition

and is common in healthcare machine learning.

---

# 3. Missingness Variables Often Behave as Operational Proxies

In this project:

```python
missing_spo2_flag = 1
```

may indirectly indicate:

* lower-acuity floor patients
* fewer monitoring requirements
* non-ICU hospitalization

rather than physiologic instability itself.

The model may learn patterns such as:

```text
ICU patient → SpO2 measured
Floor patient → SpO2 often missing
```

Thus:

```python
missing_spo2_flag
```

acts more as an operational proxy variable rather than a direct clinical severity measure.

After stronger severity variables are included, SHAP may assign lower marginal importance to the missingness flag.

---

# 4. Sparse One-Hot Encoded Features

Variables such as:

```python
race_grouped_UNKNOWN
```

may only occur in a small subset of patients.

Tree-based models often favor sparse binary indicators because they create clean splits:

```text
IF race_grouped_UNKNOWN = 1
```

This can increase XGBoost feature importance.

However, SHAP evaluates:

> Average contribution across all patients.

If only a small percentage of patients have:

```python
race_grouped_UNKNOWN = 1
```

the average SHAP contribution becomes smaller.

Therefore:

* XGBoost importance may appear high
* SHAP importance may appear lower

This is expected behavior.

---

# 5. SHAP Display Limits

SHAP plots were generated using:

```python
max_display=20
```

Features outside the top 20 variables are hidden from visualization.

Increasing the display threshold:

```python
shap.summary_plot(
    shap_values_array,
    X_test_processed_df,
    max_display=50
)
```

may reveal additional variables such as:

```python
missing_spo2_flag
race_grouped_UNKNOWN
```

further down the ranking.

---

# Key Interpretation

A feature can:

* appear frequently in tree splits
* help partition patients operationally

while still having:

* smaller average contribution to final prediction probability

This does not mean the feature is unimportant.

Rather, it suggests the feature may provide:

* indirect contextual information
* operational workflow signals
* redundant severity information already captured by stronger predictors

---

# Clinical Interpretation

The final SHAP results suggest the model primarily relies on:

* prior healthcare utilization
* chronic disease burden
* age
* hospitalization severity
* treatment complexity

which are clinically plausible and consistent with published healthcare readmission literature.

Variables such as:

```python
missing_spo2_flag
race_grouped_UNKNOWN
```

still contribute useful contextual information, but their average marginal effect is smaller after accounting for stronger correlated severity predictors.

# How to Interpret SHAP Beeswarm Plots

The SHAP beeswarm plot is one of the most valuable model interpretation tools because it explains:

1. **Feature importance**
2. **Direction of feature effects on prediction**

Unlike traditional feature importance, SHAP helps answer:

> Why does the model predict higher or lower readmission risk?

---

# 1. What Do Red and Blue Colors Mean?

In a SHAP beeswarm plot:

### 🔴 Red = High Feature Value

### 🔵 Blue = Low Feature Value

For example:

```python id="prior-example"
prior_admission_count
```

* 🔴 red dots = patients with **many prior admissions**
* 🔵 blue dots = patients with **few prior admissions**

For:

```python id="age-example"
age_at_admission
```

* 🔴 red = older patients
* 🔵 blue = younger patients

For binary variables:

```python id="binary-example"
race_grouped_UNKNOWN
discharge_group_home_self
```

typically:

* 🔴 red = feature present (`1`)
* 🔵 blue = feature absent (`0`)

---

# 2. What Does Left vs Right Mean?

SHAP values represent how much a feature pushes prediction toward or away from readmission risk.

### Right Side (+ SHAP value)

Feature increases predicted readmission risk.

Interpretation:

> Pushes prediction toward higher readmission probability.

---

### Left Side (− SHAP value)

Feature lowers predicted readmission risk.

Interpretation:

> Pushes prediction toward lower readmission probability.

Conceptually:

```text id="direction-concept"
Lower Risk  ←──────── 0 ────────→  Higher Risk
```

---

# 3. Why Does `prior_admission_count` Have One Direction?

In the SHAP beeswarm plot:

```python id="prior-count"
prior_admission_count
```

Most:

### 🔴 Red dots appear on the RIGHT

Meaning:

> Higher prior admission counts increase readmission risk.

Clinically, this makes sense because patients with repeated hospitalizations tend to have:

* chronic instability
* higher healthcare utilization
* greater likelihood of returning to the hospital

Meanwhile:

### 🔵 Blue dots appear on the LEFT

Meaning:

> Fewer prior admissions lower readmission risk.

This aligns with established healthcare literature on utilization-based risk prediction.

---

# 4. Why Does `los_days` Show the Opposite Direction?

At first glance, the SHAP direction for:

```python id="los-example"
los_days
```

may appear surprising.

The plot suggests:

### 🔴 Red dots (long LOS) appear on the LEFT

Meaning:

> Longer hospital stays lower predicted readmission risk.

### 🔵 Blue dots (short LOS) appear on the RIGHT

Meaning:

> Shorter stays increase predicted readmission risk.

Initially, this may seem counterintuitive because:

> Longer stay often indicates more severe illness.

However, several clinical explanations are plausible.

---

## Possible Explanation 1: Short Stays May Reflect Premature Discharge

Patients discharged after very short hospitalizations may:

* receive less stabilization
* have incomplete treatment
* require rapid return to care

Example:

```text id="short-los"
1–2 day stay
→ discharged quickly
→ readmitted soon after
```

Meanwhile, longer stays may allow:

* medication optimization
* discharge planning
* specialist consultation
* rehabilitation placement

which lowers readmission risk.

---

## Possible Explanation 2: Interaction With Discharge Destination

Longer LOS patients may be discharged to:

```python id="post-acute"
rehab facility
skilled nursing facility (SNF)
post-acute care
```

rather than directly home.

Additional care support may reduce readmission probability.

---

## Possible Explanation 3: Conditional Relationship After Severity Adjustment

The model already includes severity-related variables:

```python id="severity-vars"
charlson_score
procedure_count
medication_count
ICU-related variables
```

Once severity is already captured, LOS may no longer represent:

> "How sick was the patient?"

Instead, LOS may represent:

> "How much care or stabilization did the patient receive?"

Thus, the model learns:

```text id="conditional-los"
Short LOS → higher readmission risk

Long LOS → lower readmission risk
```

conditional on clinical severity.

This is a common phenomenon in nonlinear machine learning models.

---

# 5. Why Does `age_at_admission` Show Mixed Directions?

For:

```python id="age-shap"
age_at_admission
```

the SHAP plot may show:

### Some 🔴 Red dots on the RIGHT

Meaning:

> Older age increases readmission risk.

But also:

### Some 🔴 Red dots on the LEFT

Meaning:

> Older age lowers readmission risk.

This occurs because XGBoost models capture:

> nonlinear relationships

rather than simple linear effects.

Unlike logistic regression:

```text id="linear-age"
older age → always higher risk
```

XGBoost may learn more complex subgroup patterns.

For example:

### Middle-aged adults (45–65)

may have:

* chronic disease burden
* repeated utilization
* medication complexity

leading to:

> higher readmission risk

Meanwhile:

### Very elderly adults

may experience:

* hospice discharge
* skilled nursing placement
* alternative care pathways

leading to:

> different readmission patterns

Thus:

```text id="age-nonlinear"
Age effect is heterogeneous
across patient subgroups.
```

---

# General Rule for Interpreting SHAP Beeswarm Plots

### 🔴 Red dots on RIGHT

> High feature value increases risk.

Examples:

```python id="red-right"
prior_admission_count
charlson_score
```

---

### 🔴 Red dots on LEFT

> High feature value lowers risk.

Example:

```python id="red-left"
los_days
```

---

### Red and Blue Mixed on Both Sides

> Nonlinear or interaction effect.

Examples:

```python id="mixed-effects"
age_at_admission
hemoglobin
WBC
```

Meaning:

> The model learned more complex relationships rather than simple one-direction effects.

---

# Key Takeaway

The SHAP beeswarm plot demonstrates that:

* prior healthcare utilization
* comorbidity burden
* age
* treatment complexity
* hospitalization characteristics

all contribute differently to readmission risk.

Importantly, SHAP reveals that some predictors behave **nonlinearly** and may interact with other clinical variables, providing deeper insight than traditional linear models.

In this project:

* **Prior admissions** consistently increased risk.
* **Longer LOS** unexpectedly lowered risk after accounting for severity.
* **Age** demonstrated heterogeneous effects across patient populations.

These findings illustrate the value of interpretable machine learning in healthcare risk prediction.

<img width="2369" height="2819" alt="shap_bar_plot" src="https://github.com/user-attachments/assets/7143419f-8e99-4a9e-aa58-9a315773ab5d" />
<img width="2372" height="2817" alt="shap_beeswarm_plot" src="https://github.com/user-attachments/assets/ae79e8fc-826d-4b2f-bc95-41ec19a162a5" />


