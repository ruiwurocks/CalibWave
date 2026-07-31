function FileInfo = parseCalibrationFilename(filename)
%PARSECALIBRATIONFILENAME Parse calibration metadata from a file name.

[~, name, ext] = fileparts(filename);
tokens = regexp(name, '_', 'split');

FileInfo.Name = string(name);
FileInfo.Extension = string(ext);
FileInfo.Tokens = string(tokens);
FileInfo.IsBall = any(contains(FileInfo.Tokens, "Ball", 'IgnoreCase', true));
FileInfo.IsCapillary = any(contains(FileInfo.Tokens, "Cap", 'IgnoreCase', true)) || ...
    any(contains(FileInfo.Tokens, "CF", 'IgnoreCase', true));
FileInfo.Amp_dB = 0;
FileInfo.RepeatIndex = NaN;
FileInfo.BallDiameter_mm = NaN;

idBall = find(contains(FileInfo.Tokens, "Ball", 'IgnoreCase', true), 1);
if ~isempty(idBall) && numel(tokens) >= idBall + 2
    integerPart = str2double(tokens{idBall + 1});
    fractionalPart = str2double(tokens{idBall + 2});
    if ~isnan(integerPart) && ~isnan(fractionalPart)
        FileInfo.BallDiameter_mm = integerPart + fractionalPart / 10;
    end
end

idDB = find(contains(FileInfo.Tokens, "dB", 'IgnoreCase', true), 1);
if ~isempty(idDB)
    value = regexp(tokens{idDB}, '\d+', 'match');
    if ~isempty(value)
        FileInfo.Amp_dB = str2double(value{1});
    end
end

numericTokens = regexp(name, '\d+', 'match');
if ~isempty(numericTokens)
    FileInfo.RepeatIndex = str2double(numericTokens{end});
end

end
