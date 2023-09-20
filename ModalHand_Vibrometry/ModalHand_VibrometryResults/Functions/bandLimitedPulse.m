function [y,t] = bandLimitedPulse(dur,fs, bandpass)
sigLen = round(dur*fs);
R = zeros(sigLen,1);
R(round(sigLen/2),:) = 1;


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