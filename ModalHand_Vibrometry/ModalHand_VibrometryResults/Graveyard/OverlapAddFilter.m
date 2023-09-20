function [filtered_sig] = OverlapAddFilter(signal,bandwidth,win_len,fs)
    % Zero-pad signal
    % signal = [zeros(ceil(win_len/2),1), signal, zeros(ceil(win_len/2),1)];
    sig_len = length(signal);
    zero_pad = 0;
    if mod(sig_len,win_len) > 0
        zero_pad = win_len-mod(sig_len,win_len);
        signal = [signal, zeros(1,zero_pad)];
    end

    t = (0:sig_len-1)/fs;
    filtered_sig = zeros(1,length(signal));

    %% Log Sweep
    f1 = 10;
    f2 = 1000;
    T = 10;
    

    % Moving bandpass filter
    num_windows = sig_len/win_len;
    for iter1 = 1:num_windows
        start_idx = 1+(iter1-1)*win_len; 
        end_idx = iter1*win_len;
        center_time = mean(t(start_idx:end_idx));
        center_freq = f1*exp((center_time/T)*log(f2/f1));
        band_filt = designfilt('bandpassfir', 'FilterOrder', round(win_len/3)-1, ...
         'CutoffFrequency1', center_freq*bandwidth(1), 'CutoffFrequency2', center_freq*bandwidth(2),...
         'SampleRate', fs);
        filtered_sig(start_idx:end_idx) = filtfilt(band_filt,signal(start_idx:end_idx));
    end

    filtered_sig = filtered_sig(1:end-zero_pad);
end

