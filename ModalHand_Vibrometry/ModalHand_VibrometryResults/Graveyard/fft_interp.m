function [amp] = fft_interp(signal,input_fs,output_freq)
    if rem(length(signal),2) == 1
        signal = [signal,0];
    end

    signal = signal - median(signal);

    signal_fft = abs(fft(signal)/length(signal));
    actual_amp = signal_fft(1:length(signal)/2+1);
    actual_amp(2:end-1) = 2*actual_amp(2:end-1);
    actual_freq = input_fs*(0:(length(signal)/2))/length(signal);
    
    brick_wall = actual_freq>output_freq(1);

    actual_freq = actual_freq(brick_wall);
    actual_amp = actual_amp(brick_wall);

    interp_amp = interp1(actual_freq,actual_amp,output_freq,'spline');
    amp = movmedian(interp_amp,round(length(output_freq)/20));
end