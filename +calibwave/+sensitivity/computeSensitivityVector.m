function [freqU, S] = computeSensitivityVector(freqV, AV, freqT, AT, fLow, fHigh)
%COMPUTESENSITIVITYVECTOR Divide voltage and displacement spectra.

[freqVU, AVU] = collapseSpectrum(freqV, AV);
[freqTU, ATU] = collapseSpectrum(freqT, AT);
idBand = freqVU >= fLow & freqVU <= fHigh;
if nnz(idBand) < 5 || isempty(freqTU)
    freqU = [];
    S = [];
    return;
end

AT_on_V = 10.^interp1(freqTU, log10(ATU), freqVU(idBand), ...
    'linear', 'extrap');
freqU = freqVU(idBand);
S = AVU(idBand) ./ AT_on_V;
id = isfinite(S) & S > 0;
freqU = freqU(id);
S = S(id);

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
