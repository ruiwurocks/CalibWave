function fLow = findNoiseExceedFrequency(freqV, AV, freqN, AN, threshold)
%FINDNOISEEXCEEDFREQUENCY Find first sustained signal-to-noise crossing.

if nargin < 5 || isempty(threshold)
    threshold = 3;
end
fLow = NaN;
if isempty(freqV) || isempty(AV) || isempty(freqN) || isempty(AN)
    return;
end

[freqVU, AVU] = collapseSpectrum(freqV, AV);
[freqNU, ANU] = collapseSpectrum(freqN, AN);
if numel(freqVU) < 5 || numel(freqNU) < 5
    return;
end

AN_on_V = 10.^interp1(freqNU, log10(ANU), freqVU, 'linear', 'extrap');
good = AVU ./ AN_on_V >= threshold;
nConsecutive = 5;
for i = 1:numel(good) - nConsecutive + 1
    if all(good(i:i + nConsecutive - 1))
        fLow = freqVU(i);
        return;
    end
end

end

function [freqU, AU] = collapseSpectrum(freq, A)
freq = freq(:);
A = A(:);
id = isfinite(freq) & isfinite(A) & freq > 0 & A > 0;
freq = freq(id);
A = A(id);
[freq, idx] = sort(freq);
A = A(idx);
[freqU, ~, ic] = unique(freq);
AU = 10.^accumarray(ic, log10(A), [], @mean);
end
