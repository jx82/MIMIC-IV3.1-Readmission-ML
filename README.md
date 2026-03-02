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

---

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
