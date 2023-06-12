%% analyze_EEG_fNIRSandGerbils
% script to calculate ERPs for scrambled and unscrambled word onsets in
% fNIRS and Gerbils

eeglab;
% Define subject information (which BDFs to load)

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

% Question for resolution: order of presentation vs. order put into the
% .csv? To that end, which trigger is which?

% Find tOnset to isolate ERPs
load('C:\Users\benri\Documents\GitHub\fNIRSandGerbils\stim\s_nooverlappilot2\nooverlappilot2_alltrialwords.mat')

% isolate ERPs
scrambled_epochs = EEG_scrambled.data; % num channels x num time points x num trials
unscrambled_epochs = EEG_unscrambled.data;
scrambled_time = EEG_scrambled.times; % in milliseconds
unscrambled_time = EEG_unscrambled.times; % in milliseconds

scrambled_by_onset = [];
unscrambled_by_onset = [];

for itrial = 1:size(scrambled_epochs,3)
    for ionset = 1:length(tOnset)
        [~,start_time_scrambled] = min(abs(scrambled_time - tOnset(ionset)));
        [~,end_time_scrambled] = min(abs(scrambled_time - (tOnset(ionset)+500)));

        [~,start_time_unscrambled] = min(abs(unscrambled_time - tOnset(ionset)));
        [~,end_time_unscrambled] = min(abs(unscrambled_time - (tOnset(ionset)+500)));
        scrambled_by_onset(ionset,:,:) = scrambled_epochs(:,start_time_scrambled:end_time_scrambled,itrial);
        unscrambled_by_onset(ionset,:,:) = unscrambled_epochs(:,start_time_unscrambled:end_time_unscrambled,itrial);
       
    end
end

single_onset_time = linspace(0,500,size(scrambled_by_onset,3));
figure;plot(single_onset_time,squeeze(mean(scrambled_by_onset,1)))
xlabel('Time (ms)')
ylabel('Amplitude (/muV)')
title('ERPs all channels (average over 24 presentations)','FontSize',18)

% Just plotting Cz
single_onset_time = linspace(0,500,size(scrambled_by_onset(:,14,:),3));
scrambled_cz_erp = squeeze(mean(scrambled_by_onset(:,14,:)));
unscrambled_cz_erp = squeeze(mean(unscrambled_by_onset(:,14,:)));
scrambled_cz_erp_baselined = (scrambled_cz_erp - mean(scrambled_epochs(14,1:0.1*256,:),"all"))/std(scrambled_epochs(14,1:0.1*256,:),[],"all");
unscrambled_cz_erp_baselined = (unscrambled_cz_erp - mean(unscrambled_epochs(14,1:0.1*256,:),"all"))/std(unscrambled_epochs(14,1:0.1*256,:),[],"all");

figure;plot(single_onset_time,scrambled_cz_erp_baselined)
hold on;plot(single_onset_time,unscrambled_cz_erp_baselined)
xlabel('Time (ms)')
ylabel('Amplitude (normalized)')
title('Average Cz ERP','FontSize',18)
legend({'Scrambled','Unscrambled'})
