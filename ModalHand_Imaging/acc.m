function [acc_sig] = acc(signal,num_samples,fs)
    acc_sig = (signal(2*num_samples+1:end) - 2*signal(num_samples+1:end-num_samples) + ...
        signal(1:end-2*num_samples))*(fs/num_samples)^2;
end