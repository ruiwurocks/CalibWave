function tests = testSignalAndSensitivity
tests = functiontests(localfunctions);
end

function setupOnce(~)
setupCalibWave();
end

function testAlignAndAppendPadsWithNaN(testCase)
X = calibwave.signal.alignAndAppend([], 1:3);
X = calibwave.signal.alignAndAppend(X, 4:5);
verifySize(testCase, X, [2 3]);
verifyTrue(testCase, isnan(X(2, 3)));
end

function testTriggerIndexBounds(testCase)
verifyEqual(testCase, calibwave.signal.getTriggerSampleIndex(100, 0.5), 51);
verifyEqual(testCase, calibwave.signal.getTriggerSampleIndex(100, 2), 100);
verifyEqual(testCase, calibwave.signal.getTriggerSampleIndex(100, -1), 1);
end

function testAmplitudeFFTLocatesTone(testCase)
Fs = 10000;
t = (0:999)' / Fs;
[f, A] = calibwave.signal.computeAmplitudeFFT(sin(2*pi*500*t), Fs);
[~, id] = max(A);
verifyEqual(testCase, f(id), 500, 'AbsTol', Fs / numel(t));
end

function testSensitivityVector(testCase)
f = logspace(3, 5, 50)';
theory = 1 ./ f;
voltage = 2.5 * theory;
[fOut, S] = calibwave.sensitivity.computeSensitivityVector( ...
    f, voltage, f, theory, 2e3, 8e4);
verifyNotEmpty(testCase, fOut);
verifyEqual(testCase, median(S), 2.5, 'RelTol', 1e-12);
end

function testRobustAverage(testCase)
data.freqCommon = logspace(3, 4, 10);
data.Curves(1) = struct('Name', "A", 'freq', data.freqCommon, ...
    'S', 2 * ones(size(data.freqCommon)), 'fLow', 1e3, 'fHigh', 1e4);
data.Curves(2) = struct('Name', "B", 'freq', data.freqCommon, ...
    'S', 8 * ones(size(data.freqCommon)), 'fLow', 1e3, 'fHigh', 1e4);
data = calibwave.sensitivity.robustAverageSensitivity(data);
verifyEqual(testCase, data.S_final, 4 * ones(10, 1), 'RelTol', 1e-12);
verifyEqual(testCase, data.N, 2 * ones(10, 1));
end

function testCropPlotDataToTimeWindow(testCase)
plotData.Title = "Example";
plotData.ExpAvg(1).t = -5:5;
plotData.ExpAvg(1).y = 10:20;
plotData.ExpRaw = struct([]);
plotData.Theory(1).t = -5:5;
plotData.Theory(1).y = 100:110;
plotData.Arrivals(1).SensorID = 1;
plotData.Arrivals(1).Times_us = [-4 0 4];
plotData.Arrivals(1).Labels = ["A" "B" "C"];

zoomData = calibwave.io.cropPlotDataToTimeWindow(plotData, [-1 3]);

verifyEqual(testCase, zoomData.XLim_us, [-1 3]);
verifyEqual(testCase, zoomData.ExpAvg(1).t, (-1:3)');
verifyEqual(testCase, zoomData.ExpAvg(1).y, (14:18)');
verifyEqual(testCase, zoomData.Theory(1).t, (-1:3)');
verifyEqual(testCase, zoomData.Arrivals(1).Times_us, 0);
verifyEqual(testCase, zoomData.Arrivals(1).Labels, "B");
end
