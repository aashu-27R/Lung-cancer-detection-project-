function y = predict_with_net(netp, X)
%PREDICT_WITH_NET Run saved network on features X.
% Ensures the input matrix uses columns as samples.

if ~isa(netp, 'network')
    error('netp is not a MATLAB network object.');
end

inputSize = netp.inputs{1}.size;

% If features are rows and samples are columns, transpose
if size(X,1) == inputSize
    Xt = X;
elseif size(X,2) == inputSize
    Xt = X';
else
    warning('Feature size does not match network input size. Proceeding without transpose.');
    Xt = X;
end

y = netp(Xt);
end
