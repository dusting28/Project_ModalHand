function [] = plotMean(freq,freq_up,signals,kernal)
    %% Plot Impedance
    sig_avg = movmean(mean(signals,1),kernal);
    sig_std = movmean(std(signals,0,1),kernal);

    plot(freq_up,csapi(freq,sig_avg,freq_up),'k');
    hold on;
    plot(freq_up,csapi(freq,sig_avg-sig_std,freq_up),'k--');
    hold on;
    plot(freq_up,csapi(freq,sig_avg+sig_std,freq_up),'k--');
    hold on;
end