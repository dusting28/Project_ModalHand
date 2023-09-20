function [t,ir] = computeIR_Kirkeby(input_sig,output_sig,fs)
    % Zero pad
    in_len = length(input_sig);
    out_len = length(output_sig);
    output_sig = [zeros(1,in_len),output_sig,zeros(1,in_len),0];
    input_sig = [input_sig,zeros(1,out_len),zeros(1,in_len),0];

    % Computer transfer function
    output_spec = fft(output_sig);
    input_spec = fft(input_sig);
    freq = fs*(0:floor(length(input_sig)/2))/(length(input_sig)-1);
    freq = [freq(1:end),fliplr(freq(2:end))];

    % Kirkeby's Invsere Filter
    reg = Trapezoid_Regularizer(freq,[15, 950],[10^4,10^4],[15,15]);
    inverse_filter = conj(input_spec)./((abs(input_spec)).^2 + reg);

    %Compute IR
    transfer_func = output_spec.*inverse_filter;
    ir=ifft(transfer_func,"symmetric");
    t = (1:length(ir))/fs;

    % Chop
    chop_length = 0.15;
    center_point = t(in_len);
    chop_idx = and(t>center_point-chop_length, t<center_point+chop_length);
    ir = ir(chop_idx);
    t = t(chop_idx)-(center_point-chop_length);
end