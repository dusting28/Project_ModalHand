%% Generates a sine sweep test signal
% Written by Gregory Reardon (reardon@ucsb.edu)

function y = sineOsc(f,T,fs)
%----------------------------------------
% inputs:
%       f0 (int): start frequency
%       f1 (int): end frequency
%       T (float): length of signal (in seconds)
%       fs (int): sampling rate
% outputs:
%       y (array): time-domain sine sweep signal
%----------------------------------------

%winLen = 12000;
t = (0:(fs*T)-1) / fs;
w = 2*pi*f;
y = sin(w*t);

win= tukeywin(length(y),0.25);
y = y.*win';

%% Analyze Test Signal
%plot(t,y);
%ylabel('Amplitude');
%xlabel('Time (Seconds)');
%spectrogram(y, hanning(1024),512,2048,fs);

end