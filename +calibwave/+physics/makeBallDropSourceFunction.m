function [source, SourceInfo] = makeBallDropSourceFunction(ball, id, Fs, N, specimen)
%MAKEBALLDROPSOURCEFUNCTION Create the Hertzian ball-impact force history.

if nargin < 5 || isempty(specimen)
    specimen.young = 210e9;
    specimen.nu = 0.27;
end

rho1 = ball.rho;
young1 = ball.young;
nu1 = ball.nu;
R = ball.R(id);
h = ball.h(id);
v = sqrt(2 * 9.81 * h);

delta1 = (1 - nu1.^2) ./ (pi * young1);
delta2 = (1 - specimen.nu.^2) ./ (pi * specimen.young);
tc = 4.53 * ((4 * rho1 * pi * (delta1 + delta2) / 3).^(2 / 5)) ...
    .* R .* v.^(-1 / 5);
Fmax = 1.917 * rho1.^(3 / 5) .* (delta1 + delta2).^(-2 / 5) ...
    .* R.^2 .* v.^(6 / 5);

source = zeros(N, 1);
N_contact = min(round(tc * Fs), N);
for ii = 1:N_contact
    tau = (ii - 1) / Fs;
    source(ii) = Fmax * sin(pi * tau / tc).^(3 / 2);
end

SourceInfo.R = R;
SourceInfo.D = 2 * R;
SourceInfo.h = h;
SourceInfo.v = v;
SourceInfo.tc = tc;
SourceInfo.Fmax = Fmax;
SourceInfo.delta_P = 0.5564 * tc * Fmax;
SourceInfo.N_contact = N_contact;

end
