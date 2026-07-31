function CalibConfig = buildCalibConfig(input)
%BUILDCALIBCONFIG Build the persisted calibration configuration schema.

required = {'ball', 'cap', 'DAQ', 'SensorArray', 'SensorGrid'};
for i = 1:numel(required)
    if ~isfield(input, required{i})
        error('calibwave:config:MissingInput', ...
            'Configuration input is missing field %s.', required{i});
    end
end

CalibConfig.ball = input.ball;
CalibConfig.cap = input.cap;
CalibConfig.DAQ = input.DAQ;
CalibConfig.SensorArray = input.SensorArray;
CalibConfig.SensorGrid = input.SensorGrid;

if isfield(input, 'GF')
    CalibConfig.GF = normalizeGreenFunctions(input.GF);
else
    CalibConfig.GF = [];
end
if isfield(input, 'Param')
    CalibConfig.Param = input.Param;
else
    CalibConfig.Param.Note = ...
        'Specimen/plate parameters should be read from GF.mat when available.';
end

CalibConfig.DAQ.SensorArray = input.SensorArray;
CalibConfig.DAQ.SensorGrid = input.SensorGrid;
CalibConfig.DAQ.SizeNum = numel(input.ball.D);
CalibConfig.CreatedTime = datetime('now');

calibwave.config.validateCalibConfig(CalibConfig);

end

function GF = normalizeGreenFunctions(GF)
if isstruct(GF) && isscalar(GF) && isfield(GF, 'GF')
    GF = GF.GF;
end
end
