function [Fz] = Default_Loop(MeasurementSignal, MeasurementInfo, TestSignal, freq, amp, trial_num, daq_in)

    MFx=[0.00364 -0.04142 -0.16003 -1.67055 0.09189 1.63189];   % scaling matrix from Mengjia's models. I assume these values are directly from the ATI weebsite
    MFy=[0.05623 2.02388 -0.09620 -1.00659 -0.04977 -0.91361];
    MFz=[1.57108 -0.04694 1.92652 -0.04539 1.88337 -0.07715];
    MTx=[0.59557 12.2419 10.2107 -6.39444 -10.74076 -5.12130];
    MTy=[-9.94484 0.64581 7.72366 9.94193 5.20606 -10.13430];
    MTz=[0.19084 7.21740 0.69153 7.37822 0.45365 6.91279];
    
    desired_preload = MeasurementInfo.preloadRange;
    
    stable_force = false;
    while ~stable_force
        initial_data = read(daq_in,TestSignal.sigLength*MeasurementSignal.fs/2);
        initial_force_data = [initial_data.Dev1_ai0, initial_data.Dev1_ai1, initial_data.Dev1_ai2,...
            initial_data.Dev1_ai4, initial_data.Dev1_ai5, initial_data.Dev1_ai6];
        preload = -(initial_force_data-MeasurementSignal.forceBias)*MFz';
        
        mean_force = mean(preload);
        max_force = max(preload);
        min_force = min(preload);
        plotForces(mean_force,desired_preload,"Apply Constant Force",[.94, .94 .94],1)
        if and(min_force > desired_preload(1), max_force < desired_preload(2))
            stable_force = true;
        end
    end
    
    plotForces(mean_force,desired_preload,num2str(trial_num),'b',1)
    
    %Open udp port
    u = udp('127.0.0.1',8000);  
    fopen(u);
    oscsend(u,'/MAXSig','ifi',freq,amp,TestSignal.sigLength);

    recordedData = read(daq_in,TestSignal.sigLength*MeasurementSignal.fs); %start the foreground task for measurements 

    force_data = [recordedData.Dev1_ai0, recordedData.Dev1_ai1, recordedData.Dev1_ai2,...
        recordedData.Dev1_ai4, recordedData.Dev1_ai5, recordedData.Dev1_ai6];

    Fx = (force_data-MeasurementSignal.forceBias)*MFx';
    Fy = (force_data-MeasurementSignal.forceBias)*MFy';
    Fz = (force_data-MeasurementSignal.forceBias)*MFz';
    Tx = (force_data-MeasurementSignal.forceBias)*MTx';
    Ty = (force_data-MeasurementSignal.forceBias)*MTy';
    Tz = (force_data-MeasurementSignal.forceBias)*MTz';

    pause(TestSignal.delay);
    fclose(u);
    
end
