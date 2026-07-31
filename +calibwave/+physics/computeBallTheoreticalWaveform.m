function [theory_nm, t_theory_rel_us, TheoryInfo] = ...
    computeBallTheoreticalWaveform(Config, sensorID, D_target, N_meas, method)
%COMPUTEBALLTHEORETICALWAVEFORM Generate a ball-impact displacement model.

theory_nm = [];
t_theory_rel_us = [];
TheoryInfo = [];
if ~isfield(Config, 'GF') || isempty(Config.GF)
    return;
end

r_now = Config.SensorArray(sensorID).r;
[G, t_G, id_GF, tP_GF, RAY] = ...
    calibwave.physics.getGreenFunctionByOffset(Config.GF, r_now, method);
if isempty(G) || isnan(tP_GF)
    return;
end

id_ball = find(abs(Config.ball.D * 1e3 - D_target) < 1e-9, 1);
if isempty(id_ball)
    return;
end

[~, idP] = min(abs(t_G - tP_GF));
G_tail = G(idP:end);
N_tail = numel(G_tail);
G_pad = zeros(1, 2 * N_tail);
G_pad(N_tail + 1:end) = G_tail;

[source, SourceInfo] = calibwave.physics.makeBallDropSourceFunction( ...
    Config.ball, id_ball, Config.DAQ.Fs, numel(G_pad));
theory_full = conv(source, G_pad);
theory_nm = theory_full(1:numel(G_pad)) * 1e9;

triggerID = calibwave.signal.getTriggerSampleIndex(N_meas, Config.DAQ);
tP_meas = (triggerID - 1) / Config.DAQ.Fs;
t_src = tP_meas - tP_GF;
t_theory_abs_s = ((1:numel(theory_nm)) - (N_tail + 1)) ...
    / Config.DAQ.Fs + tP_meas;
t_theory_rel_us = (t_theory_abs_s - t_src) * 1e6;

TheoryInfo.id_GF = id_GF;
TheoryInfo.idP_GF = idP;
TheoryInfo.tP_GF = tP_GF;
TheoryInfo.tP_meas = tP_meas;
TheoryInfo.t_src = t_src;
TheoryInfo.RAY = RAY;
TheoryInfo.SourceInfo = SourceInfo;
TheoryInfo.N_tail = N_tail;

end
