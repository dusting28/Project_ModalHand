function [SNR] = computeSNR(signal,freq_map,width,fs)
    SNR = zeros(1,size(freq_map,2));
    [~,f_bins,t_bins,p] = spectrogram(signal,2*round(fs/16),round(fs/16),fs,fs);
    f_bins = f_bins(and(f_bins>=freq_map(1,1),f_bins<=freq_map(1,end)));
    p = p(and(f_bins>=freq_map(1,1),f_bins<=freq_map(1,end)),:);
    for iter1=1:size(freq_map,2)
        [~,t_idx] = min(abs(t_bins-freq_map(2,iter1)));
        num_samples = length(and(f_bins>=freq_map(1,iter1)-width/2,f_bins<=freq_map(1,iter1)+width/2));
        signal_amp = sum(p(and(f_bins>=freq_map(1,iter1)-width/2,f_bins<=freq_map(1,iter1)+width/2),t_idx).^.5);
        noise_amp = sum(p(or(f_bins<freq_map(1,iter1)-width/2,f_bins>freq_map(1,iter1)+width/2),t_idx).^.5);
        SNR(iter1) = signal_amp/num_samples;%/noise_amp;
    end
    SNR = movmean(SNR,5);
end

