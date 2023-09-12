%% Primary Authors: Victoria Figarola, Benjamin Richardson 7/21/23
%% Secondary Authors: Emaya Anand, Maanasa Guru Adimurthy
%% EPOCHING
subID = 'newpilot93';
addpath('C:\Users\benri\Documents\eeglab2023.0');
eeglab

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename', [subID, '_ICAdone.set'], 'filepath', 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data\');
%change ^^ after channel load changes
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
EEG = eeg_checkset( EEG );

%scrambled same talker condition
EEG_scrambled_st = pop_epoch( EEG, {'45055'}, [-1  16], 'newname', [subID, 'scrambled same talker epochs'], 'epochinfo', 'yes');
EEG_scrambled_st = eeg_checkset( EEG_scrambled_st );
EEG_scrambled_st = pop_rmbase( EEG_scrambled_st, [], []);
[ALLEEG EEG_scrambled_st CURRENTSET] = pop_newset(ALLEEG, EEG_scrambled_st, 2, 'gui', 'off');
EEG_scrambled_st = eeg_checkset( EEG_scrambled_st );
save(['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data\', subID, 'scrambled_st_epoch.mat'], "EEG_scrambled_st")

%unscrambled same talker condition
EEG_unscrambled_st = pop_epoch( EEG, {'36351'}, [-1  16], 'newname', [subID, 'unscrambled same talker epochs'], 'epochinfo', 'yes');
EEG_unscrambled_st = eeg_checkset( EEG_unscrambled_st );
EEG_unscrambled_st = pop_rmbase( EEG_unscrambled_st, [], []);
[ALLEEG EEG_unscrambled_st CURRENTSET] = pop_newset(ALLEEG, EEG_unscrambled_st, 2, 'gui', 'off');
EEG_unscrambled_st = eeg_checkset( EEG_unscrambled_st );
save(['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data\', subID , 'unscrambled_st_epoch.mat'], "EEG_unscrambled_st")

%scrambled diff talker condition
EEG_scrambled_dt = pop_epoch( EEG, {'19711'}, [-1  16], 'newname', [subID, 'scrambled diff talker epochs'], 'epochinfo', 'yes');
EEG_scrambled_dt = eeg_checkset( EEG_scrambled_dt );
EEG_scrambled_dt = pop_rmbase( EEG_scrambled_dt, [], []);
[ALLEEG EEG_scrambled_dt CURRENTSET] = pop_newset(ALLEEG, EEG_scrambled_dt, 2, 'gui', 'off');
EEG_scrambled_dt = eeg_checkset( EEG_scrambled_dt );
save(['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data\', subID, 'scrambled_dt_epoch.mat'], "EEG_scrambled_dt")

%unscrambled diff talker condition
EEG_unscrambled_dt = pop_epoch( EEG, {'11007'}, [-1  16], 'newname', [subID, 'unscrambled diff talker epochs'], 'epochinfo', 'yes');
EEG_unscrambled_dt = eeg_checkset( EEG_unscrambled_dt );
EEG_unscrambled_dt = pop_rmbase( EEG_unscrambled_dt, [], []);
[ALLEEG EEG_unscrambled_dt CURRENTSET] = pop_newset(ALLEEG, EEG_unscrambled_dt, 2, 'gui', 'off');
EEG_unscrambled_dt = eeg_checkset( EEG_unscrambled_dt );
save(['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data\', subID , 'unscrambled_dt_epoch.mat'], "EEG_unscrambled_dt")

%all epochs
EEG = pop_epoch( EEG, {'19711' , '36351', '45055', '11007'}, [-1  16], 'newname', [subID, 'all epochs'], 'epochinfo', 'yes');
EEG = eeg_checkset( EEG );
EEG = pop_rmbase( EEG, [], []);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'gui', 'off');
EEG = eeg_checkset( EEG );
save(['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data\' ,subID, 'all_epoch.mat'], "EEG")

eeglab redraw;
 