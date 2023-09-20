%% This script is for running tactile source cloaking illusion
% Adapted from Greg
%
% Written by Dustin Goetz
%------------------------------------------------------------------------
%% Load the params file - MAKE CHANGES IN PARAMS.M!
clc
warning('off','all');
clearvars -except forceBias
folder = fileparts(which(mfilename));
addpath(genpath(folder));
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
freq_vector = reshape(repmat(TestSignal.frequencies,length(TestSignal.locations),1),1,[]);
location_vector = reshape(repmat(TestSignal.locations,1,length(TestSignal.frequencies)),1,[]);
if strcmp(MeasurementInfo.condition,"Fixed")
    amp_vector = reshape(repmat(TestSignal.scaleFactor(1:2:end)',length(TestSignal.locations),1),1,[]);
end
if strcmp(MeasurementInfo.condition,"Free")
    amp_vector = reshape(repmat(TestSignal.scaleFactor(2:2:end)',length(TestSignal.locations),1),1,[]);
end

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

        if and(iter0==11, iter1==1)
            disp("Break")
        end
        
        idx = order_cell{iter0}(iter1);
        freq = freq_vector(idx);
        location = location_vector(idx);
        amp = amp_vector(idx);
        
        location_idx = 0;
        for iter2 = 1:length(TestSignal.locations)
            if strcmp(location,TestSignal.locations(iter2))
                location_idx = iter2;
            end
        end

        %%  Display Signal
        [Fz] = Measurement_Loop(MeasurementSignal, MeasurementInfo, TestSignal, freq, amp, location_idx, trial_num, daq_in);

        % Get Response
        figure(2);
        plot(squeeze(Fz(:,1))-mean(Fz(:,1)),'b');
        hold on;
        plot(squeeze(Fz(:,2)),'g');
        hold off;
        ylim([-MeasurementInfo.preload,MeasurementInfo.preload]);
        title(strcat("Trial: ", num2str(trial_num)));

        plotTrialNum(-mean(Fz(:,1)),MeasurementInfo.preloadRange,"Press TIP or BASE",'g', trial_num, 1)
        
        w = false;
        while ~w
            w = waitforbuttonpress; 
        end
        response = get(gcf, 'CurrentCharacter');

        % Go to Next
        if double(response) == 9
            perceived = "Base";
        else
            perceived = "Tip";
        end   
        
        correct = false;
        if strcmp(perceived, location)
            correct = true;
        end

        trial_num = trial_num+1;
        plotTrialNum(-mean(Fz(:,1)),MeasurementInfo.preloadRange,"Apply Constant Force",[.94, .94 .94],trial_num,1)
        
        %% Save Input Forces
        measFN2 = sprintf('%s%s_Trial%i_%iHz_%s.mat',...
            MeasurementInfo.outputDir,MeasurementInfo.fn,iter0,freq,location);
        save(measFN2,'Fz','correct','-v7.3');
    end
    start_signal = 1;
end
close all;