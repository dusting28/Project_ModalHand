function [vel_signal, force_signal, vel_fs, force_fs] = chopMeasurementData(all_data,LDV_scale)
    
    % Amplifier on Motu Input
    motu_scale = 13;
    
    % Get sample rates
    force_fs = all_data.MeasurementSignal.fs;
    vel_fs = all_data.TestSignal.fs;

    % Get signal properties
    input_len = all_data.TestSignal.sigLength;
    sig_length_daq = force_fs*input_len;
    sig_length_motu = all_data.TestSignal.fs*input_len;

    % Get number of trials
    repetitions = all_data.MeasurementInfo.nRepetitions;
    locations = all_data.MeasurementInfo.nLocations;
    
    % Declare matrices for storing chopped data
    vel_signal = zeros(repetitions, locations, sig_length_motu);
    force_signal = zeros(repetitions, locations, sig_length_daq);
    
    % Chop data
    for iter1 = 1:repetitions
        for iter2 = 1:locations

            % Forward Difference
            motu_trigger = all_data.Signals.Motu{iter2,iter1}(2:end,2)-...
                all_data.Signals.Motu{iter2,iter1}(1:end-1,2);
            daq_trigger = all_data.Signals.Daq{iter2,iter1}(2:end,7)-...
                all_data.Signals.Daq{iter2,iter1}(1:end-1,7);

            % Find triggers
            [~,chop_iter_motu] = max(motu_trigger);
            [spike_daq,chop_iter_daq] = max(-daq_trigger);
            
            % In case trigger to DAQ not picked up
            chop_iter_daq_est = round(chop_iter_motu*.0273);
            if spike_daq < 2
                chop_iter_daq = chop_iter_daq_est;
                % Note: Error too large to catch phase information. 
                % Could be used for magnitude estimate but not advised.
            end
            
            % Store chopped signals
            vel_signal(iter1,iter2,:) = motu_scale*LDV_scale(iter2)*all_data.Signals.Motu{iter2,iter1}...
                (chop_iter_motu+1:chop_iter_motu+sig_length_motu,1);
            force_signal(iter1,iter2,:) = all_data.Signals.Daq{iter2,iter1}...
                (chop_iter_daq+1:chop_iter_daq+sig_length_daq,3);          
        end
    end
end