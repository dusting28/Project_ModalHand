function [Signals] = MeasurementLoop_ModalTest(MeasurementSignal, MeasurementInfo, TestSignal, daq_in, recObj, vidInfo,SLDVInfo,plotter)
    
    MFx=[0.00364 -0.04142 -0.16003 -1.67055 0.09189 1.63189];   % scaling matrix from Mengjia's models. I assume these values are directly from the ATI weebsite
    MFy=[0.05623 2.02388 -0.09620 -1.00659 -0.04977 -0.91361];
    MFz=[1.57108 -0.04694 1.92652 -0.04539 1.88337 -0.07715];
    MTx=[0.59557 12.2419 10.2107 -6.39444 -10.74076 -5.12130];
    MTy=[-9.94484 0.64581 7.72366 9.94193 5.20606 -10.13430];
    MTz=[0.19084 7.21740 0.69153 7.37822 0.45365 6.91279];
    
    desired_preload = MeasurementInfo.preload;
    
    stable_force = false; % changed 9-2
    
    axes(plotter.imP)

    while ~stable_force
        initial_data = read(daq_in,2*MeasurementSignal.fs,'OutputFormat','Matrix');
        initial_force_data = initial_data(:,1:6);
        
        %initial_force_data = [initial_data.Dev1_ai1, initial_data.Dev1_ai2, initial_data.Dev1_ai3,...
        %    initial_data.Dev1_ai5, initial_data.Dev1_ai6, initial_data.Dev1_ai7];
        
        preload = -(initial_force_data-MeasurementSignal.forceBias)*MFz';
        mean_force = mean(preload);
        max_force = max(preload);
        min_force = min(preload);
        %disp([min_force,mean_force,max_force]);
        if (mean_force < 1.2*desired_preload && mean_force > .8*desired_preload ...
                && max_force < 1.5*desired_preload && min_force > .5*desired_preload)
            stable_force = true;
        end
        
        plotter.t1.String = sprintf('Min Force: %0.2f',min_force);
        plotter.t2.String = sprintf('Mean Force: %0.2f',mean_force);
        plotter.t3.String = sprintf('Max Force: %0.2f',max_force);
    end
    
    
    u = udp('127.0.0.1',8000);  
    fopen(u);
        
    for j = 1:MeasurementInfo.nRepetitions

        % insert camera snapshot here
%         img = GetImage(vidInfo);
%         plotter.im.CData = img;
%         plotter.repText.String = sprintf('Repetition: %i',j);
        
        %send udp message to Max
        oscsend(u, '/sigType','s', TestSignal.udpmessage);
        
        %
        start(daq_in,'Duration',TestSignal.sigLength*MeasurementSignal.fs);
        recordblocking(recObj, TestSignal.sigLength+1);
        stop(daq_in);

        y = getaudiodata(recObj);
        
%         Signals.Image(j) = {img};
        Signals.Motu(j) = {y};
        
        recordedData = read(daq_in,'all','OutputFormat','Matrix');
        force_data = recordedData(:,1:6);

        Fx = (force_data-MeasurementSignal.forceBias)*MFx';
        Fy = (force_data-MeasurementSignal.forceBias)*MFy';
        Fz = (force_data-MeasurementSignal.forceBias)*MFz';
        Tx = (force_data-MeasurementSignal.forceBias)*MTx';
        Ty = (force_data-MeasurementSignal.forceBias)*MTy';
        Tz = (force_data-MeasurementSignal.forceBias)*MTz';

        yDaq = [Fx,Fy,Fz,Tx,Ty,Tz,recordedData(:,7)];
        Signals.Daq(j) = {yDaq};
       
        axes(plotter.p1)
        plot(Fx)
        hold on
        plot(Fy)
        plot(Fz)
        plot(recordedData(:,7))
        hold off
        
        axes(plotter.p2)
        plot(Tx)
        hold on
        plot(Ty)
        plot(Tz)
        plot(recordedData(:,7))
        hold off
        
        axes(plotter.p3)
        plot(y);
        
        if ((max(abs(y(:,1)))*SLDVInfo.VoltageFactor) < 0.5)
            fprintf('Max Velocity Below 0.5 Volts \n');
        end

        %fprintf('Completed Trial %i\n',j);
        pause(1);
    end
    
    fclose(u);
    
end

