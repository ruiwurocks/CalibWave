function SensData = robustAverageSensitivity(SensData)
%ROBUSTAVERAGESENSITIVITY Combine curves using log-domain robust statistics.

fCommon = SensData.freqCommon(:);
if isempty(SensData.Curves)
    return;
end

logSAll = NaN(numel(fCommon), numel(SensData.Curves));
for i = 1:numel(SensData.Curves)
    f = SensData.Curves(i).freq(:);
    S = SensData.Curves(i).S(:);
    id = isfinite(f) & isfinite(S) & f > 0 & S > 0;
    if nnz(id) >= 5
        logSAll(:, i) = interp1(log10(f(id)), log10(S(id)), ...
            log10(fCommon), 'linear', NaN);
    end
end
SensData.logSAll = logSAll;
SensData.S_final = 10.^median(logSAll, 2, 'omitnan');
SensData.S_stdFactor = 10.^std(logSAll, 0, 2, 'omitnan');
SensData.N = sum(isfinite(logSAll), 2);

end
