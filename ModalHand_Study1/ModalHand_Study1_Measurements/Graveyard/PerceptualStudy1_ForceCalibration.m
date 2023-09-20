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
Default_Params
pause(1);

%% Setup Measurement Devices
dev_num = 'Dev1';
daq_in = daq('ni');
daq_in.Rate = MeasurementSignal.fs;

daq_out = daq('ni');

outputTrigger = addoutput(daq_out,dev_num,outputCh,'Digital');

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
order_vector = 1:length(freq_vector);

% Normalize Force Inputs
trial_num = 0;
for iter1 = 1:length(freq_vector)
    trial_num = trial_num+1;
    idx = order_vector(iter1);

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
    Fz = Default_Loop_HumanHand(MeasurementSignal, MeasurementInfo, TestSignal, freq, TestSignal.PeakAmp*amp, trial_num, daq_in);
    figure(1)
    plot(Fz);
    disp("Trial Complete");

    sig_length = length(Fz);
    filtered_sig = bandpass(Fz,[freq*.8,freq*1.2],MeasurementSignal.fs);
    amplitude = max(filtered_sig(floor(.4*sig_length):floor(.6*sig_length)))/2-...
        min(filtered_sig(floor(.4*sig_length):floor(.6*sig_length)))/2;
    disp(amplitude);
    scale_factors(idx) = amp*(TestSignal.desiredAmp/amplitude);
end

save("Scaling.mat", "scale_factors" ,'-v7.3');
disp(scale_factors./TestSignal.refscaleFactor);