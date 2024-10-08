%% gerbilmaster_postprocessing_alltrials.m

% Set directories
whos_using = 'Bon';
if all(whos_using == 'Ben')
    addpath('/home/ben/Documents/MATLAB/eeglab2023.1');
    dir = '/home/ben/Documents/GitHub/fNIRSandGerbils/';
    dir_fnirsandgerbils = '/home/ben/Documents/GitHub/fNIRSandGerbils/data/fNIRSandGerbils.xlsx';
elseif all(whos_using == 'Bon')
    addpath('C:\Users\benri\Documents\eeglab2023.1');
    dir = 'D:\GitHub\fNIRSandGerbils\';
    dir_fnirsandgerbils = 'D:\GitHub\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';
    prepro_folder = 'D:\prepro_epoched_data\';
elseif all(whos_using == 'Maa')
    dir = 'C:\Users\maana\Documents\GitHub\fNIRSandGerbils\';
    dir_fnirsandgerbils = 'C:\Users\maana\Documents\GitHub\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';
    prepro_folder = 'C:\Users\maana\Documents\GitHub\fNIRSandGerbils/prepro_epoched_data/';
else
    dir = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\';
    dir_fnirsandgerbils = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';
end

curr_subject_ID =  char('7033','7035','7036','7039','7040','7041','7043','7044','7045','7047','7048','7049','7050');%char('7002','7004','7007','7008','7010','7023','7024','7033','7035','7036','7038','7039','7040');
% '7023','7024',
% Set analysis parameters
erp_window_start_time = -100; % 100 ms before onset of word
erp_window_end_time = 750; % 750 ms after onset of word
nsubjects = size(curr_subject_ID,1);
word_length = 0.3;
num_tot_trials = 144; % look into this
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
fs = 2048;
target_info={};
subplot_counter = 0;
%% For each subject.....
for isubject = 1:size(curr_subject_ID,1)
    subID = curr_subject_ID(isubject,:); % set subject ID
    disp(subID)

    % Load word onset times data
    stim_info_filename = [dir,'stim/s_',strtrim(curr_subject_ID(isubject,:)),'/',strtrim(curr_subject_ID(isubject,:)),'_alltrialwords.mat'];
    load(stim_info_filename); % loads all_word_order (array of all words) and tOnset (the onset times within each trial)

    % Read in click times, find the rows in the table for this subject
    all_click_info = readtable(dir_fnirsandgerbils,'FileType','spreadsheet','Format','auto');
    which_rows_this_subject = find(all_click_info.S == string(curr_subject_ID(isubject,:))); % find the rows in the spreadsheet which belong to this subject
    conditions = all_click_info.Condition(which_rows_this_subject); % conditions by trial for this subject
    condition_names = {'scrambled_dt','scrambled_st','unscrambled_dt','unscrambled_st'};
    this_subject_table = all_click_info(which_rows_this_subject,:);

    % Create empty arrays for ERPs
    data_by_masker_onset = [];
    data_by_target_onset = [];
    data_by_button_press = [];

    % Create empty arrays for info for each ERP
    % Will contain subID, trial, and word (if target)
    ERP_info_masker = struct('SubID',{},'Trial',{});
    ERP_info_target = struct('SubID',{},'Trial',{},'Word',{});
    ERP_info_button_press = struct('SubID',{},'Trial',{});

    % Load EEG for this subject
    epochs_filename = join([prepro_folder,strtrim(curr_subject_ID(isubject,:)),'all_epoch.mat'],'');
    this_EEG = load(epochs_filename);
    eeg_struct_name = fieldnames(this_EEG);
    this_EEG = getfield(this_EEG,string(eeg_struct_name(1)));
    these_epochs = this_EEG.data; % 32 channels x Time x 36 trials


    % Define time vector for extracting target ERPs
    eeg_time = this_EEG.times; % in milliseconds
    audio_time = 0:1/44100:12;
    %resampled_audio_time = resample(audio_time,this_EEG.srate,44100);
    resampled_audio_time = -1:1/fs:16;
    resampled_audio_time = resampled_audio_time.*1000;

    % Define time vector for extracting masker ERPs
    stimulus_length = 12; % seconds
    word_length = 0.3; % seconds
    masker_time = 0:word_length:11.7;

    noise_thresh = 100; % 80;

    for itrial = 1:size(this_EEG.data,3)% for each trial (should be 144)
        if mod(40,itrial) == 0 
            disp(itrial)
        end
        icondition = conditions(itrial);
        
        %this_trial_target_onsets = all_target_onsets(itrial).onsets;
        % actually this_trial_target_onsets should be the one that matches
        % the SOUNDFILE, not the trial number. They were not played in that
        % order
        which_soundfile_this_trial = this_subject_table.Soundfile(itrial);
        which_soundfile_this_trial = cell2mat(which_soundfile_this_trial);
        slash_indices = find(which_soundfile_this_trial == '\');
        slash_index = max(slash_indices);
        which_soundfile_this_trial = which_soundfile_this_trial(slash_index + 1:slash_index + 3);
        if contains(which_soundfile_this_trial, '_s') || contains(which_soundfile_this_trial,'_u')
            which_soundfile_this_trial = str2num(which_soundfile_this_trial(1));
        elseif contains(which_soundfile_this_trial,'_')
            which_soundfile_this_trial = str2num(which_soundfile_this_trial(1:2));
        else
            which_soundfile_this_trial = str2num(which_soundfile_this_trial);
        end
        this_trial_target_onsets = all_target_onsets(which_soundfile_this_trial).onsets;

        if length(all_target_onsets(which_soundfile_this_trial).onsets) ~=length(all_target_words(which_soundfile_this_trial).words)
            pause()
        end

        %% ISOLATE BUTTON PRESSES
        % Find this trial button presses
        this_trial_click_times = table2array(this_subject_table(itrial,9:end));
        this_trial_click_times(isnan(this_trial_click_times)) = [];
        for iclick = 1:length(this_trial_click_times) % for each target word onset...
            resampled_search_time = floor(this_trial_click_times(iclick)*1000);
            button_press_delay = 0; % ms 
            [~,start_time] = min(abs(resampled_audio_time - (resampled_search_time + erp_window_start_time + button_press_delay))); %
            [~,end_time] = min(abs(resampled_audio_time - (resampled_search_time + erp_window_end_time)));%


             if end_time - start_time == 1741
                end_time = end_time - 1;
            end

             % Reject epochs with amplitude above +/- 100 uV
            if any(abs(detrend(these_epochs(:,start_time:end_time,itrial))) > noise_thresh,'all')
                %disp('ERP rejected')
                continue
            end

            % Isolate ERP
            this_erp = these_epochs(:,start_time:end_time,itrial);
            data_by_button_press = cat(3, data_by_button_press,this_erp);

            % Append Info
            if ~isempty(ERP_info_button_press)
                ERP_info_button_press.SubID = [ERP_info_button_press.SubID; curr_subject_ID(isubject,:)];
                ERP_info_button_press.Trial = [ERP_info_button_press.Trial, itrial];
            else
                ERP_info_button_press(1).SubID = curr_subject_ID(isubject,:);
                ERP_info_button_press(1).Trial = itrial;
            end



        end

        %% ISOLATE TARGET WORD ONSETS 
        % Within Target Onsets
        
        for ionset = 1:length(this_trial_target_onsets) % for each target word onset...
            resampled_search_time = floor(this_trial_target_onsets(ionset)*1000);
            [~,start_time] = min(abs(resampled_audio_time - (resampled_search_time + erp_window_start_time))); %
            [~,end_time] = min(abs(resampled_audio_time - (resampled_search_time + erp_window_end_time)));%

            %start_time = resampled_search_time + ((erp_window_start_time/1000)*fs);
            %end_time = resampled_search_time + ((erp_window_end_time/1000)*fs);

            %start_time = floor((this_trial_target_onsets(ionset)  + (erp_window_start_time/1000))*fs) + fs;
            %end_time = floor((this_trial_target_onsets(ionset) + (erp_window_end_time/1000))*fs) + fs;
            if end_time - start_time == 1741
                end_time = end_time -1;
            end


            % Reject epochs with amplitude above +/- 100 uV
            if any(abs(detrend(these_epochs(:,start_time:end_time,itrial))) > noise_thresh,'all')
                %disp('ERP rejected')
                continue
            end
             % Store target information in the cell array
            target_info{end+1,1} = subID; % Subject ID
            target_info{end,2} = this_trial_target_onsets(ionset); % Target Onset
            target_info{end,3} = resampled_audio_time(start_time); % Start Time
            target_info{end,4} = resampled_audio_time(end_time); % End Time

            % Isolate ERP

            this_erp = these_epochs(:,start_time:end_time,itrial);
            data_by_target_onset = cat(3,data_by_target_onset,this_erp);

            % Append Info
            if ~isempty(ERP_info_target)
                ERP_info_target.SubID = [ERP_info_target.SubID; curr_subject_ID(isubject,:)];
                ERP_info_target.Trial = [ERP_info_target.Trial, itrial];
                ERP_info_target.Word = [ERP_info_target.Word; all_target_words(which_soundfile_this_trial).words(ionset)];
                ERP_info_target.Condition = [ERP_info_target.Condition, conditions(itrial)];
            else
                ERP_info_target(1).SubID = curr_subject_ID(isubject,:);
                ERP_info_target(1).Trial = itrial;
                ERP_info_target(1).Word = all_target_words(which_soundfile_this_trial).words(ionset);
                ERP_info_target(1).Condition = conditions(itrial);
            end
          
        end

        %% ISOLATE MASKER WORD ONSETS
        % Background Onsets (masker onsets)
        for ionset = 1:length(masker_time)

            resampled_search_time = (masker_time(ionset))*1000;
            [~,start_time] = min(abs(resampled_audio_time - (resampled_search_time + erp_window_start_time))); %
            [~,end_time] = min(abs(resampled_audio_time - (resampled_search_time + erp_window_end_time)));%

            %resampled_search_index = (masker_time(ionset) + (1*fs) - (0.1*fs));
            %start_time = round(resampled_search_index);
            %end_time = round(start_time + floor(((erp_window_end_time - erp_window_start_time)/1000)*fs));
            if end_time - start_time == 1741
                end_time = end_time -1;
            end

            % Reject epochs with amplitude above +/- 100 uV
            if any(abs(detrend(these_epochs(:,start_time:end_time,itrial))) > noise_thresh,'all')
                %disp('ERP rejected')
                continue
                %add variance here
            end

            this_erp = these_epochs(:,start_time:end_time,itrial);
            data_by_masker_onset = cat(3, data_by_masker_onset,this_erp);

            % Append Info
            if ~isempty(ERP_info_masker)
                ERP_info_masker.SubID = [ERP_info_masker.SubID; curr_subject_ID(isubject,:)];
                ERP_info_masker.Trial = [ERP_info_masker.Trial, itrial];
                ERP_info_masker.Condition = [ERP_info_masker.Condition, conditions(itrial)];
            else
                ERP_info_masker(1).SubID = curr_subject_ID(isubject,:);
                ERP_info_masker(1).Trial = itrial;
                ERP_info_masker(1).Condition = conditions(itrial);
            end

        end

    end

    %% Concatenate and baseline within each channel for this subject
    % Baseline to the mean voltage during the baseline period over ALL
    % trials

    % Masker and target will be baselined separately


    single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(data_by_target_onset,2));
    [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
    [~,baseline_end_index] = min(abs(single_onset_time - 0));

    single_onset_time_buttonpress = linspace(erp_window_start_time + button_press_delay,erp_window_end_time,size(data_by_target_onset,2));
    [~,baseline_start_index_buttonpress] = min(abs(single_onset_time_buttonpress - erp_window_start_time));
    [~,baseline_end_index_buttonpress] = min(abs(single_onset_time_buttonpress - 0));

    data_by_button_press_baselined = nan(size(data_by_button_press));
    data_by_target_onset_baselined = nan(size(data_by_target_onset));
    data_by_masker_onset_baselined = nan(size(data_by_masker_onset));
    for ichannel = 1:32
        data_by_button_press_baselined(ichannel,:,:) = data_by_button_press(ichannel,:,:) - mean(data_by_button_press(ichannel,baseline_start_index_buttonpress:baseline_end_index_buttonpress,:),'all');
        data_by_target_onset_baselined(ichannel,:,:) = data_by_target_onset(ichannel,:,:) - mean(data_by_target_onset(ichannel,baseline_start_index:baseline_end_index,:),'all');
        data_by_masker_onset_baselined(ichannel,:,:) = data_by_masker_onset(ichannel,:,:) - mean(data_by_masker_onset(ichannel,baseline_start_index:baseline_end_index,:),'all');
        
    end

    % Save to larget array with all subjects in it
    % condition 1 = scrambled diff talker
    % condition 2 = scrambled same talker
    % condition 3 = unscrambled diff talker
    % condition 4 = unscrambled same talker

    all_data_button_press(isubject,:,:) = squeeze(mean(data_by_button_press_baselined,3));
    all_data_target(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined,3));
    all_data_masker(isubject,:,:) = squeeze(mean(data_by_masker_onset_baselined,3));

    %all_info_button_press(isubject).info = ERP_info_button_press;
    %all_info_target(isubject).info = ERP_info_target;
    %all_info_masker(isubject).info = ERP_info_masker;

    color_words = {'red','green','blue','white'};
    all_scrambled_by_color_onset(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined(:,:,logical(ismember(ERP_info_target(:).Word,color_words)'.*ismember(ERP_info_target(:).Condition,[1,2]))),3));
    all_scrambled_by_object_onset(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined(:,:,logical(~ismember(ERP_info_target(:).Word,color_words)'.*ismember(ERP_info_target(:).Condition,[1,2]))),3));
    all_scrambled_by_masker_onset(isubject,:,:) = squeeze(mean(data_by_masker_onset_baselined(:,:,logical(ismember(ERP_info_masker(:).Condition,[1,2]))),3));
    
    all_unscrambled_by_color_onset(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined(:,:,logical(ismember(ERP_info_target(:).Word,color_words)'.*ismember(ERP_info_target(:).Condition,[3,4]))),3));
    all_unscrambled_by_object_onset(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined(:,:,logical(~ismember(ERP_info_target(:).Word,color_words)'.*ismember(ERP_info_target(:).Condition,[3,4]))),3));
    all_unscrambled_by_masker_onset(isubject,:,:) = squeeze(mean(data_by_masker_onset_baselined(:,:,logical(ismember(ERP_info_masker(:).Condition,[3,4]))),3));

    % Plot for each subject
    figure;
    subplot_counter = subplot_counter + 1;
    subplot(1,3,1)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_color_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_color_onset(isubject,frontocentral_channels,:),2)),'-b');
    if isubject == 1
        title('Target Color Word')
    end
    %legend({'Scrambled','Unscrambled'})
    ylim([-8,8])

    subplot_counter = subplot_counter + 1;
    subplot(1,3,2)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_object_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_object_onset(isubject,frontocentral_channels,:),2)),'-b');
    if isubject == 1
        title('Target Object Word')
    end
    %legend({'Scrambled','Unscrambled'})
    ylim([-8,8])

    subplot_counter = subplot_counter + 1;
    subplot(1,3,3)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_masker_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_masker_onset(isubject,frontocentral_channels,:),2)),'-b');
    if isubject == 1
        title('Masker Word')
    end
    %legend({'Scrambled','Unscrambled'})
    ylim([-8,8])
    sgtitle(subID)

%    % Plot whole trial EEG
%     figure(2);
%     subplot(size(curr_subject_ID,1),1,isubject)
%     plot(eeg_time,mean(these_epochs(frontocentral_channels,:,ismember(conditions,[1,2])),[1,3]))
%     hold on;plot(eeg_time,mean(these_epochs(frontocentral_channels,:,ismember(conditions,[3,4])),[1,3]))
%     %legend({'Scrambled','Unscrambled'})
%     if isubject == size(curr_subject_ID,1)
%         xlabel('Time (ms)','FontSize',18)
%     elseif isubject == round(size(curr_subject_ID,1)/2)
%         ylabel('Voltage (mV)','FontSize',18)
%     end
% 
%     % Plot button press
%     figure(3);
%     subplot(size(curr_subject_ID,1),1,isubject)
%     plot(single_onset_time,squeeze(mean(all_data_button_press(isubject,1,:,:),[2,4])))
%     if isubject == size(curr_subject_ID,1)
%         xlabel('Time (ms)','FontSize',18)
%     elseif isubject == round(size(curr_subject_ID,1)/2)
%         ylabel('Voltage (mV)','FontSize',18)
%     end
%     title('Button Press at Cz')

    % button press topoplot
%     figure;
%     topoplot_indices = round(0:0.1*fs:(((erp_window_end_time - erp_window_start_time)/1000)*fs));
% topoplot_indices(1) = 1;
% topoplot_times = -100:50:750;
% 
% iplot = 1;
% itime = 1;
% for itopo = topoplot_indices
%     subplot(1,length(topoplot_indices)+ 1,iplot);
%     this_data = squeeze(mean(all_data_button_this_subject(:,itopo,:),[2,3]));
%     topoplot(this_data,this_EEG.chanlocs,'maplimits',[-10, 5]);
%     title([num2str(topoplot_times(itime)),' ms'])
%     iplot = iplot + 1;
%     itime = itime + 1;
% end
% colorbar


%% SAVE INFO FOR THIS SUBBY
save(append('Results_Subject_',string(curr_subject_ID(isubject,:)),'.mat'),'data_by_masker_onset_baselined','data_by_target_onset_baselined','data_by_button_press_baselined','ERP_info_button_press','ERP_info_masker','ERP_info_target','-v7.3')

end

