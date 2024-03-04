function details = sat_define_subjectDetails( subjectID, options )
%SAT_DEFINE_SUBJECTDETAILS Returns a struct with participant-specific infos
%for the SAT EEG study.

if nargin <2
    options = sat_set_analysis_options;
end

details.subjectName = ['sub' sprintf('%02.0f', subjectID)];

details.rawSubjectFolder = fullfile(options.rawDataDir, details.subjectName);
details.rawEEGfile = fullfile(details.subjectFolder, ...
    ['Subject' sprintf('%02.0f', subjectID) '.dat']);

details.prepSubjectFolder = fullfile(options.workingDir, details.subjectName);
details.prepEEGfile = fullfile(details.subjectFolder, ...
    [details.subjectName '_preproc.mat']);


