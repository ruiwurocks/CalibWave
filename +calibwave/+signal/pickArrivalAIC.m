function idPick = pickArrivalAIC(sig, centerID, halfWin)
%PICKARRIVALAIC Pick a signal arrival using the AIC variance criterion.

idPick = NaN;
sig = sig(:);
i1 = max(1, centerID - halfWin);
i2 = min(numel(sig), centerID + halfWin);
x = sig(i1:i2);
x = x - mean(x, 'omitnan');
if numel(x) < 20
    return;
end

AIC = nan(numel(x), 1);
for k = 5:numel(x) - 5
    v1 = max(var(x(1:k), 1, 'omitnan'), eps);
    v2 = max(var(x(k + 1:end), 1, 'omitnan'), eps);
    AIC(k) = k * log(v1) + (numel(x) - k - 1) * log(v2);
end
[~, kmin] = min(AIC);
idPick = i1 + kmin - 1;

end
