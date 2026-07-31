function tests = testFilenameAndConfig
tests = functiontests(localfunctions);
end

function setupOnce(~)
setupCalibWave();
end

function testParseBallFilename(testCase)
info = calibwave.io.parseCalibrationFilename('Ball_1_5_mm_20dB_002.tpc5');
verifyTrue(testCase, info.IsBall);
verifyEqual(testCase, info.BallDiameter_mm, 1.5);
verifyEqual(testCase, info.Amp_dB, 20);
verifyEqual(testCase, info.RepeatIndex, 2);
end

function testSanitizeFileStemPreservesDecimalDigits(testCase)
stem = calibwave.io.sanitizeFileStem('Ball diameter = 0.5 mm');
verifyEqual(testCase, stem, "Ball_diameter_0_5_mm");

stem = calibwave.io.sanitizeFileStem('FFT_Ball_diameter__05_mm');
verifyEqual(testCase, stem, "FFT_Ball_diameter_05_mm");
end

function testMatchConfiguredBall(testCase)
info = calibwave.io.parseCalibrationFilename('Ball_1_0_mm_0dB_001.tpc5');
ball.D = [0.5; 1] * 1e-3;
ball.R = ball.D / 2;
ball.h = [0.1; 0.2];
matched = calibwave.io.matchBallInfo(info, ball);
verifyEqual(testCase, matched.SizeIndex, 2);
verifyEqual(testCase, matched.D, 1e-3, 'AbsTol', eps);
end

function testBuildConfigNormalizesGreenFunctions(testCase)
input = minimalInput();
wrapped.GF = struct('r', 0, 'GF_Ray', 1, 't_Ray', 0, ...
    'GF_NM', 1, 't_NM', 0, 'RAY', [0 0 0]);
input.GF = wrapped;
config = calibwave.config.buildCalibConfig(input);
verifyTrue(testCase, isfield(config.GF, 'r'));
verifyFalse(testCase, isfield(config.GF, 'GF'));
verifyEqual(testCase, config.DAQ.SizeNum, numel(config.ball.D));
end

function input = minimalInput()
input.SensorArray = calibwave.geometry.createSensorArray(1, 40, 50);
input.SensorArray.SensorLabel = "S1";
input.SensorArray.ChannelLabel = "CH1";
input.SensorArray.IsActive = true;
input.SensorGrid = input.SensorArray;
input.ball = struct('rho', 7850, 'young', 210e9, 'nu', 0.28, ...
    'D', 1e-3, 'R', 0.5e-3, 'h', 0.2);
input.cap = struct('FV_Sen', 0.2, 'tau_rise', 1e-7, ...
    'T2_cf', 40, 'chanName_Force', "F1");
input.DAQ = struct('Fs', 10e6, 'PreTriggerRatio', 0.5);
end
