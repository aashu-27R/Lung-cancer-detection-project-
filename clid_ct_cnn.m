%% CLID CT CNN pipeline (MATLAB Deep Learning Toolbox)
% Usage:
%   clid_ct_cnn
%   clid_ct_cnn('fourclass')
%
% Default mode: binary (normal vs cancer)

function clid_ct_cnn(mode)
if nargin < 1
    mode = 'binary';
end

if exist('trainNetwork', 'file') ~= 2
    error('Deep Learning Toolbox required (trainNetwork not found).');
end
if exist('imageDatastore', 'file') ~= 2
    error('Image Processing Toolbox required (imageDatastore not found).');
end

projectRoot = fileparts(mfilename('fullpath'));
dataRoot = fullfile(projectRoot, 'archive', 'CT Scan');
modeTag = lower(char(string(mode)));
inputSize = [128 128 1];

if ~isfolder(dataRoot)
    error('CT dataset folder not found: %s', dataRoot);
end

fprintf('CLID CT CNN data root: %s\n', dataRoot);
fprintf('Mode: %s\n', mode);

imds = imageDatastore(dataRoot, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames', ...
    'FileExtensions', {'.png','.jpg','.jpeg'});
imds.ReadFcn = @read_grayscale_single;

% Keep expected classes only
allowed = categorical({'adenocarcinoma','large_cell','normal','squamous_cell'});
origFiles = imds.Files;
origLabels = imds.Labels;
mask = ismember(origLabels, allowed);
imds.Files = origFiles(mask);
imds.Labels = origLabels(mask);

if numel(imds.Files) == 0
    error('No CT images found under %s', dataRoot);
end

% Map labels based on selected mode
imds.Labels = map_labels(imds.Labels, mode);

fprintf('Images loaded: %d\n', numel(imds.Files));
show_label_counts(imds.Labels);

cats = categories(imds.Labels);
if numel(cats) < 2
    error('Need at least two classes to train.');
end

% Stratified split
rng(42);
[imdsTrain, imdsTemp] = splitEachLabel(imds, 0.8, 'randomized');
[imdsVal, imdsTest] = splitEachLabel(imdsTemp, 0.5, 'randomized');

fprintf('Train: %d  Val: %d  Test: %d\n', numel(imdsTrain.Files), numel(imdsVal.Files), numel(imdsTest.Files));

% Read grayscale and resize inside datastore pipeline
augTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain, ...
    'ColorPreprocessing', 'none', ...
    'DataAugmentation', imageDataAugmenter( ...
        'RandXReflection', true, ...
        'RandRotation', [-10 10], ...
        'RandXTranslation', [-5 5], ...
        'RandYTranslation', [-5 5]));
augVal = augmentedImageDatastore(inputSize(1:2), imdsVal, 'ColorPreprocessing', 'none');
augTest = augmentedImageDatastore(inputSize(1:2), imdsTest, 'ColorPreprocessing', 'none');

trainCats = categories(imdsTrain.Labels);
numClasses = numel(trainCats);
classNames = cellstr(trainCats);
classWeights = inverse_frequency_weights(imdsTrain.Labels);

layers = [
    imageInputLayer(inputSize, 'Normalization', 'rescale-zero-one')

    convolution2dLayer(3, 16, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)

    convolution2dLayer(3, 32, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)

    convolution2dLayer(3, 64, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)

    convolution2dLayer(3, 128, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer

    fullyConnectedLayer(128)
    dropoutLayer(0.4)
    reluLayer
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer('Classes', categorical(trainCats, trainCats), 'ClassWeights', classWeights)
];

miniBatch = 32;
valFreq = max(1, floor(numel(imdsTrain.Files) / miniBatch));
options = trainingOptions('adam', ...
    'InitialLearnRate', 1e-3, ...
    'MaxEpochs', 12, ...
    'MiniBatchSize', miniBatch, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', augVal, ...
    'ValidationFrequency', valFreq, ...
    'Verbose', true, ...
    'Plots', 'training-progress');

fprintf('Training CNN...\n');
net = trainNetwork(augTrain, layers, options);

fprintf('Evaluating on test set...\n');
predLabels = classify(net, augTest);
ytestLabels = imdsTest.Labels;

[cm, classNamesOrdered] = confusion_from_categorical(ytestLabels, predLabels);
acc = mean(predLabels == ytestLabels);

fprintf('CNN Accuracy: %.2f%%\n', acc * 100);
disp('Confusion matrix (rows=true, cols=pred):');
disp(cm);

% Save model and split outputs compatible with clid_ct_report_metrics
pred = label_indices(predLabels, classNamesOrdered);
ytest = label_indices(ytestLabels, classNamesOrdered);
classNames = cellstr(classNamesOrdered);

save(fullfile(projectRoot, sprintf('clid_ct_cnn_model_%s.mat', modeTag)), ...
    'net', 'classNames', 'mode', 'inputSize');
save(fullfile(projectRoot, sprintf('clid_ct_cnn_split_%s.mat', modeTag)), ...
    'ytest', 'pred', 'classNames', 'cm', 'acc', 'mode');

end

function labelsOut = map_labels(labelsIn, mode)
labelsStr = lower(string(labelsIn));
switch lower(string(mode))
    case "binary"
        labelsOut = categorical(repmat("cancer", size(labelsStr)));
        labelsOut(labelsStr == "normal") = categorical("normal");
        labelsOut = reordercats(labelsOut, {'normal','cancer'});
    case "fourclass"
        labelsOut = categorical(labelsStr);
        labelsOut = removecats(labelsOut);
        labelsOut = reordercats(labelsOut, sort(categories(labelsOut)));
    otherwise
        error('Unknown mode: %s (use ''binary'' or ''fourclass'')', mode);
end
end

function show_label_counts(labels)
cats = categories(labels);
for i = 1:numel(cats)
    fprintf('  %s: %d\n', cats{i}, sum(labels == cats{i}));
end
end

function w = inverse_frequency_weights(labels)
cats = categories(labels);
counts = zeros(numel(cats),1);
for i = 1:numel(cats)
    counts(i) = sum(labels == cats{i});
end
w = numel(labels) ./ (numel(cats) * counts);
end

function [cm, classOrder] = confusion_from_categorical(ytrue, ypred)
classOrder = categorical(categories(ytrue));
cm = zeros(numel(classOrder));
yt = label_indices(ytrue, classOrder);
yp = label_indices(ypred, classOrder);
for i = 1:numel(yt)
    cm(yt(i), yp(i)) = cm(yt(i), yp(i)) + 1;
end
end

function idx = label_indices(labels, classOrder)
labelStr = string(labels);
classStr = string(classOrder);
idx = zeros(numel(labelStr),1);
for i = 1:numel(labelStr)
    idx(i) = find(classStr == labelStr(i), 1, 'first');
end
end

function I = read_grayscale_single(filename)
I = imread(filename);
if ndims(I) == 3
    I = rgb2gray(I);
end
I = im2single(I);
end
