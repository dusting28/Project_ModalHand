function [vel_signal, force_signal, vel_fs, force_fs] = computeImpulseFreq(folder,filename,freq)
    all_data = load(strcat(folder,filename));
    
    force_fs = all_data.MeasurementSignal.fs;
    vel_fs = all_data.TestSignal.fs;
    input_len = all_data.TestSignal.sigLength;
    sig_length_daq = force_fs*input_len;
    sig_length_motu = all_data.TestSignal.fs*input_len;
   
    win_len = all_data.TestSignal.winLen/all_data.TestSignal.fs;
    [~,inverse_input_daq] = logSweep(all_data.TestSignal.f0, all_data.TestSignal.f1, input_len, force_fs, win_len);
    [~,inverse_input_motu] = logSweep(all_data.TestSignal.f0, all_data.TestSignal.f1, input_len, vel_fs, win_len);
    
    [~,chop_iter_daq] = max(all_data.Signals.Daq(:,:,7),[],1);
    [~,chop_iter_motu] = max(all_data.Signals.Motu(:,:,2),[],1);
    vel_signals = zeros(all_data.MeasurementInfo.nRepetitions,length(freq));
    force_signals = zeros(all_data.MeasurementInfo.nRepetitions,length(freq));
    for iter1 = 1:all_data.MeasurementInfo.nRepetitions
        temp_velocity = all_data.Signals.Motu(chop_iter_motu+1:chop_iter_motu+sig_length_motu,iter1,1)';
        temp_force = all_data.Signals.Daq(chop_iter_daq(iter1)+1:chop_iter_daq(iter1)+sig_length_daq,iter1,3)';
        temp_vel_impulse = conv(temp_velocity-mean(temp_velocity),inverse_input_motu);
        temp_force_impulse = conv(temp_force-mean(temp_force),inverse_input_daq);
        temp_vel_chop = temp_vel_impulse(round(sig_length_motu*.9):round(sig_length_motu*1.2)-1);
        temp_force_chop = temp_force_impulse(round(sig_length_daq*.9):round(sig_length_daq*1.2)-1);
        vel_signals(iter1,:) = fft_interp(temp_vel_chop,vel_fs,freq);
        force_signals(iter1,:) = fft_interp(temp_force_chop,force_fs,freq);
        figure
        plot(freq,vel_signals(iter1,:));
        figure
        plot(freq,force_signals(iter1,:));
    end
    vel_signal = mean(vel_signals,1);
    force_signal = mean(force_signals,1);
    figure;
    plot(freq,force_signal);
    figure
    plot(freq,vel_signal);
end