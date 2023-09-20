function [signal,inv_signal] = logSweep(f1,f2,T,fs,win_len)
t = (0:(T*fs-1))/fs;
R = log(f2/f1);
k = exp(t*R/T);

signal = sin((2*pi*f1*T/R)*(k-1));
win_samps = round(.5*fs*win_len)*2;
win = hanning(win_samps);
win = win';
half_win = win_samps/2;
signal(1:half_win) = signal(1:half_win).*win(1:half_win);
signal(end-half_win+1:end) = signal(end-half_win+1:end).*win(half_win+1:end);

inv_signal = fliplr(signal)./k;
end