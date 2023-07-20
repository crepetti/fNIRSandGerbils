%% PREPROCESSING

% addpath('C:\Users\ema36\OneDrive\Documents\fNIRS&Gerbils')
%% analyze_EEG_fNIRSandGerbils
% script to calculate ERPs for scrambled and unscrambled word onsets in
% fNIRS and Gerbils
% addpath('C:\Users\ema36\OneDrive\Documents\MATLAB\eeglab2023.0')
eeglab;
% Define subject information (which BDFs to load)
% curr_subject_ID = char('nooverlappilot2','nooverlappilot3');
curr_subject_ID = char('nooverlappilot3');
scrambled_by_target_onset = [];
unscrambled_by_target_onset = [];
unscrambled_by_masker_onset = [];
erp_window_start_time = -100; % 100 ms before onset of word
erp_window_end_time = 500; % 500 ms after onset of word
nsubjects = size(curr_subject_ID,1);

for isubject = 1:nsubjects
    subID = curr_subject_ID(isubject,:);
    bdf_filename = [subID,'_EEG.bdf'];
    ALLEEG = [];
    EEG = [];
    %^^reset everything piece of mind
    EEG = pop_biosig(bdf_filename,'ref',[1:32],'refoptions',{'keepref' 'on'}); %commonavg reference
    %EEG = pop_biosig(bdf_filename,'ref',[33 34],'refoptions',{'keepref' 'off'}); %mastoid reference
    EEG = pop_select( EEG,'nochannel',{'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'}); %take out EXG1/2 for mastoid ref
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',subID,'gui','on');
    EEG = pop_resample( EEG, 256);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',subID,'overwrite','on','gui','on');
   % EEG = pop_firws(EEG, 'fcutoff', [0.3 30], 'ftype', 'bandpass', 'wtype', 'hamming', 'warg', 5.65326, 'forder', 50, 'minphase', 0,'plotfresp',true);
   
    %different filter options within pop_firws = kaiser, hamming, blackman,
    %rectangular, hann

    %what is the 5.65326??
    % try overlap2 and overlap3 individually

    fs = EEG.srate;
    [b, a] = butter(1, [1, 30] / (fs / 2));
    fvtool(b, a); %this shows magnitude and phase response
    EEG.data = filtfilt(b, a, double(EEG.data'));
    EEG.data = EEG.data';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',[subID,'BPF'],'gui','on');
    
    
    % STOP TO CLEAN UP HERE

    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[subID, 'BPF CU'],'gui','on');
    % EEG=pop_chanedit(EEG, 'load',{'C:\Users\ema36\OneDrive\Documents\fNIRS&Gerbils\richardson_32_chanlocs.locs' 'filetype' 'locs'});
    EEG=pop_chanedit(EEG, 'load',{'/Users/victoriafigarola/Documents/1_CMU/Barb_Lab/Ben/richardson_32_chanlocs.locs' 'filetype' 'locs'});

    EEG = pop_runica(EEG, 'extended',1);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[subID, 'ICA'],'gui','on');

    pop_selectcomps(EEG, [1:32] );

  EEG = pop_saveset( EEG, 'filename','nooverlappilot_ICA3.set','filepath','/Users/victoriafigarola/Documents/1_CMU/Barb_Lab/Ben');
  [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

  eeglab redraw;


end


% SEM_of_masker = std(masker_frontocentral_erp_mean_over_electrodes,[],1)./sqrt(nsubjects-1);
% dy = SEM_of_masker';
% x = single_onset_time';
% op = 0.3;
% y = nanmean(masker_frontocentral_erp_mean_over_electrodes,1)';
% fill([x;flipud(x)],[y-dy;flipud(y+dy)],[0 0 1],'linestyle','none','facealpha',op);

% xlabel('Time (ms)')
% ylabel('Amplitude (normalized)')
% title('Average FrontoCentral ERP (baselined to 100ms before onset)','FontSize',18)
% legend([target_mean_plot(1),masker_mean_plot(1)],{'Target','Masker'})



