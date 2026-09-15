# MIMIC-IV Readmission Project --- Reconstruction Notes

> **Purpose:** My working memory document. Reconstruct what I actually
> did before changing or improving the project.
>
> **Rule:** Write from memory first → inspect actual code → correct
> these notes. If I do not know, write **???** rather than guessing.

## Quick Project Snapshot

**Project goal:** ???

**Prediction target:** ???

**Unit of observation:** ???

**Prediction time / intended use:** ???

**Main models:** Logistic Regression / Random Forest / XGBoost

**Main evaluation metrics:** ???

**Current best result:** ???

------------------------------------------------------------------------

# 1. Research Question

### What am I predicting?

???

### Why 30-day readmission?

???

### Why is this clinically or operationally useful?

???

### What would the model output?

???

### Questions to verify

-   [ ] ???
-   [ ] ???

------------------------------------------------------------------------

# 2. Cohort Definition

### What does one observation represent?

???

### MIMIC-IV source tables used

-   `admissions`
-   `patients`
-   ???
-   ???

### Key identifiers

  ID             Meaning   How I used it
  -------------- --------- ---------------
  `subject_id`   ???       ???
  `hadm_id`      ???       ???
  Other          ???       ???

### Inclusion criteria

-   ???
-   ???

### Exclusion criteria

-   ???
-   ???

### Cohort counts

  Stage                Admissions/rows   Unique patients Notes
  ------------------ ----------------- ----------------- -------
  Initial                          ???               ??? 
  After exclusions                 ???               ??? 
  Final cohort                     ???               ??? 

### Interview explanation

"My study cohort consisted of..."

???

------------------------------------------------------------------------

# 3. 30-Day Readmission Target

**Target variable name:** `???`

### Positive case (1)

???

### Negative case (0)

???

### Label creation steps

1.  ???
2.  ???
3.  ???
4.  ???

### Intermediate variables

  Variable               Purpose   Predictor or label-building only?
  ---------------------- --------- -----------------------------------
  `next_admittime`       ???       ???
  `days_to_next_admit`   ???       ???
  Other                  ???       ???

### Special cases

**Transfers:** ???

**Planned/elective readmissions:** ???

**Deaths:** ???

**Same-day readmission:** ???

**Last observed admission:** ???

### Leakage warning

Variables used to create the outcome that must not enter predictors: -
??? - ???

------------------------------------------------------------------------

# 4. Feature Engineering

## 4A. Tier 1 --- Administrative Baseline

  Feature                       Meaning   Source   Available at prediction time?   Notes
  ----------------------------- --------- -------- ------------------------------- -------
  Age                           ???       ???      ???                             
  Gender                        ???       ???      ???                             
  Race/grouped race             ???       ???      ???                             
  Insurance/grouped insurance   ???       ???      ???                             
  Admission type                ???       ???      ???                             
  Prior utilization             ???       ???      ???                             

**Grouping/mapping logic:** ???

## 4B. Tier 2 --- Clinical Burden & Care Intensity

  Feature               Meaning   Source   Implemented?   Notes
  --------------------- --------- -------- -------------- -------
  LOS                   ???       ???      ???            
  ICU flag              ???       ???      ???            
  Diagnosis count       ???       ???      ???            
  Comorbidity measure   ???       ???      ???            
  Procedure count       ???       ???      ???            
  Discharge context     ???       ???      ???            

**Charlson/comorbidity work actually completed:** ???

**What was only planned:** ???

## 4C. Tier 3 --- Physiologic & Treatment Signals

### Labs / vitals

  Feature      Summary used   Time window   Missingness   Notes
  ------------ -------------- ------------- ------------- -------
  Creatinine   ???            ???           ???           
  WBC          ???            ???           ???           
  Hemoglobin   ???            ???           ???           
  Sodium       ???            ???           ???           
  Potassium    ???            ???           ???           
  SpO2         ???            ???           ???           
  Other        ???            ???           ???           

### Medication features

-   Medication count: ???
-   Polypharmacy flag: ???
-   Other: ???

### Missingness indicators

-   ???
-   ???

**Could missingness indicate care setting rather than random absence?**\
???

------------------------------------------------------------------------

# 5. Leakage Prevention

### My prediction-time rule

"At the point when the model makes a prediction, would this information
actually be known?"

**Intended prediction point:** ???

  Variable                            Keep/Drop   Why?
  ----------------------------------- ----------- ------
  `next_admittime`                    Drop        ???
  `days_to_next_admit`                Drop        ???
  `hospital_expire_flag`              ???         ???
  `deathtime`                         ???         ???
  `edregtime`                         ???         ???
  `edouttime`                         ???         ???
  `admit_provider_id`                 ???         ???
  Raw race/insurance/admission type   ???         ???
  Discharge location                  ???         ???
  Other                               ???         ???

### Explain leakage in my own words

???

------------------------------------------------------------------------

# 6. Train / Validation / Test Split

**Split method:** ???

**Grouping variable:** `???`

**Random seed:** ???

  Split          Rows   Unique patients   Readmission rate
  ------------ ------ ----------------- ------------------
  Train           ???               ???                ???
  Validation      ???               ???                ???
  Test            ???               ???                ???

### Why split by patient?

???

### Why could admission-level random splitting be risky?

???

------------------------------------------------------------------------

# 7. Preprocessing Pipeline

### Numeric features

-   ???
-   ???

### Categorical features

-   ???
-   ???

### Binary features

-   ???
-   ???

  Feature type   Imputation   Encoding   Scaling
  -------------- ------------ ---------- ---------
  Numeric        ???          N/A        ???
  Categorical    ???          ???        N/A
  Binary         ???          ???        ???

### Why preprocessing belongs inside the pipeline

???

### Explain ColumnTransformer in plain English

???

### Explain sklearn Pipeline in plain English

???

------------------------------------------------------------------------

# 8. Models

## Logistic Regression

**Why used:** ???

**Important settings:** ???

**ROC-AUC:** ???

**PR-AUC:** ???

**What I learned:** ???

## Random Forest

**Why used:** ???

**Important settings:** ???

**ROC-AUC:** ???

**PR-AUC:** ???

**What I learned:** ???

## XGBoost

**Why used:** ???

**Important settings:** ???

**ROC-AUC:** ???

**PR-AUC:** ???

**What I learned:** ???

------------------------------------------------------------------------

# 9. Model Comparison

  ---------------------------------------------------------------------------------
  Model               ROC-AUC         PR-AUC Calibration   Main        Main
                                                           advantage   limitation
  ------------ -------------- -------------- ------------- ----------- ------------
  Logistic                ???            ??? ???           ???         ???
  Regression                                                           

  Random                  ???            ??? ???           ???         ???
  Forest                                                               

  XGBoost                 ???            ??? ???           ???         ???

  Tuned final             ???            ??? ???           ???         ???
  model                                                                
  ---------------------------------------------------------------------------------

**Which model would I choose and why?**\
???

------------------------------------------------------------------------

# 10. Evaluation

**ROC-AUC --- what does it tell me?**\
???

**PR-AUC --- why useful for readmission?**\
???

**Confusion matrix:** ???

**Sensitivity/Recall:** ???

**Specificity:** ???

**Precision/PPV:** ???

**Calibration completed?** ???

**Why might calibration matter?**\
???

**Threshold analysis completed?** ???

**How does threshold choice affect clinical workload and missed
high-risk patients?**\
???

------------------------------------------------------------------------

# 11. SHAP / Interpretation

**Which model did I explain with SHAP?** ???

### Top predictors

1.  ???
2.  ???
3.  ???
4.  ???
5.  ???

### What do the findings suggest?

???

> SHAP explains how features influence model predictions. It does not
> establish causality.

------------------------------------------------------------------------

# 12. Tier Comparison

  Feature set      Model     ROC-AUC   PR-AUC Added information
  ---------------- ------- --------- -------- --------------------------------
  Tier 1           ???           ???      ??? Administrative baseline
  Tier 1 + 2       ???           ???      ??? Clinical burden/care intensity
  Tier 1 + 2 + 3   ???           ???      ??? Physiologic/treatment signals

**Did I complete this comparison?** ???

**If not: MUST or NICE-TO-HAVE?** ???

------------------------------------------------------------------------

# 13. Limitations

-   [ ] Single-center / generalizability
-   [ ] Retrospective observational data
-   [ ] Outcome definition limitations
-   [ ] Missing data / informative missingness
-   [ ] Prediction-time assumptions
-   [ ] Temporal validation
-   [ ] External validation
-   [ ] No prospective clinical validation
-   [ ] Other: ???

### My three most important limitations

1.  ???
2.  ???
3.  ???

------------------------------------------------------------------------

# 14. Things I Don't Remember Yet

Do not stop reconstruction every time I find a gap.

-   [ ] ???
-   [ ] ???
-   [ ] ???
-   [ ] ???

------------------------------------------------------------------------

# 15. Things to Fix Later --- NOT During Recall

-   [ ] ???
-   [ ] ???
-   [ ] ???
-   [ ] ???

------------------------------------------------------------------------

# 16. GitHub / Portfolio Notes

### Best figures to show

-   [ ] Model comparison
-   [ ] ROC curve
-   [ ] PR curve
-   [ ] SHAP summary
-   [ ] Calibration plot
-   [ ] Other: ???

### README structure

1.  Overview / problem
2.  Data
3.  Cohort
4.  Target
5.  Features
6.  Leakage prevention
7.  Modeling
8.  Results
9.  Interpretation
10. Limitations

**Important:** Do not publish restricted MIMIC-IV patient-level/source
data.

------------------------------------------------------------------------

# 17. CV / LinkedIn Notes

### Verified technologies I can claim

-   Python: ???
-   pandas: ???
-   scikit-learn: ???
-   XGBoost: ???
-   SHAP: ???
-   SQL: ???
-   Other: ???

### Verified results worth mentioning

-   ???
-   ???

### Draft résumé bullet ideas

-   ???
-   ???
-   ???

------------------------------------------------------------------------

# 18. Interview Cheat Sheet

### 30-second explanation

???

### 2-minute explanation

???

### Questions I must answer confidently

-   [ ] What problem were you solving?
-   [ ] How did you define 30-day readmission?
-   [ ] How did you construct the cohort?
-   [ ] What does one row represent?
-   [ ] What features did you use?
-   [ ] How did you prevent leakage?
-   [ ] Why split by `subject_id`?
-   [ ] Why LR, RF, and XGBoost?
-   [ ] Why ROC-AUC and PR-AUC?
-   [ ] How did you handle missing data?
-   [ ] What did SHAP show?
-   [ ] What was final model performance?
-   [ ] What are the major limitations?
-   [ ] What would you do next?

------------------------------------------------------------------------

# 19. Daily Recall Log

  --------------------------------------------------------------------------
  Date           Section        Remembered     Forgotten /    Questions
                 reviewed                      corrected      
  -------------- -------------- -------------- -------------- --------------
                                                              

                                                              

                                                              

                                                              
  --------------------------------------------------------------------------

------------------------------------------------------------------------

# 20. Final Self-Test

-   [ ] I can explain the project without opening code.
-   [ ] I know exactly what my cohort is.
-   [ ] I know exactly how the target is defined.
-   [ ] I know what one row represents.
-   [ ] I understand Tier 1, Tier 2, and Tier 3.
-   [ ] I can identify leakage risks.
-   [ ] I can explain patient-level splitting.
-   [ ] I understand the preprocessing pipeline.
-   [ ] I can explain LR, RF, and XGBoost.
-   [ ] I know my VERIFIED results.
-   [ ] I can interpret SHAP carefully.
-   [ ] I can explain the limitations.
-   [ ] I can give a 5--10 minute presentation without notes.

------------------------------------------------------------------------

## Reconstruction Principle

**RECALL → VERIFY → EXPLAIN → PUBLISH → APPLY**
