function [t,ir] = computeIR(input_sig,output_sig,fs)
    in_len = length(input_sig);
    out_len = length(output_sig);
    output_sig = [output_sig,zeros(1,in_len)];
    input_sig = [input_sig,zeros(1,out_len)];
    ir = impzest(input_sig',output_sig');
    ir = ir';
    t = (1:length(ir))/fs;
    ir = ir(t<.1);
    t = t(t<.1);
end