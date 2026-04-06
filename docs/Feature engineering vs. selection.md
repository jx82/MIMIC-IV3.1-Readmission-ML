# Feature Engineering vs. Feature Selection  
## Example: Medication Complexity in Tier 3 Readmission Modeling

---

## 1. Key Idea

**Feature engineering** and **feature selection** are related, but they are not the same step.

### Feature Engineering
Feature engineering means creating useful candidate variables from raw data.

### Feature Selection
Feature selection means deciding which variables should be included in the final model.

In practice, we often engineer multiple variables representing the same concept, then decide which one to keep using model comparison.

---

## 2. Example: Medication Complexity

In this project, medication-related features were engineered from the `prescriptions` table.

| Feature | Definition | Clinical Meaning |
|--------|------------|------------------|
| `medication_count` | Total prescriptions during admission | Treatment volume |
| `unique_drug_count` | Number of distinct drugs | Medication complexity |
| `polypharmacy_flag` | ≥5 unique drugs | High-risk threshold |

These are all valid features, but not all should be used in the final model.

---

## 3. Why Engineer All Three?

At the feature engineering stage, we create multiple representations:

- `medication_count` → volume  
- `unique_drug_count` → diversity  
- `polypharmacy_flag` → threshold  

This allows:

- flexibility in modeling  
- comparison across representations  
- better understanding of clinical signals  

---

## 4. Feature Relationship
polypharmacy_flag = (unique_drug_count >= 5)

This shows:

- `polypharmacy_flag` is derived from `unique_drug_count`
- It does not add new information
- Using both may introduce redundancy

---

## 5. Model Comparison Strategy

We test different representations:

- Model A: + `medication_count`
- Model B: + `unique_drug_count`
- Model C: + `polypharmacy_flag`
- Model D: + multiple features

### What we evaluate:

- ROC-AUC
- Stability
- Interpretability

---

## 6. Interpretation of Results

### Case 1: `unique_drug_count` performs best

- strongest predictive signal  
- captures more detailed information  

👉 keep it in final model

---

### Case 2: `polypharmacy_flag` performs similarly

- simpler and easier to explain  

👉 useful for reporting:

> “Patients with ≥5 medications have higher readmission risk”

---

### Case 3: `medication_count` underperforms

- less clinically meaningful  

👉 drop from final model

---

### Case 4: Using all features adds no gain

- redundancy present  
- no improvement in ROC  

👉 keep only most informative feature

---

### Case 5: Tree models benefit from multiple features

- RF / XGBoost can handle redundancy  

👉 may include both continuous + flag

---

## 7. Final Recommendation

### Logistic Regression

Use:

- `unique_drug_count`

Avoid:

- `polypharmacy_flag` (redundant)
- `medication_count` (less informative)

---

### Tree-Based Models

Test:

- `unique_drug_count`
- `polypharmacy_flag`

---

### Clinical Communication

Use:

- `polypharmacy_flag`

---

## 8. Key Takeaway

Feature engineering and feature selection are different:

- Feature engineering → create multiple candidates  
- Feature selection → choose the best ones  

In this project:

- multiple medication features were engineered  
- only the most informative are used in modeling  

---

## 9. Interview Explanation

> I engineered multiple representations of medication complexity—count, diversity, and a threshold-based indicator. Then I used model comparison and redundancy analysis to select the most informative feature for the final model, while keeping simpler features for interpretability.

---
