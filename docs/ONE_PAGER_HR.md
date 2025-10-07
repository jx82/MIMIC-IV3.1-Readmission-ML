# Readmission Risk Model — One‑Pager (Plain English)

**What is this?**  
A project to estimate whether a patient will come back to the hospital within **30 days** of discharge.

**Why it matters:**  
Readmissions are stressful for patients and costly for hospitals. If we can **see risk early**, care teams can **prioritize follow‑ups** and potentially prevent avoidable returns.

**What data is used:**  
**MIMIC‑IV v3.1** — a large, **de‑identified** hospital dataset used for research. No private patient information is stored here.

**What the model gives:**  
A **risk score** for each discharge (higher = more likely to be readmitted).

**How performance is checked:**  
- **AUROC/AUPRC** (overall quality)  
- **Calibration** (are probabilities realistic?)  
- **Recall@k** (among top‑risk patients, how many true readmissions did we correctly catch?)

**Safeguards:**  
- No raw patient data in the repo  
- De‑identified research data only  
- Basic fairness checks by age/sex

**Tools:** Python, SQL/PostgreSQL, XGBoost, SHAP; optional dashboards in Tableau/Power BI.

_Last updated: 2025-10-07_
