% POSTPROCESSING INDIVIDUAL ERPs and WORD ONSETS
% Primary Author: Benjamin Richardson
% Secondary Authors: Emaya Anand, Maanasa Guru Adimurthy

% Set directories
whos_using = 'Ben';
if all(whos_using == 'Ben')
    addpath('/home/ben/Documents/MATLAB/eeglab2023.1');
    dir = '/home/ben/Documents/GitHub/fNIRSandGerbils/';
    dir_fnirsandgerbils = '/home/ben/Documents/GitHub/fNIRSandGerbils/data/fNIRSandGerbils.xlsx';
elseif all(whos_using == 'Bon')
    addpath('C:\Users\benri\Documents\eeglab2023.1');
    dir = 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\';
    dir_fnirsandgerbils = 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';   
else
    dir = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\';
    dir_fnirsandgerbils = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';
end
curr_subject_ID =  char('7038');% char('7006','7007','7008','7009','7010','7017','7022','7023','7024','7025','7030','7033'); % ,

% Set analysis parameters
erp_window_start_time = -100; % 100 ms before onset of word
erp_window_end_time = 750; % 750 ms after onset of word
nsubjects = size(curr_subject_ID,1); 
word_length = 0.3;
num_tot_trials = 144; % look into this
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
fs = 256;

%% For each subject.....
for isubject = 1:size(curr_subject_ID,1)
    subID = curr_subject_ID(isubject,:); % set subject ID

    % Load word onset times data
    stim_info_filename = [dir,'stim/s_',strtrim(curr_subject_ID(isubject,:)),'/',strtrim(curr_subject_ID(isubject,:)),'_alltrialwords.mat'];
    load(stim_info_filename); % loads all_word_order (array of all words) and tOnset (the onset times within each trial)

    % Read in click times, find the rows in the table for this subject
    all_click_info = readtable(dir_fnirsandgerbils,'FileType','spreadsheet','Format','auto');
    which_rows_this_subject = find(all_click_info.S == string(curr_subject_ID(isubject,:))); % find the rows in the spreadsheet which belong to this subject
    conditions = all_click_info.Condition(which_rows_this_subject); % conditions by trial for this subject
    condition_names = {'scrambled_dt','scrambled_st','unscrambled_dt','unscrambled_st'};

    % Create empty arrays for ERPs
    % Scrambled Same Talker
    scrambled_st_by_target_red_onset = [];
    scrambled_st_by_target_green_onset = [];
    scrambled_st_by_target_blue_onset = [];
    scrambled_st_by_target_white_onset = [];
    scrambled_st_by_target_object_onset = [];
    scrambled_st_by_masker_onset = [];
    
    % Unscrambled Same Talker
    unscrambled_st_by_target_red_onset = [];
    unscrambled_st_by_target_green_onset = [];
    unscrambled_st_by_target_blue_onset = [];
    unscrambled_st_by_target_white_onset =[];
    unscrambled_st_by_target_object_onset = [];
    unscrambled_st_by_masker_onset = [];

    % Scrambled Different Talker
    scrambled_dt_by_target_red_onset = [];
    scrambled_dt_by_target_green_onset = [];
    scrambled_dt_by_target_blue_onset = [];
    scrambled_dt_by_target_white_onset = [];
    scrambled_dt_by_target_object_onset = [];
    scrambled_dt_by_masker_onset = [];

    % Unscrambled Different Talker
    unscrambled_dt_by_target_red_onset = [];
    unscrambled_dt_by_target_green_onset = [];
    unscrambled_dt_by_target_blue_onset = [];
    unscrambled_dt_by_target_white_onset = [];
    unscrambled_dt_by_target_object_onset = [];
    unscrambled_dt_by_masker_onset = [];


    %% For each of the four conditions....
    for icondition = 1:4
        % condition 1 = scrambled diff talker
        % condition 2 = scrambled same talker
        % condition 3 = unscrambled diff talker
        % condition 4 = unscrambled same talker
        data_by_masker_onset = [];
        data_by_red_onset = [];
        data_by_green_onset = [];
        data_by_blue_onset = [];
        data_by_white_onset  = [];
        data_by_color_onset = [];
        data_by_object_onset = [];

        % Load EEG for this condition
        epochs_filename = join([dir,'prepro_epoched_data/',strtrim(curr_subject_ID(isubject,:)),string(condition_names(icondition)),'_epoch.mat'],'');
        this_condition_EEG = load(epochs_filename);
        eeg_struct_name = fieldnames(this_condition_EEG);
        this_condition_EEG = getfield(this_condition_EEG,string(eeg_struct_name(1)));
        these_epochs = this_condition_EEG.data; % 32 channels x Time x 36 trials

        % Find target words and onset times for this condition
        which_rows_this_condition = find(conditions == icondition);
        this_condition_target_onsets = all_target_onsets(which_rows_this_condition);
        this_condition_target_words = all_target_words(which_rows_this_condition);



        % Define time vector for extracting target ERPs
        scrambled_time = this_condition_EEG.times; % in milliseconds
        unscrambled_time = this_condition_EEG.times; % in milliseconds

        % Define time vector for extracting masker ERPs
        stimulus_length = 12; % seconds
        word_length = 0.3; % seconds
        masker_time = 0:0.3*fs:(11.7*fs);

        %% For each trial...
        for itrial = 1:size(this_condition_EEG.data,3)% for each trial in this condition (should be 36)
            this_trial_target_onsets = this_condition_target_onsets(itrial).onsets; % find onsets of target words in this trial
            % Within Target Onsets
            for ionset = 1:length(this_trial_target_onsets) % for each target word onset...
                resampled_search_index = (this_trial_target_onsets(ionset));%/(44100/fs);
                [~,start_time] = min(abs(scrambled_time - resampled_search_index)); % find index in time vector that corresponds

                start_time = round(start_time + ((erp_window_start_time/1000)*fs)); % find ERP start index
                end_time = round(start_time + floor(((erp_window_end_time - erp_window_start_time)/1000)*256)); % find ERP end index

                % Reject epochs with amplitude above +/- 100 uV
                if any(abs(detrend(these_epochs(:,start_time:end_time,itrial))) > 100,'all')
                    continue
                    print('epoch rejected')
                end

                % Isolate ERP
                this_erp = these_epochs(:,start_time:end_time,itrial);

                % Put it into appropriate matrix
                if this_condition_target_words(itrial).words(ionset) == 'red'
                    data_by_red_onset = cat(3, data_by_red_onset,this_erp);
                    data_by_color_onset = cat(3, data_by_color_onset ,these_epochs(:,start_time:end_time,itrial));

                elseif this_condition_target_words(itrial).words(ionset) == 'green'
                    data_by_green_onset = cat(3, data_by_green_onset,this_erp);
                    data_by_color_onset= cat(3, data_by_color_onset ,this_erp);

                elseif this_condition_target_words(itrial).words(ionset) == 'white'
                    data_by_white_onset = cat(3, data_by_white_onset,this_erp);
                    data_by_color_onset= cat(3, data_by_color_onset ,this_erp);

                elseif this_condition_target_words(itrial).words(ionset) == 'blue'
                    data_by_blue_onset= cat(3, data_by_blue_onset,this_erp);
                    data_by_color_onset= cat(3, data_by_color_onset,this_erp);

                else
                    data_by_object_onset = cat(3, data_by_object_onset,this_erp);
                end
            end
            
            % Background Onsets (masker onsets)
            for ionset = 1:length(masker_time)

                resampled_search_index = (masker_time(ionset) + (1*fs) - (0.1*fs));
                start_time = round(resampled_search_index);
                end_time = round(start_time + floor(((erp_window_end_time - erp_window_start_time)/1000)*256));

                % Reject epochs with amplitude above +/- 100 uV
                if any(abs(detrend(these_epochs(:,start_time:end_time,itrial))) > 100,'all')
                    continue
                    print('epoch rejected')
                end

                this_erp = these_epochs(:,start_time:end_time,itrial);
                data_by_masker_onset = cat(3, data_by_masker_onset,these_epochs(:,start_time:end_time,itrial));
            end
            
        end
        % save to appropriate array
        if icondition == 1
            scrambled_dt_by_target_red_onset = data_by_red_onset;
            scrambled_dt_by_target_green_onset = data_by_green_onset;
            scrambled_dt_by_target_blue_onset = data_by_blue_onset;
            scrambled_dt_by_target_white_onset = data_by_white_onset;
            scrambled_dt_by_target_color_onset = data_by_color_onset;
            scrambled_dt_by_target_object_onset = data_by_object_onset;
            scrambled_dt_by_masker_onset =data_by_masker_onset;
        elseif icondition == 2
            scrambled_st_by_target_red_onset = data_by_red_onset;
            scrambled_st_by_target_green_onset = data_by_green_onset;
            scrambled_st_by_target_blue_onset = data_by_blue_onset;
            scrambled_st_by_target_white_onset = data_by_white_onset;
            scrambled_st_by_target_color_onset = data_by_color_onset;
            scrambled_st_by_target_object_onset = data_by_object_onset;
            scrambled_st_by_masker_onset = data_by_masker_onset;
        elseif icondition == 3
            unscrambled_dt_by_target_red_onset = data_by_red_onset;
            unscrambled_dt_by_target_green_onset = data_by_green_onset;
            unscrambled_dt_by_target_blue_onset = data_by_blue_onset;
            unscrambled_dt_by_target_white_onset =data_by_white_onset;
            unscrambled_dt_by_target_color_onset = data_by_color_onset;
            unscrambled_dt_by_target_object_onset = data_by_object_onset;
            unscrambled_dt_by_masker_onset = data_by_masker_onset;
        elseif icondition == 4
            unscrambled_st_by_target_red_onset = data_by_red_onset;
            unscrambled_st_by_target_green_onset = data_by_green_onset;
            unscrambled_st_by_target_blue_onset = data_by_blue_onset;
            unscrambled_st_by_target_white_onset =data_by_white_onset;
            unscrambled_st_by_target_color_onset = data_by_color_onset;
            unscrambled_st_by_target_object_onset = data_by_object_onset;
            unscrambled_st_by_masker_onset = data_by_masker_onset;
        end   

    end

    single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_color_onset,2));

    [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
    [~,baseline_end_index] = min(abs(single_onset_time - 0));

    % Concatenate and baseline

    all_data_target_this_subject = cat(3,scrambled_st_by_target_color_onset,scrambled_dt_by_target_color_onset,...
        scrambled_st_by_target_object_onset,scrambled_dt_by_target_object_onset,...
        unscrambled_st_by_target_color_onset,unscrambled_dt_by_target_color_onset,...
        unscrambled_st_by_target_object_onset,unscrambled_dt_by_target_object_onset); % include masker or no??

    all_data_masker_this_subject = cat(3,scrambled_st_by_masker_onset,scrambled_dt_by_masker_onset,...
        unscrambled_st_by_masker_onset,unscrambled_dt_by_masker_onset); % include masker or no??

    for ichannel = 1:32
        this_target_baseline_mean = nanmean(all_data_target_this_subject(ichannel,baseline_start_index:baseline_end_index,:),'all');
        this_masker_baseline_mean = nanmean(all_data_masker_this_subject(ichannel,baseline_start_index:baseline_end_index,:),'all');

        all_scrambled_st_by_target_red_onset(isubject,ichannel,:) = squeeze(mean(scrambled_st_by_target_red_onset(ichannel,:,:) - this_target_baseline_mean,3));
        all_scrambled_st_by_target_green_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_st_by_target_green_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_scrambled_st_by_target_blue_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_st_by_target_blue_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_scrambled_st_by_target_white_onset(isubject,ichannel,:) = squeeze(mean(scrambled_st_by_target_white_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_scrambled_st_by_target_object_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_st_by_target_object_onset(ichannel,:,:)  - this_target_baseline_mean,3));
    
        all_unscrambled_st_by_target_red_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_st_by_target_red_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_unscrambled_st_by_target_green_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_st_by_target_green_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_unscrambled_st_by_target_blue_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_st_by_target_blue_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_unscrambled_st_by_target_white_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_st_by_target_white_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_unscrambled_st_by_target_object_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_st_by_target_object_onset(ichannel,:,:)  - this_target_baseline_mean,3));
    
        all_scrambled_dt_by_target_red_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_dt_by_target_red_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_scrambled_dt_by_target_green_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_dt_by_target_green_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_scrambled_dt_by_target_blue_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_dt_by_target_blue_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_scrambled_dt_by_target_white_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_dt_by_target_white_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_scrambled_dt_by_target_object_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_dt_by_target_object_onset(ichannel,:,:)  - this_target_baseline_mean,3));
    
        all_unscrambled_dt_by_target_red_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_dt_by_target_red_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_unscrambled_dt_by_target_green_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_dt_by_target_green_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_unscrambled_dt_by_target_blue_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_dt_by_target_blue_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_unscrambled_dt_by_target_white_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_dt_by_target_white_onset(ichannel,:,:)  - this_target_baseline_mean,3));
        all_unscrambled_dt_by_target_object_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_dt_by_target_object_onset(ichannel,:,:)  - this_target_baseline_mean,3));
    
        all_scrambled_dt_by_masker_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_dt_by_masker_onset(ichannel,:,:)  - this_masker_baseline_mean,3));
        all_scrambled_st_by_masker_onset(isubject,ichannel,:) =  squeeze(mean(scrambled_st_by_masker_onset(ichannel,:,:)  - this_masker_baseline_mean,3));
        all_unscrambled_st_by_masker_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_st_by_masker_onset(ichannel,:,:)  - this_masker_baseline_mean,3));
        all_unscrambled_dt_by_masker_onset(isubject,ichannel,:) =  squeeze(mean(unscrambled_dt_by_masker_onset(ichannel,:,:)  - this_masker_baseline_mean,3));
    
        % for plotting big averages ignoring same vs diff talker
        
        all_scrambled_by_color_onset(isubject,ichannel,:) = squeeze(mean(cat(3,scrambled_st_by_target_color_onset(ichannel,:,:)  - this_target_baseline_mean,scrambled_dt_by_target_color_onset(ichannel,:,:)  - this_target_baseline_mean),3));
        all_scrambled_by_object_onset(isubject,ichannel,:)  = squeeze(mean(cat(3,scrambled_st_by_target_object_onset(ichannel,:,:) - this_target_baseline_mean,scrambled_dt_by_target_object_onset(ichannel,:,:) - this_target_baseline_mean),3));
        all_scrambled_by_masker_onset(isubject,ichannel,:) = squeeze(mean(cat(3,scrambled_st_by_masker_onset(ichannel,:,:) - this_masker_baseline_mean,scrambled_dt_by_masker_onset(ichannel,:,:) - this_masker_baseline_mean),3));
    
        all_unscrambled_by_color_onset(isubject,ichannel,:) = squeeze(mean(cat(3,unscrambled_st_by_target_color_onset(ichannel,:,:) - this_target_baseline_mean,unscrambled_dt_by_target_color_onset(ichannel,:,:) - this_target_baseline_mean),3));
        all_unscrambled_by_object_onset(isubject,ichannel,:) = squeeze(mean(cat(3,unscrambled_st_by_target_object_onset(ichannel,:,:) - this_target_baseline_mean,unscrambled_dt_by_target_object_onset(ichannel,:,:) - this_target_baseline_mean),3));
        all_unscrambled_by_masker_onset(isubject,ichannel,:)  = squeeze(mean(cat(3,unscrambled_st_by_masker_onset(ichannel,:,:) - this_masker_baseline_mean,unscrambled_dt_by_masker_onset(ichannel,:,:) - this_masker_baseline_mean),3));
    end
    % Plot for each subject
    figure;
   
    subplot(1,3,1)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_color_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_color_onset(isubject,frontocentral_channels,:),2)),'-b');
    title('Target Color Word')
    legend({'Scrambled','Unscrambled'})

    subplot(1,3,2)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_object_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_object_onset(isubject,frontocentral_channels,:),2)),'-b');
    title('Target Object Word')
    legend({'Scrambled','Unscrambled'})

    subplot(1,3,3)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_masker_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_masker_onset(isubject,frontocentral_channels,:),2)),'-b');
    title('Masker Word')
    legend({'Scrambled','Unscrambled'})
    sgtitle(subID)
end

%% Going to build a 4 conditions x 6 word types x time array for this subject
% 1) Same Talker scrambled, 2) Same Talker unsrambled, 3) Diff Talker scrambled,
% 4) Diff talker unscrambled

% 1) red, 2) green , 3) white , 4) blue , 5) object, 6) masker
meanERPArray = [];


%% Plotting
%addpath C:\Users\ema36\OneDrive\Documents\errorbar_files\errorbar_files
%% Same Talker Plot
figure;

%% scrambled vs unscrambled red
subplot(2,3,1)
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp_baselined = squeeze(all_scrambled_st_by_target_red_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp_baselined = squeeze(all_unscrambled_st_by_target_red_onset(:,frontocentral_channels,:));
% average over presentations
% [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
% [~,baseline_end_index] = min(abs(single_onset_time - 0));
% for isubject = 1:size(curr_subject_ID,1)
%     for ichannel = 1:length(frontocentral_channels)
%         scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%         unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%     end
% end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects -1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Red','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

meanERPArray(1,1,:) = scrambled_mean_to_plot;
meanERPArray(2,1,:) = unscrambled_mean_to_plot;

semERPArray(1,1,:) = scrambled_SEM_to_plot;
semERPArray(2,1,:) = unscrambled_SEM_to_plot;
%% scrambled vs unscrambled green
subplot(2,3,2)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_st_by_target_green_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_st_by_target_green_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Green','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

meanERPArray(1,2,:) = scrambled_mean_to_plot;
meanERPArray(2,2,:) = unscrambled_mean_to_plot;

semERPArray(1,2,:) = scrambled_SEM_to_plot;
semERPArray(2,2,:) = unscrambled_SEM_to_plot;
%% scrambled vs unccrambled white
subplot(2,3,4)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_st_by_target_white_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_st_by_target_white_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('White','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

meanERPArray(1,3,:) = scrambled_mean_to_plot;
meanERPArray(2,3,:) = unscrambled_mean_to_plot;

semERPArray(1,3,:) = scrambled_SEM_to_plot;
semERPArray(2,3,:) = unscrambled_SEM_to_plot;
%% scrambled vs unscrambled blue
subplot(2,3,5)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_st_by_target_blue_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_st_by_target_blue_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Blue','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

meanERPArray(1,4,:) = scrambled_mean_to_plot;
meanERPArray(2,4,:) = unscrambled_mean_to_plot;

semERPArray(1,4,:) = scrambled_SEM_to_plot;
semERPArray(2,4,:) = unscrambled_SEM_to_plot;
%% scrambled vs unscrambled object
subplot(2,3,3)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_st_by_target_object_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_st_by_target_object_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Object','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

meanERPArray(1,5,:) = scrambled_mean_to_plot;
meanERPArray(2,5,:) = unscrambled_mean_to_plot;

semERPArray(1,5,:) = scrambled_SEM_to_plot;
semERPArray(2,5,:) = unscrambled_SEM_to_plot;
%% scrambled vs unscrambled masker word
subplot(2,3,6)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_st_by_masker_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_st_by_masker_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Masker','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])
sgtitle('Same Talker')

meanERPArray(1,6,:) = scrambled_mean_to_plot;
meanERPArray(2,6,:) = unscrambled_mean_to_plot;

semERPArray(1,6,:) = scrambled_SEM_to_plot;
semERPArray(2,6,:) = unscrambled_SEM_to_plot;
%% Diff Talker Plot
figure;

% scrambled vs unscrambled red
subplot(2,3,1)
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_dt_by_target_red_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_dt_by_target_red_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Red','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

meanERPArray(3,1,:) = scrambled_mean_to_plot;
meanERPArray(4,1,:) = unscrambled_mean_to_plot;

semERPArray(3,1,:) = scrambled_SEM_to_plot;
semERPArray(4,1,:) = unscrambled_SEM_to_plot;
%% scrambled vs unscrambled green
subplot(2,3,2)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_dt_by_target_green_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_dt_by_target_green_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Green','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])



meanERPArray(3,2,:) = scrambled_mean_to_plot;
meanERPArray(4,2,:) = unscrambled_mean_to_plot;

semERPArray(3,2,:) = scrambled_SEM_to_plot;
semERPArray(4,2,:) = unscrambled_SEM_to_plot;
%% scrambled vs unccrambled white
subplot(2,3,4)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_dt_by_target_white_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_dt_by_target_white_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('White','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])


meanERPArray(3,3,:) = scrambled_mean_to_plot;
meanERPArray(4,3,:) = unscrambled_mean_to_plot;

semERPArray(3,3,:) = scrambled_SEM_to_plot;
semERPArray(4,3,:) = unscrambled_SEM_to_plot;
%% scrambled vs unscrambled blue
subplot(2,3,5)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_dt_by_target_blue_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_dt_by_target_blue_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Blue','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])


meanERPArray(3,4,:) = scrambled_mean_to_plot;
meanERPArray(4,4,:) = unscrambled_mean_to_plot;

semERPArray(3,4,:) = scrambled_SEM_to_plot;
semERPArray(4,4,:) = unscrambled_SEM_to_plot;
%% scrambled vs unscrambled object
subplot(2,3,3)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_dt_by_target_object_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_dt_by_target_object_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Object','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

meanERPArray(3,5,:) = scrambled_mean_to_plot;
meanERPArray(4,5,:) = unscrambled_mean_to_plot;

semERPArray(3,5,:) = scrambled_SEM_to_plot;
semERPArray(4,5,:) = unscrambled_SEM_to_plot;
%% scrambled vs unscrambled Masker words
subplot(2,3,6)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_dt_by_masker_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_dt_by_masker_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Masker','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

sgtitle('Diff Talker')

meanERPArray(3,6,:) = scrambled_mean_to_plot;
meanERPArray(4,6,:) = unscrambled_mean_to_plot;

semERPArray(3,6,:) = scrambled_SEM_to_plot;
semERPArray(4,6,:) = unscrambled_SEM_to_plot;

%% Collapsed same and different talker
figure;

% scrambled vs unscrambled red
subplot(2,3,1)
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(cat(1,all_scrambled_dt_by_target_red_onset(:,frontocentral_channels,:),all_scrambled_st_by_target_red_onset(:,frontocentral_channels,:)));
unscrambled_frontocentral_erp = squeeze(cat(1,all_unscrambled_dt_by_target_red_onset(:,frontocentral_channels,:),all_unscrambled_st_by_target_red_onset(:,frontocentral_channels,:)));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Red','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

% scrambled vs unscrambled green
subplot(2,3,2)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(cat(1,all_scrambled_dt_by_target_green_onset(:,frontocentral_channels,:),all_scrambled_st_by_target_green_onset(:,frontocentral_channels,:)));
unscrambled_frontocentral_erp = squeeze(cat(1,all_unscrambled_dt_by_target_green_onset(:,frontocentral_channels,:),all_unscrambled_st_by_target_green_onset(:,frontocentral_channels,:)));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Green','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

%% scrambled vs unccrambled white
subplot(2,3,4)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(cat(1,all_scrambled_dt_by_target_white_onset(:,frontocentral_channels,:),all_scrambled_st_by_target_white_onset(:,frontocentral_channels,:)));
unscrambled_frontocentral_erp = squeeze(cat(1,all_unscrambled_dt_by_target_white_onset(:,frontocentral_channels,:),all_unscrambled_st_by_target_white_onset(:,frontocentral_channels,:)));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('White','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])


%% scrambled vs unscrambled blue
subplot(2,3,5)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(cat(1,all_scrambled_dt_by_target_blue_onset(:,frontocentral_channels,:),all_scrambled_st_by_target_blue_onset(:,frontocentral_channels,:)));
unscrambled_frontocentral_erp = squeeze(cat(1,all_unscrambled_dt_by_target_blue_onset(:,frontocentral_channels,:),all_unscrambled_st_by_target_blue_onset(:,frontocentral_channels,:)));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Blue','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

%% scrambled vs unscrambled object
subplot(2,3,3)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(cat(1,all_scrambled_dt_by_target_object_onset(:,frontocentral_channels,:),all_scrambled_st_by_target_object_onset(:,frontocentral_channels,:)));
unscrambled_frontocentral_erp = squeeze(cat(1,all_unscrambled_dt_by_target_object_onset(:,frontocentral_channels,:),all_unscrambled_st_by_target_object_onset(:,frontocentral_channels,:)));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Object','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])


%% scrambled vs unscrambled Masker words
subplot(2,3,6)

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(cat(1,all_scrambled_dt_by_masker_onset(:,frontocentral_channels,:),all_scrambled_st_by_masker_onset(:,frontocentral_channels,:)));
unscrambled_frontocentral_erp = squeeze(cat(1,all_unscrambled_dt_by_masker_onset(:,frontocentral_channels,:),all_unscrambled_st_by_masker_onset(:,frontocentral_channels,:)));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (scrambled_frontocentral_erp(isubject,ichannel,:) - mean(scrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,ichannel,:) = (unscrambled_frontocentral_erp(isubject,ichannel,:) - mean(unscrambled_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end

scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Masker','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-3 4])

sgtitle('Both Talker Conditions')







%% average color word, average object word, and average masker responses in unscrambled vs scrambled
figure;
subplot(1,2,1) % unscrambled


frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
color_frontocentral_erp = squeeze(all_unscrambled_by_color_onset(:,frontocentral_channels,:));
object_frontocentral_erp = squeeze(all_unscrambled_by_object_onset(:,frontocentral_channels,:));
masker_frontocentral_erp = squeeze(all_unscrambled_by_masker_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        color_frontocentral_erp_baselined(isubject,ichannel,:) = (color_frontocentral_erp(isubject,ichannel,:) - mean(color_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        object_frontocentral_erp_baselined(isubject,ichannel,:) = (object_frontocentral_erp(isubject,ichannel,:) - mean(object_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        masker_frontocentral_erp_baselined(isubject,ichannel,:) = (masker_frontocentral_erp(isubject,ichannel,:) - mean(masker_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);

    end
end

unscrambled_color_mean_to_plot = mean(color_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_color_SEM_to_plot = std(color_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,unscrambled_color_mean_to_plot,unscrambled_color_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_object_mean_to_plot = mean(object_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_object_SEM_to_plot = std(object_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,unscrambled_object_mean_to_plot,unscrambled_object_SEM_to_plot,'lineProps','-g')

unscrambled_masker_mean_to_plot = mean(masker_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_masker_SEM_to_plot = std(masker_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,unscrambled_masker_mean_to_plot,unscrambled_masker_SEM_to_plot,'lineProps','-b')

title('Unscrambled','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Color Target Word','Object Target Word','Masker Word'})
ylim([-3,4])


subplot(1,2,2) % scrambled

frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
color_frontocentral_erp = squeeze(all_scrambled_by_color_onset(:,frontocentral_channels,:));
object_frontocentral_erp = squeeze(all_scrambled_by_object_onset(:,frontocentral_channels,:));
masker_frontocentral_erp = squeeze(all_scrambled_by_masker_onset(:,frontocentral_channels,:));
% average over presentations
[~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
[~,baseline_end_index] = min(abs(single_onset_time - 0));
for isubject = 1:size(curr_subject_ID,1)
    for ichannel = 1:length(frontocentral_channels)
        color_frontocentral_erp_baselined(isubject,ichannel,:) = (color_frontocentral_erp(isubject,ichannel,:) - mean(color_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        object_frontocentral_erp_baselined(isubject,ichannel,:) = (object_frontocentral_erp(isubject,ichannel,:) - mean(object_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        masker_frontocentral_erp_baselined(isubject,ichannel,:) = (masker_frontocentral_erp(isubject,ichannel,:) - mean(masker_frontocentral_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);

    end
end

scrambled_color_mean_to_plot = mean(color_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_color_SEM_to_plot = std(color_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_color_mean_to_plot,scrambled_color_SEM_to_plot,'lineProps','-r')
hold on
scrambled_object_mean_to_plot = mean(object_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_object_SEM_to_plot = std(object_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_object_mean_to_plot,scrambled_object_SEM_to_plot,'lineProps','-g')

scrambled_masker_mean_to_plot = mean(masker_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_masker_SEM_to_plot = std(masker_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects-1)); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_masker_mean_to_plot,scrambled_masker_SEM_to_plot,'lineProps','-b')

title('Scrambled','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Color Target Word','Object Target Word','Masker Word'})
ylim([-3,4])


%% Figure by word type
figure;
subplot(1,3,1)
hold on
shadedErrorBar(single_onset_time,scrambled_color_mean_to_plot,scrambled_color_SEM_to_plot,'lineProps','-r')
shadedErrorBar(single_onset_time,unscrambled_color_mean_to_plot,unscrambled_color_SEM_to_plot,'lineProps','-b')


title('Target Color Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Scrambled','Unscrambled'})
ylim([-3 4])
xlim([-100 600])


subplot(1,3,2)
hold on
shadedErrorBar(single_onset_time,scrambled_object_mean_to_plot,scrambled_object_SEM_to_plot,'lineProps','-r')
shadedErrorBar(single_onset_time,unscrambled_object_mean_to_plot,unscrambled_object_SEM_to_plot,'lineProps','-b')

title('Non-Target Object Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Scrambled','Unscrambled'})
ylim([-3 4])
xlim([-100 600])


subplot(1,3,3)
hold on
shadedErrorBar(single_onset_time,scrambled_masker_mean_to_plot,scrambled_masker_SEM_to_plot,'lineProps','-r')
shadedErrorBar(single_onset_time,unscrambled_masker_mean_to_plot,unscrambled_masker_SEM_to_plot,'lineProps','-b')

title('Masker Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Scrambled','Unscrambled'})
ylim([-3 4])
xlim([-100 600])


%% Same vs. Different talker
%% Figure by word type
figure;

% scrambled color
subplot(2,3,1)
hold on
shadedErrorBar(single_onset_time,mean(meanERPArray(1,[1,2,3,4],:),[1,2]),mean(semERPArray(1,[1,2,3,4],:),[1,2]),'lineProps','-g')
shadedErrorBar(single_onset_time,mean(meanERPArray(3,[1,2,3,4],:),[1,2]),mean(semERPArray(3,[1,2,3,4],:),[1,2]),'lineProps','-m')


title('Scrambled Target Color Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Same Talker','Different Talker'})
ylim([-4,4])
xlim([-100 600])

% scrambled object 
subplot(2,3,2)
hold on
shadedErrorBar(single_onset_time,mean(meanERPArray(1,5,:),[1,2]),mean(semERPArray(1,5,:),[1,2]),'lineProps','-g')
shadedErrorBar(single_onset_time,mean(meanERPArray(3,5,:),[1,2]),mean(semERPArray(3,5,:),[1,2]),'lineProps','-m')

title('Scrambled Distracting Object Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Same Talker','Different Talker'})
ylim([-4,4])
xlim([-100 600])

% scrambled masker 
subplot(2,3,3)
hold on
shadedErrorBar(single_onset_time,mean(meanERPArray(1,6,:),[1,2]),mean(semERPArray(1,6,:),[1,2]),'lineProps','-g')
shadedErrorBar(single_onset_time,mean(meanERPArray(3,6,:),[1,2]),mean(semERPArray(3,6,:),[1,2]),'lineProps','-m')

title('Scrambled Masker Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Same Talker','Different Talker'})
ylim([-4,4])
xlim([-100 600])

% unscrambled color
subplot(2,3,4)
hold on
shadedErrorBar(single_onset_time,mean(meanERPArray(2,[1,2,3,4],:),[1,2]),mean(semERPArray(2,[1,2,3,4],:),[1,2]),'lineProps','-g')
shadedErrorBar(single_onset_time,mean(meanERPArray(4,[1,2,3,4],:),[1,2]),mean(semERPArray(4,[1,2,3,4],:),[1,2]),'lineProps','-m')


title('Unscrambled Target Color Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Same Talker','Different Talker'})
ylim([-4,4])
xlim([-100 600])

% unscrambled object 
subplot(2,3,5)
hold on
shadedErrorBar(single_onset_time,mean(meanERPArray(2,5,:),[1,2]),mean(semERPArray(2,5,:),[1,2]),'lineProps','-g')
shadedErrorBar(single_onset_time,mean(meanERPArray(4,5,:),[1,2]),mean(semERPArray(4,5,:),[1,2]),'lineProps','-m')

title('Unscrambled Distracting Object Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Same Talker','Different Talker'})
ylim([-4,4])
xlim([-100 600])

% unscrambled masker 
subplot(2,3,6)
hold on
shadedErrorBar(single_onset_time,mean(meanERPArray(2,6,:),[1,2]),mean(semERPArray(2,6,:),[1,2]),'lineProps','-g')
shadedErrorBar(single_onset_time,mean(meanERPArray(4,6,:),[1,2]),mean(semERPArray(4,6,:),[1,2]),'lineProps','-m')

title('Unscrambled Masker Word','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Same Talker','Different Talker'})
ylim([-4,4])
xlim([-100 600])

%% TOPOPLOTS
eeglab;

figure;
hold on
cmin = -3;
cmax = 5;

% Scrambled

single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(unscrambled_st_by_target_red_onset,2));
color_erp_baselined_scrambled = squeeze(all_scrambled_by_color_onset);
object_erp_baselined_scrambled = squeeze(all_scrambled_by_object_onset);
masker_erp_baselined_scrambled = squeeze(all_scrambled_by_masker_onset);
% % average over presentations
% [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
% [~,baseline_end_index] = min(abs(single_onset_time - 0));
% for isubject = 1:size(curr_subject_ID,1)
%     for ichannel = 1:32
%         color_erp_baselined_scrambled(isubject,ichannel,:) = (color_erp(isubject,ichannel,:) - mean(color_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%         object_erp_baselined_scrambled(isubject,ichannel,:) = (object_erp(isubject,ichannel,:) - mean(object_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%         masker_erp_baselined_scrambled(isubject,ichannel,:) = (masker_erp(isubject,ichannel,:) - mean(masker_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
% 
%     end
% end

% Unscrambled 

single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(unscrambled_st_by_target_red_onset,2));
color_erp_baselined_unscrambled = squeeze(all_unscrambled_by_color_onset);
object_erp_baselined_unscrambled = squeeze(all_unscrambled_by_object_onset);
masker_erp_baselined_unscrambled = squeeze(all_unscrambled_by_masker_onset);
% % average over presentations
% [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
% [~,baseline_end_index] = min(abs(single_onset_time - 0));
% for isubject = 1:size(curr_subject_ID,1)
%     for ichannel = 1:32
%         color_erp_baselined_unscrambled(isubject,ichannel,:) = (color_erp(isubject,ichannel,:) - mean(color_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%         object_erp_baselined_unscrambled(isubject,ichannel,:) = (object_erp(isubject,ichannel,:) - mean(object_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
%         masker_erp_baselined_unscrambled(isubject,ichannel,:) = (masker_erp(isubject,ichannel,:) - mean(masker_erp(isubject,ichannel,baseline_start_index:baseline_end_index),[3]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
% 
%     end
% end

topoplot_indices = round(0:0.05*fs:(((erp_window_end_time - erp_window_start_time)/1000)*fs));
topoplot_indices(1) = 1;
topoplot_times = -100:50:750;

iplot = 1;

subplot(6,length(topoplot_indices)+ 1,iplot);
text(-1,0.5,'Scrambled\newlineColor','Interpreter','tex','FontSize',18);
axis off
iplot = iplot+1;


% Scrambled Color
itime = 1;
for itopo = topoplot_indices
    subplot(6,length(topoplot_indices)+ 1,iplot);
    this_data = mean(color_erp_baselined_scrambled(:,:,itopo), [1,3]);
    topoplot(this_data,this_condition_EEG.chanlocs,'maplimits',[cmin, cmax]);
    title([num2str(topoplot_times(itime)),' ms'])
    iplot = iplot + 1;
    itime = itime + 1;
end

subplot(6,length(topoplot_indices)+ 1,iplot);
text(-1,0.5,'Unscrambled\newlineColor','Interpreter','tex','FontSize',18);
axis off
iplot = iplot+1;

% Unscrambled Color
for itopo = topoplot_indices
    subplot(6,length(topoplot_indices)+ 1,iplot);
    this_data = mean(color_erp_baselined_unscrambled(:,:,itopo), [1,3]);
    topoplot(this_data,this_condition_EEG.chanlocs,'maplimits',[cmin, cmax]);
    iplot = iplot + 1;
end

subplot(6,length(topoplot_indices)+ 1,iplot);
text(-1,0.5,'Scrambled\newlineObject','Interpreter','tex','FontSize',18);
axis off
iplot = iplot+1;

% Scrambled Object
for itopo = topoplot_indices
    subplot(6,length(topoplot_indices)+ 1,iplot);
    this_data = mean(object_erp_baselined_scrambled(:,:,itopo), [1,3]);
    topoplot(this_data,this_condition_EEG.chanlocs,'maplimits',[cmin, cmax]);
    iplot = iplot + 1;
end

subplot(6,length(topoplot_indices)+ 1,iplot);
text(-1,0.5,'Unscrambled\newlineObject','Interpreter','tex','FontSize',18);
axis off
iplot = iplot+1;

% Unscrambled Object
for itopo = topoplot_indices
    subplot(6,length(topoplot_indices)+ 1,iplot);
    this_data = mean(object_erp_baselined_unscrambled(:,:,itopo), [1,3]);
    topoplot(this_data,this_condition_EEG.chanlocs,'maplimits',[cmin, cmax]);
    iplot = iplot + 1;
end

subplot(6,length(topoplot_indices)+ 1,iplot);
text(-1,0.5,'Scrambled\newlineMasker','Interpreter','tex','FontSize',18);
axis off
iplot = iplot+1;

% Scrambled Masker
for itopo = topoplot_indices
    subplot(6,length(topoplot_indices)+ 1,iplot);
    this_data = mean(masker_erp_baselined_scrambled(:,:,itopo), [1,3]);
    topoplot(this_data,this_condition_EEG.chanlocs,'maplimits',[cmin, cmax]);
    iplot = iplot + 1;
end

subplot(6,length(topoplot_indices)+ 1,iplot);
text(-1,0.5,'Unscrambled\newlineMasker','Interpreter','tex','FontSize',18);
axis off
iplot = iplot+1;


% Unscrambled Masker
for itopo = topoplot_indices
    subplot(6,length(topoplot_indices)+ 1,iplot);
    this_data = mean(masker_erp_baselined_unscrambled(:,:,itopo), [1,3]);
    topoplot(this_data,this_condition_EEG.chanlocs,'maplimits',[cmin, cmax]);
    iplot = iplot + 1;
    if itopo == topoplot_indices(end)
        colorbar
    end
end
