%% Primary Authors: Victoria Figarola, Benjamin Richardson 7/21/23
%% Secondary Authors: Emaya Anand, Maanasa Guru Adimurthy
%% MULTSUBJECTS

% This script combines multiple subjects epoched data across both
% conditions, fronto-central electrodes
% In the first for loop, it's looping across total number of subjects.
% Outputs:
    % scrambled_data_avg 3D: # subj x time points x trials
    % unscrambled_data_avg 3D: # subj x time points x trials
% Inputs: 
    % subject_ID: make a list of all subjects IDs
    % ERP window start and end times
    % num_tot_trials: total number of trials for each condition 
    % nChan: total number of channels using in analysis
    % frontocentral_channels: which channels you want to use in analysis
% Optional Inputs:
    % scrambled_by_target_onset: would need to be created as a 4D array so
    % it loops across all subjects. 
        % EXAMPLE (2 subjects): scrambled_by_target_onset(i,:,:,:) = # subj x # of channels x time points x trials
        % In this case, scrambled_by_target_onset(i,:,:,:) would be 2 subj x 14 channels x time points x 24 trials
 
%curr_subject_ID = char('nooverlappilot2','nooverlappilot3');

nSubjects = 1;
fs = 256; 
subID = ["test274"];  
erp_window_start_time = -100; % 100 ms before onset of word
erp_window_end_time = 500; % 500 ms after onset of word
num_tot_trials = 48; %per condition
nChan = 14;
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];



for i = 1:nSubjects
    [~,~,scrambled_data_avg(i,:,:),unscrambled_data_avg(i,:,:)] = gerbilmaster_postprocessing(subID(i),erp_window_start_time,erp_window_end_time,num_tot_trials,nChan,frontocentral_channels);
end


%% Plotting data -- you have to fix this. i just copied this over from NoOverlap_PostProcessing script lol -VF
scrambled_by_target_onset_avg = mean(scrambled_data_avg,2); %averaging across trials
SEM_scrambled_by_target_onset_across_trials = std(scrambled_data_avg,[],2)/sqrt(num_tot_trials); %getting SEM across trials

t_scrambled_epoch = 0:1/fs:(length(scrambled_by_target_onset)-1)/fs;
t_scrambled_epoch_normalized = (t_scrambled_epoch-0.1)*1000; %"normalized", just shifting it back 100ms so it's -100 to 500ms (def a better way to do this, just didn't have time to finish)

finding_scram_first_nonzero = find(t_scrambled_epoch_normalized(:)<0,1,'last'); % Want to know estimated onset in plot as xline

unscrambled_by_target_onset_avg = mean(unscrambled_data_avg,2); %averaging across trials
SEM_unscrambled_by_target_onset_across_trials = std(unscrambled_data_avg,[],2)/sqrt(num_tot_trials); %getting SEM across trials 

t_unscrambled_epoch = 0:1/fs:(length(unscrambled_by_target_onset)-1)/fs;
t_unscrambled_epoch_normalized = (t_unscrambled_epoch-0.1)*1000; %"normalized", just shifting it back 100ms so it's -100 to 500ms (def a better way to do this, just didn't have time to finish) 
finding_unscram_first_nonzero = find(t_unscrambled_epoch_normalized(:)<0,1,'last'); % Want to know estimated onset in plot as xline



% figure; 
% plot(t_scrambled_epoch_normalized,detrend(scrambled_by_target_onset_avg))
% xline(t_scrambled_epoch_normalized(finding_first_nonzero),'r--','Target Onset') %plotting xline at first nonzero
% xlabel('Time (ms)')
% ylabel('Amplitude')
% title('Scrambled Condition Epoch')

% addpath errorbar_files/
% figure;
% shadedErrorBar(t_scrambled_epoch_normalized,scrambled_by_target_onset_avg,SEM_scrambled_by_target_onset_across_trials,'lineProps','b')
% hold on
% shadedErrorBar(t_scrambled_epoch_normalized,unscrambled_by_target_onset_avg,SEM_unscrambled_by_target_onset_across_trials,'lineProps','r')
% xline(t_scrambled_epoch_normalized(finding_scram_first_nonzero),'k--','Target Onset','LineWidth',1.5) %plotting xline at first nonzero
% legend('Scrambled','Unscrambled')
% xlabel('Time (ms)')
% ylabel('Amplitude')
% title('Scrambled & Unscrambled Conditions Epoch (across trials SEM)')













