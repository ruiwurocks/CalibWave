function tests = testGeometry
tests = functiontests(localfunctions);
end

function setupOnce(~)
setupCalibWave();
end

function testCenterSensorIsFirst(testCase)
sensors = calibwave.geometry.createSensorArray(3, 40, 50);
verifyEqual(testCase, numel(sensors), 9);
verifyEqual(testCase, sensors(1).r, 0, 'AbsTol', eps);
verifyEqual(testCase, [sensors.Index], 1:9);
end

function testEvenGridRejected(testCase)
verifyError(testCase, ...
    @() calibwave.geometry.createSensorArray(4, 40, 50), ...
    'calibwave:geometry:EvenGridSize');
end

function testMergeLabels(testCase)
grid = calibwave.geometry.createSensorArray(3, 40, 50);
active = grid(2);
active.SensorLabel = "S1";
active.ChannelLabel = "CH1";
merged = calibwave.geometry.mergeLabelsIntoGrid(grid, active);
verifyEqual(testCase, merged(2).SensorLabel, "S1");
verifyTrue(testCase, merged(2).IsActive);
verifyEqual(testCase, sum([merged.IsActive]), 1);
end
