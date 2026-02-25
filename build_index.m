function T = build_index(cfg)
%BUILD_INDEX Build a series index with labels inferred from LIDC XML.

% Read and merge all manifests
allTables = {};
for i = 1:numel(cfg.metadataPaths)
    t = readtable(cfg.metadataPaths{i}, 'TextType', 'string', 'VariableNamingRule', 'preserve');

    % Normalize file location to absolute path
    fileLoc = string(t.('File Location'));
    fileLoc = erase(fileLoc, "./");
    t.SeriesDir = fullfile(cfg.manifestRoots{i}, fileLoc);
    t.ManifestRoot = repmat(string(cfg.manifestRoots{i}), height(t), 1);

    allTables{end+1} = t; %#ok<AGROW>
end

T = vertcat(allTables{:});

% Normalize modality for comparisons
T.Modality = strtrim(string(T.Modality));

% Preallocate label fields
n = height(T);
T.Label = nan(n,1);
T.NoduleCount = nan(n,1);
T.LabelSource = strings(n,1);

for i = 1:n
    if T.Modality(i) ~= "CT"
        continue;
    end

    seriesDir = T.SeriesDir(i);
    [label, nNod] = label_from_lidc_xml(seriesDir);
    T.Label(i) = label;
    T.NoduleCount(i) = nNod;
    if ~isnan(label)
        T.LabelSource(i) = "LIDC XML";
    end
end

end
