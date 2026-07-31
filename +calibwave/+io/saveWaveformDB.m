function saveWaveformDB(filePath, WaveformDB)
%SAVEWAVEFORMDB Validate and save a waveform database.

calibwave.config.validateWaveformDB(WaveformDB);
save(filePath, 'WaveformDB', '-v7.3');

end
