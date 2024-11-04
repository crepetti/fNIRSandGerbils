% subjects are asked to identify (rather than detect). Words are still
% filtered such that there is little energetic masking in frequency to
% match with the gerbils.

%% TO DO NOTES 8-17:
% -  We need to save target onset word times separately, since they won't be
% aligned to tOnset anymore.
% - The GUI will now need to allow for color word selection.
% - how many color words should we place in the masker sound?
% - need to make sure these are 70 dB SPL ish when they come out of the RME
% - right now, masker stream does NOT include color words. Made it a bit
% too confusing
% - are these streams really separable? is that the point?

% WE'RE GOING WITH BOB
%% facts - it takes approx. 500ms for humans to process words
%%energetic masking control - scrambled (the MASKERS ARE SCRAMBLED NOT THE
%%TARGET WORDS)
%%informational masking - unscrambled
%%need to filter the energetic masking target words to not overlap in
%%frequency band

%%%TO DO BEFORE CAP DESIGN SUNDAY
% 15 seconds (closest you can get)
%Sunday = cap design and make the behavioral side of things

%%OK HERE'S ACTUAL CODE
%%path
% addpath('D:\Experiments\fNIRSandGerbils\unprocessed\bob_all')
% addpath('D:\Experiments\fNIRSandGerbils\unprocessed\bob_all_long')
% addpath('D:\Experiments\fNIRSandGerbils\unprocessed\mike_all')
% addpath('D:\Experiments\fNIRSandGerbils\stim\')
% addpath('D:\Experiments\fNIRSandGerbils\AuditoryToolbox')
% 
% addpath('D:\Experiments\fNIRSandGerbils\AuditoryToolbox');

addpath('/home/ben/Documents/GitHub/fNIRSandGerbils/unprocessed/bob_all')
addpath('/home/ben/Documents/GitHub/fNIRSandGerbils/unprocessed/bob_all_long')
addpath('/home/ben/Documents/GitHub/fNIRSandGerbils/unprocessed/mike_all')
addpath('/home/ben/Documents/GitHub/fNIRSandGerbils/stim/')
addpath('/home/ben/Documents/GitHub/fNIRSandGerbils/AuditoryToolbox')


%comment nonsense

%%make a master stream/control stream and variables
subjectID = input('Enter Subject ID Below: ', 's');

all_object_words = ["bag", "card", "chairs", "desks", "glove", "hat", "pen", "shoe", "sock", "spoons", "tables", "toy"];
all_color_words = ["blue", "green", "red", "white"];
all_words = ["bag", "card", "chairs", "desks", "glove", "hat", "pen", "shoe", "sock", "spoons", "tables", "toy", "blue", "green", "red", "white"];
numtotalwords = 40;
wordlength = 0.30; %length of sound file
fs = 44100;
overlap = 0;
trial = 1;
practicetrial = 1;
numtrials = 144;
numpracticetrials = 10;

conditionarray = [ones(1, numtrials/4), 2*ones(1, numtrials/4), 3*ones(1, numtrials/4), 4*ones(1, numtrials/4)];
conditionarray = randsample(conditionarray,numtrials);
for i = 1:length(conditionarray)
    if conditionarray(i) == 1 % scrambled diff talker
        scramblingarray(i) = 1;
        talkerarray(i) = 1;
        bob_or_mike(i) =  randi([0,1]);
    elseif conditionarray(i) == 2 % scrambled same talker
        scramblingarray(i) = 1;
        talkerarray(i) = 0;
        bob_or_mike(i) =  randi([0,1]);
    elseif conditionarray(i) == 3 % unscrambled diff talker
        scramblingarray(i) = 0;
        talkerarray(i) = 1;
        bob_or_mike(i) =  randi([0,1]);
    elseif conditionarray(i) == 4 % unscrambled same talker
        scramblingarray(i) = 0;
        talkerarray(i) = 0;
        bob_or_mike(i) =  randi([0,1]);
    end
end

% make arrays for practice 
practice_scramblingarray = [zeros(1, numpracticetrials/2), ones(1, numpracticetrials/2)];
practice_scramblingarray = randsample(practice_scramblingarray, numpracticetrials);
practice_talkerarray = [zeros(1, numpracticetrials/2), ones(1, numpracticetrials/2)];
practice_talkerarray = randsample(practice_talkerarray,numpracticetrials);
practice_bob_or_mike = [zeros(1, numpracticetrials/2), ones(1, numpracticetrials/2)];
practice_bob_or_mike = randsample(practice_bob_or_mike,numpracticetrials);

all_masker_word_order = strings(numtrials,numtotalwords);

% set rms
rmsset = 0.0356;
% generate folder
foldername = ['stim/s_',subjectID];
if ~isfolder(foldername) % if this folder already exists, we will overwrite those stimuli
    mkdir(foldername);
    mkdir([foldername,'/scrambled_same_talker']);
    mkdir([foldername,'/unscrambled_same_talker']);
    mkdir([foldername,'/scrambled_diff_talker']);
    mkdir([foldername,'/unscrambled_diff_talker']);
    mkdir([foldername,'/practice']);
elseif isfolder(foldername)
    delete(foldername);
    mkdir(foldername);
    mkdir([foldername,'/scrambled_same_talker']);
    mkdir([foldername,'/unscrambled_same_talker']);
    mkdir([foldername,'/scrambled_diff_talker']);
    mkdir([foldername,'/unscrambled_diff_talker']);
    mkdir([foldername,'/practice']);
end

%% Generate Practice Trials
while practicetrial <= numpracticetrials
    %% Create masker sound
    % Steps: 1) Choose words, 2) Filter at the word level, 3) Concatenate,
    % 4) Scramble if necessary
    randcolor = randi([3 5],1,1);
    nummasker = numtotalwords - randcolor;
    
    scramblingindex = practice_scramblingarray(practicetrial);
    talkerindex = practice_talkerarray(practicetrial);
    bob_or_mike_index = practice_bob_or_mike(practicetrial);

    %lets choose 15-17 masker words and 3-5 color words
    masker_words_to_use = randsample(all_object_words, nummasker, 'true'); %picking words from masker bucket and allowing multiple of the same word
    color_words_to_use = randsample(all_color_words,randcolor,'true'); %same for color words
    
    %mix them in a bucket and randomize them, sample without replacements showing up, but also randomizing so that color and masker words are mixed
    num_words_total = length(masker_words_to_use) + length(color_words_to_use);
    masker_word_order = randsample([masker_words_to_use, color_words_to_use], num_words_total, false);
    
    %% Duplicate Check
    %check for two words in a row (if color, do color, if masker, do masker)
    duplicateindex = 1;
    duplicatecheck = strings(1,numtotalwords);
    while duplicateindex <= numtotalwords - 3
        duplicatecheck(duplicateindex) = masker_word_order(duplicateindex);
        if duplicatecheck(duplicateindex) == masker_word_order(duplicateindex + 1)
            if ismember(duplicatecheck(duplicateindex), all_color_words) == 1
                masker_word_order(duplicateindex) = randsample(all_color_words(all_color_words ~= duplicatecheck(duplicateindex)), 1, 'false');
            elseif ismember(duplicatecheck(duplicateindex), all_object_words) == 1
                masker_word_order(duplicateindex) = randsample(all_object_words(all_object_words ~= duplicatecheck(duplicateindex)), 1, 'false');
            else
                duplicateindex = duplicateindex + 0;
            end
        end
        % make sure no color words are next to each other (if within two,
        % switch it with someone else
        if ismember(masker_word_order(duplicateindex), all_color_words) && ismember(masker_word_order(duplicateindex + 1), all_color_words)
            masker_word_order(duplicateindex + 1) = randsample(all_object_words,1,1);
        end
        if ismember(masker_word_order(duplicateindex), all_color_words) && ismember(masker_word_order(duplicateindex + 2), all_color_words)
            masker_word_order(duplicateindex + 2) = randsample(all_object_words,1,1);            
        end
        if ismember(masker_word_order(duplicateindex), all_color_words) && ismember(masker_word_order(duplicateindex + 3), all_color_words)
            masker_word_order(duplicateindex + 3) = randsample(all_object_words,1,1);          
        end
        duplicateindex = duplicateindex + 1;
        
    end
    % no color words in the first three words
    for ifirstcheck = 1:3
        if ismember(masker_word_order(ifirstcheck),all_color_words)
            masker_word_order(ifirstcheck) = randsample(all_object_words(all_object_words ~= masker_word_order(ifirstcheck)), 1, 'false');
        end
    end
    % no color words in the last three words
    
    for ilastcheck = num_words_total-3:num_words_total
        if ismember(masker_word_order(ilastcheck),all_color_words)
            masker_word_order(ilastcheck) = randsample(all_object_words(all_object_words ~= masker_word_order(ilastcheck)), 1, 'false');
        end
    end
    
    % load the small audio files, filter, level correct and then put into a larger array
    loadsoundindex = 1;
    soundArray = strings(1, numtotalwords);
    while loadsoundindex <= numtotalwords
        if bob_or_mike_index == 0
            word_filename = append('unprocessed/bob_all/',masker_word_order(loadsoundindex), '_short.wav');
        elseif bob_or_mike_index == 1
            word_filename = append('unprocessed/mike_all/',masker_word_order(loadsoundindex), '_short.wav');
        end
        soundArray(loadsoundindex) = word_filename;
        loadsoundindex = loadsoundindex + 1;
    end
    
    %overlap the sounds
    tOnset = 0:wordlength-overlap:(wordlength-overlap)*numtotalwords;
    tVec = 0:1/fs:(wordlength*numtotalwords) - (overlap*(numtotalwords-1)); %1/fs = seconds per sample
    newtotalSound = zeros(length(tVec), 1);
    newTargetSound = zeros(length(tVec), 1);
    newMaskerSound = zeros(length(tVec), 1);
    iOnset = 1;
    while iOnset <= numtotalwords
        [y,fs] = audioread(soundArray(iOnset)); % load this word
        filtered_word = zeros(length(y),1);
        % filter this word

        %making the filter
        numfilters = 16; %go between like 2 and 16
        order = 9; %go between like 2 and 10
        edges = logspace(log10(300), log10(10000), numfilters + 1);

        for iFilter = 1:numfilters
            lowedge = edges(iFilter);
            highedge = edges(iFilter + 1);
            %n = order of filter (sharp/shallow)
            %Wn = normalized frequency
            [bLow, aLow] = butter(order, highedge/(fs/2), 'low');
            [bHigh, aHigh] = butter(order, lowedge/(fs/2), 'high');
            thisFilteredSound = zeros(1, length(y));
            if mod(iFilter,2) == 1
                thisFilteredSound = filter(bLow, aLow, y);
                thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
                filtered_word = filtered_word + thisFilteredSound;
            elseif mod(iFilter,2) == 0
                thisFilteredSound = filter(bLow, aLow, y);
                thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
                filtered_word = filtered_word + thisFilteredSound;
            end
        end

        % level correct this word
        filtered_word = filtered_word * rmsset/rms(filtered_word);


        % add this word to the array newMaskerSound

        curr_tOnset = tOnset(iOnset);
        [~,start_index] = min(abs(tVec - curr_tOnset));
        [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
        newMaskerSound(start_index:stop_index - 1) = newMaskerSound(start_index:stop_index - 1) + filtered_word;
        %find the closest values for onset time and onset time + 300 ms
        %    [~,start_index] = min(abs(tVec - curr_tOnset));
        %    [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
        %    newtotalSound(start_index:stop_index - 1) = newtotalSound(start_index:stop_index - 1) + y;
        iOnset = iOnset + 1;
    end
    
    %% Scramble masker sound if necessary
    % find envelope first (half wave rectify, low pass filter at 125 Hz)
    this_masker_envelope = newMaskerSound;
    this_masker_envelope(this_masker_envelope < 0) = 0;
    [b,a] = butter(4,125/fs);
    this_masker_envelope = filter(b,a,this_masker_envelope)';
    if (scramblingindex == 1)
        newMaskerSound = scrambling(newMaskerSound, fs);
    end
    newMaskerSound = newMaskerSound'; % transpose the array

    %% Amplitude modulate masker sound if necessary
    rms_before_AM = rms(newMaskerSound);
    if scramblingindex == 1
        newMaskerSound = newMaskerSound.*this_masker_envelope;
    end
    rms_after_AM = rms(newMaskerSound);
    newMaskerSound = newMaskerSound*(rmsset/rms(newMaskerSound));
    

    %% Create target sound
    % STEPS: 1) Choose words, 2) Filter at the word level 3) Concatenate

    % choose 6-7 words in the target sound. Between 3-5 of them will be
    % color words
    start_time = tOnset(1) + 1;
    end_time = tOnset(end) - wordlength;
    num_target_color_words = randsample([3,4,5],1);
    num_target_object_words = num_target_color_words; % always half and half colors and objects
    num_target_words = num_target_color_words + num_target_object_words;
    target_onsets = (end_time-start_time).*rand(num_target_words,1) + start_time; % choose target word onset times, making sure they are at least 1 second apart and at least wordlength before the end of stimulus
    target_onsets = sort(target_onsets);
    % target words will be prohibited from being 50 ms on either side of a masker word onset
    tOnset_low = tOnset - 0.08;
    tOnset_high = tOnset + 0.08;
    onset_flag = 0;
    for itarget = 1:length(target_onsets)
        if any(logical((tOnset_low <= target_onsets(itarget)).*(target_onsets(itarget) <= tOnset_high)))
            onset_flag = 1;
        end
    end
    while any(abs(diff(target_onsets)) < 0.8) 
        target_onsets = (end_time-start_time).*rand(num_target_words,1) + start_time;     % make sure target onset times are at least 1 second apart
        target_onsets = sort(target_onsets);

        onset_flag = 0;
        for itarget = 1:length(target_onsets)
            if any(logical((tOnset_low <= target_onsets(itarget)).*(target_onsets(itarget) <= tOnset_high)))
                onset_flag = 1;
            end
        end
    end

    target_color_word_order = randsample(all_color_words,num_target_color_words,'true'); % choose target words
    target_object_word_order = randsample(all_object_words,num_target_object_words,'true');
    target_word_order = [target_color_word_order,target_object_word_order];
    target_word_order = target_word_order(randperm(length(target_word_order)));

    % ensure target word is never near the same word in the masker sound
    for i = 1:length(target_word_order)
        % find the closest word in final word order
        [~,masker_word_index] = min(abs(tOnset - target_onsets(i)));
        if target_word_order(i) == masker_word_order(masker_word_index) && ismember(target_word_order(i),all_color_words)
            target_word_order(i) = randsample(all_color_words(all_color_words ~= target_word_order(i)),1);
        elseif target_word_order(i) == masker_word_order(masker_word_index) && ismember(target_word_order(i),all_object_words)
            target_word_order(i) = randsample(all_object_words(all_object_words ~= target_word_order(i)),1);
        end
    end


    for i = 1:length(target_onsets)
        if bob_or_mike_index == 0 && talkerindex == 0 % bob background, same talker
            word_filename = append('unprocessed/bob_all/',target_word_order(i), '_short.wav');
        elseif bob_or_mike_index == 0 && talkerindex == 1 % bob background, diff talker
            word_filename = append('unprocessed/mike_all/',target_word_order(i), '_short.wav');
        elseif bob_or_mike_index == 1 && talkerindex == 0 % mike background, same talker
            word_filename = append('unprocessed/mike_all/',target_word_order(i), '_short.wav');
        elseif bob_or_mike_index == 1 && talkerindex == 1 % mike background, diff talker            
            word_filename = append('unprocessed/bob_all/',target_word_order(i), '_short.wav');
        end
        [y,fs] = audioread(word_filename);
        filtered_word = zeros(length(y),1);
        %making the filter
        numfilters = 16; %go between like 2 and 16
        order = 9; %go between like 2 and 10
        edges = logspace(log10(300), log10(10000), numfilters + 1);

        % Filter this word (opposite filters from masker)

        for iFilter = 1:numfilters
            lowedge = edges(iFilter);
            highedge = edges(iFilter + 1);
            %n = order of filter (sharp/shallow)
            %Wn = normalized frequency
            [bLow, aLow] = butter(order, highedge/(fs/2), 'low');
            [bHigh, aHigh] = butter(order, lowedge/(fs/2), 'high');
            thisFilteredSound = zeros(1, length(y));
            if mod(iFilter,2) == 0
                thisFilteredSound = filter(bLow, aLow, y);
                thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
                filtered_word = filtered_word + thisFilteredSound;
            elseif mod(iFilter,2) == 1
                thisFilteredSound = filter(bLow, aLow, y);
                thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
                filtered_word = filtered_word + thisFilteredSound;
            end
        end

        % Level set this word
        filtered_word = filtered_word * rmsset/rms(filtered_word);

        % Add to larger array
        [~,ionset] = min(abs(tVec - target_onsets(i)));
        newTargetSound(ionset:ionset + length(filtered_word) -1) = filtered_word;
    end
    

    this_foldername = [foldername,'/practice'];
    audiofilename = [this_foldername,'/',num2str(practicetrial),'_practice', '.wav'];
    output = newTargetSound' + newMaskerSound;
    output = output * rmsset/rms(output);
    audiowrite(audiofilename, output, fs);
    disp(audiofilename)
    
    practicetrial = practicetrial + 1;
end

%% Generate Experiment Trials
while trial <= numtrials

    %% Create masker sound
    % Steps: 1) Choose words, 2) Filter at the word level, 3) Concatenate,
    % 4) Scramble if necessary
    randcolor = randi([3 5],1,1);
    nummasker = numtotalwords - randcolor;
    
    scramblingindex = scramblingarray(trial);
    talkerindex = talkerarray(trial);
    bob_or_mike_index = bob_or_mike(trial);

    %lets choose 15-17 masker words and 3-5 color words
    masker_words_to_use = randsample(all_object_words, nummasker, 'true'); %picking words from masker bucket and allowing multiple of the same word
    color_words_to_use = randsample(all_color_words,randcolor,'true'); %same for color words
    
    %mix them in a bucket and randomize them, sample without replacements showing up, but also randomizing so that color and masker words are mixed
    num_words_total = length(masker_words_to_use) + length(color_words_to_use);
    masker_word_order = randsample([masker_words_to_use, color_words_to_use], num_words_total, false);
    
    %% Duplicate Check
    %check for two words in a row (if color, do color, if masker, do masker)
    duplicateindex = 1;
    duplicatecheck = strings(1,numtotalwords);
    while duplicateindex <= numtotalwords - 3
        duplicatecheck(duplicateindex) = masker_word_order(duplicateindex);
        if duplicatecheck(duplicateindex) == masker_word_order(duplicateindex + 1)
            if ismember(duplicatecheck(duplicateindex), all_color_words) == 1
                masker_word_order(duplicateindex) = randsample(all_color_words(all_color_words ~= duplicatecheck(duplicateindex)), 1, 'false');
            elseif ismember(duplicatecheck(duplicateindex), all_object_words) == 1
                masker_word_order(duplicateindex) = randsample(all_object_words(all_object_words ~= duplicatecheck(duplicateindex)), 1, 'false');
            else
                duplicateindex = duplicateindex + 0;
            end
        end
        % make sure no color words are next to each other (if within two,
        % switch it with someone else
        if ismember(masker_word_order(duplicateindex), all_color_words) && ismember(masker_word_order(duplicateindex + 1), all_color_words)
            masker_word_order(duplicateindex + 1) = randsample(all_object_words,1,1);
        end
        if ismember(masker_word_order(duplicateindex), all_color_words) && ismember(masker_word_order(duplicateindex + 2), all_color_words)
            masker_word_order(duplicateindex + 2) = randsample(all_object_words,1,1);            
        end
        if ismember(masker_word_order(duplicateindex), all_color_words) && ismember(masker_word_order(duplicateindex + 3), all_color_words)
            masker_word_order(duplicateindex + 3) = randsample(all_object_words,1,1);          
        end
        duplicateindex = duplicateindex + 1;
        
    end
    % no color words in the first three words
    for ifirstcheck = 1:3
        if ismember(masker_word_order(ifirstcheck),all_color_words)
            masker_word_order(ifirstcheck) = randsample(all_object_words(all_object_words ~= masker_word_order(ifirstcheck)), 1, 'false');
        end
    end
    % no color words in the last three words
    
    for ilastcheck = num_words_total-3:num_words_total
        if ismember(masker_word_order(ilastcheck),all_color_words)
            masker_word_order(ilastcheck) = randsample(all_object_words(all_object_words ~= masker_word_order(ilastcheck)), 1, 'false');
        end
    end

    % load the small audio files, filter, level correct and then put into a larger array
    loadsoundindex = 1;
    soundArray = strings(1, numtotalwords);
    while loadsoundindex <= numtotalwords
        if bob_or_mike_index == 0
            word_filename = append('unprocessed/bob_all/',masker_word_order(loadsoundindex), '_short.wav');
        elseif bob_or_mike_index == 1
            word_filename = append('unprocessed/mike_all/',masker_word_order(loadsoundindex), '_short.wav');
        end
        soundArray(loadsoundindex) = word_filename;
        loadsoundindex = loadsoundindex + 1;
    end
    
    %overlap the sounds
    tOnset = 0:wordlength-overlap:(wordlength-overlap)*numtotalwords;
    tVec = 0:1/fs:(wordlength*numtotalwords) - (overlap*(numtotalwords-1)); %1/fs = seconds per sample
    newtotalSound = zeros(length(tVec), 1);
    newTargetSound = zeros(length(tVec), 1);
    newMaskerSound = zeros(length(tVec), 1);
    iOnset = 1;
    while iOnset <= numtotalwords
        [y,fs] = audioread(soundArray(iOnset)); % load this word
        filtered_word = zeros(length(y),1);
        % filter this word

        %making the filter
        numfilters = 16; %go between like 2 and 16
        order = 9; %go between like 2 and 10
        edges = logspace(log10(300), log10(10000), numfilters + 1);

        for iFilter = 1:numfilters
            lowedge = edges(iFilter);
            highedge = edges(iFilter + 1);
            %n = order of filter (sharp/shallow)
            %Wn = normalized frequency
            [bLow, aLow] = butter(order, highedge/(fs/2), 'low');
            [bHigh, aHigh] = butter(order, lowedge/(fs/2), 'high');
            thisFilteredSound = zeros(1, length(y));
            if mod(iFilter,2) == 1
                thisFilteredSound = filter(bLow, aLow, y);
                thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
                filtered_word = filtered_word + thisFilteredSound;
            elseif mod(iFilter,2) == 0
                thisFilteredSound = filter(bLow, aLow, y);
                thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
                filtered_word = filtered_word + thisFilteredSound;
            end
        end

        % level correct this word
        filtered_word = filtered_word * rmsset/rms(filtered_word);


        % add this word to the array newMaskerSound

        curr_tOnset = tOnset(iOnset);
        [~,start_index] = min(abs(tVec - curr_tOnset));
        [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
        newMaskerSound(start_index:stop_index - 1) = newMaskerSound(start_index:stop_index - 1) + filtered_word;
        %find the closest values for onset time and onset time + 300 ms
        %    [~,start_index] = min(abs(tVec - curr_tOnset));
        %    [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
        %    newtotalSound(start_index:stop_index - 1) = newtotalSound(start_index:stop_index - 1) + y;
        iOnset = iOnset + 1;
    end
    
    %% Scramble masker sound if necessary
    this_masker_envelope = newMaskerSound;
    this_masker_envelope(this_masker_envelope < 0) = 0;
    [b,a] = butter(4,125/fs);
    this_masker_envelope = filter(b,a,this_masker_envelope)';
    if (scramblingindex == 1)
        newMaskerSound = scrambling(newMaskerSound, fs);
    end
    newMaskerSound = newMaskerSound'; % transpose the array
    
    %% Amplitude modulate masker sound if necessary
    rms_before_AM = rms(newMaskerSound);
    if scramblingindex == 1
        newMaskerSound = newMaskerSound.*this_masker_envelope;
    end
    rms_after_AM = rms(newMaskerSound);
    newMaskerSound = newMaskerSound*(rmsset/rms(newMaskerSound));
    
    %% Create target sound
    % STEPS: 1) Choose words, 2) Filter at the word level 3) Concatenate

    % choose 6-7 words in the target sound. Between 3-5 of them will be
    % color words
    start_time = tOnset(1) + 1;
    end_time = tOnset(end) - wordlength;
    num_target_color_words = randsample([3,4,5],1);
    num_target_object_words = num_target_color_words; % always half and half colors and objects
    num_target_words = num_target_color_words + num_target_object_words;
    target_onsets = (end_time-start_time).*rand(num_target_words,1) + start_time; % choose target word onset times, making sure they are at least 1 second apart and at least wordlength before the end of stimulus
    target_onsets = sort(target_onsets);
    % target words will be prohibited from being 50 ms on either side of a masker word onset
    tOnset_low = tOnset - 0.08;
    tOnset_high = tOnset + 0.08;
    onset_flag = 0;
    for itarget = 1:length(target_onsets)
        if any(logical((tOnset_low <= target_onsets(itarget)).*(target_onsets(itarget) <= tOnset_high)))
            onset_flag = 1;
        end
    end
    while any(abs(diff(target_onsets)) < 0.8) 
        target_onsets = (end_time-start_time).*rand(num_target_words,1) + start_time;     % make sure target onset times are at least 1 second apart
        target_onsets = sort(target_onsets);

        onset_flag = 0;
        for itarget = 1:length(target_onsets)
            if any(logical((tOnset_low <= target_onsets(itarget)).*(target_onsets(itarget) <= tOnset_high)))
                onset_flag = 1;
            end
        end
    end

    target_color_word_order = randsample(all_color_words,num_target_color_words,'true'); % choose target words
    target_object_word_order = randsample(all_object_words,num_target_object_words,'true');
    target_word_order = [target_color_word_order,target_object_word_order];
    target_word_order = target_word_order(randperm(length(target_word_order)));


    % disp('Number of Target Words Total')
    % disp(length(target_word_order))
    % disp('Number of Target Color Words')
    % disp(sum(ismember(target_word_order,all_color_words)))

    % ensure target word is never near the same word in the masker sound
    for i = 1:length(target_word_order)
        % find the closest word in final word order
        [~,masker_word_index] = min(abs(tOnset - target_onsets(i)));
        if target_word_order(i) == masker_word_order(masker_word_index) && ismember(target_word_order(i),all_color_words)
            target_word_order(i) = randsample(all_color_words(all_color_words ~= target_word_order(i)),1);
        elseif target_word_order(i) == masker_word_order(masker_word_index) && ismember(target_word_order(i),all_object_words)
            target_word_order(i) = randsample(all_object_words(all_object_words ~= target_word_order(i)),1);
        end
    end


    for i = 1:length(target_onsets)
        if bob_or_mike_index == 0 && talkerindex == 0 % bob background, same talker
            word_filename = append('unprocessed/bob_all/',target_word_order(i), '_short.wav');
        elseif bob_or_mike_index == 0 && talkerindex == 1 % bob background, diff talker
            word_filename = append('unprocessed/mike_all/',target_word_order(i), '_short.wav');
        elseif bob_or_mike_index == 1 && talkerindex == 0 % mike background, same talker
            word_filename = append('unprocessed/mike_all/',target_word_order(i), '_short.wav');
        elseif bob_or_mike_index == 1 && talkerindex == 1 % mike background, diff talker            
            word_filename = append('unprocessed/bob_all/',target_word_order(i), '_short.wav');
        end
        [y,fs] = audioread(word_filename);
        filtered_word = zeros(length(y),1);
        %making the filter
        numfilters = 16; %go between like 2 and 16
        order = 9; %go between like 2 and 10
        edges = logspace(log10(300), log10(10000), numfilters + 1);

        % Filter this word (opposite filters from masker)

        for iFilter = 1:numfilters
            lowedge = edges(iFilter);
            highedge = edges(iFilter + 1);
            %n = order of filter (sharp/shallow)
            %Wn = normalized frequency
            [bLow, aLow] = butter(order, highedge/(fs/2), 'low');
            [bHigh, aHigh] = butter(order, lowedge/(fs/2), 'high');
            thisFilteredSound = zeros(1, length(y));
            if mod(iFilter,2) == 0
                thisFilteredSound = filter(bLow, aLow, y);
                thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
                filtered_word = filtered_word + thisFilteredSound;
            elseif mod(iFilter,2) == 1
                thisFilteredSound = filter(bLow, aLow, y);
                thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
                filtered_word = filtered_word + thisFilteredSound;
            end
        end

        % Level set this word
        filtered_word = filtered_word * rmsset/rms(filtered_word);

        % Add to larger array
        [~,ionset] = min(abs(tVec - target_onsets(i)));
        newTargetSound(ionset:ionset + length(filtered_word) -1) = filtered_word;
    end

   
    if scramblingindex == 0 && talkerindex == 0 % unscrambled same talker
        this_foldername = [foldername,'/unscrambled_same_talker'];
        audiofilename = [this_foldername,'/',num2str(trial),'_unscrambled_st', '.wav'];
        output = newTargetSound' + newMaskerSound;
        output = repmat(output,2,1)';
        % Trigger = 1 0 0
        trigger_channel_3 = zeros(size(output(:,1)));
        trigger_channel_4 = zeros(size(output(:,1)));
        trigger_channel_5 = zeros(size(output(:,1)));
        trigger_channel_3(1)= 1;
        output = cat(2,output,trigger_channel_3,trigger_channel_4,trigger_channel_5);
        audiowrite(audiofilename, output, fs);
        audiowrite(audiofilename, output, fs);
        disp(audiofilename)
    elseif scramblingindex == 1 && talkerindex == 0 % scrambled same talker
        this_foldername = [foldername,'/scrambled_same_talker'];
        audiofilename = [this_foldername,'/',num2str(trial),'_scrambled_st', '.wav'];
        output = newTargetSound' + newMaskerSound;
        output = repmat(output,2,1)';
        % Trigger = 0 1 0 
        trigger_channel_3 = zeros(size(output(:,1)));
        trigger_channel_4 = zeros(size(output(:,1)));
        trigger_channel_5 = zeros(size(output(:,1)));
        trigger_channel_3(1) = 1;
        output = cat(2,output,trigger_channel_3,trigger_channel_4,trigger_channel_5);
        audiowrite(audiofilename, output, fs);
        audiowrite(audiofilename, output, fs);
        disp(audiofilename)
    elseif scramblingindex == 0 && talkerindex == 1 % unscrambled diff talker
        this_foldername = [foldername,'/unscrambled_diff_talker'];
        audiofilename = [this_foldername,'/',num2str(trial),'_unscrambled_dt', '.wav'];
        output = newTargetSound' + newMaskerSound;
        output = repmat(output,2,1)';
        % Trigger = 0 1 1
        trigger_channel_3 = zeros(size(output(:,1)));
        trigger_channel_4 = zeros(size(output(:,1)));
        trigger_channel_5 = zeros(size(output(:,1)));
        trigger_channel_3(1) = 1;
        output = cat(2,output,trigger_channel_3,trigger_channel_4,trigger_channel_5);
        audiowrite(audiofilename, output, fs);
        audiowrite(audiofilename, output, fs);
        disp(audiofilename)
    elseif scramblingindex == 1 && talkerindex == 1 % scrambled diff talker
        this_foldername = [foldername,'/scrambled_diff_talker'];
        audiofilename = [this_foldername,'/',num2str(trial),'_scrambled_dt', '.wav'];
        output = newTargetSound' + newMaskerSound;
        output = repmat(output,2,1)';
        % Trigger = 1 0 1
        trigger_channel_3 = zeros(size(output(:,1)));
        trigger_channel_4 = zeros(size(output(:,1)));
        trigger_channel_5 = zeros(size(output(:,1)));
        trigger_channel_3(1) = 1;
        output = cat(2,output,trigger_channel_3,trigger_channel_4,trigger_channel_5);
        audiowrite(audiofilename, output, fs);
        audiowrite(audiofilename, output, fs);
        disp(audiofilename)
    end
    
    num_color_words_this_trial = sum(ismember(target_word_order,all_color_words));
    if num_color_words_this_trial < 3
        trial = trial;
    else
        all_masker_word_order(trial,:) = masker_word_order;
        all_target_onsets(trial).onsets = target_onsets;
        all_target_words(trial).words = target_word_order;
        trial = trial + 1;
    end
    
end

save([foldername, '/', subjectID, '_alltrialwords.mat'], 'all_masker_word_order','tOnset','all_target_words','all_target_onsets','scramblingarray','talkerarray','bob_or_mike');
disp('All Done!')

