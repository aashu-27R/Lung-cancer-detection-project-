# Lung-cancer-detection-project-

This repo contains a working MATLAB pipeline for a **small LIDC-IDRI subset** downloaded via the NBIA Data Retriever.

## Data layout
After download, the expected layout is:

```
manifest-1770330874189/
  metadata.csv
  LIDC-IDRI/
    LIDC-IDRI-0001/...
    LIDC-IDRI-0002/...
```

The metadata currently includes **130 series** (97 CT, 30 DX, 3 CR).

## Quick start (MATLAB)
Run:

```matlab
lidc_quickstart
```

This will:
- Build an index with labels inferred from LIDC XML
- Extract simple features from the **mid-slice** of each CT series
- Train a basic SVM classifier and report accuracy

Outputs:
- `lidc_index.csv` / `lidc_index.mat`
- `lidc_features.mat`
- `lidc_svm.mat`

## Notes
- Labels are inferred from LIDC XML: **affected = any unblindedReadNodule**.
- DX/CR (X-ray) series are included in the index but **not used for training**.
- This is a baseline pipeline; we can extend it to full 3D processing, nodule segmentation, or CNNs.

## CLID CT quick start (PNG dataset)
If you downloaded the CLID-style dataset into `archive/CT Scan` with folders:
`adenocarcinoma`, `large_cell`, `normal`, `squamous_cell`, run:

```matlab
clid_ct_quickstart
```

This runs **binary classification** (`normal` vs `cancer`).

For 4-class classification, run:

```matlab
clid_ct_quickstart('fourclass')
```

Outputs:
- `clid_ct_features_binary.mat` / `clid_ct_features_fourclass.mat`
- `clid_ct_split_binary.mat` / `clid_ct_split_fourclass.mat`
- `clid_ct_model_binary.mat` / `clid_ct_model_fourclass.mat`

Metrics helper:

```matlab
clid_ct_report_metrics('clid_ct_split_binary.mat')
clid_ct_report_metrics('clid_ct_split_fourclass.mat')
```

## CLID Results (Observed)

### Binary (`normal` vs `cancer`)
- Images used: `1027`
- Class distribution: `normal=203`, `cancer=824`
- Train/Test split: `821 / 206`
- Classifier: `nearest-centroid (fallback)`
- Accuracy: `93.20%`
- Sensitivity (cancer): `0.9515`
- Specificity: `0.8537`
- Precision (cancer): `0.9632`
- F1-score (cancer): `0.9573`
- Macro F1: `0.8953`
- Confusion matrix (rows=true, cols=pred):

```text
[35   6
  8 157]
```

### Four-class (`adenocarcinoma`, `large_cell`, `normal`, `squamous_cell`)
- Accuracy: `50.49%`
- Macro Precision: `0.5117`
- Macro Recall: `0.5260`
- Macro F1: `0.5088`
- Confusion matrix (rows=true, cols=pred):

```text
[33 20  6  9
  6 26  2 11
  5  1 34  1
 17 23  1 11]
```
