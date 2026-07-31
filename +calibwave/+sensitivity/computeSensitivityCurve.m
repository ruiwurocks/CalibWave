function Curve = computeSensitivityCurve(PlotData, Fs, curveName, autoValidBand, threshold)
%COMPUTESENSITIVITYCURVE Compute one sensitivity curve from plot data.

if nargin < 5 || isempty(threshold)
    threshold = 3;
end
Curve = [];
name = lower(string(curveName));
if contains(name, 'ball')
    fmin = 1e3; fmax = 100e3;
elseif contains(name, 'capillary')
    fmin = 100e3; fmax = 1e6;
else
    fmin = 1e3; fmax = 1e6;
end
if ~isfield(PlotData, 'ExpAvg') || ~isfield(PlotData, 'Theory')
    return;
end

freqVAll = []; ampVAll = []; freqTAll = []; ampTAll = [];
freqNAll = []; ampNAll = [];
nCurve = min(numel(PlotData.ExpAvg), numel(PlotData.Theory));
for k = 1:nCurve
    sigV = PlotData.ExpAvg(k).y(:);
    sigT = PlotData.Theory(k).y(:);
    if isfield(PlotData.ExpAvg(k), 't') && isfield(PlotData.Theory(k), 't')
        tV = PlotData.ExpAvg(k).t(:);
        tT = PlotData.Theory(k).t(:);
        id = tV >= min(tT) & tV <= max(tT);
        if nnz(id) > 10
            sigV = PlotData.ExpAvg(k).y(id);
        end
    end

    [freqV, AV] = processSpectrum(sigV, Fs, fmin, fmax);
    [freqT, AT] = processSpectrum(sigT, Fs, fmin, fmax);
    if isempty(freqV) || isempty(freqT)
        continue;
    end
    freqVAll = [freqVAll; freqV(:)]; %#ok<AGROW>
    ampVAll = [ampVAll; AV(:)]; %#ok<AGROW>
    freqTAll = [freqTAll; freqT(:)]; %#ok<AGROW>
    ampTAll = [ampTAll; AT(:)]; %#ok<AGROW>

    noise = calibwave.sensitivity.getNoiseFromPlotData(PlotData, k, numel(sigV));
    if ~isempty(noise)
        [freqN, AN] = processSpectrum(noise, Fs, fmin, fmax);
        freqNAll = [freqNAll; freqN(:)]; %#ok<AGROW>
        ampNAll = [ampNAll; AN(:)]; %#ok<AGROW>
    end
end
if isempty(freqVAll) || isempty(freqTAll)
    return;
end

if autoValidBand
    fLow = calibwave.sensitivity.findNoiseExceedFrequency( ...
        freqVAll, ampVAll, freqNAll, ampNAll, threshold);
    fc = [calibwave.sensitivity.fitOmegaModel(freqVAll, ampVAll), ...
        calibwave.sensitivity.fitOmegaModel(freqTAll, ampTAll)];
    fc = fc(isfinite(fc));
    if isempty(fc), fHigh = fmax; else, fHigh = min(mean(fc), fmax); end
    if ~isfinite(fLow), fLow = fmin; end
else
    fLow = fmin;
    fHigh = fmax;
end
if fHigh <= fLow
    return;
end

[freqU, S] = calibwave.sensitivity.computeSensitivityVector( ...
    freqVAll, ampVAll, freqTAll, ampTAll, fLow, fHigh);
if isempty(freqU)
    return;
end
Curve = struct('Name', string(curveName), 'freq', freqU, 'S', S, ...
    'fLow', fLow, 'fHigh', fHigh);

end

function [freq, A] = processSpectrum(sig, Fs, fmin, fmax)
[freq, A] = calibwave.signal.computeAmplitudeFFT(sig, Fs);
[freq, A] = calibwave.signal.cropSpectrum(freq, A, fmin, fmax);
[freq, A] = calibwave.signal.resampleSpectrumLog(freq, A, fmin, fmax, 100);
end
