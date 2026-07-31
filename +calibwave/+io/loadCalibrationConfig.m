function CalibConfig = loadCalibrationConfig(filePath)
%LOADCALIBRATIONCONFIG Load and validate CalibConfig from a MAT file.

data = load(filePath);
if ~isfield(data, 'CalibConfig')
    error('calibwave:io:InvalidCalibConfigFile', ...
        'MAT file does not contain CalibConfig.');
end
CalibConfig = data.CalibConfig;
calibwave.config.validateCalibConfig(CalibConfig);

end
