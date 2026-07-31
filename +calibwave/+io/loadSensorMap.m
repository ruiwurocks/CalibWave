function [SensorGrid, SensorArray, MapInfo] = loadSensorMap(filePath)
%LOADSENSORMAP Load and validate a sensor map MAT file.

data = load(filePath);
if ~isfield(data, 'SensorGrid') && ~isfield(data, 'SensorArray')
    error('calibwave:io:InvalidSensorMap', ...
        'MAT file must contain SensorGrid or SensorArray.');
end

if isfield(data, 'SensorGrid')
    SensorGrid = data.SensorGrid;
else
    SensorGrid = data.SensorArray;
end
if isfield(data, 'SensorArray')
    SensorArray = data.SensorArray;
else
    SensorArray = SensorGrid;
end
if isfield(data, 'MapInfo')
    MapInfo = data.MapInfo;
else
    MapInfo = struct();
end

end
