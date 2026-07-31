function [theory_nm, t_theory_us] = ...
    computeCapillaryTheoreticalWaveform(Config, sensorID, signal_w, signal_source)
%COMPUTECAPILLARYTHEORETICALWAVEFORM Generate capillary displacement model.

theory_nm = [];
t_theory_us = [];
r_now = Config.SensorArray(sensorID).r;
[G, ~] = calibwave.physics.getGreenFunctionByOffset(Config.GF, r_now, "Ray");
if isempty(G)
    return;
end

Force = calibwave.physics.makeCapillaryForceFunction( ...
    Config.cap, signal_w, signal_source, Config.DAQ);
theory_full = conv(Force(:)', G(:)');
theory_nm_full = theory_full(1:numel(signal_w)) * 1e9;

N = numel(signal_w);
id_src = calibwave.signal.getTriggerSampleIndex(N, Config.DAQ);
t_full_us = ((1:N) - id_src) / Config.DAQ.Fs * 1e6;
idWin = t_full_us >= -60 & t_full_us <= 60;
theory_nm = theory_nm_full(idWin);
t_theory_us = t_full_us(idWin);

end
