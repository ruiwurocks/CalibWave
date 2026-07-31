function tests = testExtraction
tests = functiontests(localfunctions);
end

function setupOnce(~)
setupCalibWave();
end

function testBallExtractionWithInjectedLoader(testCase)
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
filePath = fullfile(folder, 'Ball_1_0_mm_0dB_001.tpc5');
fileID = fopen(filePath, 'w');
fclose(fileID);

config = minimalConfig();
db = calibwave.io.extractWaveformCalibration( ...
    config, folder, "Ball", @mockTpc5Loader);

verifyEqual(testCase, numel(db.Files), 1);
verifyTrue(testCase, db.Files(1).Sensors(1).Found);
verifyEqual(testCase, db.Files(1).Sensors(1).signal0, (1:4)');
verifyEqual(testCase, db.Files(1).Ball.SizeIndex, 1);
clear cleanup;
end

function [dataStruct, fileStruct, errorMessage] = mockTpc5Loader(~)
dataStruct.chanName = {'CH1', 'F1'};
dataStruct.sensor(1).block.data = 1:4;
dataStruct.sensor(2).block.data = 5:8;
fileStruct = struct();
errorMessage = '';
end

function config = minimalConfig()
sensor = calibwave.geometry.createSensorArray(1, 40, 50);
sensor.SensorLabel = "S1";
sensor.ChannelLabel = "CH1";
sensor.IsActive = true;
config.SensorArray = sensor;
config.SensorGrid = sensor;
config.ball = struct('rho', 7850, 'young', 210e9, 'nu', 0.28, ...
    'D', 1e-3, 'R', 0.5e-3, 'h', 0.2);
config.cap = struct('FV_Sen', 0.2, 'tau_rise', 1e-7, ...
    'T2_cf', 40, 'chanName_Force', "F1");
config.DAQ = struct('Fs', 10e6, 'PreTriggerRatio', 0.5);
config.GF = [];
end
