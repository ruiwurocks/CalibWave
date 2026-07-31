function [freqCrop, ACrop] = cropSpectrum(freq, A, fmin, fmax)
%CROPSPECTRUM Restrict a positive spectrum to a frequency interval.

id = freq >= fmin & freq <= fmax & A > 0;
freqCrop = freq(id);
ACrop = A(id);

end
