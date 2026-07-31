function assemblyPath = validateTpc5Installation()
%VALIDATETPC5INSTALLATION Verify that the Elsys native assembly is present.

loaderPath = which('loadtpc5_V3');
if isempty(loaderPath)
    error('calibwave:io:MissingTpc5Loader', ...
        'loadtpc5_V3 is not on the MATLAB path. Run setupCalibWave.');
end

if strcmp(computer('arch'), 'win32')
    architecture = 'x86';
else
    architecture = 'x64';
end
assemblyPath = fullfile(fileparts(loaderPath), 'references', ...
    architecture, 'Elsys.HdfFiles.dll');
if ~isfile(assemblyPath)
    error('calibwave:io:MissingTpc5Assembly', ...
        ['Missing Elsys assembly: %s. Copy the vendor references folder ', ...
        'under external/tpc5.'], assemblyPath);
end

end
