function [Fz] = Measurement_Loop(MeasurementSignal, MeasurementInfo, TestSignal, freq, amp, location, trial_num, daq_in)
    
    MFz=[1.57108 -0.04694 1.92652 -0.04539 1.88337 -0.07715];
    scale_factor = 1000*4.44822/886/2;
    desired_preload = MeasurementInfo.preload;
    
    stable_force = false;
    mean_force = 0;
    while ~stable_force
        initial_data = read(daq_in,TestSignal.sigLength*MeasurementSignal.fs,'OutputFormat','Matrix');
        initial_force_data = initial_data(:,1:6);
        preload = -(initial_force_data-MeasurementSignal.forceBias(1:6))*MFz';
        
        mean_force = mean(preload);
        max_force = max(preload);
        min_force = min(preload);
        plotTrialNum(mean_force,MeasurementInfo.preloadRange,"Apply Constant Force",[.94, .94 .94],trial_num,1)
        if (mean_force < 1.2*desired_preload && mean_force > .8*desired_preload ...
                && max_force < 1.5*desired_preload && min_force > .5*desired_preload)
            stable_force = true;
        end
    end
    
    plotTrialNum(mean_force,MeasurementInfo.preloadRange,"Playing Vibration",'b',trial_num,1)

    %Open udp port
    u = udp('127.0.0.1',8000);  
    fopen(u);
    oscsend(u,'/MAXSig','ifii',freq,amp,location,TestSignal.sigLength);

    recordedData = read(daq_in,TestSignal.sigLength*MeasurementSignal.fs,'OutputFormat','Matrix');
    force_data = recordedData(:,1:6);
    Fz(:,1) = (force_data-MeasurementSignal.forceBias(1:6))*MFz';
    Fz(:,2) = scale_factor*(recordedData(:,7)-MeasurementSignal.forceBias(7));
    
    pause(TestSignal.delay);
    fclose(u);    
end
