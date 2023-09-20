%% Generate bandlimited white noise signal

% Written by Gregory Reardon (reardon@ucsb.edu) - 10/6/2019
function [y,t] = noiseTrainSignal(dur, fs, nPulses, delta, probType)

sigLen = dur*fs;
zp = delta*fs;

%rng(66); % 4 ms noise burst random seed
rng(52); % 2 ms noise burst random seed
if strcmp(probType,'gauss')
    R = randn(sigLen,1);
elseif strcmp(probType,'uniform')
    R = (rand(sigLen,1) * 2) - 1;
else
   error('Must be type gauss or uniform'); 
end

%normalize to audio range
R = R ./ max(abs(R));
R = [R; zeros(zp,1)];
y = repmat(R,[nPulses,1]);

y = lowpass(y,800,fs);

%construct time vector
t = (0:length(y) - 1) /fs;

%for i = 1:nFoci
%    y(:,:,i) = repmat(R(:,i),1,nChannels);
%end

plot(y);

%returns one-sided spectrum
%[y_fft, f] = spectr2(R,fs);
%%plot(f, 20*log10(2*abs(y_fft))); 

end