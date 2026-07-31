function DB = extractWaveformCalibration(CalibConfig, folder, mode, loader)
%EXTRACTWAVEFORMCALIBRATION Extract voltage waveforms from TPC5 files.

if nargin < 4 || isempty(loader)
    calibwave.io.validateTpc5Installation();
    loader = @loadtpc5_V3;
end

calibwave.config.validateCalibConfig(CalibConfig);
folder = char(folder);
mode = validatestring(char(mode), {'Ball', 'Capillary'});
files = dir(fullfile(folder, '*.tpc5'));

SensorArray = CalibConfig.SensorArray;
DAQ = CalibConfig.DAQ;
ball = CalibConfig.ball;
cap = CalibConfig.cap;

DB.Mode = string(mode);
DB.Folder = string(folder);
DB.CreatedTime = datetime('now');
DB.SensorArray = SensorArray;
DB.Files = struct([]);

for ii = 1:numel(files)
    filename = files(ii).name;
    filepath = fullfile(folder, filename);
    [dataStruct, ~, errorMessage] = loader(filepath);
    if ~isempty(errorMessage)
        error('calibwave:io:Tpc5LoadFailed', ...
            'Failed to load %s: %s', filepath, errorMessage);
    end

    FileInfo = calibwave.io.parseCalibrationFilename(filename);
    DB.Files(ii).FileName = string(filename);
    DB.Files(ii).FilePath = string(filepath);
    DB.Files(ii).FileInfo = FileInfo;
    DB.Files(ii).Fs = DAQ.Fs;
    DB.Files(ii).Sensors = struct([]);

    for jj = 1:numel(SensorArray)
        channelLabel = string(SensorArray(jj).ChannelLabel);
        sensorLabel = string(SensorArray(jj).SensorLabel);
        chID = find(contains(string(dataStruct.chanName), channelLabel), 1);

        DB.Files(ii).Sensors(jj).ChannelLabel = channelLabel;
        DB.Files(ii).Sensors(jj).SensorLabel = sensorLabel;
        if isempty(chID)
            DB.Files(ii).Sensors(jj).Found = false;
            DB.Files(ii).Sensors(jj).signal0 = [];
            continue;
        end

        DB.Files(ii).Sensors(jj).Found = true;
        DB.Files(ii).Sensors(jj).SensorIndex = SensorArray(jj).Index;
        DB.Files(ii).Sensors(jj).x = SensorArray(jj).x;
        DB.Files(ii).Sensors(jj).y = SensorArray(jj).y;
        DB.Files(ii).Sensors(jj).r = SensorArray(jj).r;
        DB.Files(ii).Sensors(jj).theta = SensorArray(jj).theta;
        DB.Files(ii).Sensors(jj).signal0 = ...
            dataStruct.sensor(chID).block.data(:);
    end

    if strcmp(mode, 'Ball')
        DB.Files(ii).Ball = calibwave.io.matchBallInfo(FileInfo, ball);
    else
        forceChID = find(contains(string(dataStruct.chanName), ...
            string(cap.chanName_Force)), 1);
        DB.Files(ii).ForceChannel = string(cap.chanName_Force);
        if isempty(forceChID)
            DB.Files(ii).signal_source = [];
        else
            DB.Files(ii).signal_source = ...
                dataStruct.sensor(forceChID).block.data(:);
        end
    end
end

end
