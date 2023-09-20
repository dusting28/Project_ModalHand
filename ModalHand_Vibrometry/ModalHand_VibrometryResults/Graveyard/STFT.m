function [magnitude] = STFT(signal,freq_map,width,fs)
    magnitude = zeros(1,size(freq_map,2));
    % figure;
    % spectrogram(signal,2*round(fs/16),round(fs/16),fs,fs)
    % xlim([0,1]);
    [s,f_bins,t_bins,~] = spectrogram(signal,2*round(fs/16),round(fs/16),fs,fs);
    for iter1=1:size(freq_map,2)
        [~,t_idx] = min(abs(t_bins-freq_map(2,iter1)));
        [~,f_idx] = min(abs(f_bins-freq_map(1,iter1)));
        magnitude(iter1) = s(f_idx,t_idx).^.5;
        % num_samples = length(and(f_bins>=freq_map(1,iter1)-width/2,f_bins<=freq_map(1,iter1)+width/2));
        % signal_amp = sum(p(and(f_bins>=freq_map(1,iter1)-width/2,f_bins<=freq_map(1,iter1)+width/2),t_idx).^.5);
        % magnitude(iter1) = signal_amp/num_samples;%/noise_amp;
    end
end

