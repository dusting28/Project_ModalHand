
%% This script is for running tactile source cloaking illusion
% Adapted from Greg
%
% Written by Dustin Goetz
%------------------------------------------------------------------------
%% Load the params file - MAKE CHANGES IN PARAMS.M!
clc
clearvars -except forceBias
close all;
folder = fileparts(which(mfilename));
addpath(genpath(folder));
Spatial_Params
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

freq_vector = reshape(repmat(TestSignal.frequencies,length(TestSignal.conditions),1),1,[]);
condition_vector = reshape(repmat(TestSignal.conditions,1,length(TestSignal.frequencies)),1,[]);

if MeasurementInfo.startTrial > 1
    load(strcat(MeasurementInfo.outputDir,MeasurementInfo.fn,"_orderVectors.mat"));
else
    order_vector = 1:length(freq_vector);
    order_cell = cell(1,MeasurementInfo.nRepetitions);
    for iter0 = 1:MeasurementInfo.nRepetitions
        if MeasurementInfo.random
            order_vector = order_vector(randperm(length(order_vector)));
        end
        order_cell{iter0} = order_vector;
    end
end

measFN = sprintf('%s%s_orderVectors.mat',...
    MeasurementInfo.outputDir,MeasurementInfo.fn);
save(measFN,'order_cell','-v7.3');

trial_num = MeasurementInfo.startTrial;
start_rep = ceil((MeasurementInfo.startTrial)/length(freq_vector));
start_signal = mod(MeasurementInfo.startTrial-1,length(freq_vector))+1;

for iter0 = start_rep:MeasurementInfo.nRepetitions
    for iter1 = start_signal:length(freq_vector)
        
        idx = order_cell{iter0}(iter1);

        freq = freq_vector(idx);
        condition = condition_vector(idx);
        amp = TestSignal.scaleFactor(idx);

        %% Move Linear Stage
        if strcmp(condition,"Free")
            write(daq_out,1);
            pause(2);
        else 
            write(daq_out,0);
            pause(2);
        end

        %%  Display Signal
        next = false;
        replay = 1;
        while ~next
            Fz = Spatial_Loop(MeasurementSignal, MeasurementInfo,TestSignal, freq, amp, trial_num, daq_in);
            
            % Get Response
            plotTrialNum(mean(-Fz),MeasurementInfo.preloadRange,"Press REDO or NEXT",'g', trial_num, 1)
            
            figure(2);
            plot(-Fz,'b');
            hold on;
            yline(MeasurementInfo.preload,'k');     
            hold off;
            ylim([0,MeasurementInfo.preload*5]);
            title(strcat("Trial: ", num2str(trial_num)));
                
            w = false;
            while ~w
                w = waitforbuttonpress; 
            end
            response = get(gcf, 'CurrentCharacter'); 

            % Go to Next
            if double(response) == 9                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
                next = true;
                trial_num = trial_num+1;
            else
                replay = replay+1;
            end
            plotTrialNum(mean(-Fz),MeasurementInfo.preloadRange,"Apply Constant Force",[.94, .94 .94],trial_num,1)
        end

        %% Save Trial Info
        measFN2 = sprintf('%s%s_Trial%i_%sCondition_%iHz.mat',...
            MeasurementInfo.outputDir,MeasurementInfo.fn,iter0,condition,freq);
        save(measFN2,'Fz','replay','-v7.3');
    end
    start_signal = 1;
end
close all;