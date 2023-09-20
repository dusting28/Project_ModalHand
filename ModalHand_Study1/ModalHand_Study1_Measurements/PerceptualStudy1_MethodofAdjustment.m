%% This script is for running tactile source cloaking illusion
% Adapted from Greg
%
% Written by Dustin Goetz
%------------------------------------------------------------------------
%% Load the params file - MAKE CHANGES IN PARAMS.M!
clc
clearvars -except forceBias
folder = fileparts(which(mfilename));
addpath(genpath(folder));
New_Params
pause(1);

%% Setup Measurement Devices
dev_num = 'Dev1';
daq_in = daq('ni');
daq_in.Rate = MeasurementSignal.fs;

daq_out = daq('ni');

outputTrigger = addoutput(daq_out,dev_num,MeasurementSignal.outputCh,'Digital');

for iter1 = 1:length(MeasurementSignal.allChannel)
    analogInput = addinput(daq_in,dev_num,MeasurementSignal.allChannel(iter1),'Voltage');
    analogInput.TerminalConfig = 'SingleEnded'; %floating measurement signal
end

if ~exist('forceBias','var')
    input('Re-taking force bias measurements. Please acknowledge that there is nothing contacting the force sensor')
    forceBias = forceBiasMeas(daq_in,12);
    input('Done taking bias measurements. Press Enter to continue');
end

%% MAIN LOOP
MeasurementSignal.forceBias = forceBias;
scale_factors = zeros(1,length(TestSignal.frequencies)*length(TestSignal.conditions));

freq_vector = reshape(repmat(TestSignal.frequencies,length(TestSignal.conditions),1),1,[]);
condition_vector = reshape(repmat(TestSignal.conditions,1,length(TestSignal.frequencies)),1,[]);

if MeasurementInfo.startTrial > 1
    load(strcat('Data/PerceptualNorm/',MeasurementInfo.fn,"_scaleFactors.mat"));
    load(strcat('Data/PerceptualNorm/',MeasurementInfo.fn,"_orderVector.mat"));
else
    scale_factors = zeros(length(freq_vector),2);
    order_vector = 1:2*length(freq_vector);
    if MeasurementInfo.random
        order_vector = order_vector(randperm(length(order_vector)));
    end
end
        
measFN = sprintf('%s%s_orderVector.mat',...
    MeasurementInfo.outputDir,MeasurementInfo.fn);
save(measFN,'order_vector','-v7.3');

disp(MeasurementInfo.startTrial);

for trial_num = MeasurementInfo.startTrial:length(order_vector)
    idx = mod(order_vector(trial_num)-1,length(freq_vector))+1;
    amp_idx = ceil(order_vector(trial_num)/length(freq_vector));
    if amp_idx == 1
        amp_factor = .5;
    end
    if amp_idx == 2
        amp_factor = 2;
    end

    freq = freq_vector(idx);
    condition = condition_vector(idx);
    amp = amp_factor*TestSignal.defaultOutputs(idx);

    %%  Display Signal
    next = false;
    replay = 0;
    getSlider = 0;
    while ~next
        replay = replay+1;
        write(daq_out,0);
        pause(2);
        Fz_comp = Default_Loop(MeasurementSignal, MeasurementInfo,TestSignal, freq_vector(5), TestSignal.defaultOutputs(5), trial_num, daq_in);
        
        % Get Response
        figure(2);
        plot(-Fz_comp,'b');
        hold on;
        yline(MeasurementInfo.preload,'k');
        hold off;
        ylim([0,MeasurementInfo.preload*5]);
        title(strcat("Trial: ", num2str(trial_num)));
        
        if strcmp(condition,"Free")
            write(daq_out,1);
            pause(2);
        else 
            write(daq_out,0);
            pause(0);
        end
        Fz = Default_Loop(MeasurementSignal, MeasurementInfo,TestSignal, freq, amp, trial_num, daq_in);
        disp("Trial Complete");
        
        figure(2);
        plot(-Fz_comp,'b');
        hold on;
        yline(MeasurementInfo.preload,'k');
        hold off;
        ylim([0,MeasurementInfo.preload*5]);
        title(strcat("Trial: ", num2str(trial_num)));
        
        app = UI_Loop(getSlider,trial_num);
        quit = false;
        while ~quit
            pause(0.05);
            [getSlider,next,quit] = app.getStatus();
        end

        scale_factors(idx,amp_idx) = amp_factor*TestSignal.defaultOutputs(idx)*(2^getSlider);

        measFN2 = sprintf('%s%s_Trial%i-%i_%sCondition_%iHz.mat',...
            MeasurementInfo.outputDir,MeasurementInfo.fn,trial_num,replay,condition,freq);
        save(measFN2,'Fz_comp','Fz','amp','-v7.3');

        amp = scale_factors(idx,amp_idx);
    end
    measFN3 = sprintf('%s%s_scaleFactors.mat',...
        MeasurementInfo.outputDir,MeasurementInfo.fn);
    save(measFN3,'scale_factors','-v7.3');
end
close all;