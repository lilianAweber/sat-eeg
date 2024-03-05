function options = sat_set_analysis_options
%SAT_SET_ANALYSIS_OPTIONS Sets all high-level options for the EEG analysis
%in the SAT study.

options = struct;

%%% Enter your directories here 
options.mainDir = '/Users/jessicatennett/Documents/MATLAB/RandomDots/EEG_Analyses';
options.fieldtripDir = '/Users/jessicatennett/Downloads/fieldtrip-20240214';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options.rawDataDir = fullfile(options.mainDir, 'data', 'raw');
options.workingDir = fullfile(options.mainDir, 'data', 'analysis');
options.codeDir = fullfile(options.mainDir, 'code');

addpath(genpath(options.codeDir));
addpath(options.fieldtripDir);

% Preprocessing choices
options.preproc.hpfilter = 0.1;
options.preproc.downsample = 250;
options.preproc.lpfilter = 30;
options.preproc.trialThresh = 50; % z-value based trial rejection

% GLM choices
%options.glm.(...)


