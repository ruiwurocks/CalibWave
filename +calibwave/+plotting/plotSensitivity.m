function plotSensitivity(axAll, axAvg, S)
%PLOTSENSITIVITY Render individual and robust-average sensitivity curves.

cla(axAll);
hold(axAll, 'on');
markerList = {'o', 's', '^', 'v', 'd', '>', '<', 'p', 'h'};
colorOrder = lines(max(1, numel(S.Curves)));
for i = 1:numel(S.Curves)
    marker = markerList{mod(i - 1, numel(markerList)) + 1};
    loglog(axAll, S.Curves(i).freq / 1e3, S.Curves(i).S, ...
        'LineStyle', 'none', 'Marker', marker, 'MarkerSize', 5, ...
        'LineWidth', 1.0, 'Color', colorOrder(i, :), ...
        'DisplayName', char(S.Curves(i).Name));
end
xlabel(axAll, 'Frequency (kHz)');
ylabel(axAll, 'Sensitivity (V/nm)');
title(axAll, 'Independent sensitivity estimates');
legend(axAll, 'Location', 'best');
set(axAll, 'XScale', 'log', 'YScale', 'log');
xlim(axAll, [1 1000]);
box(axAll, 'on');

cla(axAvg);
hold(axAvg, 'on');
f_kHz = S.freqCommon(:) / 1e3;
id = isfinite(S.S_final) & S.S_final > 0 & ...
    isfinite(S.S_stdFactor) & S.S_stdFactor > 0 & S.N > 0;
f_kHz = f_kHz(id);
S_final = S.S_final(id);
S_std = S.S_stdFactor(id);
if ~isempty(f_kHz)
    S_low = S_final ./ S_std;
    S_high = S_final .* S_std;
    fill(axAvg, [f_kHz; flipud(f_kHz)], ...
        [S_low; flipud(S_high)], [0.85 0.85 0.85], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.6, ...
        'DisplayName', '+/-1 log-std');
    loglog(axAvg, f_kHz, S_final, 'k-', 'LineWidth', 2.0, ...
        'DisplayName', 'Robust average');
end
xlabel(axAvg, 'Frequency (kHz)');
ylabel(axAvg, 'Sensitivity (V/nm)');
title(axAvg, 'Final robust averaged sensor sensitivity');
set(axAvg, 'XScale', 'log', 'YScale', 'log');
xlim(axAvg, [1 1000]);
legend(axAvg, 'Location', 'best');
box(axAvg, 'on');

end
