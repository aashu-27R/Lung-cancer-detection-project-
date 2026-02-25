%% LIDC quickstart pipeline
% Builds index, extracts simple features, trains a basic classifier.

cfg = config();

fprintf('Building index...\n');
T = build_index(cfg);

% Save index for reuse
writetable(T, fullfile(cfg.projectRoot, 'lidc_index.csv'));
save(fullfile(cfg.projectRoot, 'lidc_index.mat'), 'T');

% Require Image Processing Toolbox for DICOM + image ops
hasDicom = exist('dicomread', 'file') == 2;
hasImresize = exist('imresize', 'file') == 2;
if ~hasDicom || ~hasImresize
    error(['Image Processing Toolbox required for DICOM reading and resizing. ' ...
        'Install it, then rerun lidc_quickstart.']);
end

fprintf('Extracting features...\n');
[X, y, info] = extract_lidc_features(T, [64 64]);

rng(42);
n = numel(y);
if n < 2
    error(['Not enough labeled CT series to train. ' ...
        'Found %d labeled series. Check XML parsing or metadata.'], n);
end

% Report class balance
classes_all = unique(y);
counts = arrayfun(@(c) sum(y == c), classes_all);
fprintf('Label counts: ');
for i = 1:numel(classes_all)
    fprintf('%g=%d ', classes_all(i), counts(i));
end
fprintf('\n');

if numel(classes_all) < 2
    % Fallback: create proxy labels by splitting on nodule count median
    if ismember('NoduleCount', info.Properties.VariableNames)
        nNod = info.NoduleCount;
        nNod = nNod(~isnan(nNod));
        if numel(unique(nNod)) > 1
            thr = median(nNod);
            y = double(info.NoduleCount >= thr);
            fprintf('Proxy labels created using NoduleCount >= median (%.1f).\n', thr);
            classes_all = unique(y);
        else
            warning(['Only one class present and NoduleCount has no variation. ' ...
                'Skipping training. Consider downloading a more diverse subset.']);
            save(fullfile(cfg.projectRoot, 'lidc_features.mat'), 'X', 'y', 'info');
            return;
        end
    else
        warning(['Only one class present. Skipping training. ' ...
            'Consider downloading a larger or more diverse subset.']);
        save(fullfile(cfg.projectRoot, 'lidc_features.mat'), 'X', 'y', 'info');
        return;
    end
end

% Split train/test (80/20) without toolbox dependency
rng(42);
idx = randperm(n);
ntest = max(1, round(0.2 * n));
testIdx = idx(1:ntest);
trainIdx = idx(ntest+1:end);

Xtrain = X(trainIdx, :);
ytrain = y(trainIdx, :);
Xtest = X(testIdx, :);
ytest = y(testIdx, :);

fprintf('Training classifier...\n');
mdl = [];
pred = [];

if exist('fitcsvm', 'file') == 2
    % Use SVM if Statistics and Machine Learning Toolbox is available
    mdl = fitcsvm(Xtrain, ytrain, 'KernelFunction', 'linear', 'Standardize', true);
    pred = predict(mdl, Xtest);
    save(fullfile(cfg.projectRoot, 'lidc_svm.mat'), 'mdl');
else
    % Toolbox-free fallback: nearest centroid classifier
    classes = unique(ytrain);
    if numel(classes) < 2
        error('Training data has only one class. Cannot train classifier.');
    end

    mu0 = mean(Xtrain(ytrain == classes(1), :), 1);
    mu1 = mean(Xtrain(ytrain == classes(2), :), 1);

    d0 = sum((Xtest - mu0).^2, 2);
    d1 = sum((Xtest - mu1).^2, 2);
    pred = classes(1) * ones(size(ytest));
    pred(d1 < d0) = classes(2);
end

acc = mean(pred == ytest);
fprintf('Accuracy: %.2f%%\n', acc * 100);

% Save features and index
save(fullfile(cfg.projectRoot, 'lidc_features.mat'), 'X', 'y', 'info');
