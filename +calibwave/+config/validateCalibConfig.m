function validateCalibConfig(CalibConfig)
%VALIDATECALIBCONFIG Validate fields required by extraction and analysis.

mustHaveFields(CalibConfig, ...
    {'ball', 'cap', 'DAQ', 'SensorArray'}, 'CalibConfig');
mustHaveFields(CalibConfig.ball, ...
    {'rho', 'young', 'nu', 'D', 'R', 'h'}, 'CalibConfig.ball');
mustHaveFields(CalibConfig.cap, ...
    {'FV_Sen', 'tau_rise', 'chanName_Force'}, 'CalibConfig.cap');
mustHaveFields(CalibConfig.DAQ, {'Fs'}, 'CalibConfig.DAQ');

if ~isscalar(CalibConfig.DAQ.Fs) || CalibConfig.DAQ.Fs <= 0
    error('calibwave:config:InvalidSamplingRate', ...
        'CalibConfig.DAQ.Fs must be a positive scalar.');
end

sensorFields = {'Index', 'SensorLabel', 'ChannelLabel', ...
    'x', 'y', 'r', 'theta'};
if ~isempty(CalibConfig.SensorArray)
    mustHaveFields(CalibConfig.SensorArray, sensorFields, ...
        'CalibConfig.SensorArray');
end

end

function mustHaveFields(value, names, label)
for i = 1:numel(names)
    if ~isfield(value, names{i})
        error('calibwave:config:MissingField', ...
            '%s is missing required field %s.', label, names{i});
    end
end
end
