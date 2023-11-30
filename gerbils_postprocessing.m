%% POSTPROCESSING INDIVIDUAL ERPs and WORD ONSETS
%% Primary Author: Benjamin Richardson
%% Secondary Author: Emaya Anand
%% NEED ICA_DONE FILES
% script to calculate ERPs for scrambled and unscrambled word onsets in
% fNIRS and Gerbils

%% NOTES ON REJECTION
%Any processed epochs with amplitudes exceeding ±100 μV were rejected from further processing.
% Datasets with 3 or fewer non-adjacent, erratic channels
% (determined by visual inspection of ICA topographies and raw signal traces)
% underwent interpolation (Delorme & Makeig, 2004). A final visual inspection removed any remaining contaminated trials.

dir = 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\';
dir_fnirsandgerbils = 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';
curr_subject_ID = char('7006','7007','7008','7009','7010');
scrambled_by_target_onset = [];
unscrambled_by_target_onset = [];
unscrambled_by_masker_onset = [];
erp_window_start_time = -100; % 100 ms before onset of word
erp_window_end_time = 750; % 500 ms after onset of word
nsubjects = size(curr_subject_ID,1);
num_tot_trials = 144; % look into this
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];


%Load in pre-processed datasets

% Define subject information (which BDFs to load)

% for isubject = 1:nsubjects
% subID = curr_subject_ID(isubject,:);
for isubject = 1:size(curr_subject_ID,1)
    subID = curr_subject_ID(isubject,:);
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    if isfile(cat(2,dir,'\prepro_epoched_data\',subID,'_ICAcomponentsremoved.fdt'))
        EEG = pop_loadset('filename',cat(2,subID,'_ICAcomponentsremoved.set'),'filepath',[dir,'\prepro_epoched_data']);
    else
        EEG = pop_loadset('filename',cat(2,subID,'_ICAdone.set'),'filepath',[dir,'\prepro_epoched_data']);
    end
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off');
    EEG = eeg_checkset( EEG );
    fs = EEG.srate;
    tube_delay = fs/44100;
    shifting_latencies = mat2cell( cell2mat({EEG.event.latency}') + (tube_delay * fs) , length(EEG.event),1);
    shifting_latencies = shifting_latencies{:};
    for i = 1:numel(shifting_latencies)
        EEG.event(i).latency = shifting_latencies(i);
    end
    EEG = eeg_checkset( EEG );


    %% Epoching
    %     EEG_scrambled_st = pop_epoch( EEG, {'45055'}, [-1  16], 'newname', [subID, 'scrambled same talker epochs'], 'epochinfo', 'yes');
    %     EEG_unscrambled_st = pop_epoch( EEG, {'36351'}, [-1  16], 'newname', [subID, 'unscrambled same talker epochs'], 'epochinfo', 'yes');
    %     EEG_scrambled_dt = pop_epoch( EEG, {'19711'}, [-1  16], 'newname', [subID, 'scrambled diff talker epochs'], 'epochinfo', 'yes');
    %     EEG_unscrambled_dt = pop_epoch( EEG, {'11007'}, [-1  16], 'newname', [subID, 'unscrambled diff talker epochs'], 'epochinfo', 'yes');
    if all(subID == '7006')
        EEG_all = pop_epoch( EEG, {'18687' , '35327', '43519', '10495'}, [-1  16], 'newname', [subID, 'all epochs'], 'epochinfo', 'yes');
    else
        EEG_all = pop_epoch( EEG, {'18687' , '35327', '44031', '11007'}, [-1  16], 'newname', [subID, 'all epochs'], 'epochinfo', 'yes');
    end
    % Find tOnset to isolate ERPs: loading in all_word_order & tOnset -->
    % THIS IS BELOW ALREADY
    % words_filename = [dir, subID, '_alltrialwords.mat'];
    % load(words_filename);

    % isolate ERPs
    all_epochs = EEG_all.data; % num channels x num time points x num trials
    % scrambled_st_epochs= EEG_scrambled_st.data; % subject x num channels x num time points x num trials
    % unscrambled_st_epochs= EEG_unscrambled_st.data; % subject x num channels x num time points x num trials
    % scrambled_dt_epochs= EEG_scrambled_dt.data; % subject x num channels x num time points x num trials
    % unscrambled_dt_epochs= EEG_unscrambled_dt.data; % subject x num channels x num time points x num trials
    scrambled_time = EEG_all.times; % in milliseconds
    unscrambled_time = EEG_all.times; % in milliseconds


    % Load click info to find condition


    % Find target word onset times
    stim_info_filename = [dir,'stim\s_',strtrim(curr_subject_ID(isubject,:)),'\',strtrim(curr_subject_ID(isubject,:)),'_alltrialwords.mat'];
    load(stim_info_filename); % loads all_word_order (array of all words) and tOnset (the onset times within each trial)
    tOnset(end) = [];
    %target_word_indices = all_word_order == 'red' | all_word_order == 'white' | all_word_order == 'blue' | all_word_order == 'green';

    %% Isolate target word onset ERPs for both conditions
    all_click_info = readtable(dir_fnirsandgerbils,'FileType','spreadsheet','Format','auto');
    which_rows_this_subject = find(all_click_info.S == string(curr_subject_ID(isubject,:))); % find the rows in the spreadsheet which belong to this subject
    conditions = all_click_info.Condition(which_rows_this_subject); % conditions by trial for this subject

    scrambled_st_by_target_red_onset = [];
    scrambled_st_by_target_green_onset = [];
    scrambled_st_by_target_blue_onset = [];
    scrambled_st_by_target_white_onset = [];
    scrambled_st_by_target_object_onset = [];

    unscrambled_st_by_target_red_onset = [];
    unscrambled_st_by_target_green_onset = [];
    unscrambled_st_by_target_blue_onset = [];
    unscrambled_st_by_target_white_onset =[];
    unscrambled_st_by_target_object_onset = [];

    scrambled_dt_by_target_red_onset = [];
    scrambled_dt_by_target_green_onset = [];
    scrambled_dt_by_target_blue_onset = [];
    scrambled_dt_by_target_white_onset = [];
    scrambled_dt_by_target_object_onset = [];

    unscrambled_dt_by_target_red_onset = [];
    unscrambled_dt_by_target_green_onset = [];
    unscrambled_dt_by_target_blue_onset = [];
    unscrambled_dt_by_target_white_onset = [];
    unscrambled_dt_by_target_object_onset = [];

    scrambled_dt_by_masker_onset = [];
    scrambled_st_by_masker_onset = [];
    unscrambled_st_by_masker_onset = [];
    unscrambled_dt_by_masker_onset = [];
    icount_scrambled = 1;
    icount_unscrambled = 1;

    for itrial = 1:size(all_epochs,3) % for each trial...
        % find the condition
        curr_condition = conditions(itrial);
        % find onsets of target words in this trial
        this_trial_target_onsets = all_target_onsets(itrial).onsets;

        %% Background Onsets (masker onsets)
        for ionset = 1:length(tOnset)
            resampled_search_time = (tOnset(ionset))/(44100/fs);
            [~,start_time] = min(abs(scrambled_time - ((resampled_search_time*1000)+erp_window_start_time) ) ); % ...find 100 ms before the time it starts (indexing where it's located in scrambled_time)
            end_time = start_time + floor(((erp_window_end_time - erp_window_start_time)/1000)*256);
%             [~,end_time] = min(abs(scrambled_time - ((resampled_search_time*1000)+erp_window_end_time) )); % ...find the time it ends (500 ms later)
            % correct if number of samples is off
%             if ~isempty([scrambled_st_by_masker_onset,scrambled_dt_by_masker_onset,unscrambled_dt_by_masker_onset,unscrambled_st_by_masker_onset]) && (start_time - end_time) ~= size([scrambled_st_by_masker_onset,scrambled_dt_by_masker_onset,unscrambled_dt_by_masker_onset,unscrambled_st_by_masker_onset],2)
%                 end_time = start_time + size([scrambled_st_by_masker_onset,scrambled_dt_by_masker_onset,unscrambled_dt_by_masker_onset,unscrambled_st_by_masker_onset],2) - 1;
%             end
            if curr_condition == 1 % scrambled diff talker
                scrambled_dt_by_masker_onset= cat(3, scrambled_dt_by_masker_onset,all_epochs(:,start_time:end_time,itrial));
            elseif curr_condition == 2
                scrambled_st_by_masker_onset= cat(3, scrambled_st_by_masker_onset,all_epochs(:,start_time:end_time,itrial));
            elseif curr_condition == 3
                unscrambled_dt_by_masker_onset= cat(3, unscrambled_dt_by_masker_onset,all_epochs(:,start_time:end_time,itrial));
            elseif curr_condition == 4
                unscrambled_st_by_masker_onset= cat(3, unscrambled_st_by_masker_onset,all_epochs(:,start_time:end_time,itrial));
            end
        end

        %% Within Target
        for ionset = 1:length(this_trial_target_onsets) % for each target word onset...
            resampled_search_time = (this_trial_target_onsets(ionset))/(44100/fs);
            [~,start_time] = min(abs(scrambled_time - ((resampled_search_time*1000)+erp_window_start_time) ) ); % ...find 100 ms before the time it starts (indexing where it's located in scrambled_time)
            end_time = start_time + floor(((erp_window_end_time - erp_window_start_time)/1000)*256);
%             if end_time - start_time == 154
%                 end_time = end_time - 1;
%             end
            % start_time = (this_trial_target_onsets(ionset)*1000)+ erp_window_start_time ; % ...find 100 ms before the time it starts
            % end_time] = (this_trial_target_onsets(ionset)*1000)+ erp_window_end_time; % ...find the time it ends (500 ms later)

            % condition 1 = scrambled diff talker
            % condition 2 = scrambled same talker
            % condition 3 = unscrambled diff talker
            % condition 4 = unscrambled same talker

            % Reject epochs with amplitude above +/1 100 uV
            if any(abs(detrend(all_epochs(frontocentral_channels,start_time:end_time,itrial))) > 30,'all')
                continue
            end

            % Isolate ERP
            if curr_condition == 1 % scrambled diff talker
                if all_target_words(itrial).words(ionset) == 'red'
                    scrambled_dt_by_target_red_onset= cat(3, scrambled_dt_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));
                    scrambled_dt_by_target_color_onset= cat(3, scrambled_dt_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'green'
                    scrambled_dt_by_target_green_onset= cat(3, scrambled_dt_by_target_green_onset,all_epochs(:,start_time:end_time,itrial));
                    scrambled_dt_by_target_color_onset= cat(3, scrambled_dt_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'white'
                    scrambled_dt_by_target_white_onset= cat(3, scrambled_dt_by_target_white_onset,all_epochs(:,start_time:end_time,itrial));
                    scrambled_dt_by_target_color_onset= cat(3, scrambled_dt_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'blue'
                    scrambled_dt_by_target_blue_onset= cat(3, scrambled_dt_by_target_blue_onset,all_epochs(:,start_time:end_time,itrial));
                    scrambled_dt_by_target_color_onset= cat(3, scrambled_dt_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                else
                    scrambled_dt_by_target_object_onset= cat(3, scrambled_dt_by_target_object_onset,all_epochs(:,start_time:end_time,itrial));
                end
                % scrambled_by_target_onset(icount_scrambled,:,:) = all_epochs(:,start_time:end_time,itrial);
                % scrambled_by_target_onset(isubject,icount_scrambled,:,:) = all_epochs(:,start_time:end_time,itrial);

                %icount_scrambled = icount_scrambled + 1;
            elseif curr_condition == 2 % scrambled same talker
                if all_target_words(itrial).words(ionset) == 'red'
                    scrambled_st_by_target_red_onset= cat(3, scrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));
                    scrambled_st_by_target_color_onset= cat(3, scrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));
                elseif all_target_words(itrial).words(ionset) == 'green'
                    scrambled_st_by_target_green_onset= cat(3, scrambled_st_by_target_green_onset,all_epochs(:,start_time:end_time,itrial));
                    scrambled_st_by_target_color_onset= cat(3, scrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'white'
                    scrambled_st_by_target_white_onset= cat(3, scrambled_st_by_target_white_onset,all_epochs(:,start_time:end_time,itrial));
                    scrambled_st_by_target_color_onset= cat(3, scrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'blue'
                    scrambled_st_by_target_blue_onset= cat(3, scrambled_st_by_target_blue_onset,all_epochs(:,start_time:end_time,itrial));
                    scrambled_st_by_target_color_onset= cat(3, scrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                else
                    scrambled_st_by_target_object_onset= cat(3, scrambled_st_by_target_object_onset,all_epochs(:,start_time:end_time,itrial));

                end

            elseif curr_condition == 3 % unscrambled diff talker
                if all_target_words(itrial).words(ionset) == 'red'
                    unscrambled_dt_by_target_red_onset= cat(3, unscrambled_dt_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));
                    unscrambled_dt_by_target_color_onset = cat(3, unscrambled_dt_by_target_blue_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'green'
                    unscrambled_dt_by_target_green_onset= cat(3, unscrambled_dt_by_target_green_onset,all_epochs(:,start_time:end_time,itrial));
                    unscrambled_dt_by_target_color_onset = cat(3, unscrambled_dt_by_target_blue_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'white'
                    unscrambled_dt_by_target_white_onset= cat(3, unscrambled_dt_by_target_white_onset,all_epochs(:,start_time:end_time,itrial));
                    unscrambled_dt_by_target_color_onset = cat(3, unscrambled_dt_by_target_blue_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'blue'
                    unscrambled_dt_by_target_blue_onset = cat(3, unscrambled_dt_by_target_blue_onset,all_epochs(:,start_time:end_time,itrial));
                    unscrambled_dt_by_target_color_onset = cat(3, unscrambled_dt_by_target_blue_onset,all_epochs(:,start_time:end_time,itrial));
                else
                    unscrambled_dt_by_target_object_onset= cat(3, unscrambled_dt_by_target_object_onset,all_epochs(:,start_time:end_time,itrial));

                end

            elseif curr_condition == 4 % unscrambled same talker
                if all_target_words(itrial).words(ionset) == 'red'
                    unscrambled_st_by_target_red_onset= cat(3, unscrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));
                    unscrambled_st_by_target_color_onset= cat(3, unscrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));
                elseif all_target_words(itrial).words(ionset) == 'green'
                    unscrambled_st_by_target_green_onset= cat(3, unscrambled_st_by_target_green_onset,all_epochs(:,start_time:end_time,itrial));
                    unscrambled_st_by_target_color_onset= cat(3, unscrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'white'
                    unscrambled_st_by_target_white_onset= cat(3, unscrambled_st_by_target_white_onset,all_epochs(:,start_time:end_time,itrial));
                    unscrambled_st_by_target_color_onset= cat(3, unscrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                elseif all_target_words(itrial).words(ionset) == 'blue'
                    unscrambled_st_by_target_blue_onset= cat(3, unscrambled_st_by_target_blue_onset,all_epochs(:,start_time:end_time,itrial));
                    unscrambled_st_by_target_color_onset= cat(3, unscrambled_st_by_target_red_onset,all_epochs(:,start_time:end_time,itrial));

                else
                    unscrambled_st_by_target_object_onset= cat(3, unscrambled_st_by_target_object_onset,all_epochs(:,start_time:end_time,itrial));

                end

            end
        end
    end
    % Detrending
    for k = 1:size(scrambled_st_by_target_red_onset,3)
        scrambled_st_by_target_red_onset(:,:,k) = detrend(scrambled_st_by_target_red_onset(:,:,k)')';
    end

    for k = 1:size(scrambled_st_by_target_green_onset,3)
        scrambled_st_by_target_green_onset(:,:,k) =  detrend(scrambled_st_by_target_green_onset(:,:,k)')';
    end

    for k = 1:size(scrambled_st_by_target_blue_onset,3)
        scrambled_st_by_target_blue_onset(:,:,k) =  detrend(scrambled_st_by_target_blue_onset(:,:,k)')';
    end

    for k = 1:size(scrambled_st_by_target_white_onset,3)
        scrambled_st_by_target_white_onset(:,:,k) = detrend(scrambled_st_by_target_white_onset(:,:,k)')';
    end

    for k = 1:size(scrambled_st_by_target_object_onset,3)
        scrambled_st_by_target_object_onset(:,:,k) =  detrend(scrambled_st_by_target_object_onset(:,:,k)')';
    end

    for k = 1:size(unscrambled_st_by_target_red_onset,3)
        unscrambled_st_by_target_red_onset(:,:,k) =  detrend(unscrambled_st_by_target_red_onset(:,:,k)')';
    end

    for k = 1:size(unscrambled_st_by_target_green_onset,3)
        unscrambled_st_by_target_green_onset(:,:,k) =  detrend(unscrambled_st_by_target_green_onset(:,:,k)')';
    end

    for k = 1:size(unscrambled_st_by_target_blue_onset,3)
        unscrambled_st_by_target_blue_onset(:,:,k) =  detrend(unscrambled_st_by_target_blue_onset(:,:,k)')';
    end

    for k = 1:size(unscrambled_st_by_target_white_onset,3)
        unscrambled_st_by_target_white_onset(:,:,k) =  detrend(unscrambled_st_by_target_white_onset(:,:,k)')';
    end

    for k = 1:size(unscrambled_st_by_target_object_onset,3)
        unscrambled_st_by_target_object_onset(:,:,k) =  detrend(unscrambled_st_by_target_object_onset(:,:,k)')';
    end

    for k = 1:size(scrambled_dt_by_target_red_onset,3)
        scrambled_dt_by_target_red_onset(:,:,k) =  detrend(scrambled_dt_by_target_red_onset(:,:,k)')';
    end
    for k = 1:size(scrambled_dt_by_target_green_onset,3)
        scrambled_dt_by_target_green_onset(:,:,k) =  detrend(scrambled_dt_by_target_green_onset(:,:,k)')';
    end
    for k = 1:size(scrambled_dt_by_target_blue_onset,3)
        scrambled_dt_by_target_blue_onset(:,:,k) =  detrend(scrambled_dt_by_target_blue_onset(:,:,k)')';
    end
    for k = 1:size(scrambled_dt_by_target_white_onset,3)
        scrambled_dt_by_target_white_onset(:,:,k) =  detrend(scrambled_dt_by_target_white_onset(:,:,k)')';
    end
    for k = 1:size(scrambled_dt_by_target_object_onset,3)
        scrambled_dt_by_target_object_onset(:,:,k) =  detrend(scrambled_dt_by_target_object_onset(:,:,k)')';
    end

    for k = 1:size(unscrambled_dt_by_target_red_onset,3)
        unscrambled_dt_by_target_red_onset(:,:,k) =  detrend(unscrambled_dt_by_target_red_onset(:,:,k)')';
    end
    for k = 1:size(unscrambled_dt_by_target_green_onset,3)
        unscrambled_dt_by_target_green_onset(:,:,k) =  detrend(unscrambled_dt_by_target_green_onset(:,:,k)')';
    end
    for k = 1:size(unscrambled_dt_by_target_blue_onset,3)
        unscrambled_dt_by_target_blue_onset(:,:,k) =  detrend(unscrambled_dt_by_target_blue_onset(:,:,k)')';
    end
    for k = 1:size(unscrambled_dt_by_target_white_onset,3)
        unscrambled_dt_by_target_white_onset(:,:,k) =  detrend(unscrambled_dt_by_target_white_onset(:,:,k)')';
    end
    for k = 1:size(unscrambled_dt_by_target_object_onset,3)
        unscrambled_dt_by_target_object_onset(:,:,k) =  detrend(unscrambled_dt_by_target_object_onset(:,:,k)')';
    end

    for k = 1:size(scrambled_dt_by_masker_onset,3)
        scrambled_dt_by_masker_onset(:,:,k) =  detrend(scrambled_dt_by_masker_onset(:,:,k)')';
    end
    for k = 1:size(scrambled_st_by_masker_onset,3)
        scrambled_st_by_masker_onset(:,:,k) =  detrend(scrambled_st_by_masker_onset(:,:,k)')';
    end
    for k = 1:size(unscrambled_st_by_masker_onset,3)
        unscrambled_st_by_masker_onset(:,:,k) =  detrend(unscrambled_st_by_masker_onset(:,:,k)')';
    end
    for k = 1:size(unscrambled_dt_by_masker_onset,3)
        unscrambled_dt_by_masker_onset(:,:,k) =  detrend(unscrambled_dt_by_masker_onset(:,:,k)')';
    end




    all_scrambled_st_by_target_red_onset(isubject,:,:) = squeeze(mean(scrambled_st_by_target_red_onset,3));
    all_scrambled_st_by_target_green_onset(isubject,:,:) =  squeeze(mean(scrambled_st_by_target_green_onset,3));
    all_scrambled_st_by_target_blue_onset(isubject,:,:) =  squeeze(mean(scrambled_st_by_target_blue_onset,3));
    all_scrambled_st_by_target_white_onset(isubject,:,:) = squeeze(mean(scrambled_st_by_target_white_onset,3));
    all_scrambled_st_by_target_object_onset(isubject,:,:) =  squeeze(mean(scrambled_st_by_target_object_onset,3));

    all_unscrambled_st_by_target_red_onset(isubject,:,:) =  squeeze(mean(unscrambled_st_by_target_red_onset,3));
    all_unscrambled_st_by_target_green_onset(isubject,:,:) =  squeeze(mean(unscrambled_st_by_target_green_onset,3));
    all_unscrambled_st_by_target_blue_onset(isubject,:,:) =  squeeze(mean(unscrambled_st_by_target_blue_onset,3));
    all_unscrambled_st_by_target_white_onset(isubject,:,:) =  squeeze(mean(unscrambled_st_by_target_white_onset,3));
    all_unscrambled_st_by_target_object_onset(isubject,:,:) =  squeeze(mean(unscrambled_st_by_target_object_onset,3));

    all_scrambled_dt_by_target_red_onset(isubject,:,:) =  squeeze(mean(scrambled_dt_by_target_red_onset,3));
    all_scrambled_dt_by_target_green_onset(isubject,:,:) =  squeeze(mean(scrambled_dt_by_target_green_onset,3));
    all_scrambled_dt_by_target_blue_onset(isubject,:,:) =  squeeze(mean(scrambled_dt_by_target_blue_onset,3));
    all_scrambled_dt_by_target_white_onset(isubject,:,:) =  squeeze(mean(scrambled_dt_by_target_white_onset,3));
    all_scrambled_dt_by_target_object_onset(isubject,:,:) =  squeeze(mean(scrambled_dt_by_target_object_onset,3));

    all_unscrambled_dt_by_target_red_onset(isubject,:,:) =  squeeze(mean(unscrambled_dt_by_target_red_onset,3));
    all_unscrambled_dt_by_target_green_onset(isubject,:,:) =  squeeze(mean(unscrambled_dt_by_target_green_onset,3));
    all_unscrambled_dt_by_target_blue_onset(isubject,:,:) =  squeeze(mean(unscrambled_dt_by_target_blue_onset,3));
    all_unscrambled_dt_by_target_white_onset(isubject,:,:) =  squeeze(mean(unscrambled_dt_by_target_white_onset,3));
    all_unscrambled_dt_by_target_object_onset(isubject,:,:) =  squeeze(mean(unscrambled_dt_by_target_object_onset,3));

    all_scrambled_dt_by_masker_onset(isubject,:,:) =  squeeze(mean(scrambled_dt_by_masker_onset,3));
    all_scrambled_st_by_masker_onset(isubject,:,:) =  squeeze(mean(scrambled_st_by_masker_onset,3));
    all_unscrambled_st_by_masker_onset(isubject,:,:) =  squeeze(mean(unscrambled_st_by_masker_onset,3));
    all_unscrambled_dt_by_masker_onset(isubject,:,:) =  squeeze(mean(unscrambled_dt_by_masker_onset,3));

    % for plotting big averages ignoring same vs diff talker
    
    all_scrambled_by_color_onset(isubject,:,:) = squeeze(mean(cat(3,scrambled_st_by_target_color_onset,scrambled_dt_by_target_color_onset),3));
    all_scrambled_by_masker_onset(isubject,:,:) = squeeze(mean(cat(3,scrambled_st_by_target_object_onset,scrambled_dt_by_target_object_onset),3));
    all_scrambled_by_object_onset(isubject,:,:) = squeeze(mean(cat(3,scrambled_st_by_masker_onset,scrambled_dt_by_masker_onset),3));

    all_unscrambled_by_color_onset(isubject,:,:) = squeeze(mean(cat(3,unscrambled_st_by_target_color_onset,unscrambled_dt_by_target_color_onset),3));
    all_unscrambled_by_masker_onset(isubject,:,:) = squeeze(mean(cat(3,unscrambled_st_by_target_object_onset,unscrambled_dt_by_target_object_onset),3));
    all_unscrambled_by_object_onset(isubject,:,:) = squeeze(mean(cat(3,unscrambled_st_by_masker_onset,unscrambled_dt_by_masker_onset),3));
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
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

%% red ST
% scrambled vs unscrambled red
subplot(2,3,1)
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_st_by_target_red_onset,2));
scrambled_frontocentral_erp = squeeze(all_scrambled_st_by_target_red_onset(:,frontocentral_channels,:));
unscrambled_frontocentral_erp = squeeze(all_unscrambled_st_by_target_red_onset(:,frontocentral_channels,:));
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
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Red','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])

meanERPArray(1,1,:) = scrambled_mean_to_plot;
meanERPArray(2,1,:) = unscrambled_mean_to_plot;


%% green ST
% scrambled vs unscrambled green
subplot(2,3,2)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Green','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])

meanERPArray(1,2,:) = scrambled_mean_to_plot;
meanERPArray(2,2,:) = unscrambled_mean_to_plot;


%% scrambled vs unccrambled white
subplot(2,3,4)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('White','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])

meanERPArray(1,3,:) = scrambled_mean_to_plot;
meanERPArray(2,3,:) = unscrambled_mean_to_plot;


%% scrambled vs unscrambled blue
subplot(2,3,5)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Blue','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])

meanERPArray(1,4,:) = scrambled_mean_to_plot;
meanERPArray(2,4,:) = unscrambled_mean_to_plot;

%% scrambled vs unscrambled object
subplot(2,3,3)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Object','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])

meanERPArray(1,5,:) = scrambled_mean_to_plot;
meanERPArray(2,5,:) = unscrambled_mean_to_plot;

%% scrambled vs unscrambled masker word
subplot(2,3,6)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Masker','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])
sgtitle('Same Talker')

meanERPArray(1,6,:) = scrambled_mean_to_plot;
meanERPArray(2,6,:) = unscrambled_mean_to_plot;


%% Diff Talker Plot
figure;
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Red','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])

meanERPArray(3,1,:) = scrambled_mean_to_plot;
meanERPArray(4,1,:) = unscrambled_mean_to_plot;

%% scrambled vs unscrambled green
subplot(2,3,2)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Green','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])



meanERPArray(3,2,:) = scrambled_mean_to_plot;
meanERPArray(4,2,:) = unscrambled_mean_to_plot;

%% scrambled vs unccrambled white
subplot(2,3,4)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('White','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])


meanERPArray(3,3,:) = scrambled_mean_to_plot;
meanERPArray(4,3,:) = unscrambled_mean_to_plot;

%% scrambled vs unscrambled blue
subplot(2,3,5)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Blue','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])


meanERPArray(3,4,:) = scrambled_mean_to_plot;
meanERPArray(4,4,:) = unscrambled_mean_to_plot;

%% scrambled vs unscrambled object
subplot(2,3,3)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Object','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])

meanERPArray(3,5,:) = scrambled_mean_to_plot;
meanERPArray(4,5,:) = unscrambled_mean_to_plot;

%% scrambled vs unscrambled Masker words
subplot(2,3,6)
scrambled_frontocentral_erp = [];
unscrambled_frontocentral_erp = [];
scrambled_frontocentral_erp_baselined = [];
unscrambled_frontocentral_erp_baselined = [];

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
%      for k = 1:size(scrambled_frontocentral_erp_baselined,3) %variability across trials
%         scrambled_frontocentral_erp_baselined(:,:,k) = detrend(scrambled_frontocentral_erp_baselined(:,:,k)')';
%
%     end
%     for k = 1:size(unscrambled_frontocentral_erp_baselined,3)
%         unscrambled_frontocentral_erp_baselined(:,:,k) = detrend(unscrambled_frontocentral_erp_baselined(:,:,k)')';
%     end


scrambled_mean_to_plot = mean(scrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
scrambled_SEM_to_plot = std(scrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,scrambled_mean_to_plot,scrambled_SEM_to_plot,'lineProps','-r')
hold on
unscrambled_mean_to_plot = mean(unscrambled_frontocentral_erp_baselined,[1,2]); %averaging across trials
unscrambled_SEM_to_plot = std(unscrambled_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials
shadedErrorBar(single_onset_time,unscrambled_mean_to_plot,unscrambled_SEM_to_plot,'lineProps','-b')
title('Masker','FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'scrambled','unscrambled'})
ylim([-10 10])

sgtitle('Diff Talker')

meanERPArray(3,6,:) = scrambled_mean_to_plot;
meanERPArray(4,6,:) = unscrambled_mean_to_plot;

%    save(append(dir,'\prepro_epoched_data\',string(curr_subject_ID),'meanERPArray.mat'),'meanERPArray')

%% average color word, average object word, and average masker responses in unscrambled vs scrambled
figure;
subplot(1,2,1) % unscrambled


color_frontocentral_erp_baselined = [];
object_frontocentral_erp_baselined = [];
masker_frontocentral_erp_baselined = [];

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

color_mean_to_plot = mean(color_frontocentral_erp_baselined,[1,2]); %averaging across trials
color_SEM_to_plot = std(color_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,color_mean_to_plot,color_SEM_to_plot,'lineProps','-r')
hold on
object_mean_to_plot = mean(object_frontocentral_erp_baselined,[1,2]); %averaging across trials
object_SEM_to_plot = std(object_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,object_mean_to_plot,object_SEM_to_plot,'lineProps','-g')

masker_mean_to_plot = mean(masker_frontocentral_erp_baselined,[1,2]); %averaging across trials
masker_SEM_to_plot = std(masker_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,masker_mean_to_plot,masker_SEM_to_plot,'lineProps','-b')

title('Unscrambled','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Color Target Word','Object Target Word','Masker Word'})



subplot(1,2,2) % scrambled

color_frontocentral_erp_baselined = [];
object_frontocentral_erp_baselined = [];
masker_frontocentral_erp_baselined = [];

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

color_mean_to_plot = mean(color_frontocentral_erp_baselined,[1,2]); %averaging across trials
color_SEM_to_plot = std(color_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,color_mean_to_plot,color_SEM_to_plot,'lineProps','-r')
hold on
object_mean_to_plot = mean(object_frontocentral_erp_baselined,[1,2]); %averaging across trials
object_SEM_to_plot = std(object_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,object_mean_to_plot,object_SEM_to_plot,'lineProps','-g')

masker_mean_to_plot = mean(masker_frontocentral_erp_baselined,[1,2]); %averaging across trials
masker_SEM_to_plot = std(masker_frontocentral_erp_baselined,[],[1,2])/(sqrt(nsubjects)-1); %getting SEM across trials; %getting SEM across subjects
shadedErrorBar(single_onset_time,masker_mean_to_plot,masker_SEM_to_plot,'lineProps','-b')

title('Scrambled','FontSize',14)
xlabel('Time (ms)','FontSize',14)
ylabel('Voltage (uV)','FontSize',14)
legend({'Color Target Word','Object Target Word','Masker Word'})



%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% All Colors


% %     test_scram=squeeze(scrambled_by_target_onset(:,2,:));
% % test_avg_scram=mean(test_scram,1);
% %
%  test_unscram=squeeze(unscrambled_by_target_onset(:,2,:));
% test_avg_unscram=mean(test_unscram,1);
% %
% % figure
% % plot(t_epoched,test_avg_scram)
% % hold on
% % plot(t_epoched,test_avg_unscram)
% % legend('scrambled','unscrambled')
%
%     %% Isolate masker word onset ERPs for unscrambled condition only
% %     icount_masker = 1;
% %     for itrial = 1:size(target_word_indices,1) % for each trial...
% %         % find the condition
% %         curr_condition = conditions(itrial);
% %         if curr_condition == 1
% %             continue
% %         elseif curr_condition == 2
% %             % find onsets of target words in this trial
% %             this_trial_masker_onsets = tOnset;
% %             this_trial_masker_onsets(target_word_indices(itrial,:)==1) = [];
% %             for ionset = 1:length(this_trial_masker_onsets) % for each target word onset...
% %                 [~,start_time] = min(abs(unscrambled_time - ((this_trial_masker_onsets(ionset)*1000)+erp_window_start_time))); % ...find 100 ms before the time it starts
% %                 [~,end_time] = min(abs(unscrambled_time - ((this_trial_masker_onsets(ionset)*1000)+erp_window_end_time))); % ...find the time it ends (500 ms later)
% %
% %                 % Isolate ERP
% %                 unscrambled_by_masker_onset(icount_masker,:,:) = all_epochs(:,start_time:end_time,itrial);
% %                 % unscrambled_by_masker_onset(isubject,icount_masker,:,:) = all_epochs(:,start_time:end_time,itrial);
% %
% %                 icount_masker = icount_masker + 1;
% %
% %             end
% %         end
% %     end
%
% % end
%
% test_unscram=squeeze(unscrambled_by_target_onset(:,2,:));
% test_avg_unscram=mean(test_unscram,1);
%
% test_unscram_masker = squeeze(unscrambled_by_masker_onset(:,2,:));
% test_avg_unscram_masker=mean(test_unscram_masker,1);
%
% t_epoched = linspace(-100,500,length(test_avg_unscram));
% figure;
% plot(t_epoched,detrend(test_avg_unscram))
% hold on
% plot(t_epoched,detrend(test_avg_unscram_masker))
% legend('unscrambled','masker unscrambled')
%
% %% Plot average over all frontocentral electrodes across the whole trial (mean subtracted)
% frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
% unscrambled_whole_trial = squeeze(mean(unscrambled_epochs(:,frontocentral_channels,:,:),[2,4]));
% scrambled_whole_trial = squeeze(mean(scrambled_epochs(:,frontocentral_channels,:,:),[2,4]));
%
% figure;
% scrambled_mean_plot = plot(scrambled_time,mean(scrambled_whole_trial,1),'r');
% hold on;
% unscrambled_mean_plot = plot(unscrambled_time,mean(unscrambled_whole_trial,1),'b');
%
% SEM_of_scrambled = std(scrambled_whole_trial,[],1)./sqrt(nsubjects-1);
% dy = SEM_of_scrambled';
% x = scrambled_time';
% op = 0.3;
% % y = mean(scrambled_whole_trial,1)';
% %fill([x;flipud(x)],[y-dy;flipud(y+dy)],[1 0 0],'linestyle','none','facealpha',op);
%
% % SEM_of_unscrambled = std(unscrambled_whole_trial,[],1)./sqrt(nsubjects-1);
% % dy = SEM_of_unscrambled';
% % x = scrambled_time';
% % op = 0.3;
% % y = mean(unscrambled_whole_trial,1)';
% % fill([x;flipud(x)],[y-dy;flipud(y+dy)],[0 0 1],'linestyle','none','facealpha',op);
%
% xlabel('Time (ms)','FontSize',18)
% ylabel('Amplitude (normalized)','FontSize',18)
% title('Average FrontoCentral Activity over whole trial','FontSize',18)
% legend([scrambled_mean_plot(1),unscrambled_mean_plot(1)],{'Scrambled','Unscrambled'},'FontSize',18)
%
%
% %% Plot all scrambled target ERPs, all electrodes
% % scrambled_by_target_onset and unscrambled_by_target_onset are of
% % dimension num_subjects x num_total_onsets x num_electrodes x time
% single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_by_target_onset,4));
% figure;plot(single_onset_time,squeeze(mean(scrambled_by_target_onset,[1,2])))
% xlabel('Time (ms)')
% ylabel('Amplitude (/muV)')
% title('ERPs all channels (average over 24 presentations)','FontSize',18)
%
% %% Plot scrambled vs. unscrambled target onset in frontocentral electrodes
% % Just Frontocentral electrodes
% % Fp1 (ch1), AF3 (ch2), F3 (ch4), FC1 (ch5), FC5 (ch6),
% % C3 (ch8), CP1 (ch9), C4 (ch23), FC6 (ch25), FC2 (ch26), F4 (ch27), AF4 (ch29), Fz (ch31), and Cz (ch32)
% frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
%
% single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_by_target_onset(:,:,frontocentral_channels,:),3));
%
% % find erp and baseline
% for isubject = 1:nsubjects
%     scrambled_frontocentral_erp= scrambled_by_target_onset(:,frontocentral_channels,:);
%     unscrambled_frontocentral_erp= unscrambled_by_target_onset(:,frontocentral_channels,:);
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
% figure;
% scrambled_mean_plot = plot(single_onset_time,squeeze(mean(scrambled_frontocentral_erp_mean_over_electrodes,1)),'r');
% hold on;
% unscrambled_mean_plot = plot(single_onset_time,squeeze(mean(unscrambled_frontocentral_erp_mean_over_electrodes,1)),'b');
%
% % error patches
% % SEM_of_scrambled = std(scrambled_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
% % dy = SEM_of_scrambled';
% % x = single_onset_time';
% % op = 0.3;
% % y = nanmean(scrambled_frontocentral_erp_mean_over_electrodes,1)';
% % %fill([x;flipud(x)],[y-dy;flipud(y+dy)],[1 0 0],'linestyle','none','facealpha',op);
% %
% % SEM_of_unscrambled = std(unscrambled_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
% % dy = SEM_of_unscrambled';
% % x = single_onset_time';
% % op = 0.3;
% % y = nanmean(unscrambled_frontocentral_erp_mean_over_electrodes,1)';
% % fill([x;flipud(x)],[y-dy;flipud(y+dy)],[0 0 1],'linestyle','none','facealpha',op);
%
% xlabel('Time (ms)')
% ylabel('Amplitude (normalized)')
% title('Average FrontoCentral ERP (baselined)','FontSize',18)
% legend([scrambled_mean_plot(1),unscrambled_mean_plot(1)],{'Scrambled','Unscrambled'})
%
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
%     target_frontocentral_erp= unscrambled_by_target_onset(isubject,:,frontocentral_channels,:);
%     masker_frontocentral_erp= unscrambled_by_masker_onset(isubject,:,frontocentral_channels,:);
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
%
% figure;
% target_mean_plot = plot(single_onset_time,squeeze(mean(target_frontocentral_erp_mean_over_electrodes,1)),'r');
% hold on;
% masker_mean_plot = plot(single_onset_time,squeeze(mean(masker_frontocentral_erp_mean_over_electrodes,1)),'b');
%
% % error patches
% % SEM_of_target = std(target_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
% % dy = SEM_of_target';
% % x = single_onset_time';
% % op = 0.3;
% % y = nanmean(target_frontocentral_erp_mean_over_electrodes,1)';
% % fill([x;flipud(x)],[y-dy;flipud(y+dy)],[1 0 0],'linestyle','none','facealpha',op);
%
% % SEM_of_masker = std(masker_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
% % dy = SEM_of_masker';
% % x = single_onset_time';
% % op = 0.3;
% % y = nanmean(masker_frontocentral_erp_mean_over_electrodes,1)';
% % fill([x;flipud(x)],[y-dy;flipud(y+dy)],[0 0 1],'linestyle','none','facealpha',op);
%
% xlabel('Time (ms)')
% ylabel('Amplitude (normalized)')
% title('Average FrontoCentral ERP (baselined to 100ms before onset)','FontSize',18)
% legend([target_mean_plot(1),masker_mean_plot(1)],{'Target','Masker'})