% Make a function
function y = scrambling(d, sr)
% Load some speech
%addpath('C:\Users\ema36\Documents\Pitt\LiMN\Big Boi\unprocessed\bob_all(scrambled)');
%addpath('C:\Users\benri\Documents\PhD Year 2\Emaya Mentorship\AuditoryToolbox');
% Shuffle 25 ms windows over a 250ms radius
y = shufflewins(d,round(sr*.025),round(sr*.25));
% Listen back

% Set up Gammatone filterbank with 64 bands from Nyquist to 50 Hz
% Scale bandwidths to be 1.5 x normal, so the effect of filtering
% both forward and backwards is approximately the bandwidth of a
% single forward pass, at least in the top 10 dB.
fcoefs = MakeERBFilters(sr,64,50,1.5);
% Break the speech into subbands using the filters
% Each row of dsub is one of the 64 band-passed signals
dsub = ERBFilterBank(d,fcoefs);
% Pass each subband signal back through the same filter, but
% backwards in time, then flip them again
dsub2 = fliplr(ERBFilterBank(fliplr(dsub),fcoefs));
% sum(dsub2) is now a pretty good approximation to the original d
%soundsc(sum(dsub2),sr);
% .. but now we can scramble each subband independently
for i = 1:size(dsub2,1); ...
    ysub(i,:) = shufflewins(dsub2(i,:),round(sr*.025),round(sr*.25)); ...
end
% sum up scrambled subbands to get a full-band signal
y2 = sum(ysub);
% take a listen
% soundsc(y2,sr);
% figure;
% 
% %Plot the results
% subplot(311)
% specgram(d,512,sr);
% caxis([-50 10]);
% title('original');
% subplot(312)
% specgram(y,512,sr);
% caxis([-50 10]);
% title('full-band scrambling');
% subplot(313)
% specgram(y2,512,sr);
% caxis([-50 10]);
% title('multiband scrambling');