% Primary Authors: Victoria Figarola, Benjamin Richardson 7/21/23
% Secondary Authors: Emaya Anand, Maanasa Guru Adimurthy
% PREPROCESSING for Scrambled Speech Project
%tak22ing raw BDF file and saving it at .set file
% order = preprocessing, epoch, postprocessing, multsubjects
%-------------------------------------------------------------------------------------------------------------------

subID = '7040'; % Set current subject ID
% Excel sheet parameters
range_A = 'A40'; % Excel sheet 
range_B = 'B40';
badchannels = 'channelsremoved.xlsx';
% Set directories
whos_using = 'Maa'; % Choose user for directory stuff
if whos_using == 'Ben'
    addpath('/home/ben/Documents/MATLAB/eeglab2023.1');
    pre_pro_epoched_data_folder = '/home/ben/Documents/GitHub/fNIRSandGerbils/prepro_epoched_data/';
    addpath(pre_pro_epoched_data_folder)
    BDF_filename = ['/home/ben/Downloads/', subID, '.bdf'];
elseif whos_using == 'Ema'
    addpath('C:\Users\ema36\OneDrive\Documents\MATLAB\eeglab2023.0');
    pre_pro_epoched_data_folder = 'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\prepro_epoched_data';
    addpath(pre_pro_epoched_data_folder)
    BDF_filename = ['C:\Users\ema36\OneDrive\Documents\LiMN Things\Gerbil BDFs\', subID, '.bdf'];
elseif whos_using == 'Bon'
    addpath('C:\Users\benri\Documents\eeglab2023.1');
    pre_pro_epoched_data_folder = 'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data\';
    addpath(pre_pro_epoched_data_folder)
    BDF_filename = ['C:\Users\benri\Downloads\', subID, '.bdf'];
elseif whos_using == 'Maa'
    addpath('C:\Users\maana\Documents\MATLAB\eeglab2023.0');
    pre_pro_epoched_data_folder = 'C:\Users\maana\Documents\GitHub\fNIRSandGerbils\prepro_epoched_data\';
    addpath(pre_pro_epoched_data_folder)
    BDF_filename = ['C:\Users\maana\Downloads\', subID, '.bdf'];
end



% Load in BDF files and Re-referencing to Externals (mastoids/earlobes)
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % load EEGLAB
EEG = pop_biosig(BDF_filename, 'ref', [33 34], 'blockepoch', 'off', 'refoptions', {'keepref', 'off'}); % load in data, set reference as channels 33, 34 (mastoids)
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');
EEG = eeg_checkset( EEG );

%removing extra channels
EEG = pop_select(EEG, 'nochannel', {'EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'gui', 'off');
EEG = eeg_checkset( EEG );
% 'A1','A2','A3','A4','A5','A6','A7','A8','A9','A10','A11','A12','A13','A14','A15','A16','A17','A18','A19','A20','A21','A22','A23','A24','A25','A26','A27','A28','A29','A30','A31','A32',

%adding in channel locations 
if whos_using == 'Ben'
    EEG=pop_chanedit(EEG, 'load',{'/home/ben/Documents/GitHub/fNIRSandGerbils/chan_locs_cart.txt', 'filetype', 'sfp'});
elseif whos_using == 'Ema'
    EEG=pop_chanedit(EEG, 'load',{'C:\Users\ema36\OneDrive\Documents\LiMN Things\fNIRSandGerbils\chan_locs_cart.txt', 'filetype', 'sfp'});
elseif whos_using == 'Bon'
    EEG=pop_chanedit(EEG, 'load',{'C:\Users\benri\Documents\GitHub\fNIRSandGerbils\chan_locs_cart.txt', 'filetype', 'sfp'});
elseif whos_using == 'Maa'
    EEG=pop_chanedit(EEG, 'load',{'C:\Users\maana\Documents\GitHub\fNIRSandGerbils\chan_locs_cart.txt', 'filetype', 'sfp'});
end


EEG = eeg_checkset( EEG );

%downsampling to 256 Hz
%EEG = pop_resample( EEG, 256);
%[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'gui', 'off');
%EEG = eeg_checkset( EEG );

%bandpass filter (order of 1)
fs = EEG.srate;
[b, a] = butter(1, [1, 30] / (fs / 2));
EEG.data = filtfilt(b, a, double(EEG.data')); 
EEG.data = EEG.data';
EEG = eeg_checkset( EEG );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'setname',[subID, 'Bandpassed'],'gui','on');

%Marking out very obvious artifacts - pause here and manually do it
disp('Clean Up Data Before Running ICA!');
eeglab redraw
pause
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname',[subID, 'artifactmarked'],'gui','on');
EEG = pop_saveset( EEG, 'filename', [subID , '_artifactmarked.set'], 'filepath', pre_pro_epoched_data_folder);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%Rejecting/Interpolate Bad Channels - make sure to save # of bad channels
%plot the graph
pop_spectopo(EEG, 1);
pause
channels_to_remove = input('Please enter a comma-separated list of channels indices to interpolate (ex. [1 2 3]):');
EEG = pop_interp(EEG, channels_to_remove, 'spherical');
numchannels_removed = size(channels_to_remove, 2);
writematrix(subID, badchannels, 'Sheet', 1,'Range', range_A);
writematrix(numchannels_removed, badchannels, 'Sheet', 1, 'Range', range_B);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'setname',[subID, 'Channels Removed'],'gui','on');
EEG = eeg_checkset( EEG );

% Running ICA
EEG = pop_runica(EEG, 'extended',1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'setname',[subID, 'ICA'],'gui','on');
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename', [subID , '_ICAcomponentsin.set'], 'filepath', pre_pro_epoched_data_folder);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = eeg_checkset( EEG );
pop_selectcomps(EEG,[1:size(EEG.icawinv,2)])
% Pause to select components
pause
%channels_to_remove = str2num(input('Please enter which components to remove:'));
components_to_remove = input('Please enter a comma-separated list of ICA components to remove (ex. [1,2,3]):');
EEG = pop_subcomp( EEG, components_to_remove, 0);
close
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'setname',[subID, 'ICA Cleaned'],'gui','on');
EEG = pop_saveset( EEG, 'filename', [subID , '_ICAcomponentsremoved.set'], 'filepath', pre_pro_epoched_data_folder);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%Saving Overall Pre-Processed Data
EEG = pop_saveset( EEG, 'filename', [subID , '_ICAdone.set'], 'filepath', pre_pro_epoched_data_folder);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

disp('Done');

eeglab redraw;



