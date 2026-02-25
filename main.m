%% Lung cancer detection demo (MATLAB)
% Loads provided .mat files, inspects shapes, and runs the saved network if available.

clear; clc;

% Load data files (if present)
if exist('dfeatures-1.mat','file')
    S = load('dfeatures-1.mat');
    dfeatures = S.dfeatures;
else
    error('Missing dfeatures-1.mat');
end

if exist('qfeat-1.mat','file')
    S = load('qfeat-1.mat');
    qfeat = S.qfeat;
else
    qfeat = [];
end

if exist('netp-1.mat','file')
    S = load('netp-1.mat');
    netp = S.netp;
else
    netp = [];
end

inspect_data(dfeatures, qfeat, netp);

if ~isempty(netp)
    fprintf('\nRunning saved network...\n');
    y = predict_with_net(netp, dfeatures);
    disp('Predictions:');
    disp(y);

    % If labels exist and sizes match, compute simple accuracy
    if ~isempty(qfeat)
        try
            % Attempt to align label shape with predictions
            yt = y(:);
            qt = qfeat(:);
            if numel(yt) == numel(qt)
                acc = mean(round(yt) == round(qt));
                fprintf('Approx. accuracy (rounded): %.2f%%\n', acc*100);
            else
                fprintf('Label count (%d) does not match prediction count (%d).\n', numel(qt), numel(yt));
            end
        catch ME
            fprintf('Could not compute accuracy: %s\n', ME.message);
        end
    end
else
    fprintf('\nNo network found. Only data inspection completed.\n');
end
