%% CLID CT metrics report from saved split output
% Usage:
%   clid_ct_report_metrics
%   clid_ct_report_metrics('clid_ct_split.mat')

function stats = clid_ct_report_metrics(splitMatPath)
if nargin < 1
    splitMatPath = 'clid_ct_split.mat';
end

if exist(splitMatPath, 'file') ~= 2
    error('Split file not found: %s', splitMatPath);
end

S = load(splitMatPath);
required = {'cm','classNames','acc'};
for i = 1:numel(required)
    if ~isfield(S, required{i})
        error('Missing field "%s" in %s', required{i}, splitMatPath);
    end
end

cm = S.cm;
classNames = S.classNames;
acc = S.acc;

fprintf('Metrics report: %s\n', splitMatPath);
fprintf('Accuracy: %.2f%%\n', acc * 100);
disp('Confusion matrix (rows=true, cols=pred):');
disp(cm);

nClass = size(cm,1);

perClass = table('Size', [nClass 7], ...
    'VariableTypes', {'string','double','double','double','double','double','double'}, ...
    'VariableNames', {'Class','TP','FP','FN','Precision','Recall','F1'});

for c = 1:nClass
    tp = cm(c,c);
    fp = sum(cm(:,c)) - tp;
    fn = sum(cm(c,:)) - tp;

    prec = safe_div(tp, tp + fp);
    rec = safe_div(tp, tp + fn);
    f1 = safe_div(2 * prec * rec, prec + rec);

    perClass.Class(c) = string(classNames{c});
    perClass.TP(c) = tp;
    perClass.FP(c) = fp;
    perClass.FN(c) = fn;
    perClass.Precision(c) = prec;
    perClass.Recall(c) = rec;
    perClass.F1(c) = f1;
end

disp('Per-class metrics:');
disp(perClass);

stats = struct();
stats.accuracy = acc;
stats.confusionMatrix = cm;
stats.classNames = classNames;
stats.perClass = perClass;
stats.macroPrecision = mean(perClass.Precision, 'omitnan');
stats.macroRecall = mean(perClass.Recall, 'omitnan');
stats.macroF1 = mean(perClass.F1, 'omitnan');
fprintf('Macro Precision: %.4f\n', stats.macroPrecision);
fprintf('Macro Recall:    %.4f\n', stats.macroRecall);
fprintf('Macro F1:        %.4f\n', stats.macroF1);

if nClass == 2
    % Convention in this project: class 1 = normal, class 2 = cancer (positive)
    tn = cm(1,1);
    fp = cm(1,2);
    fn = cm(2,1);
    tp = cm(2,2);

    sensitivity = safe_div(tp, tp + fn);
    specificity = safe_div(tn, tn + fp);
    precision = safe_div(tp, tp + fp);
    npv = safe_div(tn, tn + fn);
    f1Pos = safe_div(2 * precision * sensitivity, precision + sensitivity);

    stats.binary = struct( ...
        'tp', tp, 'tn', tn, 'fp', fp, 'fn', fn, ...
        'sensitivity', sensitivity, ...
        'specificity', specificity, ...
        'precision', precision, ...
        'npv', npv, ...
        'f1', f1Pos);

    fprintf('\nBinary metrics (positive class = %s):\n', classNames{2});
    fprintf('Sensitivity (Recall): %.4f\n', sensitivity);
    fprintf('Specificity:          %.4f\n', specificity);
    fprintf('Precision:            %.4f\n', precision);
    fprintf('NPV:                  %.4f\n', npv);
    fprintf('F1-score:             %.4f\n', f1Pos);
end

if nargout == 0
    clear stats
end

end

function z = safe_div(a, b)
if b == 0
    z = NaN;
else
    z = a / b;
end
end
