function noiseSig = getNoiseFromPlotData(PlotData, k, Ntarget)
%GETNOISEFROMPLOTDATA Return explicit noise or a pre-source window.

noiseSig = [];
if isfield(PlotData, 'Noise') && numel(PlotData.Noise) >= k && ...
        isfield(PlotData.Noise(k), 'y') && ~isempty(PlotData.Noise(k).y)
    noiseSig = PlotData.Noise(k).y(:);
    return;
end
if ~isfield(PlotData, 'ExpAvg') || k > numel(PlotData.ExpAvg) || ...
        ~isfield(PlotData.ExpAvg(k), 't')
    return;
end

t = PlotData.ExpAvg(k).t(:);
y = PlotData.ExpAvg(k).y(:);
idNoise = find(t < 0);
if numel(idNoise) < 20
    return;
end
if nargin < 3 || isempty(Ntarget)
    Ntarget = min(2000, numel(y));
end
if numel(idNoise) >= Ntarget
    idNoise = idNoise(end - Ntarget + 1:end);
end
noiseSig = y(idNoise);

end
