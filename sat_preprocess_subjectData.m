function sat_preprocess_subjectData( subjectID, options )
%SAT_PREPROCESS_SUBJECTDATA Function to run the preprocessing of EEG files
%in the SAT study

%% Initialize fieldtrip
% restoredefaultpath;
% addpath('/Users/jessicatennett/Downloads/fieldtrip-20240214');
% ft_defaults;

%%

if nargin < 2
    options = sat_set_analysis_options;
end

subjectDetails = sat_define_subjectDetails(subjectID, options);
if ~exist(subjectDetails.prepSubjectFolder, 'dir')
    mkdir(subjectDeatils.prepSubjectFolder);
end

plotFilterEffects = true;

%% Step 1: Conversion & Rereferencing
cfg = [];
cfg.dataset = subjectDetails.rawEEGfile;
%cfg.dataset = 'Subject02.dat';
dataRaw    = ft_preprocessing(cfg);

% Re-referencing: we use a combined mastoids reference
cfg = [];
cfg.channel       = 'all';
cfg.implicitref   = 'LM'; % this was the recording reference
cfg.reref         = 'yes';
cfg.refchannel    = {'LM' 'RM'};
dataRereferenced = ft_preprocessing(cfg, dataRaw);

% select only EEG data
cfg = [];
cfg.channel    = [1:33 37];
dataEeg        = ft_preprocessing(cfg, dataRereferenced);

% now read the eog and keep it separate from eeg
cfg = [];
cfg.dataset = subjectDetails.rawEEGfile; %cfg.dataset    = 'Subject02.dat';
cfg.channel    = {'VEOG', 'HEOG'};
dataEog      = ft_preprocessing(cfg);

% same for trigger channel
cfg = [];
cfg.dataset = subjectDetails.rawEEGfile; %cfg.dataset    = 'Subject02.dat';
cfg.channel    = {'Trigger'};
dataTrigger    = ft_preprocessing(cfg);

% combine them back again
cfg = [];
data = ft_appenddata(cfg, dataEeg, dataEog, dataTrigger);

%% Step 2: filtering & downsampling
% high-pass filter
cfg = [];
%cfg.channel         = 'eeg';
cfg.hpfilter        = 'yes';
cfg.hpfreq          = 0.1;
cfg.hpinstabilityfix = 'reduce';
dataHPfiltered = ft_preprocessing(cfg, data);

% downsampling
cfg = [];
cfg.resamplefs = 250;
dataDownsampled = ft_resampledata(cfg, dataHPfiltered);

% low-pass filter
cfg = [];
%cfg.channel         = 'eeg';
cfg.lpfilter        = 'yes';
cfg.lpfreq          = 30;
dataLPfiltered = ft_preprocessing(cfg, dataDownsampled);

% plot the effects of the filters
if plotFilterEffects
    figure;
    chanindx = find(strcmp(dataEeg.label, 'Fz'));
    plot(dataEeg.time{1}, dataEeg.trial{1}(chanindx,:)); hold on,
    plot(dataHPfiltered.time{1}, dataHPfiltered.trial{1}(chanindx,:));
    plot(dataLPfiltered.time{1}, dataLPfiltered.trial{1}(chanindx,:));
    legend('raw EEG', 'high-pass filter', 'low-pass+high-pass filter')
end

%% step 3: ICA
% to prepare for ICA, we want to epoch the continuous signal into 1s
% segments and reject noisy segments
% segment it into 1-second pieces
cfg = [];
cfg.length      = 1;
dataSegmented   = ft_redefinetrial(cfg, dataLPfiltered);

% automatic artifact rejection
cfg             = [];
cfg.artfctdef.zvalue.channel = 'eeg';
cfg.artfctdef.zvalue.cutoff = 50;
cfg.artfctdef.zvalue.trlpadding = 0;
cfg.artfctdef.zvalue.artpadding = 0;
cfg.artfctdef.zvalue.fltpadding = 0;

% algorithmic parameters
cfg.artfctdef.zvalue.cumulative = 'yes';
cfg.artfctdef.zvalue.medianfilter = 'yes';
cfg.artfctdef.zvalue.medianfiltord = 9;
cfg.artfctdef.zvalue.absdiff = 'yes';

% if you want to check whether the threshold works, set this to 'yes':
% % make the process interactive
cfg.artfctdef.zvalue.interactive = 'no';
[cfg, artifact_jump] = ft_artifact_zvalue(cfg, dataSegmented);

% actually reject those segments
cfg                           = [];
cfg.artfctdef.reject          = 'complete'; % this rejects complete trials, use 'partial' if you want to do partial artifact rejection
cfg.artfctdef.jump.artifact   = artifact_jump;
dataSegmentedCleaned = ft_rejectartifact(cfg, dataSegmented);

% run the actual ICA
cfg        = [];
cfg.method = 'runica'; % this is the default and uses the implementation from EEGLAB
comp = ft_componentanalysis(cfg, dataSegmentedCleaned);

%plot
cfg           = [];
cfg.layout    = 'eeg1010.lay';
cfg.component = 1:20;
cfg.marker    = 'off';
ft_topoplotIC(cfg, comp)

% apply ICA to continous data


%% step 4: final artifact detection & rejection
