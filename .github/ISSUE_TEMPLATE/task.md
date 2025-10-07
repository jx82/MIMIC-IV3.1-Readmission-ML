name: Task
description: Small unit of work
title: "[task] <short description>"
labels: ["task"]
body:
  - type: dropdown
    id: dataset
    attributes:
      label: Dataset
      options: ["mimic-v3.1", "nhanes", "other"]
  - type: dropdown
    id: stage
    attributes:
      label: Stage
      options: ["ingest","eda","features","model","eval","viz","docs"]
  - type: textarea
    id: details
    attributes:
      label: Details
      placeholder: What will you do? Acceptance criteria?
  - type: input
    id: estimate
    attributes:
      label: Time estimate
