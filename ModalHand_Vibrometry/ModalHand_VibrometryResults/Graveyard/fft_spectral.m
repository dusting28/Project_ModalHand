function [freq,coefficients] = fft_spectral(signal,fs)
    if rem(length(signal),2) == 1
        signal = [signal,0];
    end

    signal_fft = fft(signal)/length(signal);
    coefficients = signal_fft(1:length(signal)/2+1);
    coefficients(2:end-1) = 2*coefficients(2:end-1);

    freq = fs*(0:(length(signal)/2))/length(signal);
end