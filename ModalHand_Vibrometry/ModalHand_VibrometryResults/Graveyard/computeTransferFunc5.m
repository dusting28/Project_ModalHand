function [t,ir,freq,transfer_func] = computeTransferFunc5(input_sig,output_sig,fs,bandwidth)
    in_len = length(input_sig);
    output_sig = [output_sig,zeros(1,in_len)];
    ir = deconv(output_sig,input_sig);
    t = (1:length(ir))/fs;
    [freq,transfer_func] = fft_spectral(ir,fs);
    ir = ir(t<.1);
    t = t(t<.1);
end