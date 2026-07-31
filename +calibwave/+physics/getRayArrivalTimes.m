function [arrTimes_us, arrLabels] = getRayArrivalTimes(Config, sensorID)
%GETRAYARRIVALTIMES Return labeled ray arrivals for a sensor.

arrTimes_us = [];
arrLabels = strings(0);
if ~isfield(Config, 'GF') || isempty(Config.GF)
    return;
end

r_now = Config.SensorArray(sensorID).r;
[~, ~, ~, ~, RAY] = ...
    calibwave.physics.getGreenFunctionByOffset(Config.GF, r_now, "Ray");
if isempty(RAY)
    return;
end

labelsAll = ["P^1", "S^1", "P^3", "P^2S^1", "P^1S^2", "P^5", "S^3"];
n = min(size(RAY, 1), numel(labelsAll));
arrTimes_us = RAY(1:n, 3)' * 1e6;
arrLabels = labelsAll(1:n);

end
