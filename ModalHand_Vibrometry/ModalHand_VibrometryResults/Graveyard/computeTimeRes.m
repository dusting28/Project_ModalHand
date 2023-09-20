function [vel_signal, force_signal, vel_fs, force_fs] = computeTimeRes(folder,filename)
    all_data = load(strcat(folder,filename));
    
    force_fs = all_data.MeasurementSignal.fs;
    vel_fs = all_data.TestSignal.fs;
    input_len = all_data.TestSignal.sigLength;
    sig_length_daq = force_fs*input_len;
    sig_length_motu = all_data.TestSignal.fs*input_len;
    
    [~,chop_iter_daq] = max(all_data.Signals.Daq(:,:,7),[],1);
    [~,chop_iter_motu] = max(all_data.Signals.Motu(:,:,2),[],1);

    vel_signals = zeros(all_data.MeasurementInfo.nRepetitions,sig_length_motu);
    force_signals = zeros(all_data.MeasurementInfo.nRepetitions,sig_length_daq);

    for iter1 = 1:all_data.MeasurementInfo.nRepetitions
        vel_temp = all_data.Signals.Motu(chop_iter_motu+1:chop_iter_motu+sig_length_motu,iter1,1)';
        force_temp = all_data.Signals.Daq(chop_iter_daq(iter1)+1:chop_iter_daq(iter1)+sig_length_daq,iter1,3)';
        figure
        plot(vel_temp);
        figure
        plot(force_temp);
        vel_signals(iter1,:) = vel_temp - mean(vel_temp);
        force_signals(iter1,:) = force_temp - mean(force_temp);
    end

    vel_signal = mean(vel_signals,1);
    force_signal = mean(force_signals,1);
    figure;
    plot(force_signal);
    figure
    plot(vel_signal);
end