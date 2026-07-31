function [G, t_G, id, tP, RAY] = getGreenFunctionByOffset(GF, r_now, method)
%GETGREENFUNCTIONBYOFFSET Return the nearest Green function by offset.

if nargin < 3 || isempty(method)
    method = "Ray";
end
if isstruct(GF) && isscalar(GF) && isfield(GF, 'GF')
    GF = GF.GF;
end
if isempty(GF)
    G = [];
    t_G = [];
    id = NaN;
    tP = NaN;
    RAY = [];
    return;
end

[~, id] = min(abs([GF.r] - r_now));
switch string(method)
    case "Ray"
        G = GF(id).GF_Ray;
        t_G = GF(id).t_Ray;
    case "NM"
        G = GF(id).GF_NM;
        t_G = GF(id).t_NM;
    otherwise
        error('calibwave:physics:UnknownGreenFunctionMethod', ...
            'Unknown Green function method: %s', method);
end

RAY = [];
tP = NaN;
if isfield(GF, 'RAY') && ~isempty(GF(id).RAY)
    RAY = GF(id).RAY;
    tP = RAY(1, 3);
end
G = G(:)';
t_G = t_G(:)';

end
