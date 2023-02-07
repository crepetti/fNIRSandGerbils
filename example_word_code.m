all_masker_words = {'box','toy','car','emaya','ben','oddball'};
all_colors_words = {'red','blue','white','green'};

% let's choose 3 masker words and 3 color words
masker_words_to_use = randsample(all_masker_words,3,true); % picking words from masker bucket
color_words_to_use = randsample(all_colors_words,3,true); % picking words from target bucket

% mix them all together
num_words_total = length(masker_words_to_use) + length(color_words_to_use);
final_word_order = randsample([masker_words_to_use,color_words_to_use],num_words_total,false); % sample without replacement so each word shows up once

% check for two words in a row

% for each word in order....
    % load the audio file
    word_filename = append(final_word_order(iword),'_short.wav');
    load(word_filename);
    % put into a larger array which is the whole sound


% play the sound