function inspect_data(dfeatures, qfeat, netp)
%INSPECT_DATA Print basic info about the loaded data.

fprintf('dfeatures size: %s\n', mat2str(size(dfeatures)));
if ~isempty(qfeat)
    fprintf('qfeat size:     %s\n', mat2str(size(qfeat)));
else
    fprintf('qfeat:          (missing)\n');
end

if isempty(netp)
    fprintf('netp:           (missing)\n');
elseif isa(netp, 'network')
    fprintf('netp:           MATLAB neural network object\n');
    fprintf('netp input size: %d\n', netp.inputs{1}.size);
else
    fprintf('netp:           type %s\n', class(netp));
end

% Heuristic to interpret sample orientation
[nr, nc] = size(dfeatures);
if ~isempty(qfeat)
    nlabels = numel(qfeat);
    if nlabels == nr
        fprintf('Heuristic: samples are rows (count=%d) and features are columns (count=%d).\n', nr, nc);
    elseif nlabels == nc
        fprintf('Heuristic: samples are columns (count=%d) and features are rows (count=%d).\n', nc, nr);
    else
        fprintf('Heuristic: could not align samples to labels.\n');
    end
else
    fprintf('Heuristic: no labels provided to infer sample orientation.\n');
end
end
