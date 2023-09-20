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
scale_factors = zeros(1,length(TestSignal.frequencies)*length(TestSignal.conditions));

freq_vector = reshape(repmat(TestSignal.frequencies,length(TestSignal.conditions),1),1,[]);
condition_vector = reshape(repmat(TestSignal.conditions,1,length(TestSignal.frequencies)),1,[]);

comparison_idx = 5;

if MeasurementInfo.startTrial > 1
    load(strcat('Data/PerceptualNorm/',MeasurementInfo.fn,"_orderVector.mat"));
    load(strcat('Data/PerceptualNorm/',MeasurementInfo.fn,"_scaleFactors.mat"));
else
    order_vector = 1:length(freq_vector);
%     order_vector = order_vector(order_vector~=(comparison_idx+1));
    if MeasurementInfo.random
        order_vector = order_vector(randperm(length(order_vector)));
    end
%     order_vector = [comparison_idx+1, order_vector];
end
        
measFN = sprintf('%s%s_orderVector.mat',...
    MeasurementInfo.outputDir,MeasurementInfo.fn);
save(measFN,'order_vector','-v7.3');

for iter1 = MeasurementInfo.startTrial:length(order_vector)
    disp(iter1);
    if iter1 == 6
        close all;
        disp("Put Break Point Here")
    end
    trial_num = 0;
    idx = order_vector(iter1);
    interweave = randi(2);
    amp = {(10^(12/20))*TestSignal.defaultOutputs(idx), (10^(-12/20))*TestSignal.defaultOutputs(idx)};
    stop = false;
    reversal = [0,0];

    while ~stop
        presentation = randperm(2);
        trial_num = trial_num+1;
%         if or(mod(idx,2),iter1==1)
%             freq = [freq_vector(comparison_idx), freq_vector(idx)];
%             condition = [condition_vector(comparison_idx), condition_vector(idx)];
%             output = [TestSignal.defaultOutputs(comparison_idx), amp{interweave}(end)];
%         else
%             freq = [freq_vector(comparison_idx+1), freq_vector(idx)];
%             condition = [condition_vector(comparison_idx+1), condition_vector(idx)];
%             output = [scale_factors(comparison_idx+1), amp{interweave}(end)];
%         end

        freq = [freq_vector(comparison_idx), freq_vector(idx)];
        condition = [condition_vector(comparison_idx), condition_vector(idx)];
        output = [TestSignal.defaultOutputs(comparison_idx), amp{interweave}(end)];

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
    
        % Go to Next
        if double(response) == 9                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
            stronger = 2;
        else
            stronger = 1;
        end
    
        measFN2 = sprintf('%s%s_Trial%i_%sCondition_%iHz.mat',...
            MeasurementInfo.outputDir,MeasurementInfo.fn,trial_num,condition(2),freq(2));
        save(measFN2,'Fz_1','Fz_2','output','presentation','stronger','interweave','-v7.3');
        % Fz_1 - Force from first stimulus played
        % Fz_2 - Force from second stimulus played
        % output - Output amplitudes (1st element - comparison, 2nd - test)
        % presentation - Order of stimuli (1 - comparison, 2 - test)
        % stronger - User response (1 - first stimulus, 2 - second)
        % interweave - Staircase (1 - upper, 2 - lower)


        decrease = find(presentation==stronger) - 1;

        if length(amp{interweave}) > 1
            if and(amp{interweave}(end)/amp{interweave}(end-1)<1, ~decrease)
                reversal(interweave) = reversal(interweave)+1;
            end
            if and(amp{interweave}(end)/amp{interweave}(end-1)>1, decrease)
                reversal(interweave) = reversal(interweave)+1;
            end
        end

        if reversal(interweave) > 2
            adjust = 3;
        else
            adjust = 6;
        end

        if decrease
            amp{interweave}(end+1) = amp{interweave}(end)*(10^(-adjust/20));
        else
            amp{interweave}(end+1) = amp{interweave}(end)*(10^(adjust/20));
        end

        if reversal(mod(interweave,2)+1) < 12
            interweave = mod(interweave,2)+1;
        end

        if and(reversal(1)>=12, reversal(2)>=12)
            stop = true;
        end
    
    end
    
    measFN2 = sprintf('%s%s_Staircase_%sCondition_%iHz.mat',...
            MeasurementInfo.outputDir,MeasurementInfo.fn,condition(2),freq(2));
        save(measFN2,'amp','-v7.3');

    scale_factors(idx) = mean([mean(amp{1}(end-9:end-1)), mean(amp{2}(end-9:end-1))]);
    measFN3 = sprintf('%s%s_scaleFactors.mat',...
    MeasurementInfo.outputDir,MeasurementInfo.fn);
    save(measFN3,'scale_factors','-v7.3');
end
close all;
