function [X, y, info] = extract_lidc_features(T, targetSize)
%EXTRACT_LIDC_FEATURES Extract simple features from mid-slice images.
% Uses resized grayscale pixel intensities as features.

if nargin < 2
    targetSize = [64 64];
end

% Use only labeled CT series
modality = strtrim(string(T.Modality));
mask = modality == "CT" & ~isnan(T.Label);
Tsub = T(mask,:);

n = height(Tsub);
X = zeros(n, prod(targetSize), 'single');
y = Tsub.Label;

for i = 1:n
    I = read_mid_slice(Tsub.SeriesDir(i));
    I = imresize(I, targetSize);
    X(i,:) = single(I(:))';
end

info = Tsub;

end
