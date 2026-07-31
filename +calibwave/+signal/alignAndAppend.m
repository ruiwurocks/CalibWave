function X = alignAndAppend(X, sig)
%ALIGNANDAPPEND Append a row signal, padding shorter rows with NaN.

sig = sig(:)';
if isempty(X)
    X = sig;
    return;
end

n0 = size(X, 2);
n1 = numel(sig);
if n1 > n0
    X(:, end + 1:n1) = NaN;
elseif n1 < n0
    sig(end + 1:n0) = NaN;
end
X(end + 1, :) = sig;

end
