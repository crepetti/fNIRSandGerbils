%% when_do_people_click_fNIRSandGerbils

% Benjamin Richardson

%1	scrambled_diff_talker
%2	scrambled_same_talker
%3	unscrambled_diff_talker
%4	unscrambled_same_talker


% Create array of subject IDs that you would like to analyze now
curr_subject_ID = char('7006','7007','7008','7009','7010','7017','7022','7023','7024','7025');
user = 'Ben';
%% Load in Relevant files
% Spreadsheet which contains all subjects' condition, soundfile
if user == 'Ema'
    fNIRSandGerbilsXL = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';
    stim_file = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\stim\s_';
elseif user == 'Bon'figure;
curr_distances = all_target_distances{:};
histogram(curr_distances,400);
xticks(0:0.25:14)
xlabel('Time (s)')
title('Distance from click to nearest preceding target color word','FontSize',18)
ylabel('Frequency of occurrence (count)','FontSize',18)

figure;
curr_distances = all_masker_distances{:};
histogram(curr_distances,400);
xticks(0:0.25:14)
xlabel('Time (s)')
title('Distance from click to nearest preceding non-target object word','FontSize',18)
    fNIRSandGerbilsXL = 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\data\fNIRSandGerbils.xlsx';
    stim_file = 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\stim\s_';
elseif user == 'Ben'
    fNIRSandGerbilsXL = '/home/ben/Documents/GitHub/fNIRSandGerbils/data/fNIRSandGerbils.xlsx';
    stim_file = '/home/ben/Documents/GitHub/fNIRSandGerbils/stim/s_';
end
% names, and click times by trial
all_click_info = readtable(fNIRSandGerbilsXL,'FileType','spreadsheet','Format','auto');

by_subject_behavior_info = struct(); % create empty structure for behavior info split up by subject
all_subjects_click_times = []; % create empty array for all click times (used for histograms)
all_subjects_click_times_scrambled = []; % create empty array for all click times (used for histograms)
all_subjects_click_times_unscrambled = []; % create empty array for all click times (used for histograms)

all_target_distances = {[],[],[],[]};
all_masker_distances = {[],[],[],[]};

for isubject = 1:size(curr_subject_ID,1) % For each subject....

    % load words  by trial for this subject
    stim_info_filename = [stim_file,strtrim(curr_subject_ID(isubject,:)),'/',strtrim(curr_subject_ID(isubject,:)),'_alltrialwords.mat'];
    load(stim_info_filename) % loads all_word_order (array of all words) and tOnset (the onset times within each trial)

    this_subject_ID = strtrim(string(curr_subject_ID(isubject,:))); % define this subject ID
    by_subject_behavior_info(isubject).subject_ID = strtrim(curr_subject_ID(isubject,:)); % save subject ID in behavior struct

    numtotalwords = 40;
    wordlength = 0.3; % length of an individual word
    fs = 44100; % sample rate of the audio (Hz)
    tVec = 0:1/fs:(wordlength*numtotalwords); % define time vector

    %% Behavior processing
    which_rows_this_subject = find(all_click_info.S == string(this_subject_ID)); % find the rows in the spreadsheet which belong to this subject

    %% Get information from files

    trials = all_click_info.Trial(which_rows_this_subject); % trial indices for this subject
    conditions = all_click_info.Condition(which_rows_this_subject); % conditions by trial for this subject
    click_times = all_click_info(which_rows_this_subject,9:end); % click times by trial for this subject. will include NaNs! accounted for later
    soundfiles_by_trial = all_click_info.Soundfile(which_rows_this_subject); % soundfile names by trial for this subject

    %% Loop through each trial, and calculate hits and false alarms

    n_trials = length(trials); % find number of trials
    threshold_window_start = 0.2; % time in seconds from onset of word for start of hit/FA windows
    threshold_window_end = 0.8; % time in seconds from onset of word for end of hit/FA windows
    double_click_threshold = 0.1; % distance between clicks at which it would be decided that it is a double click

    by_subject_behavior_info(isubject).nearest_click_distances = struct(); % create structure for nearest click distances

    color_words = string({'red','green','blue','white'}); % define which words are color words
    clicks_not_counted = 0;
    for itrial = 1:n_trials % for each trial...
        % ....find the subjects click times for this trial....
        this_trial_condition = conditions(itrial);
        if string(this_subject_ID) == '7008'
            variable = string(soundfiles_by_trial{itrial, 1});
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_7007\scrambled_diff_talker\');
            variable = erase(variable, '_scrambled_dt.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_7007\scrambled_same_talker\');
            variable = erase(variable, '_scrambled_st.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_7007\unscrambled_diff_talker\');
            variable = erase(variable,  '_unscrambled_dt.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_7007\unscrambled_same_talker\');
            variable = erase(variable,  '_unscrambled_st.wav');
            variable = str2num(variable);
        elseif string(this_subject_ID) == '7017'
            variable = string(soundfiles_by_trial{itrial, 1});
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_7016\scrambled_diff_talker\');
            variable = erase(variable, '_scrambled_dt.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_7016\scrambled_same_talker\');
            variable = erase(variable, '_scrambled_st.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_7016\unscrambled_diff_talker\');
            variable = erase(variable,  '_unscrambled_dt.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_7016\unscrambled_same_talker\');
            variable = erase(variable,  '_unscrambled_st.wav');
            variable = str2num(variable);
        else

            variable = string(soundfiles_by_trial{itrial, 1});
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_' + string(this_subject_ID) + '\scrambled_diff_talker\');
            variable = erase(variable, '_scrambled_dt.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_' + string(this_subject_ID) + '\scrambled_same_talker\');
            variable = erase(variable, '_scrambled_st.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_' + string(this_subject_ID) + '\unscrambled_diff_talker\');
            variable = erase(variable,  '_unscrambled_dt.wav');
            variable = erase(variable, 'D:\Experiments\fNIRSandGerbils\stim\s_' + string(this_subject_ID) + '\unscrambled_same_talker\');
            variable = erase(variable,  '_unscrambled_st.wav');
            variable = str2num(variable);
        end
        current_click_times = table2array(click_times(itrial,:));
        current_click_times = current_click_times(~isnan(current_click_times));

        all_subjects_click_times = [all_subjects_click_times,current_click_times];


        %% find the appropriate color times for this trial (NOT IN ORDER)
        all_target_words_this_trial = all_target_words(variable).words; % find the words presented in this trial
        target_color_indices_this_trial = find(ismember(all_target_words_this_trial,color_words) == 1); % find the indices of color words
        target_object_indices_this_trial = find(~ismember(all_target_words_this_trial,color_words) == 1); % find the indices of masker words

        current_target_color_times = all_target_onsets(variable).onsets(target_color_indices_this_trial); % onset times of color words this trial
        current_target_object_times = all_target_onsets(variable).onsets(target_object_indices_this_trial); % onset times of masker words this trial
        current_target_color_words = all_target_words_this_trial(target_color_indices_this_trial); % color word names for this trial


        %% Hit and False Alarm Windows

        hit_windows = zeros(1,length(tVec)); % create an empty array to define hit windows
        FA_windows = zeros(1,length(tVec)); % create an empty array to define false alarm windows

        % specify hit windows
        for i = 1:length(current_target_color_times) % for each of the current target color times...
            [~,start_index_hit_window] = min(abs(tVec - (current_target_color_times(i)+threshold_window_start))); % ...the hit window will start threshold_window_start seconds after the word onset
            [~,end_index_hit_window] = min(abs(tVec - (current_target_color_times(i)+threshold_window_end))); % ...the hit window will end threshold_window_end seconds after the word onset

            hit_windows(start_index_hit_window:end_index_hit_window) = 1; % a value of 1 in the vector hit_windows indicate an area where, if a click falls, it will be counted as a hit
        end

        % specify false alarm windows
        for i = 1:length(current_target_object_times) % for each of the current masker times...
            [~,start_index_FA_window] = min(abs(tVec - (current_target_object_times(i)+threshold_window_start))); % ...the false alarm window will start threshold_window_start seconds after the word onset
            [~,end_index_FA_window] = min(abs(tVec - (current_target_object_times(i)+threshold_window_end))); % ...the false alarm window will end threshold_window_end seconds after the word onset

            FA_windows(start_index_FA_window:end_index_FA_window) = 1;
        end

        FA_windows(hit_windows == 1) = 0; % any time there is a hit window, there should not be an FA window

        %% Calculate number of hits and false alarms for this trial

        by_subject_behavior_info(isubject).condition(itrial).value = conditions(itrial); % specify condition
        by_subject_behavior_info(isubject).num_hits(itrial).value = 0; % set starting number of hits to zero
        by_subject_behavior_info(isubject).num_FAs(itrial).value = 0; % set starting number of false alarms to zero

        by_subject_behavior_info(isubject).num_target_object_words(itrial).value = length(current_target_object_times);
        by_subject_behavior_info(isubject).num_target_color_words(itrial).value = length(current_target_color_times);

        for iclick = 1:length(current_click_times) % for each click in this trial...
            [~,current_click_index] = min(abs(tVec - current_click_times(iclick))); % ...find the time index of that click...
            if iclick > 1 && (current_click_times(iclick) - current_click_times(iclick - 1)) < double_click_threshold
                continue
            end%1	scrambled_diff_talker
%2	scrambled_same_talker
%3	unscrambled_diff_talker
%4	unscrambled_same_talker

            if hit_windows(current_click_index) == 1 % ...if that click falls within a hit window...
                by_subject_behavior_info(isubject).num_hits(itrial).value = by_subject_behavior_info(isubject).num_hits(itrial).value + 1; % ...add 1 to the number of hits
            elseif FA_windows(current_click_index) == 1 %...otherwise if that click falls within a false alarm window...
                by_subject_behavior_info(isubject).num_FAs(itrial).value = by_subject_behavior_info(isubject).num_FAs(itrial).value + 1; % ...add 1 to the number of false alarms
            else % ...if the click is not counted as either
                clicks_not_counted = clicks_not_counted + 1;
            end

        end

        for iclick = 1:length(current_click_times)
            if ~isempty(current_target_color_times)
                distance_to_targets = current_click_times(iclick) - current_target_color_times ;
                distance_to_targets(distance_to_targets < 0) = [];
                all_target_distances{this_trial_condition} = [all_target_distances{this_trial_condition} ; distance_to_targets];
            end

            if ~isempty(current_target_object_times)
                distance_to_maskers = current_click_times(iclick) - current_target_object_times;
                distance_to_maskers(distance_to_maskers < 0) = [];

                all_masker_distances{this_trial_condition} = [all_masker_distances{this_trial_condition}; distance_to_maskers];
            end

        end
    end
end

figure;
target_distances_to_plot = [];
masker_distances_to_plot = [];
for icondition = 1:4
    target_distances_to_plot = [target_distances_to_plot; all_target_distances{icondition}];
    masker_distances_to_plot = [masker_distances_to_plot; all_masker_distances{icondition}];
end
histogram(target_distances_to_plot,400);
xticks(0:0.25:14)
xlabel('Time (s)')
title('Distance from click to nearest preceding target color word','FontSize',18)
ylabel('Frequency of occurrence (count)','FontSize',18)

figure;
curr_distances = all_masker_distances{:};
histogram(masker_distances_to_plot,400);
xticks(0:0.25:14)
xlabel('Time (s)')
title('Distance from click to nearest preceding non-target object word','FontSize',18)
ylabel('Frequency of occurrence (count)','FontSize',18)

figure;
condition_names = {'Scrambled Diff Talker','Scrambled Same Talker','Unscrambled Diff Talker','Unscrambled Same Talker'};
for icondition = 1:4
    subplot(4,1,icondition)
    curr_distances = all_target_distances{icondition};
    histogram(curr_distances,200);
    hold on
    curr_distances = all_masker_distances{icondition};
    histogram(curr_distances,200);
    if icondition == 1
        legend({'Color','Object'},'FontSize',18)
    elseif icondition == 2
        ylabel('Count','FontSize',18)
    elseif icondition == 4
        xlabel('Time(s)','FontSize',18)
    end
    ylim([0,275])
    title(condition_names(icondition))
end


figure;
condition_names = {'Scrambled','Unscrambled'};
subplot(2,1,1)
curr_distances = all_target_distances{1:2};
histogram(curr_distances,200);
hold on
curr_distances = all_masker_distances{1:2};
histogram(curr_distances,200);
legend({'Color','Object'},'FontSize',18)
title('Scrambled')
ylabel('Count','FontSize',18)
ylim([0,275])

subplot(2,1,2)
curr_distances = all_target_distances{3:4};
histogram(curr_distances,200);
hold on
curr_distances = all_masker_distances{3:4};
histogram(curr_distances,200);
legend({'Color','Object'},'FontSize',18)
title('Unscrambled')
ylabel('Count','FontSize',18)
xlabel('Time(s)','FontSize',18)
ylim([0,275])
title('Unscrambled')