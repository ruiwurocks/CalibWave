function summary = summarizeSensitivity(freqV, AV, freqT, AT, fLow, fHigh)
%SUMMARIZESENSITIVITY Compute geometric sensitivity statistics in a band.

summary.Mean = NaN;
summary.StdFactor = NaN;
summary.N = 0;
[~, S] = calibwave.sensitivity.computeSensitivityVector( ...
    freqV, AV, freqT, AT, fLow, fHigh);
if numel(S) < 5
    return;
end
summary.Mean = exp(mean(log(S), 'omitnan'));
summary.StdFactor = exp(std(log(S), 'omitnan'));
summary.N = numel(S);

end
