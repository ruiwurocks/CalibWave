function BallInfo = matchBallInfo(FileInfo, ball)
%MATCHBALLINFO Match parsed ball diameter to configured ball properties.

BallInfo = struct( ...
    'Diameter_mm', FileInfo.BallDiameter_mm, ...
    'Amp_dB', FileInfo.Amp_dB, ...
    'RepeatIndex', FileInfo.RepeatIndex);

if isnan(FileInfo.BallDiameter_mm)
    BallInfo.SizeIndex = NaN;
    BallInfo.R = NaN;
    BallInfo.D = NaN;
    BallInfo.h = NaN;
    return;
end

D_now = FileInfo.BallDiameter_mm * 1e-3;
[err, id] = min(abs(ball.D - D_now));
if err < 1e-9
    BallInfo.SizeIndex = id;
    BallInfo.D = ball.D(id);
    BallInfo.R = ball.R(id);
    BallInfo.h = ball.h(id);
else
    BallInfo.SizeIndex = NaN;
    BallInfo.D = D_now;
    BallInfo.R = D_now / 2;
    BallInfo.h = NaN;
end

end
