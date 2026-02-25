function I = read_mid_slice(seriesDir)
%READ_MID_SLICE Read the middle DICOM slice from a series folder.

if ~isfolder(seriesDir)
    error('Series directory not found: %s', seriesDir);
end

files = dir(seriesDir);
files = files(~[files.isdir]);
files = files(~endsWith({files.name}, '.xml'));

if isempty(files)
    error('No DICOM files found in %s', seriesDir);
end

% Try sorting by InstanceNumber; fallback to name
instNums = nan(numel(files),1);
for i = 1:numel(files)
    try
        info = dicominfo(fullfile(seriesDir, files(i).name));
        instNums(i) = info.InstanceNumber;
    catch
        instNums(i) = nan;
    end
end

if any(~isnan(instNums))
    [~, idx] = sort(instNums);
else
    [~, idx] = sort({files.name});
end

midIdx = idx(ceil(numel(idx)/2));
I = dicomread(fullfile(seriesDir, files(midIdx).name));

% Ensure 2D grayscale
if ndims(I) > 2
    I = I(:,:,1);
end

I = mat2gray(I);

end
