function projectRoot = setupCalibWave()
%SETUPCALIBWAVE Configure paths required to run CalibWave.

projectRoot = fileparts(mfilename('fullpath'));


addpath(projectRoot);
addpath(fullfile(projectRoot, 'apps'));
addpath(fullfile(projectRoot, 'external', 'tpc5'));

end
