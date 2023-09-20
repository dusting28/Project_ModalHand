
%% This script is for running tactile source cloaking illusion
% Adapted from Greg
%
% Written by Dustin Goetz
%------------------------------------------------------------------------
%% Load the params file - MAKE CHANGES IN PARAMS.M!
clc
clearvars
close all;
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

write(daq_out,1);

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
order_vector = 1:length(freq_vector);

% Set Linear Stage Values
trial_num = 0;
next = false;
MFz=[1.57108 -0.04694 1.92652 -0.04539 1.88337 -0.07715];
write(daq_out,0);

while ~next
    initial_data = read(daq_in,TestSignal.sigLength*MeasurementSignal.fs);
    initial_force_data = [initial_data.Dev1_ai0, initial_data.Dev1_ai1, initial_data.Dev1_ai2,...
        initial_data.Dev1_ai4, initial_data.Dev1_ai5, initial_data.Dev1_ai6];
    preload = -(initial_force_data-MeasurementSignal.forceBias)*MFz';
    plotForces(mean(preload),MeasurementInfo.preloadRange,"Have Researcher Adjsut Probe Position",'g',1)
    figure(2)
    plot(preload,'r');
    hold on;
    yline(MeasurementInfo.preload,'k');
    hold off;
    ylim([0,MeasurementInfo.preload*2]);
    title(strcat("Trial: ", num2str(trial_num)));
end

