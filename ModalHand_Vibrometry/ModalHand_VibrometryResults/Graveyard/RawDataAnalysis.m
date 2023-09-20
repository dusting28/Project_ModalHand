clear; clc;
addpath("Functions\")
%% Load Data

% File info
folder = "Data/HighRes/";
filename = ["Dustin_HighRes_Free-002.mat", "Dustin_HighRes_Fixed-001.mat", ...
    "Dustin_Free_ProbeTip.mat", "Dustin_Fixed_ProbeTip2.mat"];

% LDV settings
LDV_scale = cell(length(filename));
LDV_scale{1} = [10*ones(1,87), ones(1,60)];
LDV_scale{2} = [10*ones(1,9), ones(1,138)];
LDV_scale{3} = 10;
LDV_scale{4} = 10;

% Cell for storing impulse responses
transfer_func.fixed = cell(1,148);
transfer_func.free = cell(1,148);
transfer_func.x = zeros(1,148);
tranfer_func.y = zeros(1,148);

freq_samples = [15, 50, 100, 200, 400];
time_samples = log_freqMap(freq_samples, 10, 10, 1000);
num_times = 20;

name = ["Free", "Fixed"];

storage_cell = cell(1,2);
for iter1 = 1:2
    % Data loaded here
    all_data = load(strcat(folder,filename(iter1)));

    [Chopped.vel_signal, Chopped.force_signal, Chopped.vel_fs, Chopped.force_fs] = chopMeasurementData(all_data,LDV_scale{iter1});
    storage_cell{iter1} = Chopped;
end

%% Processing
close all;
yCord = linspace(18,175,49);
interpolate = 100;
for iter1 = 1:2
    vel_signal = storage_cell{iter1}.vel_signal;
    force_signal = storage_cell{iter1}.force_signal;
    vel_fs = storage_cell{iter1}.vel_fs;
    force_fs = storage_cell{iter1}.force_signal;

    num_repitions = size(vel_signal,1);
    num_locations = size(vel_signal,2);
    
    % for iter2 = 1:size(freq_samples,2)
    %     iter0 = 0;
    %     figure;
    %     for iter3 = 2:3:42
    %         iter0 = iter0+1;
    %         for iter4 = 1:num_repitions 
    %             subplot(14,1,iter0)
    %             plot(squeeze(vel_signal(iter4,iter3,...
    %                 round(time_samples(2,iter2)*vel_fs-vel_fs/time_samples(1,iter2)/2):round(time_samples(2,iter2)*vel_fs+vel_fs/time_samples(1,iter2)/2))));
    %             hold on;
    %         end
    %     end
    % end
    for iter2 = 1:size(freq_samples,2)
        nominal_time = round(time_samples(2,iter2)*vel_fs-vel_fs/time_samples(1,iter2)/2);
        axis_lim = max(abs(median(vel_signal(:,:,...
                nominal_time:round(vel_fs/time_samples(1,iter2)/num_times):nominal_time+round(vel_fs/time_samples(1,iter2)))...
                ,1)),[],"all");
        figure;
        hand_response = zeros(num_times,interpolate);
        for iter3 = 1:num_times
            % subplot(1,num_times,iter3)
            hand_response_raw1 = squeeze(median(vel_signal(:,1:3:end,...
                nominal_time + round(iter3*vel_fs/time_samples(1,iter2)/num_times)),1));
            hand_response_raw2 = squeeze(median(vel_signal(:,2:3:end,...
                nominal_time + round(iter3*vel_fs/time_samples(1,iter2)/num_times)),1));
            hand_response_raw3 = squeeze(median(vel_signal(:,3:3:end,...
                nominal_time + round(iter3*vel_fs/time_samples(1,iter2)/num_times)),1));
            hand_response(iter3,:) = interp1(linspace(18,175,49),hand_response_raw1,linspace(18,175,interpolate));
            p = plot(yCord,hand_response_raw1, yCord,hand_response_raw2, yCord,hand_response_raw3);
            ylim([-1.1*axis_lim, 1.1*axis_lim]);
            xlim([0, 200]);
            hold on;
            xline(25,'k');
            xline(51,'k');
            xline(104,'k');
            xline(182,'k'); 
            hold off;
            exportgraphics(gcf,strcat("AllLines_",name(iter1),"_",num2str(time_samples(1,iter2)),"Hz",".gif"),'Append',true);
        end
        [~,k_idx] = max(hand_response(:,1)); 
        hold off;
        ks = .3057;
        [k,k_amp] = fft_spectral(hand_response(k_idx,:)',ks);
        figure;
        subplot(2,1,1)
        plot(linspace(18,175,interpolate),hand_response(k_idx,:)')
        subplot(2,1,2)
        plot(k,abs(k_amp));
        hold on;
    end
end

function freq_map = log_freqMap(freq,T,freq_1,freq_2)
    freq_map = [freq; T*log(freq/freq_1)/log(freq_2/freq_1)];
end
