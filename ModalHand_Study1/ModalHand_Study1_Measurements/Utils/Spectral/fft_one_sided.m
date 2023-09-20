function [freq,amp,phase] = fft_one_sided(signal,fs,cutoff)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
sample_len = length(signal);
f = fs*(0:(sample_len/2))/sample_len;
fft_response = fft(signal);
P2 = abs(fft_response/sample_len);
%P1 = P2(1:floor(sample_len/2)+1);
%P1(2:end-1) = 2*P1(2:end-1);
full_phase = angle(fft_response);

freq = f(f>=cutoff(1) & f<=cutoff(2));
amp = freq;
phase = freq;

iter2 = 0;
for iter1 = 1:length(f)
    if (f(iter1) >= cutoff(1)) && (f(iter1) <= cutoff(2))
        iter2 = iter2+1;
        amp(iter2) = 2*P2(iter1);
        phase(iter2) = full_phase(iter1);
    end
end

%phase = unwrap(phase);

end

