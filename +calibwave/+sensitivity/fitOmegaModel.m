function fc = fitOmegaModel(freq, A)
%FITOMEGAMODEL Fit A0/(1+(f/fc)^n) and return corner frequency.

fc = NaN;
freq = freq(:);
A = A(:);
id = isfinite(freq) & isfinite(A) & freq > 0 & A > 0;
freq = freq(id);
A = A(id);
if numel(freq) < 20
    return;
end

[freq, idx] = sort(freq);
A = A(idx);
[freq, ~, ic] = unique(freq);
A = 10.^accumarray(ic, log10(A), [], @mean);
if numel(freq) < 20
    return;
end

omegaFun = @(p, f) p(1) ./ (1 + (f ./ p(2)).^p(3));
A0 = max(A);
[~, idMid] = min(abs(A - A0 / 2));
p0 = [A0, freq(max(1, idMid)), 2];
objective = @(q) omegaMisfit(q, freq, A, omegaFun);
opts = optimset('Display', 'off', 'MaxIter', 500, 'MaxFunEvals', 1000);
p = 10.^fminsearch(objective, log10(p0), opts);
if isfinite(p(2)) && p(2) > min(freq) && p(2) < max(freq)
    fc = p(2);
end

end

function err = omegaMisfit(q, freq, A, omegaFun)
p = 10.^q;
Afit = omegaFun(p, freq);
id = isfinite(Afit) & Afit > 0;
if nnz(id) < 10
    err = inf;
else
    err = mean((log10(A(id)) - log10(Afit(id))).^2, 'omitnan');
end
end
