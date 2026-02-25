function [label, nNod] = label_from_lidc_xml(seriesDir)
%LABEL_FROM_LIDC_XML Infer affected vs non-affected from LIDC XML.
% label = 1 if any unblindedReadNodule is present, 0 if none, NaN if no XML.

label = nan;
nNod = nan;

if ~isfolder(seriesDir)
    return;
end

xmls = dir(fullfile(seriesDir, '*.xml'));
if isempty(xmls)
    return;
end

% Debug: print the first XML file path once if a flag file exists
debugFlag = fullfile(seriesDir, '.lidc_debug');
if exist(debugFlag, 'file') == 2
    fprintf('DEBUG XML sample: %s\n', fullfile(seriesDir, xmls(1).name));
end

try
    total = 0;
    for i = 1:numel(xmls)
        txt = fileread(fullfile(seriesDir, xmls(i).name));
        % Robust count without regex edge cases
        txt = lower(txt);
        total = total + numel(strfind(txt, '<unblindedreadnodule'));
    end
    nNod = total;
    if nNod > 0
        label = 1;
    else
        label = 0;
    end
catch
    % Leave as NaN if XML cannot be parsed
    label = nan;
    nNod = nan;
end

end
