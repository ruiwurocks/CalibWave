% Matlab Example, read number of traces from tpc5 file
% Copyright: 2018 Elsys AG
% Author: 2018-03-12, Thomas Berger
% Description:
% Return the number of traces in a tpc5 file


function [nrOfTraces, nrOfBlocks, errorMessage] = tpc5Info(filename, channelIndex)
	nrofTrace = 0;
    nrOfBlocks = 0;
    
    % Check if channelIndex exists
    if ~exist('channelIndex')
        channelIndex = 0;
    else
        channelIndex = channelIndex - 1;
    end

    % Get current architecture (win32 or win64)
    bitness = computer('arch');

    % Define path for TranAX remoting DLL
    if strcmp(bitness, 'win32') == 1
        path = fullfile(fileparts(mfilename('fullpath')), 'references\x86\Elsys.HdfFiles.dll');
    else
        path = fullfile(fileparts(mfilename('fullpath')), 'references\x64\Elsys.HdfFiles.dll');
    end

    try
        % Add TranAX remoting assembly. Change the path here if necessary.
        NET.addAssembly(path);

        % Open tpc5 file handle
        tpc5File = Elsys.HdfFiles.FileTypes.Tpc5File(filename, System.IO.FileMode.Open, System.IO.FileAccess.Read);

        % Get measurement 0
        measurement = tpc5File.Measurements.Item(0);
        
        % Read number of traces
        nrOfTraces = double(measurement.Channels.Count());
        
        % Get the specified channel
        channel = measurement.Channels.Item(channelIndex);
        
        % Get number of blocks
        nrOfBlocks = double(channel.Blocks.Count());

        % Close the tpc5 handle
        tpc5File.Dispose();
    catch ex
        errorMessage = char(ex.message);
    end
return


