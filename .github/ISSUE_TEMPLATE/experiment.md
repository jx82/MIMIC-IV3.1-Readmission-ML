name: Experiment
description: Record an experiment (config + results)
title: "[exp] <XGB cfg or idea>"
labels: ["experiment"]
body:
  - type: textarea
    id: hypothesis
    attributes: { label: Hypothesis }
  - type: textarea
    id: config
    attributes: { label: Data split + features + model params }
  - type: textarea
    id: results
    attributes: { label: Metrics (AUROC/AUPRC/Brier), SHAP, charts }
  - type: textarea
    id: decision
    attributes: { label: Keep/Drop + why }
