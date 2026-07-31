function saveSensorMap(filePath, SensorGrid, SensorArray, MapInfo)
%SAVESENSORMAP Save the full grid, active sensors, and map metadata.

save(filePath, 'SensorGrid', 'SensorArray', 'MapInfo');

end
