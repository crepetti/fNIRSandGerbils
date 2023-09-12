%% Primary Authors: Victoria Figarola, Benjamin Richardson 7/21/23
%% Secondary Authors: Emaya Anand, Maanasa Guru Adimurthy
%% POSTPROCESSING
% This script takes in the post-processed SINGLE SUBJECT data (already
% epoched from -1 to 16 seconds) and isolates target onset epochs/ERPs

% To analyze single subject, just comment out function line and uncomment
% input variables
% If you want multiple subjects, call this function into
% "NoOverlap_MultSubjects.m" file. 

%function [scrambled_by_target_onset,unscrambled_by_target_onset,scrambled_data_avg,unscrambled_data_avg] = gerbilmaster_postprocessing(subID,erp_window_start_time,erp_window_end_time,num_tot_trials,nChan,frontocentral_channels)

%% Defining variables in beginning:
%subID = char('nooverlappilot2','nooverlappilot3');
subID = char('test724'); %current subject --> NOTE: KEEP SUBJECT ID, FOLDER NAMES && DATA THE SAME 
dir = ['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data/']; %where the EEG data is stored in mat file
dir_fnirsandgerbils = 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\data\fNIRSandGerbils.xlsx'; %response times
erp_window_start_time = -100; % 100 ms before onset of word
erp_window_end_time = 500; % 500 ms after onset of word
num_tot_trials = 24;
nChan = 14;
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];

%% Loading in EEG Data
%IF LOADING IN SET FILE:
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',[subID '_ICAdone.set'],'filepath',dir);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off');
    EEG = eeg_checkset( EEG );

% IF LOADING IN .MAT FILE
scrambled_EEG = load([dir , subID , 'scrambled_epoch.mat']); %loading in epoched EEG structure
scrambled_data = scrambled_EEG.EEG_scrambled.data; %isolating scrambled data (32 channels x num time points (samples) x 24 trials) 
t_scrambled = scrambled_EEG.EEG_scrambled.times; % in milliseconds

unscrambled_EEG = load([dir , subID, 'unscrambled_epoch.mat']); %loading in EEG structure
unscrambled_data = unscrambled_EEG.EEG_unscrambled.data; %isolating unscrambled data
t_unscrambled = unscrambled_EEG.EEG_unscrambled.times; % in milliseconds


all_EEG = load([dir, subID, 'all_epoch.mat']); %loading in EEG structure
all_epochs_data = all_EEG.EEG.data; %isolating all data (scrambled + unscrambled)
t_all_epochs = all_EEG.EEG.times; % in milliseconds

fs = scrambled_EEG.EEG_scrambled.srate; %extracting sampling rate

%% Compiling fronto-central channels
for j = 1:nChan %getting 14 channels that will be used later on 
    scrambled_data_frontochan(j,:,:) = squeeze(scrambled_EEG.EEG_scrambled.data(frontocentral_channels(1,j),:,:)); %14 channels x time points x 24 trials
    unscrambled_data_frontochan(j,:,:) = squeeze(unscrambled_EEG.EEG_unscrambled.data(frontocentral_channels(1,j),:,:));
    
end


%% Loading in click response info and target word onsets
% Load click info to find condition
subID = 'nobehaviorpilot1';
all_click_info = readtable(dir_fnirsandgerbils,'FileType','spreadsheet','Format','auto');
which_rows_this_subject = find(all_click_info.S == string(subID)); % find the rows in the spreadsheet which belong to this subject
conditions = all_click_info.Condition(which_rows_this_subject); % conditions by trial for this subject

% Find target word onset times
stim_info_filename = ['C:\Users\ema36\OneDrive\Documents\fNIRSandGerbils\stim\s_nobehaviorpilot1\nobehaviorpilot1_alltrialwords.mat'];
target_words= load(stim_info_filename); % loads all_word_order (array of all words) and tOnset (the onset times within each trial)
target_words.tOnset(end) = [];
tOnset = target_words.tOnset;
target_word_indices = target_words.all_word_order == 'red' | target_words.all_word_order == 'white' | target_words.all_word_order == 'blue' | target_words.all_word_order == 'green';

%% Isolate target word onset ERPs for both conditions
% scrambled_data_squeeze = squeeze(scrambled_data(1,:,:));
scrambled_target_word_indices = [];
scrambled_by_target_onset = [];

finding_scrambled_times=[];
finding_scram_pre_baselined_time = [];
finding_scram_end_time=[];

unscrambled_data_squeeze = squeeze(unscrambled_data(1,:,:));
unscrambled_target_word_indices = [];
unscrambled_by_target_onset = [];
finding_unscrambled_times = [];
finding_unscram_pre_baselined_time =[];
finding_unscram_end_time=[];

curr_condition = [1 2];
for j = 1:length(curr_condition)
    % Getting target word onset ERPs for scrambled condition
    if j == 1 %scrambled condition first

        for itrial = 1:num_tot_trials
            scrambled_target_word_indices = find(conditions==j); %getting location of target_word_indices for scrambled condition
            scrambled_target_word = target_word_indices(scrambled_target_word_indices,:); %seperating target word indices for scrambled condition
            scrambled_target_word_onset = tOnset(scrambled_target_word(itrial,:)==1)*1000; %converting to ms
            for ionset = 1:size(scrambled_target_word_onset,2)
                resampled_search_time = (scrambled_target_word_onset(ionset)/1000)/(44100/fs);
                [~, resample_search_index] = min(abs(t_scrambled - resampled_search_time));
                finding_scrambled_times = [finding_scrambled_times resample_search_index]; %finding onset times location in t_scrambled
                % pre_baseline_period_time = t_scrambled(finding_scrambled_times(ionset,:))+erp_window_start_time; %getting pre-baseline time
                pre_base = fs*(abs(erp_window_start_time)/1000);
                finding_scram_pre_baselined_time = [finding_scram_pre_baselined_time (t_scrambled( ceil( (finding_scrambled_times(:,ionset) - pre_base) ) ) )]; %getting pre-baseline time in t_scrambled (NOT location)
                post = fs*(abs(erp_window_end_time)/1000);
                finding_scram_end_time = [finding_scram_end_time (t_scrambled( ceil((finding_scrambled_times(:,ionset) + post))) )]; %getting end time in t_scrambled (NOT location)

                start_end_time_indices = [find(t_scrambled==finding_scram_pre_baselined_time(:,ionset)) find(t_scrambled==finding_scram_end_time(:,ionset))];

                scrambled_by_target_onset(:,:,:) = scrambled_data_frontochan(:,start_end_time_indices(1):start_end_time_indices(2),:);
            end

        end

    end

    % Now for unscrambled condition
    if j == 2
        for itrial = 1:num_tot_trials
            unscrambled_target_word_indices = find(conditions==j); %getting location of target_word_indices for unscrambled condition
            unscrambled_target_word = target_word_indices(unscrambled_target_word_indices,:); %seperating target word indices for unscrambled condition
            unscrambled_target_word_onset = tOnset(unscrambled_target_word(itrial,:)==1)*1000; %converting to ms
            for ionset = 1:size(unscrambled_target_word_onset,2)
                resampled_search_time = (unscrambled_target_word_onset(ionset)/1000)/(44100/fs);
                [~, resample_search_index] = min(abs(t_unscrambled - resampled_search_time));
                finding_unscrambled_times = [finding_unscrambled_times resample_search_index]; %find
                % pre_baseline_period_time = t_scrambled(finding_unscrambled_times(ionset,:))+erp_window_start_time; %getting pre-baseline time
                pre_base = fs*(abs(erp_window_start_time)/1000);
                finding_unscram_pre_baselined_time = [finding_unscram_pre_baselined_time (t_unscrambled( ceil((finding_unscrambled_times(:,ionset) - pre_base)) ))]; %getting pre-baseline time in t_unscrambled (NOT location)
                post = fs*(abs(erp_window_end_time)/1000);
                finding_unscram_end_time = [finding_unscram_end_time (t_unscrambled( ceil((finding_unscrambled_times(:,ionset) + post)) ))]; %getting end time in t_unscrambled (NOT location)

                unscram_start_end_time_indices = [find(t_unscrambled==finding_unscram_pre_baselined_time(:,ionset)) find(t_unscrambled==finding_unscram_end_time(:,ionset))];

                unscrambled_by_target_onset(:,:,:) = unscrambled_data_frontochan(:,unscram_start_end_time_indices(1):unscram_start_end_time_indices(2),:);
            end

        end
    end

end


for k = 1:num_tot_trials %variability across trials 
    scrambled_data_avg(:,k) = detrend(mean(squeeze(scrambled_by_target_onset(:,:,k))) ); %(4352 time points x 24 trials)
    unscrambled_data_avg(:,k) = detrend(mean(squeeze(unscrambled_by_target_onset(:,:,k))) ); %(4352 time points x 24 trials)
end


%% Plotting single subject data 
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


[~,finding_first_nonzero] = min(abs(t_scrambled_epoch_normalized - 0));

%% scrambled epoch isolated
% figure; 
% plot(t_scrambled_epoch_normalized,detrend(scrambled_by_target_onset_avg))
% xline(t_scrambled_epoch_normalized(finding_first_nonzero),'r--','Target Onset') %plotting xline at first nonzero
% xlabel('Time (ms)')
% ylabel('Amplitude')
% title('Scrambled Condition Epoch')



addpath C:\Users\ema36\Documents\errorbar_files;
figure
shadedErrorBar(t_scrambled_epoch_normalized,scrambled_by_target_onset_avg,SEM_scrambled_by_target_onset_across_trials,'lineProps','b')
hold on
shadedErrorBar(t_scrambled_epoch_normalized,unscrambled_by_target_onset_avg,SEM_unscrambled_by_target_onset_across_trials,'lineProps','r')
xline(t_scrambled_epoch_normalized(finding_scram_first_nonzero),'k--','Target Onset','LineWidth',1.5) %plotting xline at first nonzero
legend('Scrambled','Unscrambled')
xlabel('Time (ms)')
ylabel('Amplitude')
title('Scrambled & Unscrambled Conditions Epoch (across trials SEM)')




%% BEN'S OTHER CODE I DIDN'T TOUCH BELOW (VF)
% I didn't use code below because on eeglab when I epoched from -1 to 16
% sec, I did a baseline correction where it subtracts the average of the
% entire epoch. 
% If you want to do further baseline correction for the target onset 
% epochs, modify your code below and put it "Isolate target word onset 
% ERPs for both conditions" section


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Isolate masker word onset ERPs for unscrambled condition only

% % find erp and baseline
% for isubject = 1:nsubjects
%     scrambled_frontocentral_erp(isubject,:,:,:) = scrambled_by_target_onset(isubject,:,frontocentral_channels,:);
%     unscrambled_frontocentral_erp(isubject,:,:,:) = unscrambled_by_target_onset(isubject,:,frontocentral_channels,:);
%     % average over presentations
%     [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
%     [~,baseline_end_index] = min(abs(single_onset_time - 0));
%     for ichannel = 1:length(frontocentral_channels)
%         scrambled_frontocentral_erp_baselined(isubject,:,ichannel,:) = (scrambled_frontocentral_erp(isubject,:,ichannel,:) - mean(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[2,4]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%         unscrambled_frontocentral_erp_baselined(isubject,:,ichannel,:) = (unscrambled_frontocentral_erp(isubject,:,ichannel,:) - mean(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[2,4]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%     end
% end
% % take mean over electrodes and presentation
% scrambled_frontocentral_erp_mean_over_electrodes = squeeze(mean(scrambled_frontocentral_erp_baselined,[2,3]));
% unscrambled_frontocentral_erp_mean_over_electrodes = squeeze(mean(unscrambled_frontocentral_erp_baselined,[2,3]));
% 


% %% Plot unscrambled targets vs. unscrambled masker in frontocentral electrodes
% % Just Frontocentral electrodes
% % Fp1 (ch1), AF3 (ch2), F3 (ch4), FC1 (ch5), FC5 (ch6),
% % C3 (ch8), CP1 (ch9), C4 (ch23), FC6 (ch25), FC2 (ch26), F4 (ch27), AF4 (ch29), Fz (ch31), and Cz (ch32)
% frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
% 
% single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(unscrambled_by_target_onset(:,:,frontocentral_channels,:),4));
% 
% % find erp and baseline
% for isubject = 1:nsubjects
%     target_frontocentral_erp(isubject,:,:,:) = unscrambled_by_target_onset(isubject,:,frontocentral_channels,:);
%     masker_frontocentral_erp(isubject,:,:,:) = unscrambled_by_masker_onset(isubject,:,frontocentral_channels,:);
%     [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
%     [~,baseline_end_index] = min(abs(single_onset_time - 0));
%     for ichannel = 1:length(frontocentral_channels)
%         target_frontocentral_erp_baselined(isubject,:,ichannel,:) = (target_frontocentral_erp(isubject,:,ichannel,:) - mean(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[2,4]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%         masker_frontocentral_erp_baselined(isubject,:,ichannel,:) = (masker_frontocentral_erp(isubject,:,ichannel,:) - mean(unscrambled_by_masker_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[2,4]));%./std(unscrambled_by_masker_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%     end
% end
% % take mean over electrodes and presentation
% target_frontocentral_erp_mean_over_electrodes = squeeze(mean(target_frontocentral_erp_baselined,[2,3]));
% masker_frontocentral_erp_mean_over_electrodes = squeeze(mean(masker_frontocentral_erp_baselined,[2,3]));
