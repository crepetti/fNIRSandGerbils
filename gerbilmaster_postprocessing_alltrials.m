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
else
    dir = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\';
    dir_fnirsandgerbils = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';
end

curr_subject_ID =  char('7023','7024');%char('7002','7004','7007','7008','7010','7023','7024','7033','7035','7036','7038','7039','7040');

% Set analysis parameters
erp_window_start_time = -100; % 100 ms before onset of word
erp_window_end_time = 750; % 750 ms after onset of word
nsubjects = size(curr_subject_ID,1);
word_length = 0.3;
num_tot_trials = 144; % look into this
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
fs = 2048;

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
    % Scrambled Same Talker
    scrambled_st_by_target_red_onset = [];
    scrambled_st_by_target_green_onset = [];
    scrambled_st_by_target_blue_onset = [];
    scrambled_st_by_target_white_onset = [];
    scrambled_st_by_target_color_onset = [];
    scrambled_st_by_target_object_onset = [];
    scrambled_st_by_masker_onset = [];

    % Unscrambled Same Talker
    unscrambled_st_by_target_red_onset = [];
    unscrambled_st_by_target_green_onset = [];
    unscrambled_st_by_target_blue_onset = [];
    unscrambled_st_by_target_white_onset =[];
    unscrambled_st_by_target_color_onset = [];
    unscrambled_st_by_target_object_onset = [];
    unscrambled_st_by_masker_onset = [];

    % Scrambled Different Talker
    scrambled_dt_by_target_red_onset = [];
    scrambled_dt_by_target_green_onset = [];
    scrambled_dt_by_target_blue_onset = [];
    scrambled_dt_by_target_white_onset = [];
    scrambled_dt_by_target_color_onset = [];
    scrambled_dt_by_target_object_onset = [];
    scrambled_dt_by_masker_onset = [];

    % Unscrambled Different Talker
    unscrambled_dt_by_target_red_onset = [];
    unscrambled_dt_by_target_green_onset = [];
    unscrambled_dt_by_target_blue_onset = [];
    unscrambled_dt_by_target_white_onset = [];
    unscrambled_dt_by_target_color_onset = [];
    unscrambled_dt_by_target_object_onset = [];
    unscrambled_dt_by_masker_onset = [];

    all_data_target = [];
    all_data_masker = [];
    all_data_button_this_subject = [];

    % Load EEG for this subject
    epochs_filename = join(['D:/prepro_epoched_data/',strtrim(curr_subject_ID(isubject,:)),'all_epoch.mat'],'');
    this_EEG = load(epochs_filename);
    eeg_struct_name = fieldnames(this_EEG);
    this_EEG = getfield(this_EEG,string(eeg_struct_name(1)));
    these_epochs = this_EEG.data; % 32 channels x Time x 36 trials


    % Define time vector for extracting target ERPs
    eeg_time = this_EEG.times; % in milliseconds
    audio_time = linspace(eeg_time(1),eeg_time(end),((eeg_time(end) - eeg_time(1))/1000)*44100);
    resampled_audio_time = resample(audio_time,this_EEG.srate,44100);

    % Define time vector for extracting masker ERPs
    stimulus_length = 12; % seconds
    word_length = 0.3; % seconds
    masker_time = 0:word_length:11.7;

    noise_thresh = 80;

    for itrial = 1:size(this_EEG.data,3)% for each trial (should be 144)

        data_by_masker_onset = [];
        data_by_red_onset = [];
        data_by_green_onset = [];
        data_by_blue_onset = [];
        data_by_white_onset  = [];
        data_by_color_onset = [];
        data_by_object_onset = [];
        data_by_button_press = [];

        icondition = conditions(itrial);
        this_trial_target_onsets = all_target_onsets(itrial).onsets;

        if length(all_target_onsets(itrial).onsets) ~=length(all_target_words(itrial).words)
            pause()
        end

        % BUTTON PRESSES
        % Find this trial button presses
        this_trial_click_times = table2array(this_subject_table(itrial,9:end));
        this_trial_click_times(isnan(this_trial_click_times)) = [];
        for iclick = 1:length(this_trial_click_times) % for each target word onset...
            resampled_search_time = floor(this_trial_click_times(iclick)*1000);
            [~,start_time] = min(abs(resampled_audio_time - (resampled_search_time + erp_window_start_time))); %
            [~,end_time] = min(abs(resampled_audio_time - (resampled_search_time + erp_window_end_time)));%

             if end_time - start_time == 1741
                end_time = end_time -1;
            end

             % Reject epochs with amplitude above +/- 100 uV
            if any(abs(detrend(these_epochs(:,start_time:end_time,itrial))) > noise_thresh,'all')
                disp('ERP rejected')
                continue
            end

            % Isolate ERP

            this_erp = these_epochs(:,start_time:end_time,itrial);
            single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(this_erp,2));
            [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
            [~,baseline_end_index] = min(abs(single_onset_time - 0));
            this_erp = this_erp - mean(this_erp(:,baseline_start_index:baseline_end_index),2);

            data_by_button_press = cat(3, data_by_button_press,this_erp);


        end

        % TARGET WORD ONSETS
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
                disp('ERP rejected')
                continue
            end

            % Isolate ERP

            this_erp = these_epochs(:,start_time:end_time,itrial);
            single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(this_erp,2));
            [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
            [~,baseline_end_index] = min(abs(single_onset_time - 0));
            this_erp = this_erp - mean(this_erp(:,baseline_start_index:baseline_end_index),2);

            % Put it into appropriate matrix
            if all_target_words(itrial).words(ionset) == 'red'
                data_by_red_onset = cat(3, data_by_red_onset,this_erp);
                data_by_color_onset = cat(3, data_by_color_onset ,this_erp);

            elseif all_target_words(itrial).words(ionset) == 'green'
                data_by_green_onset = cat(3, data_by_green_onset,this_erp);
                data_by_color_onset= cat(3, data_by_color_onset ,this_erp);

            elseif all_target_words(itrial).words(ionset) == 'white'
                data_by_white_onset = cat(3, data_by_white_onset,this_erp);
                data_by_color_onset= cat(3, data_by_color_onset ,this_erp);

            elseif all_target_words(itrial).words(ionset) == 'blue'
                data_by_blue_onset= cat(3, data_by_blue_onset,this_erp);
                data_by_color_onset= cat(3, data_by_color_onset,this_erp);

            else
                data_by_object_onset = cat(3, data_by_object_onset,this_erp);
            end
        end

        % MASKER WORD ONSETS
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
                disp('ERP rejected')
                continue
                %add variance here
            end

            this_erp = these_epochs(:,start_time:end_time,itrial);
            [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
            [~,baseline_end_index] = min(abs(single_onset_time - 0));
            this_erp = this_erp - mean(this_erp(:,baseline_start_index:baseline_end_index),2);
            data_by_masker_onset = cat(3, data_by_masker_onset,this_erp);
        end


        % save to appropriate array
        if icondition == 1
            %scrambled_dt_by_target_red_onset = cat(3,scrambled_dt_by_target_red_onset, data_by_red_onset);
            %scrambled_dt_by_target_green_onset = cat(3,scrambled_dt_by_target_green_onset,data_by_green_onset);
            %scrambled_dt_by_target_blue_onset = cat(3,scrambled_dt_by_target_blue_onset,data_by_blue_onset);
            %scrambled_dt_by_target_white_onset = cat(3,scrambled_dt_by_target_white_onset,data_by_white_onset);
            scrambled_dt_by_target_color_onset = cat(3,scrambled_dt_by_target_color_onset,data_by_color_onset);
            scrambled_dt_by_target_object_onset = cat(3,scrambled_dt_by_target_object_onset,data_by_object_onset);
            scrambled_dt_by_masker_onset = cat(3,scrambled_dt_by_masker_onset,data_by_masker_onset);
        elseif icondition == 2
            %scrambled_st_by_target_red_onset = cat(3,scrambled_st_by_target_red_onset, data_by_red_onset);
            %scrambled_st_by_target_green_onset = cat(3,scrambled_st_by_target_green_onset,data_by_green_onset);
            %scrambled_st_by_target_blue_onset = cat(3,scrambled_st_by_target_blue_onset,data_by_blue_onset);
            %scrambled_st_by_target_white_onset = cat(3,scrambled_st_by_target_white_onset,data_by_white_onset);
            scrambled_st_by_target_color_onset = cat(3,scrambled_st_by_target_color_onset,data_by_color_onset);
            scrambled_st_by_target_object_onset = cat(3,scrambled_st_by_target_object_onset,data_by_object_onset);
            scrambled_st_by_masker_onset = cat(3,scrambled_st_by_masker_onset,data_by_masker_onset);
        elseif icondition == 3
            %unscrambled_dt_by_target_red_onset = cat(3,unscrambled_dt_by_target_red_onset, data_by_red_onset);
            %unscrambled_dt_by_target_green_onset = cat(3,unscrambled_dt_by_target_green_onset,data_by_green_onset);
            %unscrambled_dt_by_target_blue_onset = cat(3,unscrambled_dt_by_target_blue_onset,data_by_blue_onset);
            %unscrambled_dt_by_target_white_onset = cat(3,unscrambled_dt_by_target_white_onset,data_by_white_onset);
            unscrambled_dt_by_target_color_onset = cat(3,unscrambled_dt_by_target_color_onset,data_by_color_onset);
            unscrambled_dt_by_target_object_onset = cat(3,unscrambled_dt_by_target_object_onset,data_by_object_onset);
            unscrambled_dt_by_masker_onset = cat(3,unscrambled_dt_by_masker_onset,data_by_masker_onset);
        elseif icondition == 4
            %unscrambled_st_by_target_red_onset = cat(3,unscrambled_st_by_target_red_onset,data_by_red_onset);
            %unscrambled_st_by_target_green_onset = cat(3,unscrambled_st_by_target_green_onset,data_by_green_onset);
            %unscrambled_st_by_target_blue_onset = cat(3,unscrambled_st_by_target_blue_onset,data_by_blue_onset);
            %unscrambled_st_by_target_white_onset = cat(3,unscrambled_st_by_target_white_onset,data_by_white_onset);
            unscrambled_st_by_target_color_onset = cat(3,unscrambled_st_by_target_color_onset,data_by_color_onset);
            unscrambled_st_by_target_object_onset = cat(3,unscrambled_st_by_target_object_onset,data_by_object_onset);
            unscrambled_st_by_masker_onset = cat(3,unscrambled_st_by_masker_onset,data_by_masker_onset);
        end

        all_data_button_this_subject = cat(3,all_data_button_this_subject,data_by_button_press);

    end

    % Concatenate and baseline

    all_data_target_this_subject = cat(3,scrambled_st_by_target_color_onset,scrambled_dt_by_target_color_onset,...
        scrambled_st_by_target_object_onset,scrambled_dt_by_target_object_onset,...
        unscrambled_st_by_target_color_onset,unscrambled_dt_by_target_color_onset,...
        unscrambled_st_by_target_object_onset,unscrambled_dt_by_target_object_onset); % include masker or no??

    all_data_masker_this_subject = cat(3,scrambled_st_by_masker_onset,scrambled_dt_by_masker_onset,...
        unscrambled_st_by_masker_onset,unscrambled_dt_by_masker_onset); % include masker or no??


    for ichannel = 1:32

        all_scrambled_by_color_onset(isubject,ichannel,:) = squeeze(mean(cat(3,scrambled_st_by_target_color_onset(ichannel,:,:),scrambled_dt_by_target_color_onset(ichannel,:,:)),3));
        all_scrambled_by_object_onset(isubject,ichannel,:)  = squeeze(mean(cat(3,scrambled_st_by_target_object_onset(ichannel,:,:),scrambled_dt_by_target_object_onset(ichannel,:,:)),3));
        all_scrambled_by_masker_onset(isubject,ichannel,:) = squeeze(mean(cat(3,scrambled_st_by_masker_onset(ichannel,:,:),scrambled_dt_by_masker_onset(ichannel,:,:)),3));

        all_unscrambled_by_color_onset(isubject,ichannel,:) = squeeze(mean(cat(3,unscrambled_st_by_target_color_onset(ichannel,:,:),unscrambled_dt_by_target_color_onset(ichannel,:,:) ),3));
        all_unscrambled_by_object_onset(isubject,ichannel,:) = squeeze(mean(cat(3,unscrambled_st_by_target_object_onset(ichannel,:,:) ,unscrambled_dt_by_target_object_onset(ichannel,:,:) ),3));
        all_unscrambled_by_masker_onset(isubject,ichannel,:)  = squeeze(mean(cat(3,unscrambled_st_by_masker_onset(ichannel,:,:) ,unscrambled_dt_by_masker_onset(ichannel,:,:)),3));
    end


    all_data_target(isubject,:,:,:) = cat(4,all_scrambled_by_color_onset(isubject,:,:,:),all_scrambled_by_object_onset(isubject,:,:,:),all_unscrambled_by_color_onset(isubject,:,:,:),all_unscrambled_by_object_onset(isubject,:,:,:));
    all_data_masker(isubject,:,:,:) = cat(4,all_scrambled_by_masker_onset(isubject,:,:,:),all_unscrambled_by_masker_onset(isubject,:,:,:));







    % Plot for each subject
    figure;

    subplot(1,3,1)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_color_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_color_onset(isubject,frontocentral_channels,:),2)),'-b');
    title('Target Color Word')
    legend({'Scrambled','Unscrambled'})
    ylim([-3,10])

    subplot(1,3,2)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_object_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_object_onset(isubject,frontocentral_channels,:),2)),'-b');
    title('Target Object Word')
    legend({'Scrambled','Unscrambled'})
    ylim([-3,10])

    subplot(1,3,3)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_masker_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_masker_onset(isubject,frontocentral_channels,:),2)),'-b');
    title('Masker Word')
    legend({'Scrambled','Unscrambled'})
    ylim([-3,10])
    sgtitle(subID)

    % Plot whole trial EEG
    figure;plot(eeg_time,mean(these_epochs(frontocentral_channels,:,ismember(conditions,[1,2])),[1,3]))
    hold on;plot(eeg_time,mean(these_epochs(frontocentral_channels,:,ismember(conditions,[3,4])),[1,3]))
    legend({'Scrambled','Unscrambled'})
     xlabel('Time (ms)','FontSize',18)
    ylabel('Voltage (mV)','FontSize',18)

    % Plot button press
    figure;plot(single_onset_time,squeeze(mean(all_data_button_this_subject(1,:,:),[1,3])))
    xlabel('Time (ms)','FontSize',18)
    ylabel('Voltage (mV)','FontSize',18)
    title('Button Press at Cz')

    % button press topoplot
    figure;
    topoplot_indices = round(0:0.1*fs:(((erp_window_end_time - erp_window_start_time)/1000)*fs));
topoplot_indices(1) = 1;
topoplot_times = -100:50:750;

iplot = 1;
itime = 1;
for itopo = topoplot_indices
    subplot(1,length(topoplot_indices)+ 1,iplot);
    this_data = squeeze(mean(all_data_button_this_subject(:,itopo,:),[2,3]));
    topoplot(this_data,this_EEG.chanlocs,'maplimits',[-10, 5]);
    title([num2str(topoplot_times(itime)),' ms'])
    iplot = iplot + 1;
    itime = itime + 1;
end
colorbar

end
