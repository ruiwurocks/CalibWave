function tests = testPhysics
tests = functiontests(localfunctions);
end

function setupOnce(~)
setupCalibWave();
end

function testNearestGreenFunction(testCase)
GF(1) = makeGF(0.0, 1);
GF(2) = makeGF(0.1, 2);
[G, t, id, tP] = calibwave.physics.getGreenFunctionByOffset(GF, 0.08, "Ray");
verifyEqual(testCase, id, 2);
verifyEqual(testCase, G, [2 2]);
verifyEqual(testCase, t, [0 1]);
verifyEqual(testCase, tP, 2e-6);
end

function testBallSourceIsFinite(testCase)
ball = struct('rho', 7850, 'young', 210e9, 'nu', 0.28, ...
    'R', 0.5e-3, 'h', 0.2);
[source, info] = calibwave.physics.makeBallDropSourceFunction( ...
    ball, 1, 10e6, 2000);
verifySize(testCase, source, [2000 1]);
verifyGreaterThan(testCase, info.Fmax, 0);
verifyTrue(testCase, all(isfinite(source)));
end

function value = makeGF(r, scale)
value.r = r;
value.GF_Ray = scale * [1 1];
value.t_Ray = [0 1];
value.GF_NM = scale * [3 3];
value.t_NM = [0 1];
value.RAY = [0 0 scale * 1e-6];
end
