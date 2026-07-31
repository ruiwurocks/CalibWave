function [dataStruct, fileStruct, errorMessage] = loadtpc5_V3(filenames)
% load data from tpc5 file
% Copyright: 2018 Elsys AG
% Author: 2011-01-18, R. Bertschi
% Rev. 2018-03-12, Thomas Berger
% V1: export 'trigger time' to each block and correct 'chanName', Rev. 2020-08-17 and 2020-09-16, Rui Wu
% V2: concatenate several files according to start time, Rev. 2020-09-16, Rui Wu
% V3: Multiple blocks. Rev. 2024-01-08
% V4: ECR multi channel. Rev. 2025-01-23

% Initialize errorMessage
errorMessage = '';

% Get current architecture (win32 or win64)
bitness = computer('arch');

% Define path for TranAX remoting DLL
if strcmp(bitness, 'win32') == 1
    path = fullfile(fileparts(mfilename('fullpath')), 'references\x86\Elsys.HdfFiles.dll');
else
    path = fullfile(fileparts(mfilename('fullpath')), 'references\x64\Elsys.HdfFiles.dll');
end

%filename input handling
if nargin < 1 || isempty(filenames)
    [fn,pn] = uigetfile('*.tpc5','Choose tpc5 file');
    filenames = strcat(pn,fn);
    clear pn
else
    if length(filenames) == 1
        s = strsplit(filenames,'\');
        fn = s{end};
        clear s
    else
        s = strsplit(filenames,'1.tpc5');
        fn = s{1};
        clear s
    end
end

% Read the file structure, just to get an overview
fileStruct = h5info(filenames);

% Initialize data structure for output with simple fields
dataStruct = struct('expName',fn,'startTime',0,'chanName',{{0}});
% Get number of channels and blocks
num_chan = size(fileStruct.Groups.Groups.Groups.Groups,1);
[~, nBlocks] = tpc5Info(filenames);
% Set up block fields in data structure
dataStruct.sensor(1:num_chan) = deal(struct('block',[]));

try
    % Add TranAX remoting assembly. Change the path here if necessary.
    NET.addAssembly(path);

    % Open tpc5 file handle
    tpc5File = Elsys.HdfFiles.FileTypes.Tpc5File(filenames, System.IO.FileMode.Open, System.IO.FileAccess.Read);

    % Get measurement 0
    measurement = tpc5File.Measurements.Item(0);

    % Get start time
    channel = measurement.Channels.Item(0);
    block = channel.Blocks.Item(0);
    start = block.StartTime;
    customDateFormat = ToString(start, 'yyyy-MM-dd''T''HH:mm:ss');
    startTime = datetime(char(customDateFormat),'Format','yyyy-MM-dd''T''HH:mm:ss','TimeZone','Asia/Shanghai');

    dataStruct.startTime = startTime;

    for channelIndex = 1:num_chan
        % Read out channel settings for the channel

        % Get the specified channel
        channel = measurement.Channels.Item(channelIndex-1);

        nrOfBlocks = min(nBlocks, channel.Blocks.Count);

        % Get channel name
        chanName_temp = split((fileStruct.Groups.Groups.Groups.Groups(channelIndex).Attributes(15).Value));
        dataStruct.chanName(channelIndex) = chanName_temp(1);

        for blockNr = 1:nrOfBlocks %blck to avoid conflict with block in struct
            % Get the specified block number
            block = channel.Blocks.Item(blockNr-1);
            blockNr_new = blockNr;
            dataStruct.sensor(channelIndex).block(blockNr_new).TriggerTimeSeconds = block.TriggerTimeSeconds;


            % Read the converted data
            dataType = Elsys.HdfFiles.FileStructure.DataType_File.PhysicalUnit;
            blockOffset = 0;
            dataCount = int32(block.BlockLength);
            data = GetData(block, blockOffset, dataCount, dataType);
            blockData = double(data)';
            dataStruct.sensor(channelIndex).block(blockNr_new).data = blockData;
        end
    end

    % Close the tpc5 handle
    tpc5File.Dispose();


catch ex
    errorMessage = ex.message;
end

return