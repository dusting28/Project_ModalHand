%% Simple square wave oscillator

% Written by Gregory Reardon (reardon@ucsb.edu)
function [yOut,t] = squareOsc(f, T, fs, nChannels)

sigLen = T*fs;
t = (0:sigLen-1) /fs;

y = zeros(sigLen, nChannels);
y = square(2*pi*f*t);
yOut = repmat(y,1,nChannels);

[y_fft, f] = spectr2(yOut,fs);
plot(f,20*log10(2*abs(y_fft)))
plot(yOut);

end