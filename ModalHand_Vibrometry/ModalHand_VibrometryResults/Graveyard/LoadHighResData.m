%clear; clc; close all;
%% Load Data

folder = "Data/HighRes/";
filename = ["Dustin_HighRes_Free-002.mat", "Dustin_HighRes_Fixed-001.mat", ...
    "Dustin_Free_ProbeTip.mat", "Dustin_Fixed_ProbeTip2.mat"];

freq = 10.^(1:.001:3);
LDV_scale = cell(length(filename));
LDV_scale{1} = [10*ones(1,87), ones(1,60)];
LDV_scale{2} = [10*ones(1,9), ones(1,138)];
LDV_scale{3} = 10;
LDV_scale{4} = 10;

velocity = cell(1,length(filename));
force = cell(1,length(filename));

for iter1 = 3:length(filename)
    [vel_signal, force_signal, vel_fs, force_fs] = chopMeasurementData(folder,filename(iter1),LDV_scale{iter1});
    vel_response = zeros(size(vel_signal,1),size(vel_signal,2),length(freq));
    force_response = zeros(size(vel_signal,1),size(vel_signal,2),length(freq));
    for iter2 = 1:size(vel_signal,1)
        for iter3 = 1:size(vel_signal,2)
            vel_response(iter2,iter3,:) = fft_interp(squeeze(vel_signal(iter2,iter3,:)),vel_fs,freq);
            force_response(iter2,iter3,:) = fft_interp(squeeze(force_signal(iter2,iter3,:)),force_fs,freq);
        end
    end
    velocity{iter1} = squeeze(mean(vel_response,1));
    force{iter1} = squeeze(mean(force_response,1));
end