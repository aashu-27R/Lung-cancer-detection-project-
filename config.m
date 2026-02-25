function cfg = config()
%CONFIG Central paths for the LIDC subset.

root = fileparts(mfilename('fullpath'));

cfg.projectRoot = root;

% Collect all manifest-* folders that contain metadata.csv
manifests = dir(fullfile(root, 'manifest-*'));
manifests = manifests([manifests.isdir]);

roots = {};
for i = 1:numel(manifests)
    mroot = fullfile(root, manifests(i).name);
    if exist(fullfile(mroot, 'metadata.csv'), 'file') ~= 2
        continue;
    end
    roots{end+1} = mroot; %#ok<AGROW>
end

if isempty(roots)
    error('No manifest-* folder with metadata.csv found.');
end

cfg.manifestRoots = roots;
cfg.metadataPaths = cellfun(@(r) fullfile(r, 'metadata.csv'), roots, 'UniformOutput', false);

end
