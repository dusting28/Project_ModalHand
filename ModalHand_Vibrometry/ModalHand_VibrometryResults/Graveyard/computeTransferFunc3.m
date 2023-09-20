function [t,ir,freq,transfer_func] = computeTransferFunc3(input_sig,output_sig,fs,bandwidth)
    in_len = length(input_sig);
    out_len = length(output_sig);
    output_sig = [output_sig,zeros(1,in_len)];
    input_sig = [input_sig,zeros(1,out_len)];
    tr_sig = fliplr(input_sig);
    ir = conv(tr_sig,output_sig);
    t = (1:length(ir))/fs;
    t = t(t<0.1);

    ir = ir(floor(end/2):floor(end/2)+length(t)-1);

    [freq,transfer_func] = fft_spectral(ir,fs);
end