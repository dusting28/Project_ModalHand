function [t,ir,freq,transfer_func] = computeTransferFunc2(input_sig,output_sig,fs,bandwidth)
    
    in_len = length(input_sig);
    out_len = length(output_sig); 
    input_sig = [input_sig,zeros(1,out_len)];
    output_sig = [output_sig,zeros(1,in_len)];

    % Computer transfer function
    transfer_func = fft(output_sig)./fft(input_sig);
    freq = fs*(0:(length(input_sig)/2))/length(input_sig);
    freq = [freq,freq(2:end)];

    %Brick-Wall Filter
    transfer_func(or(freq<bandwidth(1),freq>bandwidth(2))) = 0;

    %Compute IR
    ir=ifft(transfer_func,"symmetric");
    t = (1:length(ir))/fs;
    t = t(t<0.1);
    ir = ir(t<0.1);

    %Compute Transfer Func
    [freq, transfer_func] = fft_spectral(ir,fs);
end