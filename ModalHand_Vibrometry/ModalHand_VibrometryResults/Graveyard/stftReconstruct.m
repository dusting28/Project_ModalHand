function [filtered_sig] = stftReconstruct(signal,fs)
    [sst,f,t] = fsst(signal,fs);

    %% Log Sweep
    
    f1 = 10;
    f2 = 1000;
    T = 10;
    freq_map = f1*exp((t/T)*log(f2/f1));
    
    ir2 = zeros(length(freq_map),1);

    for iter1 = 1:length(freq_map)
        [~, idx] = min(abs(f-freq_map(iter1)));
        ir2(iter1) = idx; 
    end

    filtered_sig = ifsst(sst,[],ir2);

    % figure;
    % fsst(signal,fs,'yaxis')
    % penval = 1;
    % [~,ir] = tfridge(sst,f,penval,'NumRidges',1);
    
    % figure;
    % plot(t,ir,t,ir2);
    %[fr,ir] = tfridge(sst,f,1,'NumRidges',2,'NumFrequencyBins',nfb);
    % itr = ifsst(sst,[],ir,'NumFrequencyBins',nfb);
end

