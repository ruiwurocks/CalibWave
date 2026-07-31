function ZoomData = cropPlotDataToTimeWindow(PlotData, xLim_us)
%CROPPLOTDATATOTIMEWINDOW Crop PlotData curves to a visible time window.

xLim_us = sort(double(xLim_us(:)'));
if numel(xLim_us) ~= 2 || any(~isfinite(xLim_us))
    error('calibwave:io:InvalidTimeWindow', ...
        'xLim_us must contain two finite time limits.');
end

ZoomData = struct();
ZoomData.Title = "";
if isfield(PlotData, 'Title')
    ZoomData.Title = PlotData.Title;
end
ZoomData.XLim_us = xLim_us;
ZoomData.Units.Time = "us";
ZoomData.Units.Experimental = "V";
ZoomData.Units.Theory = "nm";

ZoomData.ExpRaw = cropCurveArray(PlotData, 'ExpRaw', xLim_us);
ZoomData.ExpAvg = cropCurveArray(PlotData, 'ExpAvg', xLim_us);
ZoomData.Theory = cropCurveArray(PlotData, 'Theory', xLim_us);
ZoomData.Arrivals = cropArrivals(PlotData, xLim_us);

end

function curves = cropCurveArray(PlotData, fieldName, xLim_us)
curves = struct([]);
if ~isfield(PlotData, fieldName) || isempty(PlotData.(fieldName))
    return;
end

source = PlotData.(fieldName);
curves = source;
for k = 1:numel(source)
    if ~isfield(source(k), 't') || ~isfield(source(k), 'y')
        continue;
    end

    t = source(k).t(:);
    y = source(k).y(:);
    id = t >= xLim_us(1) & t <= xLim_us(2);
    curves(k).t = t(id);
    curves(k).y = y(id);
end
end

function arrivals = cropArrivals(PlotData, xLim_us)
arrivals = [];
if ~isfield(PlotData, 'Arrivals') || isempty(PlotData.Arrivals)
    return;
end

source = PlotData.Arrivals;
arrivals = source([]);
keepCount = 0;
for k = 1:numel(source)
    if ~isfield(source(k), 'Times_us') || isempty(source(k).Times_us)
        continue;
    end

    times = source(k).Times_us(:)';
    id = times >= xLim_us(1) & times <= xLim_us(2);
    if ~any(id)
        continue;
    end

    keepCount = keepCount + 1;
    arrivals(keepCount) = source(k); %#ok<AGROW>
    arrivals(keepCount).Times_us = times(id);
    if isfield(source(k), 'Labels') && numel(source(k).Labels) == numel(times)
        arrivals(keepCount).Labels = source(k).Labels(id);
    end
end
end
