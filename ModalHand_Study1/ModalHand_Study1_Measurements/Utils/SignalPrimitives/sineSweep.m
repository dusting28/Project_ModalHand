%% Generates a sine sweep test signal
% Written by Gregory Reardon (reardon@ucsb.edu)

function y = sineSweep(f0, f1, T, fs, type, winLen)
%----------------------------------------
% inputs:
%       f0 (int): start frequency
%       f1 (int): end frequency
%       T (float): length of signal (in seconds)
%       fs (int): sampling rate
%       type (string): either 'log' or 'linear' for type of sine sweep
%                      desired
% outputs:
%       y (array): time-domain sine sweep signal
%----------------------------------------

% Equations from: IMPULSE RESPONSE MEASUREMENT WITH SINE SWEEPS AND AMPLITUDE
% MODULATION SCHEMES - Meng, Sen, Wang, and Hayes

if nargin < 6
    winLen = 10000;
end

t = (0:(fs*T)-1) / fs;
w1 = 2*pi*f0;
w2 = 2*pi*f1;

%logarithmic sine sweep - instantaneous frequency increases exponentially
if strcmp(type,'log')    
    K = (T * w1) / log(w2/w1);
    L = T / log(w2/w1);
    y = sin(K * (exp(t/L)-1));
    
%linear
elseif strcmp(type,'linear')
    y = sin(w1*t + (((w2 - w1)/T) * (t.^2 / 2)));
    %win = hanning(1000);
    %y(1:500) = y(1:500).*win(1:500)';
    %y(end-499:end) = y(end-499:end).*win(501:end)';
    
%     win = hanning(10000);
%     y(1:5000) = y(1:5000).*win(1:5000)';
%     y(end-4999:end) = y(end-4999:end).*win(5001:end)';
    
    
elseif strcmp(type,'discrete')
     error('You have to finish this, Greg!')
    
     %delay = 0.2*fs; % delay in seconds
     %nSines = floor((f1-f0) / res);
     %nSamps = floor(T*fs / nSines);
     %t = (0:nSamps-1) / fs;
     %f = f0;
     %y = zeros((nSamps*nSines) + (nSines*delay),1);
% 
     %n = 1;
     %for i = 1:nSines
     %    y(n:n+nSamps-1) = sin(2*pi*f*t');
     %    f = f+res;
     %    n = n+nSamps+delay;
     %end
    
%error is unrecognized sweep type
else
    
    error('Sweep Type not recognized, expects log or linear. See SineSweep.m'); 
end

win = hanning(winLen);
if (mod(winLen,2) ~= 0) 
    error('Window length must be even');
end
halfWinLen = winLen/2;
y(1:halfWinLen) = y(1:halfWinLen).*win(1:halfWinLen)';
y(end-halfWinLen+1:end) = y(end-halfWinLen+1:end).*win(halfWinLen+1:end)';

%% Analyze Test Signal
%plot(t,y);
%ylabel('Amplitude');
%xlabel('Time (Seconds)');
%spectrogram(y, hanning(1024),512,2048,fs);

end