function [y,t] = bandLimitedNoise(dur,fs, nChannels, bandpass)
sigLen = round(dur*fs);

rng(52); % 2 ms noise burst random seed
R = (rand(sigLen,nChannels) * 2) - 1;

%construct time vector
t = (0:sigLen - 1) /fs;

% filter noise
bpFilt = designfilt('bandpassfir', 'FilterOrder', round(sigLen/3)-1, ...
         'CutoffFrequency1', bandpass(1), 'CutoffFrequency2', bandpass(2),...
         'SampleRate', fs);
y = filtfilt(bpFilt,R);

%normalize to audio range
y = y ./ max(abs(y));

end