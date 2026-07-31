function Force = makeCapillaryForceFunction(cap, signal_w, signal_source, DAQ)
%MAKECAPILLARYFORCEFUNCTION Convert force-channel voltage to force history.

preRatio = 0.5;
if isfield(DAQ, 'PreTriggerRatio') && ~isempty(DAQ.PreTriggerRatio)
    preRatio = DAQ.PreTriggerRatio;
end
preRatio = max(0, min(1, preRatio));

L2 = max(1, min(numel(signal_source), ...
    round(numel(signal_source) * preRatio)));
V0 = mean(signal_source(1:ceil(L2)));
V1 = max(abs(signal_source(end - ceil(L2) + 1:end)));
ForceDrop = abs((V0 - V1) / cap.FV_Sen);

Force = zeros(numel(signal_w), 1);
N_half = max(1, min(numel(signal_w), ...
    round(numel(signal_w) * preRatio) + 1));
for ii = 1:numel(signal_w)
    if ii >= N_half && ii < round(N_half + cap.tau_rise * DAQ.Fs)
        Force(ii) = ForceDrop / 2 * ...
            (1 - cos(pi * (ii - N_half) / DAQ.Fs / cap.tau_rise));
    elseif ii >= N_half + cap.tau_rise * DAQ.Fs
        Force(ii) = ForceDrop;
    end
end

end
