# Creating `icu_flag`: Timing Rules and Audit Trail

**Project:** MIMIC-IV 30-day recorded readmission prediction  
**Pipeline:** Step 4 — Feature engineering; Tier 2 — Clinical burden and care intensity  
**Prediction point:** Index hospital discharge  
**Status:** Implemented in the reviewed notebook; counts below transcribed from its audit outputs.

## Purpose and scope

`icu_flag` represents recorded ICU care during the index hospitalization. It supplements hospital length of stay (`los_days`): duration and ICU care describe different aspects of the admission. Two admissions of equal length can involve different care settings. ICU utilization is a proxy for care intensity, not a direct physiological severity score or a causal effect. Its association with readmission must be estimated in subsequent modeling; a higher predicted risk is not assumed.

The cohort contains **524,309 admissions across 216,032 patients** from `cohort_step3.csv`. ICU feature construction preserves admissions, identifiers, row order, and `label_readmit_30d`. The target remains a qualifying recorded return strictly after discharge and within exactly 30 elapsed days. Future-event information in `label_audit_step3.csv` is not a predictor source.

This document records the project's operational choices. It does not establish why source timestamps disagree or claim that event timestamps prove real-time record availability.

## 1. The four timestamps

| Symbol | Timestamp | Meaning |
|---|---|---|
| **A** | `admittime` | Index hospital admission |
| **I** | `intime` | ICU entry |
| **O** | `outtime` | ICU exit |
| **D** | `dischtime` | Index hospital discharge and prediction cutoff |

An arrow denotes chronological order. Equality denotes simultaneous recorded times. Hospital and ICU intervals have positive-duration overlap when `I < D` and `O > A`, assuming valid intervals and a known exit. Touching endpoints alone do not constitute positive-duration overlap. Our final feature also permits entry-based evidence when exit is missing, and applies an additional cutoff rule to early entries.

## 2. Timing examples and decisions

The following examples are illustrative, not individual patient records. Unless stated otherwise, the hospital stay is **October 2 at 12:00 through October 5 at 12:00**.

| Case | Sequence | Example ICU interval | Decision under the final rule |
|---|---|---|---|
| ICU entirely within hospital stay | **A → I → O → D** | Oct 3, 08:00 → Oct 4, 10:00 | **1**: entry is within the hospital stay. |
| ICU begins exactly at admission | **I = A → O → D** | Oct 2, 12:00 → Oct 3, 10:00 | **1**: admission boundary is included. |
| Early entry with overlap demonstrated by discharge | **I → A → O → D** | Oct 2, 08:00 → Oct 2, 18:00 | **1**: six hours of overlap, demonstrated by an exit before discharge. |
| Early entry with exit exactly at discharge | **I → A → O = D** | Oct 2, 08:00 → Oct 5, 12:00 | **1**: exit at the cutoff is included. |
| ICU ends before hospital admission | **I → O → A → D** | Oct 1, 08:00 → Oct 2, 10:00 | This record does not qualify; **missing** if no other qualifying ICU record exists. |
| ICU ends exactly at hospital admission | **I → O = A → D** | Oct 1, 08:00 → Oct 2, 12:00 | No positive-duration overlap; **missing** if this is the only evidence. |
| Entry during hospitalization, exit after discharge | **A → I → D → O** | Oct 3, 08:00 → Oct 6, 10:00 | **1** from entry alone; do not use the future exit to derive ICU duration. |
| Early entry, exit after discharge | **I → A → D → O** | Oct 2, 08:00 → Oct 6, 10:00 | **Missing** without another qualifying record: conservative early-entry rule does not use a future exit to demonstrate overlap. |
| Entry exactly at hospital discharge | **A → I = D → O** | Oct 5, 12:00 → Oct 6, 10:00 | Entry does not qualify; **missing** without another qualifying record. |
| ICU starts after discharge | **A → D → I → O** | Oct 6, 08:00 → Oct 7, 10:00 | Future entry does not qualify; **missing** without another qualifying record. |
| Entry during hospitalization, exit missing | **A → I → D**, O unknown | Oct 3, 08:00 → missing | **1**: entry is sufficient. |
| Early entry, exit missing | **I → A → D**, O unknown | Oct 2, 08:00 → missing | **Missing** without another qualifying record: overlap cannot be established under this rule. |
| No linked ICU record | No I or O | No source match | **0**: no recorded linked ICU stay in the supplied source. |

A linked `hadm_id` connects records to an admission, but does not resolve contradictory times. A nonqualifying ICU record does not prove the patient had no ICU care. Review all linked ICU records: one qualifying record is sufficient for a positive admission flag.

### Why the cutoff matters

For **A → I → D → O**, ICU entry already occurs before discharge and supports the flag without using exit. For **I → A → D → O**, the early entry conflicts with the admission boundary; our conservative rule requires an exit by discharge to establish overlap. This asymmetry is a documented design choice, not a claim that the latter patient received no ICU care. Alternative rules can be examined later in sensitivity analyses.

## Equal timestamps: which boundaries are acceptable?

Equal recorded times are not automatically errors. Their meaning depends on which events coincide. ICU care is a component of hospital care; for the same encounter, the expected interval is `A <= I < O <= D`. Direct ICU admission can give `I = A`, and discharge directly from ICU can give `O = D`. These are illustrative interpretations, not verified explanations of individual records.

| Equality | Example sequence | Interpretation | Handling under our rule |
|---|---|---|---|
| **I = A** | **A = I → O → D** | ICU entry coincides with hospital admission. | **1**, provided `I < D`; the admission boundary is included. |
| **O = D** | **A → I → O = D** | ICU exit coincides with hospital discharge. | **1** from qualifying entry; an early-entry interval also qualifies when `A < O = D`. |
| **I = A and O = D** | **A = I → O = D** | ICU stay spans the entire recorded hospital stay. | **1**, provided `A < D`. |
| **O = A** | **I → O = A → D** | The ICU interval ends exactly when hospitalization starts. | No positive-duration overlap; this record alone does not qualify. Without another qualifying record, status is **missing**. |
| **I = D** | **A → I = D → O** | ICU entry is exactly at the prediction cutoff. | Excluded by the strict `I < D` rule. Without another qualifying record, status is **missing**. |

### Concrete acceptable equality example

| Event | Recorded time |
|---|---|
| Hospital admission **A** and ICU entry **I** | October 2, 12:00 |
| ICU exit **O** and hospital discharge **D** | October 5, 12:00 |

This is **A = I → O = D**: a three-day ICU interval covering the hospital stay. Both equalities are accepted.

### Why touching endpoints are different

For **I → O = A → D**, ICU care ends at the hospital admission boundary, so there is no positive-duration overlap. For **A → I = D → O**, entry occurs at discharge and provides no recorded ICU time before discharge. The latter is also excluded by our chosen prediction-cutoff convention. Neither case proves the patient had no ICU care; another linked record can still establish a positive flag.

The implemented boundary rules remain:

- **Entry-based evidence:** `A <= I < D`.
- **Early-entry overlap evidence:** `I < A < O <= D`.
- **Ordinary positive-duration overlap with a known exit:** `I < D` and `O > A`.

The entry-based rule does not require a known exit. Equal ICU entry and exit (`I = O`) is a separate zero-duration quality issue, not resolved by the hospital-boundary equalities above; the present entry-based implementation does not explicitly exclude it. Likewise, an index hospitalization with `A = D` has no interval satisfying `A <= I < D` and should not be confused with the positive-duration example above.

These explanations clarify the existing code; they do not change the feature or its previously reported counts.

## 3. Source and linkage checks

Load the ICU source using `subject_id`, `hadm_id`, `stay_id`, `intime`, and `outtime`. Validate complete identifiers, unique `stay_id`, timestamp parsing, and patient agreement after joining to the cohort by `hadm_id` with `validate="many_to_one"`.

| Source measure | Observed count |
|---|---:|
| ICU stays in supplied source | 94,458 |
| Unique hospital admissions in ICU source | 85,242 |
| Source stays missing ICU entry | 0 |
| Source stays missing ICU exit | 14 |
| Timestamp parse failures | 0 |
| ICU stays linked to the index cohort | 80,291 |
| Index admissions with linked ICU stays | 73,420 |

The hospital cohort includes admissions without ICU source matches. Missing ICU exits are not equivalent to missing ICU entries: an entry within the hospital stay can establish positive status without an exit.

## 4. Initial timing audit

### Table 1. Discrepancies among linked ICU stays

| Check | ICU stays | Index admissions affected |
|---|---:|---:|
| Missing ICU entry | 0 | 0 |
| Missing ICU exit | 7 | 7 |
| ICU exit before ICU entry | 0 | 0 |
| ICU entry before hospital admission | 433 | 433 |
| ICU entry exactly at hospital discharge | 0 | 0 |
| ICU entry after hospital discharge | 1 | 1 |
| ICU exit after hospital discharge | 8,827 | 8,826 |

Rows may overlap and must not be added as disjoint categories. These checks flag discrepancies; they do not automatically exclude admissions or set feature values.

### Table 2. Magnitude of timing discrepancies

Hours are positive differences in the indicated direction, rounded to three decimals.

| Discrepancy | ICU stays | Minimum hours | Median hours | 95th percentile hours | Maximum hours |
|---|---:|---:|---:|---:|---:|
| Entry before hospital admission | 433 | 0.001 | 1.472 | 20.870 | 23.981 |
| Entry after hospital discharge | 1 | 6.325 | 6.325 | 6.325 | 6.325 |
| Exit after hospital discharge | 8,827 | 0.001 | 0.296 | 1.974 | 2,623.191 |

Most late-exit differences are short, but the maximum is approximately 109 days. The data do not justify describing every discrepancy as a minor administrative delay. No empirical time tolerance was chosen from these distributions.

### Table 3. Early-entry intervals at the stay level

| Early-entry condition | ICU stays |
|---|---:|
| Exit after hospital admission | 425 |
| Exit at or before hospital admission | 8 |
| Missing exit | 0 |
| **Total early-entry stays** | **433** |

The 425 intervals overlap hospital admission. The other 8 end before, or exactly at, admission. This is a **stay-level** table; the final feature is admission-level.

## 5. Admission-level review

### Table 4. Is any ICU entry within the hospital stay?

Entry qualifies for this audit when `A <= I < D`.

| Finding | Admission count |
|---|---:|
| At least one ICU entry within the hospital stay | 73,009 |
| Only early or late ICU entries | 411 |
| Of these, admissions with early entries | 411 |
| Of these, admissions with late entries | 0 |

The last two rows describe the 411 unresolved admissions and are not additional counts. The admission with the single late ICU entry also has an entry within its hospital stay; its positive evidence does not depend on the late record.

The 73,009 admissions have direct positive entry evidence. The remaining 411 require review of early intervals.

### Table 5. Do the early-only intervals overlap hospitalization?

| Finding | Admission count |
|---|---:|
| Early-only admissions with an overlapping ICU interval | 404 |
| Early-only admissions without an overlapping ICU interval | 7 |
| **Total reviewed** | **411** |

Here, overlap means at least one early record has `O > A`. This table alone does not require `O <= D`. The additional discharge-cutoff rule is applied next.

The difference between 8 non-overlapping stays in Table 3 and 7 unresolved admissions in Table 5 reflects the change in unit and the presence of other ICU records. Stay-level counts cannot be substituted for admission-level counts.

### Table 6. Apply the discharge cutoff to early overlap

| Decision | Admission count |
|---|---:|
| Early-only overlap with qualifying exit by discharge | 393 |
| Early-only overlap without qualifying exit by discharge | 11 |
| **Early-only overlapping admissions** | **404** |
| Early-only admissions without overlap | 7 |
| **Final unresolved ICU status: 11 + 7** | **18** |

These counts follow from the preceding audits and final feature output: `73,402 - 73,009 = 393` additional positive flags and `404 - 393 = 11` overlapping admissions failing the cutoff rule.

## 6. Final operational definition

For each admission:

1. Assign **1** if any linked ICU record has `A <= I < D`.
2. Otherwise assign **1** if any linked early record has `I < A < O <= D`.
3. Assign **missing** if linked ICU records exist but neither positive rule is met.
4. Assign **0** if there is no linked ICU record in the supplied source.

| Value | Meaning | Important qualification |
|---|---|---|
| 1 | Qualifying recorded ICU care | Not a direct measure of physiological severity. |
| 0 | No recorded linked ICU stay in this source | Not proof of no ICU care elsewhere or complete source coverage. |
| Missing | Linked ICU records with unresolved timing under the rules | Not automatically converted to zero. |

No admission is dropped because its ICU status is unresolved. Missing values remain unimputed in Step 4. Any learned imputation or encoding is fitted on training data only after the patient split. ICU audit tables are quality-control outputs; register only the intended predictor in the feature list.

## 7. Reproducible notebook code

This implementation assumes `cohort`, `icu_review`, `cohort_reference`, and `tier2_features` already exist from the reviewed notebook. `icu_review` contains ICU records linked to the index cohort, with parsed timestamps and validated identifiers. `cohort_reference` contains the original `subject_id`, `hadm_id`, and `label_readmit_30d` in the original order.

### A. Reproduce the two admission-level review tables

```python
import pandas as pd

# Entry at admission is included; entry at discharge is excluded.
icu_review["entry_within_index_stay"] = (
    icu_review["intime"].ge(icu_review["admittime"])
    & icu_review["intime"].lt(icu_review["dischtime"])
)
icu_review["entry_before_index_admission"] = (
    icu_review["intime"].lt(icu_review["admittime"])
)
icu_review["entry_at_or_after_index_discharge"] = (
    icu_review["intime"].ge(icu_review["dischtime"])
)

# Aggregate records to admissions: any qualifying entry is sufficient.
icu_admission_review = (
    icu_review.groupby("hadm_id", as_index=False)
    .agg(
        has_within_stay_entry=("entry_within_index_stay", "any"),
        has_early_entry=("entry_before_index_admission", "any"),
        has_late_entry=("entry_at_or_after_index_discharge", "any"),
    )
)
needs_timing_decision = (
    ~icu_admission_review["has_within_stay_entry"]
    & (
        icu_admission_review["has_early_entry"]
        | icu_admission_review["has_late_entry"]
    )
)

entry_summary = pd.Series({
    "Admissions with an ICU entry within the hospital stay":
        int(icu_admission_review["has_within_stay_entry"].sum()),
    "Admissions with only early or late ICU entries":
        int(needs_timing_decision.sum()),
    "Of these, admissions with early entries":
        int((needs_timing_decision
             & icu_admission_review["has_early_entry"]).sum()),
    "Of these, admissions with late entries":
        int((needs_timing_decision
             & icu_admission_review["has_late_entry"]).sum()),
}, name="Admission count")
display(entry_summary.to_frame())

pending_ids = icu_admission_review.loc[needs_timing_decision, "hadm_id"]
pending_icu = icu_review.loc[
    icu_review["hadm_id"].isin(pending_ids)
].copy()

# This audit checks overlap, before imposing the discharge-cutoff rule.
pending_icu["early_interval_overlaps"] = (
    pending_icu["intime"].lt(pending_icu["admittime"])
    & pending_icu["outtime"].gt(pending_icu["admittime"])
)
pending_summary = pending_icu.groupby("hadm_id")[
    "early_interval_overlaps"
].any()
display(pd.Series({
    "Early-only admissions with an overlapping ICU interval":
        int(pending_summary.sum()),
    "Early-only admissions without an overlapping ICU interval":
        int((~pending_summary).sum()),
}, name="Admission count").to_frame())
```

### B. Construct and validate `icu_flag`

```python
# Direct entry evidence does not require an ICU exit timestamp.
entry_inside = (
    icu_review["intime"].ge(icu_review["admittime"])
    & icu_review["intime"].lt(icu_review["dischtime"])
)

# Conservative rule for early entries: demonstrate overlap by discharge.
early_overlap_by_discharge = (
    icu_review["intime"].lt(icu_review["admittime"])
    & icu_review["outtime"].gt(icu_review["admittime"])
    & icu_review["outtime"].le(icu_review["dischtime"])
)

positive_by_admission = (
    icu_review.assign(
        positive_evidence=entry_inside | early_overlap_by_discharge
    )
    .groupby("hadm_id")["positive_evidence"]
    .any()
)

# Nullable integer preserves unknown status as pd.NA.
cohort["icu_flag"] = pd.Series(0, index=cohort.index, dtype="Int64")
has_linked_record = cohort["hadm_id"].isin(positive_by_admission.index)
cohort.loc[has_linked_record, "icu_flag"] = pd.NA
positive_ids = positive_by_admission.index[positive_by_admission]
cohort.loc[cohort["hadm_id"].isin(positive_ids), "icu_flag"] = 1

if "icu_flag" not in tier2_features:
    tier2_features.append("icu_flag")

# Preserve original admissions, row order, patient IDs, and labels.
pd.testing.assert_frame_equal(
    cohort[cohort_reference.columns].reset_index(drop=True),
    cohort_reference.reset_index(drop=True),
)
assert cohort["icu_flag"].dropna().isin([0, 1]).all()
display(
    cohort["icu_flag"].value_counts(dropna=False)
    .rename_axis("icu_flag").to_frame("Admissions")
)
```

## 8. Final observed results

| `icu_flag` | Admissions | Interpretation |
|---|---:|---|
| 0 | 450,889 | No linked ICU stay in supplied source |
| 1 | 73,402 | Qualifying recorded ICU care |
| Missing | 18 | Linked ICU records with unresolved timing |
| **Total** | **524,309** | **All cohort admissions retained** |

Reconciliation:

- Linked admissions: `73,420 = 73,009 + 411`.
- Early-only admissions: `411 = 404 + 7`.
- Early-only overlapping admissions: `404 = 393 + 11`.
- Positive flags: `73,402 = 73,009 + 393`.
- Missing flags: `18 = 11 + 7`.
- Full cohort: `524,309 = 450,889 + 73,402 + 18`.

The reviewed cell completed its assertions without error. The final feature remains in Tier 2 alongside hospital length of stay.

## 9. Interpretation and limitations to retain

- **Timestamp disagreement is unresolved source uncertainty.** These audits do not establish administrative delays, transfer mechanisms, or other causes.
- **Event time differs from record availability.** `I <= D` or `O <= D` does not prove that the record was entered and accessible by discharge. Real-time deployment would require availability-time validation.
- **No source match is an operational zero.** Its validity depends on the supplied ICU source's scope and linkage, not a guarantee of complete care capture.
- **The early-entry cutoff rule is conservative.** It leaves some retrospectively overlapping cases unknown. A later sensitivity analysis could compare this rule with strict in-window entry or broader overlap definitions, documenting any future-information assumptions.
- **No ICU duration is constructed here.** Exit discrepancies must be addressed separately before deriving duration.
- **Model preprocessing remains downstream.** Use a patient-level split; fit learned preprocessing on training data only. Repeated admissions remain correlated within patients.
- **Predictive association is not causation.** Model coefficients or feature importance do not establish that ICU care causes readmission.


## 10. Clinical encounter structure and source coverage

In the expected encounter structure, ICU care is a location or care-unit episode within a hospital encounter. A patient may enter through the emergency department, move to a ward, transfer to ICU, return to a ward, and then leave the hospital. Leaving ICU does not necessarily mean leaving the hospital. One hospital admission can contain multiple ICU stays.

MIMIC-IV documents `transfers` as physical locations throughout the hospital stay; `icustays` is derived from these records. ICU stays group nearby ICU episodes, so a stay identifier need not correspond to a single bed or unit. Contradictory timestamps warrant reconciliation rather than being interpreted as a clinical pathway.

**Coverage qualification:** The current MIMIC-IV ICU documentation states that ICU stays without an available heart-rate measurement are not included in `icustays` (approximately 5%). Consequently, a zero derived solely from `icustays` should be labeled precisely as no qualifying recorded stay in that source, not definitive absence of ICU utilization. A future source-completeness review can compare ICU care units in `hosp/transfers` with `icu/icustays`; this comparison has not been performed in the present audit.

Official references:

- [MIMIC-IV transfers documentation](https://mimic.mit.edu/docs/iv/modules/hosp/transfers.html)
- [MIMIC-IV ICU stays documentation](https://mimic.mit.edu/docs/iv/modules/icu/icustays.html)

These references explain source structure. The early-entry cutoff and unknown-status rules above are project-specific choices.
