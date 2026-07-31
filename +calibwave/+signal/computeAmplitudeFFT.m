function [freq, A] = computeAmplitudeFFT(sig, Fs)
%COMPUTEAMPLITUDEFFT Compute a one-sided, windowed amplitude spectrum.

sig = sig(:);
sig = sig - mean(sig, 'omitnan');
sig = sig .* blackmanharris(numel(sig));
N = numel(sig);
freq = (0:N - 1)' / (N / Fs);
X = fft(sig) / N;
cutOff = ceil(N / 2);
freq = freq(1:cutOff);
A = 2 * abs(X(1:cutOff));

end
