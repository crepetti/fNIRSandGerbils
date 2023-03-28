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
addpath('C:\Users\benri\Nextcloud\Python\stim\bobmike\unprocessed\bob_all');
addpath('C:\Users\benri\Documents\GitHub\fNIRSandGerbils\AuditoryToolbox');

%%make a master stream/control stream and variables
subjectID = input('Enter Subject ID Below: ', 's');

all_masker_words = ["bag", "card", "chairs", "desks", "glove", "hat", "pen", "shoe", "sock", "spoons", "tables", "toy"];
all_color_words = ["blue", "green", "red", "white"];
all_words = ["bag", "card", "chairs", "desks", "glove", "hat", "pen", "shoe", "sock", "spoons", "tables", "toy", "blue", "green", "red", "white"];
numtotalwords = 30;
wordlength = 0.30; %length of sound file
fs = 44100;
overlap = 0.1;
trial = 1;
practicetrial = 1;
numtrials = 48;
numpracticetrials = 10;
scramblingarray = [zeros(1, numtrials/2), ones(1, numtrials/2)];
scramblingarray = randsample(scramblingarray, numtrials);
all_word_order = strings(numtrials,numtotalwords);

% generate folder
foldername = ['stim/s_',subjectID];
if ~isfolder(foldername) % if this folder already exists, we will overwrite those stimuli
    mkdir(foldername);
    mkdir([foldername,'/scrambled']);
    mkdir([foldername,'/unscrambled']);
    mkdir([foldername,'/practice']);
elseif isfolder(foldername)
    delete(foldername);
    mkdir(foldername);
    mkdir([foldername,'/scrambled']);
    mkdir([foldername,'/unscrambled']);
    mkdir([foldername,'/practice']);
end

%% Generate Practice Trials
while practicetrial <= numpracticetrials
    randcolor = randi([3 5],1,1);
    nummasker = numtotalwords - randcolor;

    masker_words_to_use = randsample(all_masker_words, nummasker, 'true'); %picking words from masker bucket and allowing multiple of the same word
    color_words_to_use = randsample(all_color_words,randcolor,'true'); %same for color words

    %mix them in a bucket and randomize them, sample without replacements showing up, but also randomizing so that color and masker words are mixed
    num_words_total = length(masker_words_to_use) + length(color_words_to_use);
    final_word_order = randsample([masker_words_to_use, color_words_to_use], num_words_total, false);

    %check for two words in a row (if color, do color, if masker, do masker)
    duplicateindex = 1;
    duplicatecheck = strings(1,numtotalwords);
    while duplicateindex <= numtotalwords - 1
        duplicatecheck(duplicateindex) = final_word_order(duplicateindex);
        if duplicatecheck(duplicateindex) == final_word_order(duplicateindex + 1)
            if ismember(duplicatecheck(duplicateindex), all_color_words) == 1
                final_word_order(duplicateindex) = randsample(all_color_words(all_color_words ~= duplicatecheck(duplicateindex)), 1, 'false');
            elseif ismember(duplicatecheck(duplicateindex), all_masker_words) == 1
                final_word_order(duplicateindex) = randsample(all_masker_words(all_masker_words ~= duplicatecheck(duplicateindex)), 1, 'false');
            else
                duplicateindex = duplicateindex + 0;
            end
        end
        duplicateindex = duplicateindex + 1;
    end

    % load the audio file and put into a larger array
    loadsoundindex = 1;
    soundArray = strings(1, numtotalwords);
    while loadsoundindex <= numtotalwords
        word_filename = append(final_word_order(loadsoundindex), '_short.wav');
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
        [y,fs] = audioread(soundArray(iOnset));
        curr_tOnset = tOnset(iOnset);
        %adds to target sound array
        if ismember(final_word_order(iOnset), all_color_words)
            [~,start_index] = min(abs(tVec - curr_tOnset));
            [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
            newTargetSound(start_index:stop_index - 1) = newTargetSound(start_index:stop_index - 1) + y;
            %adds to masker sound array
        elseif ismember(final_word_order(iOnset), all_masker_words)
            [~,start_index] = min(abs(tVec - curr_tOnset));
            [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
            newMaskerSound(start_index:stop_index - 1) = newMaskerSound(start_index:stop_index - 1) + y;
        else
            disp("uh oh!")
        end
        %find the closest values for onset time and onset time + 300 ms
        %    [~,start_index] = min(abs(tVec - curr_tOnset));
        %    [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
        %    newtotalSound(start_index:stop_index - 1) = newtotalSound(start_index:stop_index - 1) + y;
        iOnset = iOnset + 1;
    end

    newMaskerSound = newMaskerSound'; % transpose the array

    %making the filter
    numfilters = 16; %go between like 2 and 16
    order = 9; %go between like 2 and 10
    edges = logspace(log10(300), log10(10000), numfilters + 1);
    newMaskerFiltered = zeros(1, length(tVec));
    newTargetFiltered = zeros(1, length(tVec));

    for iFilter = 1:numfilters
        lowedge = edges(iFilter);
        highedge = edges(iFilter + 1);
        %n = order of filter (sharp/shallow)
        %Wn = normalized frequency
        [bLow, aLow] = butter(order, highedge/(fs/2), 'low');
        [bHigh, aHigh] = butter(order, lowedge/(fs/2), 'high');
        thisFilteredSound = zeros(1, length(tVec));
        if mod(iFilter,2) == 1
            thisFilteredSound = filter(bLow, aLow, newMaskerSound);
            thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
            newMaskerFiltered = newMaskerFiltered + thisFilteredSound;
        elseif mod(iFilter,2) == 0
            thisFilteredSound = filter(bLow, aLow, newTargetSound)';
            thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
            newTargetFiltered = newTargetFiltered + thisFilteredSound;
        end
    end

    this_foldername = [foldername,'/practice'];
    audiofilename = [this_foldername,'/',num2str(practicetrial),'_practice', '.wav'];
    audiowrite(audiofilename, newTargetFiltered + newMaskerFiltered, fs);
    disp(audiofilename)

    practicetrial = practicetrial + 1;
end

%% Generate Experiment Trials
while trial <= numtrials
    randcolor = randi([3 5],1,1);
    nummasker = numtotalwords - randcolor;

    scramblingindex = scramblingarray(trial);
    %lets choose 15-17 masker words and 3-5 color words
    masker_words_to_use = randsample(all_masker_words, nummasker, 'true'); %picking words from masker bucket and allowing multiple of the same word
    color_words_to_use = randsample(all_color_words,randcolor,'true'); %same for color words

    %mix them in a bucket and randomize them, sample without replacements showing up, but also randomizing so that color and masker words are mixed
    num_words_total = length(masker_words_to_use) + length(color_words_to_use);
    final_word_order = randsample([masker_words_to_use, color_words_to_use], num_words_total, false);

    %check for two words in a row (if color, do color, if masker, do masker)
    duplicateindex = 1;
    duplicatecheck = strings(1,numtotalwords);
    while duplicateindex <= numtotalwords - 3
        duplicatecheck(duplicateindex) = final_word_order(duplicateindex);
        if duplicatecheck(duplicateindex) == final_word_order(duplicateindex + 1)
            if ismember(duplicatecheck(duplicateindex), all_color_words) == 1
                final_word_order(duplicateindex) = randsample(all_color_words(all_color_words ~= duplicatecheck(duplicateindex)), 1, 'false');
            elseif ismember(duplicatecheck(duplicateindex), all_masker_words) == 1
                final_word_order(duplicateindex) = randsample(all_masker_words(all_masker_words ~= duplicatecheck(duplicateindex)), 1, 'false');
            else
                duplicateindex = duplicateindex + 0;
            end
        end
        % make sure no color words are next to each other (if within two,
        % switch it with someone else
        if ismember(final_word_order(duplicateindex), all_color_words) && ismember(final_word_order(duplicateindex + 1), all_color_words)
            possible_new_indices = 1:num_words_total;
            possible_new_indices(possible_new_indices == duplicateindex) = [];
            possible_new_indices(possible_new_indices == duplicateindex + 2) = [];
            possible_new_indices(possible_new_indices == duplicateindex + 3) = [];
            possible_new_indices(possible_new_indices == duplicateindex - 1) = [];            
            possible_new_indices(possible_new_indices == duplicateindex - 2) = [];
            possible_new_indices(possible_new_indices == duplicateindex - 3) = [];              

            new_index = randsample(possible_new_indices,1);
            old_word = final_word_order(new_index);
            while ismember(old_word,all_color_words)
                new_index = randsample(possible_new_indices,1);
                old_word = final_word_order(new_index);
            end
            final_word_order(new_index) = final_word_order(duplicateindex);
            final_word_order(duplicateindex) = old_word;
        end
        if ismember(final_word_order(duplicateindex), all_color_words) && ismember(final_word_order(duplicateindex + 2), all_color_words)
            possible_new_indices = 1:num_words_total;
            possible_new_indices(possible_new_indices == duplicateindex) = [];
            possible_new_indices(possible_new_indices == duplicateindex + 2) = [];
            possible_new_indices(possible_new_indices == duplicateindex + 3) = [];
            possible_new_indices(possible_new_indices == duplicateindex - 1) = [];            
            possible_new_indices(possible_new_indices == duplicateindex - 2) = [];
            possible_new_indices(possible_new_indices == duplicateindex - 3) = [];              

            new_index = randsample(possible_new_indices,1);
            old_word = final_word_order(new_index);
            while ismember(old_word,all_color_words)
                new_index = randsample(possible_new_indices,1);
                old_word = final_word_order(new_index);
            end
            final_word_order(new_index) = final_word_order(duplicateindex);
            final_word_order(duplicateindex) = old_word;
        end
        if ismember(final_word_order(duplicateindex), all_color_words) && ismember(final_word_order(duplicateindex + 3), all_color_words)
            possible_new_indices = 1:num_words_total;
            possible_new_indices(possible_new_indices == duplicateindex) = [];
            possible_new_indices(possible_new_indices == duplicateindex + 2) = [];
            possible_new_indices(possible_new_indices == duplicateindex + 3) = [];
            possible_new_indices(possible_new_indices == duplicateindex - 1) = [];            
            possible_new_indices(possible_new_indices == duplicateindex - 2) = [];
            possible_new_indices(possible_new_indices == duplicateindex - 3) = [];   

            new_index = randsample(possible_new_indices,1);
            old_word = final_word_order(new_index);
            while ismember(old_word,all_color_words)
                new_index = randsample(possible_new_indices,1);
                old_word = final_word_order(new_index);
            end
            final_word_order(new_index) = final_word_order(duplicateindex);
            final_word_order(duplicateindex) = old_word;
        end
        duplicateindex = duplicateindex + 1;
    end
    % no color words in the last three words

    for ilastcheck = num_words_total-3:num_words_total
        if ismember(final_word_order(ilastcheck),all_color_words)
                final_word_order(ilastcheck) = randsample(all_masker_words(all_masker_words ~= final_word_order(ilastcheck)), 1, 'false');
        end
    end
    % make sure no color words are next to each other

    % load the audio file and put into a larger array
    loadsoundindex = 1;
    soundArray = strings(1, numtotalwords);
    while loadsoundindex <= numtotalwords
        word_filename = append(final_word_order(loadsoundindex), '_short.wav');
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
        [y,fs] = audioread(soundArray(iOnset));
        curr_tOnset = tOnset(iOnset);
        %adds to target sound array
        if ismember(final_word_order(iOnset), all_color_words)
            [~,start_index] = min(abs(tVec - curr_tOnset));
            [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
            newTargetSound(start_index:stop_index - 1) = newTargetSound(start_index:stop_index - 1) + y;
            %adds to masker sound array
        elseif ismember(final_word_order(iOnset), all_masker_words)
            [~,start_index] = min(abs(tVec - curr_tOnset));
            [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
            newMaskerSound(start_index:stop_index - 1) = newMaskerSound(start_index:stop_index - 1) + y;
        else
            disp("uh oh!")
        end
        %find the closest values for onset time and onset time + 300 ms
        %    [~,start_index] = min(abs(tVec - curr_tOnset));
        %    [~,stop_index] = min(abs(tVec - (wordlength + curr_tOnset)));
        %    newtotalSound(start_index:stop_index - 1) = newtotalSound(start_index:stop_index - 1) + y;
        iOnset = iOnset + 1;
    end

    %making scrambled masker array
    if (scramblingindex == 1)
        newMaskerSound = scrambling(newMaskerSound, fs);
    end
    newMaskerSound = newMaskerSound'; % transpose the array

    %making the filter
    numfilters = 16; %go between like 2 and 16
    order = 9; %go between like 2 and 10
    edges = logspace(log10(300), log10(10000), numfilters + 1);
    newMaskerFiltered = zeros(1, length(tVec));
    newTargetFiltered = zeros(1, length(tVec));

    for iFilter = 1:numfilters
        lowedge = edges(iFilter);
        highedge = edges(iFilter + 1);
        %n = order of filter (sharp/shallow)
        %Wn = normalized frequency
        [bLow, aLow] = butter(order, highedge/(fs/2), 'low');
        [bHigh, aHigh] = butter(order, lowedge/(fs/2), 'high');
        thisFilteredSound = zeros(1, length(tVec));
        if mod(iFilter,2) == 1
            thisFilteredSound = filter(bLow, aLow, newMaskerSound);
            thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
            newMaskerFiltered = newMaskerFiltered + thisFilteredSound;
        elseif mod(iFilter,2) == 0
            thisFilteredSound = filter(bLow, aLow, newTargetSound)';
            thisFilteredSound = filter(bHigh, aHigh, thisFilteredSound);
            newTargetFiltered = newTargetFiltered + thisFilteredSound;
        end
    end
    % sound(newTargetFiltered, fs);
    % pause
    % sound(newMaskerFiltered,fs);
    %sound(newTargetFiltered + newMaskerFiltered, fs);
    if scramblingindex == 0
        this_foldername = [foldername,'/unscrambled'];
        audiofilename = [this_foldername,'/',num2str(trial),'_unscrambled', '.wav'];
        audiowrite(audiofilename, newTargetFiltered + newMaskerFiltered, fs);
        disp(audiofilename)
    elseif scramblingindex == 1
        this_foldername = [foldername,'/scrambled'];
        audiofilename = [this_foldername,'/',num2str(trial),'_scrambled', '.wav'];
        audiowrite(audiofilename, newTargetFiltered + newMaskerFiltered, fs);
        disp(audiofilename)
    end
    all_word_order(trial,:) = final_word_order;
    trial = trial + 1;

end

save([foldername, '/', subjectID, '_alltrialwords.mat'], 'all_word_order','tOnset');
disp('All Done!')





% %figure;
% hold on; %plots all arguments on the same figure
% targetFFT = fft(newTargetFiltered);
% maskerFFT = fft(newMaskerFiltered);
% targetFFT = abs(targetFFT)/abs(max(targetFFT));
% maskerFFT = abs(maskerFFT)/abs(max(maskerFFT));
% targetFFT = targetFFT(1:length(targetFFT)/2+1);
% maskerFFT = maskerFFT(1:length(maskerFFT)/2+1);
% % targetFFT(2:end-1) = 2*targetFFT(2:end-1);
% % maskerFFT(2:end-1) = 2*targetFFT(2:end-1);
% f = fs*(0:(length(targetFFT/2))-1)/length(targetFFT);
%
% plot(f, maskerFFT, 'blue');
% plot(f, targetFFT, 'red');
% xlabel('Frequency (Hz)');
% ylabel('FFT Magnitude');



%plot(tVec, newMaskerSound);
% save('Test Sound 11-15.mat','twoStreamsTest1','fs')


%%filter = 16 bands, log spaced between 300Hz - 10kHz (from
%%filtering/Vocoding paper - Zhang et. al 2021)





%play the sounds
% iStart = 1;
% fs = 44100;
% totalSound = [];
% while iStart <= numtotalwords
%    [y,fs] = audioread(soundArray(iStart));
%    totalSound = [totalSound;y;zeros(0.05*fs, 1)]; %adding "y" to end of total sound so the sounds are sequential
%    iStart = iStart + 1;
% end
% sound(totalSound, fs);






% fs = 44100;
% tVec = 0:1/fs:10;
%
% [Y,Fs] = cellfun(@wavread,N);
% for k = randperm(numel(N))
%     soundsc(Y{k},Fs{k})
% end
% for iOnset = 1:length(tOnset)
%     iTempWord = soundArray(iOnset);
%     tempOnset = tOnset(iOnset);
%     iStart = find(tVec == tempOnset);
%     iEnd   = iStart + length(tempWord) - 1;
%     soundWave(1, iStart:iEnd) = tempWord;
%     soundWave(2, iStart:iEnd) = tempWord;
% end


%[y, fs] = audioread('voc_demo_hipass.wav'); %this loads and reads the sound as a two-dimensional matrix
%y being the data itself and fs being the given sampling rate
% sound(y, fs); %this plays the sound

%plot(y);
% time = linspace(1, length(y), 1/fs); %linspace generates linear values from a complex matrix (I think?)
% time2 = linspace(0,1/fs,length(y)/fs);
% time3 = linspace (0, length(y)/fs, fs);
