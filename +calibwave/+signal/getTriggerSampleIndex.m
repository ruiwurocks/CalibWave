function triggerID = getTriggerSampleIndex(N, DAQ)
%GETTRIGGERSAMPLEINDEX Convert pre-trigger ratio to a bounded sample index.

ratio = 0.5;
if nargin >= 2 && ~isempty(DAQ)
    if isnumeric(DAQ)
        ratio = DAQ;
    elseif isfield(DAQ, 'PreTriggerRatio') && ~isempty(DAQ.PreTriggerRatio)
        ratio = DAQ.PreTriggerRatio;
    end
end
ratio = max(0, min(1, ratio));
triggerID = max(1, min(N, round(N * ratio) + 1));

end
