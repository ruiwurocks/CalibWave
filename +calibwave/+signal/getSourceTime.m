function t_src_us = getSourceTime(Config, sensorID, N_meas, sig)
%GETSOURCETIME Estimate source time from measured and theoretical P arrivals.

t_src_us = NaN;
if ~isfield(Config, 'GF') || isempty(Config.GF) || isempty(sig)
    return;
end

r_now = Config.SensorArray(sensorID).r;
[~, ~, ~, tP_GF] = ...
    calibwave.physics.getGreenFunctionByOffset(Config.GF, r_now, "Ray");
if isnan(tP_GF)
    return;
end

centerID = calibwave.signal.getTriggerSampleIndex(N_meas, Config.DAQ);
idP_meas = calibwave.signal.pickArrivalAIC(sig, centerID, 200);
if ~isnan(idP_meas)
    tP_meas = (idP_meas - 1) / Config.DAQ.Fs;
    t_src_us = (tP_meas - tP_GF) * 1e6;
end

end
