%% Simple saw wave oscillator

% Written by Gregory Reardon (reardon@ucsb.edu)
function [yOut,t] = sawOsc(f, T, fs, nChannels, w)

sigLen = T*fs;
t = (0:sigLen-1) /fs;

y =  sawtooth(2*pi*f*t,w);
yOut = repmat(y,1,nChannels);

plot(yOut);

end