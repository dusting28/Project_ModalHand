function [velocity_signal, force_signal, vel_fs, force_fs] = computeImpulses(folder,filename)
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
    vel_impulse = zeros(all_data.MeasurementInfo.nRepetitions,2*sig_length_motu-1);
    force_impulse = zeros(all_data.MeasurementInfo.nRepetitions,2*sig_length_daq-1);
    for iter1 = 1:all_data.MeasurementInfo.nRepetitions
        temp_velocity = all_data.Signals.Motu(chop_iter_motu+1:chop_iter_motu+sig_length_motu,iter1,1)';
        temp_force = all_data.Signals.Daq(chop_iter_daq(iter1)+1:chop_iter_daq(iter1)+sig_length_daq,iter1,3)';
        vel_impulse(iter1,:) = conv(temp_velocity-mean(temp_velocity),inverse_input_motu);
        force_impulse(iter1,:) = conv(temp_force-mean(temp_force),inverse_input_daq);
    end

    velocity_signal = mean(vel_impulse(:,round(sig_length_motu*.9):round(sig_length_motu*1.2)-1),1);
    force_signal = mean(force_impulse(:,round(sig_length_daq*.9):round(sig_length_daq*1.2)-1),1);
    plot(force_signal);
end