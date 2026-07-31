function validateWaveformDB(WaveformDB)
%VALIDATEWAVEFORMDB Validate the top-level waveform database schema.

if ~isstruct(WaveformDB) || ~isfield(WaveformDB, 'Config')
    error('calibwave:config:InvalidWaveformDB', ...
        'WaveformDB must be a struct containing Config.');
end
if ~isfield(WaveformDB, 'Ball') && ~isfield(WaveformDB, 'Capillary')
    error('calibwave:config:EmptyWaveformDB', ...
        'WaveformDB must contain Ball or Capillary data.');
end
calibwave.config.validateCalibConfig(WaveformDB.Config);

end
