# Research Design Discussion: Repeated Admissions and Study Limitations

**Project:** MIMIC-IV recorded 30-day hospital return prediction  
**Discussion recorded:** October 28, 2026  
**Status:** Working design memo. Revisit after data review and before finalizing model development and evaluation.

> One row per admission defines the prediction occasion. It does not make repeated admissions from the same patient independent observations.

## 1. Purpose of this document

This memo records a research-design question identified during Step 4: how should the study use and interpret multiple admissions from the same patient?

The question affects the entire pipeline, including the target population, feature history, data splitting, model fitting, uncertainty estimates, and reporting. It is not solely a feature-engineering issue.

The current admission-level design remains a candidate primary approach. The alternatives and proposed checks below are documented for later review; they are not completed analyses or a final statistical analysis plan.

## 2. Current study design and confirmed sample

| Element | Current definition or status |
|---|---|
| Data | MIMIC-IV v3.1 hospital records |
| Unit of observation | One eligible index admission, identified by `hadm_id` |
| Patient grouping | `subject_id`; a patient can contribute multiple index admissions |
| Prediction point | Index discharge |
| Outcome | A qualifying recorded return starting strictly after discharge and no later than exactly 30 elapsed days afterward |
| Encounter scope | Elective and observation admissions are included under the established definitions |
| Final Step 3 cohort | 524,309 admissions across 216,032 patients |
| Positive outcome | 106,111 admissions (20.24%) |
| Negative outcome | 418,198 admissions (79.76%) |
| Negative-label interpretation | No qualifying return was recorded; complete follow-up, survival, and absence of readmission elsewhere are not guaranteed |
| Feature eligibility | Information available by index discharge; availability requires source-specific review |
| Predictor/target separation | Future-return and mortality audit information remains separate in `label_audit_step3.csv` |
| Planned feature comparisons | Tier 1; Tier 1 + Tier 2; Tier 1 + Tier 2 + Tier 3 |
| Downstream validation | Patient splitting and revised-cohort model evaluation remain to be implemented and verified |

The cohort averages approximately 2.43 admissions per patient. This average does not describe the distribution of admission counts or quantify the degree of within-patient correlation.

## 3. Why repeated admissions matter

Admissions from the same patient can share chronic conditions, persistent social circumstances, care patterns, and unmeasured characteristics. Measurements and treatment may change between stays, but that does not erase the shared patient context.

### Illustrative admission sequence

| Stay | Role as an index observation | Relationship to another stay |
|---|---|---|
| A | Predict return risk at discharge from A | B can establish a positive outcome for A if B qualifies and starts within A's window |
| B | Can also receive its own prediction if eligible as an index stay | B is an outcome event for A and a separate prediction occasion |
| C | Can receive another prediction if eligible | May establish the outcome for B; it may also fall within another index window |

This dual role is not automatically leakage. At each prediction occasion, features must be restricted to information available by that index discharge. Outcome events may be assessed afterward. Within-patient labels and windows can nevertheless be dependent.

### Separate methodological concerns

| Concern | Why it matters | What does not fully solve it |
|---|---|---|
| Patient overlap across partitions | A model can encounter the same person's patterns during development and evaluation | Removing IDs from predictors alone |
| Dependence within a partition | Ordinary independent-row uncertainty calculations may misrepresent precision | Patient splitting alone |
| Unequal admission counts | Frequent users contribute more training loss and more evaluation observations | Patient-level bootstrap alone |
| Linked outcomes and overlapping windows | Several observations can reflect related episodes or return events | One-row-per-admission formatting |
| Historical feature availability | A prior encounter may be known, while its eventual discharge or finalized coding was not yet known | Sorting all records by time alone |
| Predictive versus causal interpretation | Shared patient factors can help explain observed associations | SHAP explanations or feature importance alone |

## 4. What population and prediction occasion do we want to represent?

There is no universally correct sampling strategy independent of the intended use. The choice changes the question answered.

| Design | Question represented | Benefit | Tradeoff |
|---|---|---|---|
| All eligible admissions, equal admission weight | How well does the model perform across eligible discharge occasions? | Uses repeated opportunities for discharge-time prediction and retains changing clinical information | Frequent users have greater influence |
| One first observed eligible admission per patient | How well does the model perform at the earliest eligible encounter observed in this dataset? | One observation per patient; simple interpretation | First observed is not necessarily first-ever; later clinical contexts are omitted |
| One randomly selected eligible admission per patient | How well does the model perform at a sampled observed encounter for each patient? | Gives each patient one observation without always selecting the earliest stay | Discards information; results depend on the sampling rule and seed |
| All admissions with inverse admission-count weights | How well does the model perform when each patient's total contribution is equal? | Retains encounters while reducing dominance by frequent users | Defines a different weighted objective; full observed admission counts may not be available prospectively |
| Longitudinal or recurrent-event design | How does risk evolve across a patient's observed sequence of encounters? | Can represent repeated history or event timing explicitly | Greater complexity and additional assumptions; may change the target |

Admission-weighted and patient-weighted results need not agree. Neither weighting is automatically unbiased for every clinical use. The intended population and prediction occasion must be stated first.

## 5. Examples from published readmission research

These examples illustrate methodological options; they are not a systematic review or evidence that one approach is universally preferred. Their populations, outcome definitions, and feature timing differ from this project.

| Study | Relevant reported method | Design lesson |
|---|---|---|
| *A Public-Private Partnership Develops and Externally Validates a 30-Day Hospital Readmission Risk Prediction Model* (2013) [1] | Randomly sampled one consecutive index/readmission encounter pair per patient for modeling | Selecting one index occasion per patient is a published strategy |
| Fleming et al., *Derivation and Validation of a 30-Day Heart Failure Readmission Model* (2014) [2] | Used generalized estimating equations to account for repeated hospitalizations | Repeated admissions can be retained with explicit correlation-aware regression |
| *Uncertainty-calibrated adaptation of clinical transformer foundation models enhances in-hospital mortality and hospital readmission prediction* (2026) [3] | Reported patient-level splits for admission-level MIMIC-IV prediction tasks | Admission-level modeling can be combined with patient-disjoint evaluation |
| *Timing of 30-Day Hospital Readmission Risk and Its Implications for Clinical Utility* (2026) [4] | Reported patient-level cluster bootstrap confidence intervals | Performance uncertainty can account for patient clustering |

These methods operate at different stages. Patient splitting, correlation-aware regression, and cluster bootstrap are complementary tools, not interchangeable fixes. Published practice alone does not establish that our implementation is valid.

## 6. Proposed primary analysis and alternatives to revisit

| Component | Working proposal | Status and unresolved choice |
|---|---|---|
| Primary observation set | Retain all finalized eligible index admissions | Working proposal; justify against intended discharge-time use |
| Training/validation/test partition | Keep each patient's admissions in exactly one partition | Planned; verify patient-ID disjointness |
| Cross-validation/tuning | Keep patients together in every fold | Planned; avoid ordinary admission-level folds |
| Learned preprocessing | Fit within training data, and within each training fold during tuning | Planned; applies to imputation, scaling, encoding, selection, and data-driven grouping |
| Primary evaluation weighting | Equal weight per admission | Proposed; describe results as admission-level performance |
| Performance uncertainty | Resample held-out patients with replacement, retaining their full admission clusters | Proposed; specify replicate count, intervals, and metric handling |
| Single-admission sensitivity | Select one eligible index admission per patient before model comparison | Proposed; decide first versus random and whether to repeat random sampling |
| Patient-weighted sensitivity | Consider weighting each held-out admission by the inverse of its patient's eligible admission count | Optional; define clearly as a retrospective weighted analysis |
| Inferential regression | Consider GEE or patient-clustered standard errors if reporting association estimates and uncertainty | Optional; distinct from the predictive model comparison |
| External/temporal validation | Define a feasible additional validation design | Unresolved; current source alone does not establish transportability |

### Different evaluation targets require different splits

A patient-disjoint random split evaluates performance for patients absent from model fitting, within the source population. It does not establish future-calendar performance or performance at another hospital.

A temporal split can represent later prediction occasions and may legitimately include patients seen earlier in training. That answers a different operational question and needs strict chronological feature construction. If both patient disjointness and temporal generalization are desired, the design must explicitly enforce both. MIMIC's shifted dates require care when defining calendar-time validation; arbitrary shifted years should not be treated as a shared real calendar across patients.

### Scope of a patient-level bootstrap

For a fixed fitted model, resampling held-out patients estimates uncertainty in evaluation metrics due to the sampled test patients while preserving their observed within-patient dependence. It does not by itself capture variability from model fitting, tuning, training-sample selection, or hospital selection. Broader uncertainty would require a broader resampling and refitting design.

If a sampled patient is drawn more than once, that patient's complete admission cluster must contribute with the corresponding multiplicity. Simply filtering to unique sampled patient IDs is not a valid implementation of sampling with replacement.

## 7. Model fitting and interpretation

| Method or output | How repeated admissions enter the issue | Reporting implication |
|---|---|---|
| Standard predictive logistic regression | Can be fitted to admission rows, but conventional independent-row coefficient uncertainty does not account for clustering | Do not report ordinary coefficient p-values or confidence intervals as if rows were independent |
| GEE | Models a population-average association while accounting for specified within-patient dependence | A possible inferential analysis; requires assumptions and does not establish causality |
| Mixed-effects logistic regression | Represents patient-specific heterogeneity through random effects | Predictions for unseen patients require an explicit treatment of unavailable patient effects |
| Random Forest / XGBoost | Repeated observations can influence fitting even though the algorithms do not report conventional regression standard errors | Use patient-grouped validation; do not claim the algorithm automatically resolves dependence |
| SHAP / feature importance | Describes the fitted model's behavior; may reflect persistent patient context and correlated predictors | Avoid causal or intervention-effect language |
| Prior-utilization features | Summarize observed history and can help prediction | They do not remove within-patient dependence or measure complete lifetime use |

For this project, tier comparisons should use the same eligible admissions, patient partitions, and evaluation definitions. Missing clinical measurements should not silently produce a different cohort for richer tiers.

## 8. Broader limitations connected to this design

| Limitation | Potential implication | Planned response or discussion |
|---|---|---|
| Incomplete observation of subsequent care | A negative label can include readmission elsewhere or incomplete follow-up | Use the phrase 'qualifying recorded return'; avoid claiming complete capture |
| Death after discharge | A patient can die without returning and remain negative under the current binary target | State this interpretation; consider a competing-risk target only as a separately defined analysis |
| Planned and observation returns included | The target differs from unplanned inpatient readmission or preventable readmission | Avoid direct performance comparisons without checking target alignment |
| Overlap/timing exclusions | Excluded records may represent different care pathways or administrative patterns | Report exclusions; examine selection implications before generalizing |
| Unequal history coverage | Earlier observed admissions have less available prior history; zero counts may reflect limited observation | Document source coverage and consider history-availability sensitivity analyses |
| Timing of source eligibility | Retrospective filtering on a prior stay's eventual discharge can use information unavailable at an earlier prediction occasion | Audit whether counted historical stays were completed by the prediction cutoff, or justify start-only eligibility without future-dependent screening |
| Retrospective coding and documentation | Diagnoses, procedures, or results associated with a stay may become available after discharge | Review event and availability timestamps; document unverifiable availability |
| Single source institution and care context | Learned patterns may not transfer to other settings | Present internal validation as internal; pursue external validation if feasible |
| Administrative demographic grouping | Broad categories lose detail and missingness may reflect documentation | Preserve original fields; consider subgroup performance with appropriate uncertainty |
| Many analyst decisions during data review | Repeated outcome-guided choices could make evaluation optimistic | Record decisions and reserve final test results from model/feature selection |

## 9. Review questions after data review

| Priority | Question to resolve | Evidence or action needed |
|---|---|---|
| High | Is the intended unit an eligible discharge occasion or an equally weighted patient? | Write the intended-use statement and primary evaluation weighting |
| High | How concentrated are admissions among frequent users? | Admission-count distribution, percent with multiple stays, and share of rows from high-utilization patients |
| High | Are all validation and tuning partitions grouped by patient? | Automated patient-overlap checks |
| High | Does any historical feature use later documentation or eventual encounter outcomes? | Source-specific temporal audit |
| High | What uncertainty will reported confidence intervals cover? | Define patient bootstrap and whether model refitting is included |
| Medium | How sensitive are results to retaining repeated admissions? | Predefine and run a one-admission-per-patient analysis |
| Medium | Do conclusions change with patient-weighted evaluation? | Compare discrimination and calibration under both weighting schemes |
| Medium | Does performance differ by prior-use burden? | Prespecified strata and patient-clustered uncertainty |
| Medium | Are coefficients being used for prediction or inference? | Separate predictive modeling from inferential regression reporting |
| Medium | Which additional validation design is feasible? | Assess patient, temporal, geographic, and dataset constraints |

## 10. Decision log and completion checklist

| Date | Decision or issue | Status |
|---|---|---|
| October 22, 2026 | Identified dependence among admissions from the same patient | Documented |
| October 28, 2026 | Consolidated design alternatives and limitations in this memo | Documented |
| Pending | Finalize primary observation and weighting strategy | Open |
| Pending | Finalize grouped validation and uncertainty procedures | Open |
| Pending | Choose single-admission sensitivity rule before examining its results | Open |
| Pending | Update Methods, Results, and Limitations after analyses | Open |

- [ ] Complete current data and feature review.
- [ ] Review this memo before finalizing Steps 5–6.
- [ ] Record the final analysis plan and its rationale.
- [ ] Verify patient separation in every development/evaluation partition.
- [ ] Audit historical-feature availability at each prediction cutoff.
- [ ] Run and report the selected sensitivity analyses.
- [ ] Distinguish completed analyses from proposed work in GitHub documentation.

## 11. Provisional Methods and Limitations wording

**Methods draft — use only after the procedures are implemented and verified:**

The unit of prediction was an eligible hospital admission, with risk estimated at discharge. Patients could contribute multiple index admissions. Training, validation, and test partitions were constructed at the patient level so that admissions from one patient did not cross partitions. Learned preprocessing was fitted using training data only. Primary metrics gave equal weight to each eligible admission. Confidence intervals for held-out performance were estimated by resampling patients and retaining their admission clusters.

**Limitations draft — applicable to the current design:**

Repeated admissions from the same patient are dependent observations. Retaining all eligible admissions represents repeated discharge-time prediction occasions, but gives patients with frequent admissions greater influence in admission-level fitting and evaluation. Patient-disjoint splitting addresses overlap across development and evaluation partitions; it does not remove within-patient dependence, establish temporal or external validity, or make feature associations causal. The binary outcome captures qualifying returns recorded in the available data and does not guarantee complete follow-up, survival throughout the window, or capture of admissions elsewhere. The consequences of alternative sampling and weighting strategies require further evaluation.

## References and reading notes

1. *A Public-Private Partnership Develops and Externally Validates a 30-Day Hospital Readmission Risk Prediction Model* (2013). [Full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC3812998/). Relevant issue: one sampled encounter pair per patient.
2. Fleming et al. *Derivation and Validation of a 30-Day Heart Failure Readmission Model* (2014). [PubMed](https://pubmed.ncbi.nlm.nih.gov/25200338/). Relevant issue: GEE for repeated hospitalizations.
3. *Uncertainty-calibrated adaptation of clinical transformer foundation models enhances in-hospital mortality and hospital readmission prediction* (2026). [Full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC13354191/). Relevant issue: patient-level splitting in admission-level prediction.
4. Alkayali et al. *Timing of 30-Day Hospital Readmission Risk and Its Implications for Clinical Utility* (2026). [Article](https://jamanetwork.com/journals/jamanetworkopen/fullarticle/2852734). Relevant issue: patient-level cluster bootstrap; its competing-risk target differs from this project's binary target.
5. [MIMIC-IV v3.1 documentation](https://physionet.org/content/mimiciv/3.1/). Review source coverage and deidentification constraints when finalizing temporal validation and feature availability.

Before formal manuscript submission, review full methods and supplements for the cited studies and complete bibliographic details. This memo uses them as design examples, not a comprehensive assessment of their validity.
