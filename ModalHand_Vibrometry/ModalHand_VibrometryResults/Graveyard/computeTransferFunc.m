function [freq, transfer_func] = computeTransferFunc(input_sig,output_sig,fs,bandwidth)

% Zero-pad signal
in_len = length(input_sig);
out_len = length(output_sig);
total_len = in_len+out_len;

input_sig = [input_sig,zeros(1,out_len)];
output_sig = [output_sig,zeros(1,in_len)];

% Computer transfer function
transfer_func = fft(output_sig)./fft(input_sig);
transfer_func = transfer_func(1:total_len/2+1);
transfer_func(2:end-1) = 2*transfer_func(2:end-1);

% Brick-Wall Filter
freq = fs*(0:(total_len/2))/total_len;
transfer_func(or(freq<bandwidth(1),freq>bandwidth(2))) = 0;

end