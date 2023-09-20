function [impulse_response] = computeIRTime(force_sig,vel_sig,fs,bandwidth)
    tr_sig = fliplr(force_sig);
    colored_sig = conv(tr_sig,vel_sig);
    colored_sig = colored_sig(round(length(vel_sig)/2):round(length(vel_sig)/2)+length(force_sig)-1);

    % figure();
    % plot(colored_sig)

    force_sig = [force_sig,zeros(1,length(force_sig))];
    colored_sig = [colored_sig,zeros(1,length(colored_sig))];

    ir_spec = fft(colored_sig)./(fft(force_sig).^2);

    % Brick-Wall Filter
    freq = fs*(length(force_sig)/2:-1+length(force_sig)/2)/length(force_sig);
    ir_spec(or(freq<bandwidth(1),freq>bandwidth(2))) = 0;

    impulse_response=ifft(ir_spec);
end