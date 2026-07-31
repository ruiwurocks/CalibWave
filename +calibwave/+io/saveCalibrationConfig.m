function saveCalibrationConfig(filePath, CalibConfig)
%SAVECALIBRATIONCONFIG Validate and save CalibConfig.

calibwave.config.validateCalibConfig(CalibConfig);
save(filePath, 'CalibConfig');

end
