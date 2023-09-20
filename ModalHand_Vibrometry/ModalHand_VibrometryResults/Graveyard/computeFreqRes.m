function [vel_signal, force_signal] = computeFreqRes(folder,filename,freq)
    all_data = load(strcat(folder,filename));
    
    force_fs = all_data.MeasurementSignal.fs;
    vel_fs = all_data.TestSignal.fs;
    input_len = all_data.TestSignal.sigLength;
    sig_length_daq = force_fs*input_len;
    sig_length_motu = all_data.TestSignal.fs*input_len;
    
    [~,chop_iter_daq] = max(all_data.Signals.Daq(:,:,7),[],1);
    [~,chop_iter_motu] = max(all_data.Signals.Motu(:,:,2),[],1);

    vel_signals = zeros(all_data.MeasurementInfo.nRepetitions,length(freq));
    force_signals = zeros(all_data.MeasurementInfo.nRepetitions,length(freq));
    for iter1 = 1:all_data.MeasurementInfo.nRepetitions
        
        vel_temp = all_data.Signals.Motu(chop_iter_motu+1:chop_iter_motu+sig_length_motu,iter1,1)';
        force_temp = all_data.Signals.Daq(chop_iter_daq(iter1)+1:chop_iter_daq(iter1)+sig_length_daq,iter1,3)';
        vel_temp = vel_temp - mean(vel_temp);
        force_temp = force_temp - mean(force_temp);
        vel_signals(iter1,:) = fft_interp(vel_temp,vel_fs,freq);
        force_signals(iter1,:) = fft_interp(force_temp,force_fs,freq);
%         figure
%         plot(freq,vel_signals(iter1,:));
%         figure
%         plot(freq,force_signals(iter1,:));
    end

    vel_signal = mean(vel_signals,1);
    force_signal = mean(force_signals,1);
%     figure
%     plot(freq,vel_signal);
%     figure
%     plot(freq,force_signal);
end