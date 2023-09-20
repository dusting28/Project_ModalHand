%% This script is for running tactile source cloaking illusion
% Adapted from Greg
%
% Written by Dustin Goetz
%------------------------------------------------------------------------
%% Load the params file - MAKE CHANGES IN PARAMS.M!
clc
clearvars -except forceBias
close all;
warning('off','all')
folder = fileparts(which(mfilename));
addpath(genpath(folder));
Normalization_Params
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

comparison_idx = 5;
 
trial_num = 0;
while true
    trial_num = trial_num+1;
    presentation = randperm(2);
    freq = [100, 75];
    condition = ["Fixed", "Free"];
    output = [TestSignal.defaultOutputs(comparison_idx), 4*TestSignal.defaultOutputs(comparison_idx)];
        
    %  Display Signal

    if strcmp(condition(presentation(1)),"Free")
        write(daq_out,1);
    else 
        write(daq_out,0);
    end

    if or(~strcmp(condition(presentation(1)), condition(presentation(2))), trial_num==1)
        pause(2);
    end

    Fz_1 = Default_Loop(MeasurementSignal, MeasurementInfo, TestSignal,...
        freq(presentation(1)), output(presentation(1)), "A", daq_in);
    
    plotForces(mean(-Fz_1),MeasurementInfo.preloadRange,"Apply Constant Force",[.94, .94 .94],1)

    % Get Response
    figure(2);
    plot(-Fz_1,'b');
    hold on;
    yline(MeasurementInfo.preload,'k');
    hold off;
    ylim([0,MeasurementInfo.preload*5]);
    title(strcat("Trial: ", num2str(trial_num)));

    
    if strcmp(condition(presentation(2)),"Free")
        write(daq_out,1);
    else 
        write(daq_out,0);
    end    

    if ~strcmp(condition(presentation(1)), condition(presentation(2)))
        pause(2);
    end

    Fz_2 = Default_Loop(MeasurementSignal, MeasurementInfo, TestSignal,...
        freq(presentation(2)), output(presentation(2)), "B", daq_in);
    
    figure(2);
    plot(-Fz_2,'b');
    hold on;
    yline(MeasurementInfo.preload,'k');
    hold off;
    ylim([0,MeasurementInfo.preload*5]);
    title(strcat("Trial: ", num2str(trial_num)));
    
    plotForces(mean(-Fz_2),MeasurementInfo.preloadRange,"Enter A or B",'g',1)

    w = false;
    while ~w
            w = waitforbuttonpress; 
    end
    response = get(gcf, 'CurrentCharacter'); 

    plotForces(mean(-Fz_2),MeasurementInfo.preloadRange,"Apply Constant Force",[.94, .94 .94],1)
end
