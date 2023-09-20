function freq_map = log_freqMap(freq,T)
    freq_map = [freq; T*log(freq/freq(1))/log(freq(end)/freq(1))];
end