%% analyze_EEG_fNIRSandGerbils
% script to calculate ERPs for scrambled and unscrambled word onsets in
% fNIRS and Gerbils
addpath('C:\Users\benri\Documents\eeglab2023.0')
eeglab;
% Define subject information (which BDFs to load)
curr_subject_ID = char('nooverlappilot2','nooverlappilot3');
scrambled_by_target_onset = [];
unscrambled_by_target_onset = [];
unscrambled_by_masker_onset = [];
erp_window_start_time = -100; % 100 ms before onset of word
erp_window_end_time = 500; % 500 ms after onset of word
nsubjects = size(curr_subject_ID,1);

for isubject = 1:nsubjects
    subID = curr_subject_ID(isubject,:);
    bdf_filename = [subID,'_EEG.bdf'];


    EEG = pop_biosig(bdf_filename,'ref',[33 34],'refoptions',{'keepref' 'off'});
    EEG = pop_select( EEG,'nochannel',{'EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'});
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',subID,'gui','on');
    EEG = pop_resample( EEG, 256);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',subID,'overwrite','on','gui','on');
    % EEG = pop_firws(EEG, 'fcutoff', [0.3 30], 'ftype', 'bandpass', 'wtype', 'kaiser', 'warg', 5.65326, 'forder', 50, 'minphase', 0,'plotfresp',true);
    fs = EEG.srate;
    [b, a] = butter(5, [0.3, 30] / (fs / 2));
    EEG.data = filtfilt(b, a, double(EEG.data'));
    EEG.data = EEG.data';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',[subID,'BPF'],'gui','on');

    % STOP TO CLEAN UP HERE

    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[subID, 'BPF CU'],'gui','on');
    EEG=pop_chanedit(EEG, 'load',{'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\richardson_32_chanlocs.locs' 'filetype' 'locs'});

    EEG = pop_runica(EEG, 'extended',1);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[subID, 'ICA'],'gui','on');

    pop_selectcomps(EEG, [1:32] );


    % Pause to select components
    pause
    %channels_to_remove = str2num(input('Please enter which components to remove:'));
    components_to_remove = input('Please enter a comma-separated list of ICA components to remove (ex. [1,2,3]:');
    EEG = pop_subcomp( EEG, components_to_remove, 0);
    close
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[subID, 'ICA Cleaned'],'gui','on');

    %% Epoching
    EEG_scrambled = pop_epoch( EEG, {'19711'}, [-1 16], 'newname', [subID, 'scrambled epochs'], 'epochinfo', 'yes');

    EEG_unscrambled = pop_epoch( EEG, {'36351'}, [-1 16], 'newname', [subID, 'unscrambled epochs'], 'epochinfo', 'yes');

    EEG_all = pop_epoch( EEG, {'19711','36351'}, [-1 16], 'newname', [subID, 'unscrambled epochs'], 'epochinfo', 'yes');
    % Question for resolution: order of presentation vs. order put into the
    % .csv? To that end, which trigger is which?

    % Find tOnset to isolate ERPs
    words_filename = ['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\stim\s_', subID, '\', subID, '_alltrialwords.mat'];
    load(words_filename)

    % isolate ERPs
    all_epochs = EEG_all.data;
    scrambled_epochs(isubject,:,:,:) = EEG_scrambled.data; % num channels x num time points x num trials
    unscrambled_epochs(isubject,:,:,:) = EEG_unscrambled.data;
    scrambled_time = EEG_scrambled.times; % in milliseconds
    unscrambled_time = EEG_unscrambled.times; % in milliseconds


    % Load click info to find condition
    all_click_info = readtable('C:\Users\benri\Documents\GitHub\fNIRSandGerbils\data\fNIRSandGerbils.xlsx','FileType','spreadsheet','Format','auto');
    which_rows_this_subject = find(all_click_info.S == string(curr_subject_ID(isubject,:))); % find the rows in the spreadsheet which belong to this subject
    conditions = all_click_info.Condition(which_rows_this_subject); % conditions by trial for this subject


    % Find target word onset times
    stim_info_filename = ['C:\Users\benri\Documents\GitHub\fNIRSandGerbils\stim\s_',strtrim(curr_subject_ID(isubject,:)),'\',strtrim(curr_subject_ID(isubject,:)),'_alltrialwords.mat'];
    load(stim_info_filename) % loads all_word_order (array of all words) and tOnset (the onset times within each trial)
    target_word_indices = all_word_order == 'red' | all_word_order == 'white' | all_word_order == 'blue' | all_word_order == 'green';

    %% Isolate target word onset ERPs for both conditions
    icount_scrambled = 1;
    icount_unscrambled = 1;

    for itrial = 1:size(target_word_indices,1) % for each trial...
        % find the condition
        curr_condition = conditions(itrial);
        % find onsets of target words in this trial
        this_trial_target_onsets = tOnset(target_word_indices(itrial,:) == 1);
        for ionset = 1:length(this_trial_target_onsets) % for each target word onset...
            [~,start_time] = min(abs(scrambled_time - ((this_trial_target_onsets(ionset)*1000)+erp_window_start_time))); % ...find 100 ms before the time it starts
            [~,end_time] = min(abs(scrambled_time - ((this_trial_target_onsets(ionset)*1000)+erp_window_end_time))); % ...find the time it ends (500 ms later)

            % Isolate ERP
            if curr_condition == 1
                    scrambled_by_target_onset(isubject,icount_scrambled,:,:) = all_epochs(:,start_time:end_time,itrial);
                    icount_scrambled = icount_scrambled + 1;
            elseif curr_condition == 2
                    unscrambled_by_target_onset(isubject,icount_unscrambled,:,:) = all_epochs(:,start_time:end_time,itrial);
                    icount_unscrambled = icount_unscrambled + 1;

            end
        end
    end

    %% Isolate masker word onset ERPs for unscrambled condition only 
    icount_masker = 1;
    for itrial = 1:size(target_word_indices,1) % for each trial...
        % find the condition
        curr_condition = conditions(itrial);
        if curr_condition == 1
            continue
        elseif curr_condition == 2
            % find onsets of target words in this trial
            this_trial_masker_onsets = tOnset;
            this_trial_masker_onsets(target_word_indices(itrial,:)==1) = [];
            for ionset = 1:length(this_trial_masker_onsets) % for each target word onset...
                [~,start_time] = min(abs(unscrambled_time - ((this_trial_masker_onsets(ionset)*1000)+erp_window_start_time))); % ...find 100 ms before the time it starts
                [~,end_time] = min(abs(unscrambled_time - ((this_trial_masker_onsets(ionset)*1000)+erp_window_end_time))); % ...find the time it ends (500 ms later)

                % Isolate ERP
                unscrambled_by_masker_onset(isubject,icount_masker,:,:) = all_epochs(:,start_time:end_time,itrial);
                icount_masker = icount_masker + 1;

            end
        end
    end

end

%% Plot average over all frontocentral electrodes across the whole trial (mean subtracted)
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
unscrambled_whole_trial = squeeze(mean(unscrambled_epochs(:,frontocentral_channels,:,:),[2,4]));
scrambled_whole_trial = squeeze(mean(scrambled_epochs(:,frontocentral_channels,:,:),[2,4]));

figure;
scrambled_mean_plot = plot(scrambled_time,mean(scrambled_whole_trial,1),'r');
hold on;
unscrambled_mean_plot = plot(unscrambled_time,mean(unscrambled_whole_trial,1),'b');

SEM_of_scrambled = std(scrambled_whole_trial,[],1)./sqrt(nsubjects-1);
dy = SEM_of_scrambled';
x = scrambled_time';
op = 0.3;
y = mean(scrambled_whole_trial,1)';
fill([x;flipud(x)],[y-dy;flipud(y+dy)],[1 0 0],'linestyle','none','facealpha',op);

SEM_of_unscrambled = std(unscrambled_whole_trial,[],1)./sqrt(nsubjects-1);
dy = SEM_of_unscrambled';
x = scrambled_time';
op = 0.3;
y = mean(unscrambled_whole_trial,1)';
fill([x;flipud(x)],[y-dy;flipud(y+dy)],[0 0 1],'linestyle','none','facealpha',op);

xlabel('Time (ms)','FontSize',18)
ylabel('Amplitude (normalized)','FontSize',18)
title('Average FrontoCentral Activity over whole trial','FontSize',18)
legend([scrambled_mean_plot(1),unscrambled_mean_plot(1)],{'Scrambled','Unscrambled'},'FontSize',18)


%% Plot all scrambled target ERPs, all electrodes
% scrambled_by_target_onset and unscrambled_by_target_onset are of
% dimension num_subjects x num_total_onsets x num_electrodes x time
single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_by_target_onset,4));
figure;plot(single_onset_time,squeeze(mean(scrambled_by_target_onset,[1,2])))
xlabel('Time (ms)')
ylabel('Amplitude (/muV)')
title('ERPs all channels (average over 24 presentations)','FontSize',18)

%% Plot scrambled vs. unscrambled target onset in frontocentral electrodes
% Just Frontocentral electrodes
% Fp1 (ch1), AF3 (ch2), F3 (ch4), FC1 (ch5), FC5 (ch6),
% C3 (ch8), CP1 (ch9), C4 (ch23), FC6 (ch25), FC2 (ch26), F4 (ch27), AF4 (ch29), Fz (ch31), and Cz (ch32)
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];

single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(scrambled_by_target_onset(:,:,frontocentral_channels,:),4));

% find erp and baseline
for isubject = 1:nsubjects
    scrambled_frontocentral_erp(isubject,:,:,:) = scrambled_by_target_onset(isubject,:,frontocentral_channels,:);
    unscrambled_frontocentral_erp(isubject,:,:,:) = unscrambled_by_target_onset(isubject,:,frontocentral_channels,:);
    % average over presentations
    [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
    [~,baseline_end_index] = min(abs(single_onset_time - 0));
    for ichannel = 1:length(frontocentral_channels)
        scrambled_frontocentral_erp_baselined(isubject,:,ichannel,:) = (scrambled_frontocentral_erp(isubject,:,ichannel,:) - mean(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[2,4]));%./std(scrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        unscrambled_frontocentral_erp_baselined(isubject,:,ichannel,:) = (unscrambled_frontocentral_erp(isubject,:,ichannel,:) - mean(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[2,4]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end
% take mean over electrodes and presentation
scrambled_frontocentral_erp_mean_over_electrodes = squeeze(mean(scrambled_frontocentral_erp_baselined,[2,3]));
unscrambled_frontocentral_erp_mean_over_electrodes = squeeze(mean(unscrambled_frontocentral_erp_baselined,[2,3]));

figure;
scrambled_mean_plot = plot(single_onset_time,squeeze(mean(scrambled_frontocentral_erp_mean_over_electrodes,1)),'r');
hold on;
unscrambled_mean_plot = plot(single_onset_time,squeeze(mean(unscrambled_frontocentral_erp_mean_over_electrodes,1)),'b');
% error patches
SEM_of_scrambled = std(scrambled_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
dy = SEM_of_scrambled';
x = single_onset_time';
op = 0.3;
y = nanmean(scrambled_frontocentral_erp_mean_over_electrodes,1)';
fill([x;flipud(x)],[y-dy;flipud(y+dy)],[1 0 0],'linestyle','none','facealpha',op);

SEM_of_unscrambled = std(unscrambled_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
dy = SEM_of_unscrambled';
x = single_onset_time';
op = 0.3;
y = nanmean(unscrambled_frontocentral_erp_mean_over_electrodes,1)';
fill([x;flipud(x)],[y-dy;flipud(y+dy)],[0 0 1],'linestyle','none','facealpha',op);

xlabel('Time (ms)')
ylabel('Amplitude (normalized)')
title('Average FrontoCentral ERP (baselined)','FontSize',18)
legend([scrambled_mean_plot(1),unscrambled_mean_plot(1)],{'Scrambled','Unscrambled'})


%% Plot unscrambled targets vs. unscrambled masker in frontocentral electrodes
% Just Frontocentral electrodes
% Fp1 (ch1), AF3 (ch2), F3 (ch4), FC1 (ch5), FC5 (ch6),
% C3 (ch8), CP1 (ch9), C4 (ch23), FC6 (ch25), FC2 (ch26), F4 (ch27), AF4 (ch29), Fz (ch31), and Cz (ch32)
frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];

single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(unscrambled_by_target_onset(:,:,frontocentral_channels,:),4));

% find erp and baseline
for isubject = 1:nsubjects
    target_frontocentral_erp(isubject,:,:,:) = unscrambled_by_target_onset(isubject,:,frontocentral_channels,:);
    masker_frontocentral_erp(isubject,:,:,:) = unscrambled_by_masker_onset(isubject,:,frontocentral_channels,:);
    [~,baseline_start_index] = min(abs(single_onset_time - erp_window_start_time));
    [~,baseline_end_index] = min(abs(single_onset_time - 0));
    for ichannel = 1:length(frontocentral_channels)
        target_frontocentral_erp_baselined(isubject,:,ichannel,:) = (target_frontocentral_erp(isubject,:,ichannel,:) - mean(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[2,4]));%./std(unscrambled_by_target_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
        masker_frontocentral_erp_baselined(isubject,:,ichannel,:) = (masker_frontocentral_erp(isubject,:,ichannel,:) - mean(unscrambled_by_masker_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[2,4]));%./std(unscrambled_by_masker_onset(isubject,:,ichannel,baseline_start_index:baseline_end_index),[],[2,4]);
    end
end
% take mean over electrodes and presentation
target_frontocentral_erp_mean_over_electrodes = squeeze(mean(target_frontocentral_erp_baselined,[2,3]));
masker_frontocentral_erp_mean_over_electrodes = squeeze(mean(masker_frontocentral_erp_baselined,[2,3]));

figure;
target_mean_plot = plot(single_onset_time,squeeze(mean(target_frontocentral_erp_mean_over_electrodes,1)),'r');
hold on;
masker_mean_plot = plot(single_onset_time,squeeze(mean(masker_frontocentral_erp_mean_over_electrodes,1)),'b');
% error patches
SEM_of_target = std(target_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
dy = SEM_of_target';
x = single_onset_time';
op = 0.3;
y = nanmean(target_frontocentral_erp_mean_over_electrodes,1)';
fill([x;flipud(x)],[y-dy;flipud(y+dy)],[1 0 0],'linestyle','none','facealpha',op);

SEM_of_masker = std(masker_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
dy = SEM_of_masker';
x = single_onset_time';
op = 0.3;
y = nanmean(masker_frontocentral_erp_mean_over_electrodes,1)';
fill([x;flipud(x)],[y-dy;flipud(y+dy)],[0 0 1],'linestyle','none','facealpha',op);

xlabel('Time (ms)')
ylabel('Amplitude (normalized)')
title('Average FrontoCentral ERP (baselined to 100ms before onset)','FontSize',18)
legend([target_mean_plot(1),masker_mean_plot(1)],{'Target','Masker'})
