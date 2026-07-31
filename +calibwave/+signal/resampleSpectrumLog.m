function [freq_s, A_s] = resampleSpectrumLog(freq, A, fmin, fmax, nPerDecade)
%RESAMPLESPECTRUMLOG Interpolate a positive spectrum on a logarithmic grid.

freq = freq(:);
A = A(:);
id = isfinite(freq) & isfinite(A) & freq > 0 & A > 0;
freq = freq(id);
A = A(id);
if isempty(freq)
    freq_s = [];
    A_s = [];
    return;
end

[freq, order] = sort(freq);
A = A(order);
fmin = max(fmin, min(freq));
fmax = min(fmax, max(freq));
if fmax <= fmin
    freq_s = [];
    A_s = [];
    return;
end

DesignFreq = [];
for p = floor(log10(fmin)):ceil(log10(fmax)) - 1
    DesignFreq = [DesignFreq; ...
        logspace(p, p + 1, nPerDecade + 1)']; %#ok<AGROW>
end
DesignFreq = unique(DesignFreq);
DesignFreq = DesignFreq(DesignFreq >= fmin & DesignFreq <= fmax);
A_s = 10.^interp1(freq, log10(A), DesignFreq, 'linear', 'extrap');
freq_s = DesignFreq;

end
