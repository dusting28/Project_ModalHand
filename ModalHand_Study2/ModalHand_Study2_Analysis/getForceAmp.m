function [amp] = getForceAmp(signal,freq,fs)

    sig_length = length(signal);
    filtered_sig = bandpass(signal,[freq*.8,freq*1.2],fs);
    amp = max(filtered_sig(floor(.7*sig_length):floor(.9*sig_length)))/2-...
                        min(filtered_sig(floor(.7*sig_length):floor(.9*sig_length)))/2;
end