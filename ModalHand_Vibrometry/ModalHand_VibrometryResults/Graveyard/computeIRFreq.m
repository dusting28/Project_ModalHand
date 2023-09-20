function [impulse_response] = computeIRFreq(force_sig,vel_sig,fs,bandwidth)
    force_sig = [force_sig,zeros(1,length(force_sig))];
    vel_sig = [vel_sig,zeros(1,length(vel_sig))];

    ir_spec = fft(vel_sig)./fft(force_sig);

    % Brick-Wall Filter
    freq = fs*(length(force_sig)/2:-1+length(force_sig)/2)/length(force_sig);
    ir_spec(or(freq<bandwidth(1),freq>bandwidth(2))) = 0;

    impulse_response=ifft(ir_spec);
end