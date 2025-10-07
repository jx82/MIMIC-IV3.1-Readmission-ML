# Experiment: EXP-YYYYMMDD-XX (XGBoost baseline)

**Hypothesis**: Adding DRG + prior utilization improves AUROC vs demographics-only.  
**Data**: MIMIC-IV v3.1, adult index admissions, temporal split (train 2011–2016, val 2017, test 2018).  
**Features**: age, sex, LOS, discharge disposition, DRG, Elixhauser flags, prior 6-mo admits.  
**Model/Config**: XGBClassifier (seed=42, max_depth=4, eta=0.1, n_estimators=500, scale_pos_weight=…).  
**Metrics**: AUROC, AUPRC, Brier, calibration curve, recall@k.  
**Results**: AUROC=…, AUPRC=… (vs baseline AUROC=…).  
**Interpretation**: Top features by SHAP: …  
**Decision**: Keep / iterate (why).  
**Artifacts**: `notebooks/EXP-YYYYMMDD-XX.ipynb`, `models/…`, charts in `reports/`.
