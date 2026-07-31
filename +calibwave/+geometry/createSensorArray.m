function SensorArray = createSensorArray(N, spacing_mm, h_mm)
%CREATESENSORARRAY Create an odd, square sensor grid sorted by radius.

arguments
    N (1,1) double {mustBeInteger, mustBePositive}
    spacing_mm (1,1) double {mustBePositive}
    h_mm (1,1) double {mustBePositive}
end

if mod(N, 2) == 0
    error('calibwave:geometry:EvenGridSize', 'N must be odd.');
end

spacing = spacing_mm * 1e-3;
h = h_mm * 1e-3;
centerID = (N + 1) / 2;

tmp = struct([]);
k = 0;
for iy = 1:N
    for ix = 1:N
        k = k + 1;
        x = (ix - centerID) * spacing;
        y = (centerID - iy) * spacing;
        r = hypot(x, y);

        tmp(k).x = x; %#ok<AGROW>
        tmp(k).y = y;
        tmp(k).r = r;
        tmp(k).theta = atan(r / h) * 180 / pi;
        tmp(k).SensorLabel = "";
        tmp(k).ChannelLabel = "";
        tmp(k).IsActive = false;
    end
end

[~, order] = sort([tmp.r], 'ascend');
SensorArray = tmp(order);
for i = 1:numel(SensorArray)
    SensorArray(i).Index = i;
end

end
