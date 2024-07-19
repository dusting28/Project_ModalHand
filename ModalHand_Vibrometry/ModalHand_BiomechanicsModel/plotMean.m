function [] = plotMean(freq,freq_up,signals,kernal)
    %% Plot Impedance
    sig_avg = movmean(mean(signals,1),kernal);
    %sig_std = movmean(std(signals,0,1),kernal);
    sig_qrt25 = movmean(quantile(signals,0.25,1),kernal);
    sig_qrt75 = movmean(quantile(signals,0.75,1),kernal);

    plot(freq_up,csapi(freq,sig_avg,freq_up),'k');
    hold on;
    plot(freq_up,csapi(freq,sig_qrt25,freq_up),'k--');
    hold on;
    plot(freq_up,csapi(freq,sig_qrt75,freq_up),'k--');
    hold on;
end