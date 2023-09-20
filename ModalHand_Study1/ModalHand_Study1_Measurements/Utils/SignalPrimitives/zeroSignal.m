%% Generates a blank test signal for noise power estimation
% Written by Gregory Reardon (reardon@ucsb.edu)

function y = zeroSignal(T,fs)
%----------------------------------------
% inputs:
%       T (float): length of signal (in seconds)
%       fs (int): sampling rate
% outputs:
%       y (array): time-domain sine sweep signal
%----------------------------------------


y = zeros(T*fs,1);


%% Analyze Test Signal
%plot(t,y);
%ylabel('Amplitude');
%xlabel('Time (Seconds)');
%spectrogram(y, hanning(1024),512,2048,fs);

end