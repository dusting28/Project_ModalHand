%% Generate bandlimited white noise signal

% Written by Gregory Reardon (reardon@ucsb.edu) - 10/6/2019
function [y,t] = noiseSignal(dur, fs, nChannels, nFoci, probType)

sigLen = dur*fs;

%rng(66); % 4 ms noise burst random seed
rng(52); % 2 ms noise burst random seed
if strcmp(probType,'gauss')
    R = randn(sigLen,nFoci);
elseif strcmp(probType,'uniform')
    R = (rand(sigLen,nFoci) * 2) - 1;
else
   error('Must be type gauss or uniform'); 
end

%normalize to audio range
R = R ./ max(abs(R));

for i = 1:nFoci
    y(:,:,i) = repmat(R(:,i),1,nChannels);
end

%construct time vector
t = (0:sigLen - 1) /fs;


%returns one-sided spectrum
[y_fft, f] = spectr2(R,fs);
plot(f, 20*log10(2*abs(y_fft))); 

end