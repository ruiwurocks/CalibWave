function SensorGrid = mergeLabelsIntoGrid(SensorGrid, SensorArray, tolerance)
%MERGELABELSINTOGRID Copy active labels onto matching grid positions.

if nargin < 3 || isempty(tolerance)
    tolerance = 1e-9;
end

for i = 1:numel(SensorGrid)
    SensorGrid(i).SensorLabel = "";
    SensorGrid(i).ChannelLabel = "";
    SensorGrid(i).IsActive = false;
end

for j = 1:numel(SensorArray)
    d = hypot([SensorGrid.x] - SensorArray(j).x, ...
        [SensorGrid.y] - SensorArray(j).y);
    [dmin, idx] = min(d);
    if dmin < tolerance
        SensorGrid(idx).SensorLabel = SensorArray(j).SensorLabel;
        SensorGrid(idx).ChannelLabel = SensorArray(j).ChannelLabel;
        SensorGrid(idx).IsActive = true;
    end
end

for i = 1:numel(SensorGrid)
    SensorGrid(i).Index = i;
end

end
