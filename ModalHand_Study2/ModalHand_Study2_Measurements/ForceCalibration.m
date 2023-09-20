%% This script is for running tactile source cloaking illusion
% Adapted from Greg
%
% Written by Dustin Goetz
%------------------------------------------------------------------------
%% Load the params file - MAKE CHANGES IN PARAMS.M!
clc
warning('off','all');
clearvars -except forceBias
Default_Params

%% Setup Measurement Devices
dev_num = 'Dev1';
daq_in = daq('ni');
daq_in.Rate = MeasurementSignal.fs;

for iter1 = 1:length(MeasurementSignal.forceCh)
    analogInput = addinput(daq_in,dev_num,MeasurementSignal.forceCh(iter1),'Voltage');
    analogInput.TerminalConfig = 'SingleEnded'; %floating measurement signal
end

analogInput = addinput(daq_in,dev_num,MeasurementSignal.piezoCh,'Voltage');
analogInput.TerminalConfig = 'Differential'; %floating measurement signal

if ~exist('forceBias','var')
    input('Re-taking force bias measurements. Please acknowledge that there is nothing contacting the force sensor')
    forceBias = forceBiasMeas(daq_in,12*MeasurementSignal.fs);
    input('Done taking bias measurements. Press Enter to continue');
end
MeasurementSignal.forceBias = forceBias;

%% MAIN LOOP
MFz=[1.57108 -0.04694 1.92652 -0.04539 1.88337 -0.07715];
scale_factor = 1000*4.44822/886/2;
desired_preload = MeasurementInfo.preload;

stable_force = false;
while ~stable_force
    initial_data = read(daq_in,1*MeasurementSignal.fs,'OutputFormat','Matrix');
    initial_force_data = initial_data(:,1:6);
    preload = -(initial_force_data-MeasurementSignal.forceBias(1:6))*MFz';
    
    figure(1)
    plot(preload,'r')
    hold on;
    yline(MeasurementInfo.preload,'k')
    hold off;
    ylim([0,3*MeasurementInfo.preload])
end

close all;