%% gerbilmaster_plotting.m

% Author: Benjamin Richards
% 09/16/2024

curr_subject_ID =  char('7023','7024','7033','7035','7036','7038','7039','7040','7041','7043','7044','7045','7047','7048','7049','7050');%char('7002','7004','7007','7008','7010','7023','7024','7033','7035','7036','7038','7039','7040');

all_scrambled_by_color_onset = [];
all_scrambled_by_object_onset = [];
all_scrambled_by_masker_onset = [];
all_unscrambled_by_color_onset = [];
all_unscrambled_by_object_onset = [];
all_unscrambled_by_masker_onset = [];
num_erps_removed = zeros(size(curr_subject_ID,1));

noise_thresh = 100;

for isubject = 1:size(curr_subject_ID,1)
    subID = string(curr_subject_ID(isubject,:));
    % Load Data
    load(append('Results_Subject_',string(curr_subject_ID(isubject,:)),'.mat'))

    % Remove noisy ERPs
    erps_to_remove = [];
    z = [];
    for iERP = 1:size(data_by_target_onset_baselined,3)
        if max(abs(data_by_target_onset_baselined(:,:,iERP)),[],'all') > noise_thresh
            z(iERP) = max(abs(data_by_target_onset_baselined(:,:,iERP)),[],'all');
            num_erps_removed(isubject) = num_erps_removed(isubject) + 1;
            erps_to_remove = [erps_to_remove, iERP];
        end
    end
    data_by_target_onset_baselined(:,:,erps_to_remove) = [];
    ERP_info_target.SubID(erps_to_remove,:) = [];
    ERP_info_target.Trial(erps_to_remove) = [];
    ERP_info_target.Word(erps_to_remove) = [];
    ERP_info_target.Condition(erps_to_remove) = [];

    erps_to_remove = [];
    for iERP = 1:size(data_by_masker_onset_baselined,3)
        if max(abs(data_by_masker_onset_baselined(:,:,iERP)),[],'all') > noise_thresh
            num_erps_removed(isubject) = num_erps_removed(isubject) + 1;
            erps_to_remove = [erps_to_remove, iERP];
        end
    end
    data_by_masker_onset_baselined(:,:,erps_to_remove) = [];
    ERP_info_masker.SubID(erps_to_remove,:) = [];
    ERP_info_masker.Trial(erps_to_remove) = [];
    ERP_info_masker.Condition(erps_to_remove) = [];

    % Plotting parameters
    erp_window_start_time =-100;
    erp_window_end_time = 750;
    single_onset_time = linspace(erp_window_start_time,erp_window_end_time,size(data_by_target_onset_baselined,2));
    frontocentral_channels = [1,2,4,5,6,8,9,23,25,26,27,29,31,32];
    
    % Plot all individual word ERPs for this subject
    figure;
    plot(single_onset_time,squeeze(mean(data_by_target_onset_baselined(frontocentral_channels,:,:),1)))
    hold on
    plot(single_onset_time,squeeze(mean(data_by_masker_onset_baselined(frontocentral_channels,:,:),1)))
    title(subID)

        color_words = {'red','green','blue','white'};
    all_scrambled_by_color_onset(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined(:,:,logical(ismember(ERP_info_target(:).Word,color_words)'.*ismember(ERP_info_target(:).Condition,[1,2]))),3));
    all_scrambled_by_object_onset(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined(:,:,logical(~ismember(ERP_info_target(:).Word,color_words)'.*ismember(ERP_info_target(:).Condition,[1,2]))),3));
    all_scrambled_by_masker_onset(isubject,:,:) = squeeze(mean(data_by_masker_onset_baselined(:,:,logical(ismember(ERP_info_masker(:).Condition,[1,2]))),3));
    
    all_unscrambled_by_color_onset(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined(:,:,logical(ismember(ERP_info_target(:).Word,color_words)'.*ismember(ERP_info_target(:).Condition,[3,4]))),3));
    all_unscrambled_by_object_onset(isubject,:,:) = squeeze(mean(data_by_target_onset_baselined(:,:,logical(~ismember(ERP_info_target(:).Word,color_words)'.*ismember(ERP_info_target(:).Condition,[3,4]))),3));
    all_unscrambled_by_masker_onset(isubject,:,:) = squeeze(mean(data_by_masker_onset_baselined(:,:,logical(ismember(ERP_info_masker(:).Condition,[3,4]))),3));

    % Plot averages for each subject
    figure;
    subplot(1,3,1)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_color_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_color_onset(isubject,frontocentral_channels,:),2)),'-b');
    if isubject == 1
        title('Target Color Word')
    end
    %legend({'Scrambled','Unscrambled'})
    ylim([-8,8])

    subplot(1,3,2)
    hold on
    plot(single_onset_time,squeeze(mean(all_scrambled_by_object_onset(isubject,frontocentral_channels,:),2)),'-r');
    plot(single_onset_time,squeeze(mean(all_unscrambled_by_object_onset(isubject,frontocentral_channels,:),2)),'-b');
    if isubject == 1
        title('Target Object Word')
    end
    %legend({'Scrambled','Unscrambled'})
    ylim([-8,8])

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



end
