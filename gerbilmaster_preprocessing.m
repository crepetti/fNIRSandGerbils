
%Emaya Anand, 7/23/23
%% PREPROCESSING
%taking raw BDF file and saving it at .set file
%order = preprocessing, epoch, postprocessing, multsubjects
%-------------------------------------------------------------------------------------------------------------------
addpath('C:\Users\ema36\OneDrive\Documents\MATLAB\eeglab2023.0');
subID = 'nooverlappilot2';
eeglab

%loading in BDF files and re-referencing to externals (mastoids/earlobes)
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_biosig('C:\Users\ema36\OneDrive\Documents\fNIRSandGerbils\' + subID + '.bdf', 'ref', [33 34], 'blockepoch', 'off', 'refoptions', {'keepref', 'off'});
[ALLEEG EEG CURRENSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');
EEG = eeg_checkset( EEG );

%removing extra channels
EEG = pop_select(EEG, 'nochannel', {'EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'});
[ALLEEG EEG CURRENSET] = pop_newset(ALLEEG, EEG, 1, 'gui', 'off');
EEG = eeg_checkset( EEG );

%adding in channel locations - FOR NOW DOING LOAD, WILL EDIT LATER!
EEG=pop_chanedit(EEG, 'load',{'C:\Users\ema36\OneDrive\Documents\fNIRSandGerbils\richardson_32_chanlocs.locs' 'filetype' 'locs'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'gui', 'off');
EEG = eeg_checkset( EEG );

%downsampling to 256 Hz
EEG = pop_resample( EEG, 256);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'gui', 'off');
EEG = eeg_checkset( EEG );

%bandpass filter (order of 1)
fs = EEG.srate;
[b, a] = butter(1, [1, 30] / (fs / 2));
EEG.data = filtfilt(b, a, double(EEG/data')); 
EEG.data = EEG.data';
EEG = eeg_checkset( EEG );

%Running ICA
EEG = pop_runica(EEG, 'icatype', 'runcia', 'extended', 1, 'interrupt', 'on');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = eeg_checkset( EEG );

disp('EEGLAB ran ICA');

%Saving ICA
EEG = pop_saveset( EEG, 'filename', subID + '_ICA.set', 'filepath', 'C:\Users\ema36\OneDrive\Documents\fNIRSandGerbils\pre processed data\');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

eeglab redraw;







