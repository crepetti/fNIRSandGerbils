%% analyze_EEG_fNIRSandGerbils
% script to calculate ERPs for scrambled and unscrambled word onsets in
% fNIRS and Gerbils
addpath('C:\Users\benri\Documents\eeglab2023.0')
eeglab;
% Define subject information (which BDFs to load)
curr_subject_ID = char('nooverlappilot2');
isubject = 1;


EEG = pop_biosig('nooverlappilot2_EEG.bdf','ref',[33 34],'refoptions',{'keepref' 'off'});
EEG = pop_select( EEG,'nochannel',{'EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','s002','gui','on');
EEG = pop_resample( EEG, 256);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','s002','overwrite','on','gui','on');
EEG = pop_firws(EEG, 'fcutoff', [0.1 50], 'ftype', 'bandpass', 'wtype', 'kaiser', 'warg', 5.65326, 'forder', 1856, 'minphase', 0);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','s002 BPF','gui','on'); 

% STOP TO CLEAN UP HERE

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','s002 BPF CU','gui','on'); 
EEG=pop_chanedit(EEG, 'load',{'C:\Users\benri\Documents\eeglab2023.0\sample_data\eeglab_chan32.locs' 'filetype' 'locs'});

EEG = pop_runica(EEG, 'extended',1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','s002 ICA','gui','on'); 

pop_selectcomps(EEG, [1:32] );


% Pause to select components
pause
%channels_to_remove = str2num(input('Please enter which components to remove:'));
EEG = pop_subcomp( EEG, [1 4 13 21], 0);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','s002 ICA Cleaned','gui','on'); 

%% Epoching 
EEG_scrambled = pop_epoch( EEG, {'19711'}, [-0.1 16], 'newname', 's002 scrambled epochs', 'epochinfo', 'yes');

EEG_unscrambled = pop_epoch( EEG, {'36351'}, [-0.1 16], 'newname', 's002 unscrambled epochs', 'epochinfo', 'yes');

EEG_all = pop_epoch( EEG, {'19711','36351'}, [-0.1 16], 'newname', 's002 unscrambled epochs', 'epochinfo', 'yes');
% Question for resolution: order of presentation vs. order put into the
% .csv? To that end, which trigger is which?

% Find tOnset to isolate ERPs
load('C:\Users\benri\Documents\GitHub\fNIRSandGerbils\stim\s_nooverlappilot2\nooverlappilot2_alltrialwords.mat')

% isolate ERPs
all_epochs = EEG_all.data;
scrambled_epochs = EEG_scrambled.data; % num channels x num time points x num trials
unscrambled_epochs = EEG_unscrambled.data;
scrambled_time = EEG_scrambled.times; % in milliseconds
unscrambled_time = EEG_unscrambled.times; % in milliseconds

scrambled_by_target_onset = [];
unscrambled_by_target_onset = [];

% Load click info to find condition
all_click_info = readtable('C:\Users\benri\Documents\GitHub\fNIRSandGerbils\data\fNIRSandGerbils.xlsx','FileType','spreadsheet','Format','auto');
which_rows_this_subject = find(all_click_info.S == string(curr_subject_ID(isubject,:))); % find the rows in the spreadsheet which belong to this subject
conditions = all_click_info.Condition(which_rows_this_subject); % conditions by trial for this subject


% Find target word onset times
stim_info_filename = ['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\stim\s_',strtrim(curr_subject_ID(isubject,:)),'\',strtrim(curr_subject_ID(isubject,:)),'_alltrialwords.mat'];
load(stim_info_filename) % loads all_word_order (array of all words) and tOnset (the onset times within each trial)
target_word_indices = all_word_order == 'red' | all_word_order == 'white' | all_word_order == 'blue' | all_word_order == 'green';

for itrial = 1:size(target_word_indices,1) % for each trial...
    % find the condition
    curr_condition = conditions(itrial);
    % find onsets of target words in this trial
    this_trial_target_onsets = tOnset(target_word_indices(itrial,:) == 1);
    for ionset = 1:length(this_trial_target_onsets) % for each target word onset...
        [~,start_time] = min(abs(scrambled_time - this_trial_target_onsets(ionset)/1000)); % ...find the time it starts
        [~,end_time] = min(abs(scrambled_time - ((this_trial_target_onsets(ionset)/1000)+500))); % ...find the time it ends (500 ms later)

        % Isolate ERP
        if curr_condition == 1
            scrambled_by_target_onset = cat(3,scrambled_by_target_onset,all_epochs(:,start_time:end_time,itrial));
        elseif curr_condition == 2
            unscrambled_by_target_onset = cat(3,unscrambled_by_target_onset,all_epochs(:,start_time:end_time,itrial));
        end
    end
end

single_onset_time = linspace(0,500,size(scrambled_by_target_onset,2));
figure;plot(single_onset_time,squeeze(mean(scrambled_by_target_onset,3)))
xlabel('Time (ms)')
ylabel('Amplitude (/muV)')
title('ERPs all channels (average over 24 presentations)','FontSize',18)

% Just plotting Cz
single_onset_time = linspace(0,500,size(scrambled_by_target_onset(14,:,:),2));
scrambled_cz_erp = squeeze(mean(scrambled_by_target_onset(14,:,:),3));
unscrambled_cz_erp = squeeze(mean(unscrambled_by_target_onset(14,:,:),3));
% baseline
scrambled_cz_erp_baselined = (scrambled_cz_erp - mean(scrambled_epochs(14,1:0.1*256,:),"all"))/std(scrambled_epochs(14,1:0.1*256,:),[],"all");
unscrambled_cz_erp_baselined = (unscrambled_cz_erp - mean(unscrambled_epochs(14,1:0.1*256,:),"all"))/std(unscrambled_epochs(14,1:0.1*256,:),[],"all");

figure;plot(single_onset_time,scrambled_cz_erp_baselined)
hold on;plot(single_onset_time,unscrambled_cz_erp_baselined)
xlabel('Time (ms)')
ylabel('Amplitude (normalized)')
title('Average Cz ERP (baselined)','FontSize',18)
legend({'Scrambled','Unscrambled'})
