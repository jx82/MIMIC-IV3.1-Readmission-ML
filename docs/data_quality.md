# 🏥 Data Quality Validation for Readmission Modeling

## 📌 Objective

Ensure the cohort used for 30-day readmission modeling is:

- Clinically valid  
- Free of label leakage  
- Consistent across data sources  
- Aligned with healthcare industry standards  

---

## 🔍 Step 1 — Initial Data Inspection

We first examined key variables:

- `hospital_expire_flag`
- `discharge_location`
- admission timestamps  



```python
cohort["discharge_location"].value_counts(dropna=False)

---

## 🚫 Step 2 — Remove In-Hospital Deaths

### Rationale

Patients who die during hospitalization:

* cannot be readmitted
* introduce structural label bias

### Implementation

```python
cohort = cohort[cohort["hospital_expire_flag"] == 0]
```

### Validation

```python
cohort["hospital_expire_flag"].value_counts()
```

**Result:**

| hospital_expire_flag | count   |
| -------------------- | ------- |
| 0                    | 528,852 |

✅ All in-hospital deaths removed

---

## 🚫 Step 3 — Remove Hospice Discharges

### Rationale

Hospice patients:

* follow end-of-life care pathways
* are not part of standard readmission populations

### Implementation

```python
cohort = cohort[
    ~cohort["discharge_location"].str.contains("hospice", case=False, na=False)
]
```

### Validation

```python
cohort["discharge_location"].str.contains("hospice", case=False).sum()
```

**Result:**

| hospice cases | count |
| ------------- | ----- |
| 0             | 0     |

✅ Hospice fully removed

---

## ⚠️ Step 4 — Cross-Field Consistency Check

### Goal

Validate alignment between:

* structured flag → `hospital_expire_flag`
* text field → `discharge_location`

### Implementation

```python
pd.crosstab(
    cohort["discharge_location"],
    cohort["hospital_expire_flag"]
)
```

---

### 🚨 Key Finding

| discharge_location | hospital_expire_flag = 0 |
| ------------------ | ------------------------ |
| DIED               | 227                      |

👉 These patients:

* were NOT flagged as deaths
* but labeled `"DIED"` in discharge field

---

## 🧠 Interpretation

This indicates a **data inconsistency between structured and text-based fields**.

Common causes in EHR systems:

* coding discrepancies
* delayed updates
* system integration issues

---

## 🚫 Step 5 — Remove Inconsistent Records

### Rationale

These records:

* do not represent true clinical outcomes
* introduce misleading signals into the model

### Implementation

```python
cohort = cohort[
    ~cohort["discharge_location"].str.contains("died", case=False, na=False)
]
```

---

### Validation

```python
cohort["discharge_location"].value_counts()
```

**Result:**

| discharge_location | count |
| ------------------ | ----- |
| DIED               | 0     |

✅ Inconsistency resolved

---

## 📊 Final Cohort Summary

| Step                           | Remaining Rows |
| ------------------------------ | -------------- |
| Initial admissions             | 546,028        |
| After removing deaths          | 534,227        |
| After removing hospice         | 528,852        |
| After removing inconsistencies | 528,625        |

---

## 🎯 Key Takeaways

* Data cleaning is not just filtering — it requires cross-variable validation
* Structured and text fields may contradict each other
* Clinical logic must guide data decisions
* Small inconsistencies can introduce large modeling bias

---

## 🧠 Practical Framework for Healthcare Data Validation

### 🔷 Layer 1 — Structural Validation

* Missing values
* Duplicates

### 🔷 Layer 2 — Clinical Logic Validation

* Impossible states (e.g., dead but readmitted)
* Cohort definition

### 🔷 Layer 3 — Cross-Field Consistency

* Compare multiple variables representing the same concept

### 🔷 Layer 4 — Temporal Validation

* Ensure no future information leakage

---

## 🚀 Conclusion

In healthcare machine learning:

> The biggest risk is not overfitting — it is misunderstanding the data.

Robust validation ensures models are both **accurate and clinically meaningful**.

```

---
