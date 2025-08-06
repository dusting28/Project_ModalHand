function [vel_sig] = vel(signal,num_samples,fs)
    vel_sig = (signal(2*num_samples+1:end) - signal(1:end-2*num_samples))*(fs/num_samples);
end