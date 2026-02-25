%% CLID CT quickstart pipeline (PNG images)
% Supports:
%   mode = 'binary'   -> cancer vs normal (default)
%   mode = 'fourclass'-> adenocarcinoma / large_cell / squamous_cell / normal
%
% Usage:
%   clid_ct_quickstart
%   clid_ct_quickstart('fourclass')

function clid_ct_quickstart(mode)
if nargin < 1
    mode = 'binary';
end

projectRoot = fileparts(mfilename('fullpath'));
dataRoot = fullfile(projectRoot, 'archive', 'CT Scan');
modeTag = lower(char(string(mode)));

if ~isfolder(dataRoot)
    error('CT dataset folder not found: %s', dataRoot);
end

if exist('imresize', 'file') ~= 2
    error('Image Processing Toolbox required (imresize).');
end

fprintf('CLID CT data root: %s\n', dataRoot);
fprintf('Mode: %s\n', mode);

[X, y, classNames, files] = load_clid_ct_png_dataset(dataRoot, mode, [64 64]);

n = numel(y);
fprintf('Images loaded: %d\n', n);
for i = 1:numel(classNames)
    fprintf('  %s: %d\n', classNames{i}, sum(y == i));
end

if n < 2 || numel(unique(y)) < 2
    error('Need at least two classes to train.');
end

% Stratified split without toolbox dependencies
rng(42);
trainMask = false(n,1);
testMask = false(n,1);
for c = 1:numel(classNames)
    idx = find(y == c);
    idx = idx(randperm(numel(idx)));
    nTest = max(1, round(0.2 * numel(idx)));
    testMask(idx(1:nTest)) = true;
    trainMask(idx(nTest+1:end)) = true;
end

if ~any(trainMask) || ~any(testMask)
    error('Train/test split failed.');
end

Xtrain = X(trainMask,:);
ytrain = y(trainMask);
Xtest = X(testMask,:);
ytest = y(testMask);

fprintf('Train: %d  Test: %d\n', numel(ytrain), numel(ytest));

pred = [];
modelInfo = struct('type', '', 'classNames', {classNames});

if exist('fitcecoc', 'file') == 2
    fprintf('Training classifier: fitcecoc\n');
    mdl = fitcecoc(Xtrain, ytrain);
    pred = predict(mdl, Xtest);
    modelInfo.type = 'fitcecoc';
    save(fullfile(projectRoot, sprintf('clid_ct_model_%s.mat', modeTag)), 'mdl', 'classNames');
else
    fprintf('Training classifier: nearest-centroid (fallback)\n');
    mu = zeros(numel(classNames), size(Xtrain,2), 'single');
    for c = 1:numel(classNames)
        mu(c,:) = mean(Xtrain(ytrain == c,:), 1);
    end
    pred = nearest_centroid_predict(Xtest, mu);
    modelInfo.type = 'nearest_centroid';
    modelInfo.centroids = mu;
    save(fullfile(projectRoot, sprintf('clid_ct_model_%s.mat', modeTag)), 'modelInfo');
end

acc = mean(pred == ytest);
fprintf('Accuracy: %.2f%%\n', acc * 100);

cm = confusion_counts(ytest, pred, numel(classNames));
disp('Confusion matrix (rows=true, cols=pred):');
disp(cm);

save(fullfile(projectRoot, sprintf('clid_ct_features_%s.mat', modeTag)), ...
    'X', 'y', 'classNames', 'files', 'mode');
save(fullfile(projectRoot, sprintf('clid_ct_split_%s.mat', modeTag)), ...
    'trainMask', 'testMask', 'ytest', 'pred', 'classNames', 'cm', 'acc');

end

function [X, y, classNames, files] = load_clid_ct_png_dataset(dataRoot, mode, targetSize)
dirs = dir(dataRoot);
dirs = dirs([dirs.isdir]);
dirs = dirs(~ismember({dirs.name}, {'.', '..'}));

rawClassNames = sort(lower(string({dirs.name})));
allowed = ["adenocarcinoma","large_cell","normal","squamous_cell"];
rawClassNames = rawClassNames(ismember(rawClassNames, allowed));

if isempty(rawClassNames)
    error('No expected class folders found under %s', dataRoot);
end

switch lower(string(mode))
    case "binary"
        classNames = {'normal', 'cancer'};
    case "fourclass"
        classNames = cellstr(rawClassNames);
    otherwise
        error('Unknown mode: %s (use ''binary'' or ''fourclass'')', mode);
end

files = {};
labels = [];

for i = 1:numel(rawClassNames)
    cname = char(rawClassNames(i));
    imgDir = fullfile(dataRoot, cname);
    imgs = dir(fullfile(imgDir, '*.png'));
    for k = 1:numel(imgs)
        f = fullfile(imgDir, imgs(k).name);
        files{end+1,1} = f; %#ok<AGROW>
        if strcmpi(mode, 'binary')
            if strcmpi(cname, 'normal')
                labels(end+1,1) = 1; %#ok<AGROW>
            else
                labels(end+1,1) = 2; %#ok<AGROW>
            end
        else
            labels(end+1,1) = find(strcmpi(classNames, cname), 1); %#ok<AGROW>
        end
    end
end

n = numel(files);
X = zeros(n, prod(targetSize), 'single');
y = labels(:);

for i = 1:n
    if mod(i,100) == 1 || i == n
        fprintf('Loading image %d/%d\n', i, n);
    end
    I = imread(files{i});
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    I = im2single(I);
    I = imresize(I, targetSize);
    X(i,:) = I(:)';
end

end

function pred = nearest_centroid_predict(X, mu)
n = size(X,1);
k = size(mu,1);
D = zeros(n, k, 'single');
for c = 1:k
    diff = X - mu(c,:);
    D(:,c) = sum(diff .* diff, 2);
end
[~, pred] = min(D, [], 2);
end

function cm = confusion_counts(ytrue, ypred, nClass)
cm = zeros(nClass, nClass);
for i = 1:numel(ytrue)
    cm(ytrue(i), ypred(i)) = cm(ytrue(i), ypred(i)) + 1;
end
end
