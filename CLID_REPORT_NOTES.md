# CLID Dataset and Result Notes (Report Draft)

## Dataset (CT Subset)
We used the **CT Scan** subset of the **Comprehensive Lung Cancer Imaging Dataset (CLID)** (Version 1.0.0, last updated October 21, 2025). CLID is a curated derivative dataset that aggregates lung cancer imaging data from multiple public sources and organizes them by modality.

For this project, only the **CT Scan** modality was used. The CT data is organized into four class folders:
- `adenocarcinoma`
- `large_cell`
- `normal`
- `squamous_cell`

This structure supports both:
- Binary classification (`normal` vs `cancer`)
- Multi-class classification (cancer subtype + normal)

## Data Source Provenance (from CLID README)
CLID aggregates data from multiple public sources, including:
- `programmer3/lung-ct-and-histopathological-images-dataset` (Kaggle)
- `mohamedhanyyy/chest-ctscan-images` (Kaggle)
- `andrewmvd/lung-and-colon-cancer-histopathological-images` (Kaggle; histopathology source)

## Methodology (Implemented MATLAB Baseline)
A MATLAB baseline classifier was implemented using the CT PNG images:
1. Read CT images from class folders.
2. Convert images to grayscale (if needed).
3. Resize all images to `64 x 64` pixels.
4. Flatten each image into a feature vector.
5. Perform a stratified 80/20 train-test split.
6. Train a classifier:
   - `fitcecoc` if Statistics and Machine Learning Toolbox is available, otherwise
   - nearest-centroid fallback classifier.
7. Evaluate using confusion matrix and accuracy.

## Binary Classification Result (Observed Run)
Run command:
```matlab
clid_ct_quickstart
```

Observed output:
- Total images used: `1027`
- Class distribution:
  - `normal = 203`
  - `cancer = 824`
- Train/Test split:
  - `Train = 821`
  - `Test = 206`
- Classifier used: `nearest-centroid (fallback)`
- Accuracy: `93.20%`
- Confusion matrix (rows=true, cols=pred):
  - `[[35, 6], [8, 157]]`

## Notes / Limitations
- The dataset is class-imbalanced (cancer images are more frequent than normal images).
- CLID is a derivative dataset combining multiple sources, so source-domain differences may affect generalization.
- This is a baseline using resized pixel intensities; performance may improve with CNN-based feature learning.
