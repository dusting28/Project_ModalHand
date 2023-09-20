clear; clc; close all;
%% Load Data
freq = 10.^(1:.001:3);

folder = "Data/HighRes/";
filename = ["Dustin_HighRes_Free-002.mat", "Dustin_HighRes_Fixed-001.mat", ...
    "Dustin_Free_ProbeTip.mat", "Dustin_Fixed_ProbeTip2.mat"];

LDV_scale = cell(length(filename));
LDV_scale{1} = [10*ones(1,87), ones(1,60)];
LDV_scale{2} = [10*ones(1,9), ones(1,138)];
LDV_scale{3} = 10;
LDV_scale{4} = 10;

loaded_vel = cell(1,length(filename));
loaded_force = cell(1,length(filename));


for iter1 = 1:length(filename)
    [vel_signal, force_signal, vel_fs, force_fs] = chopMeasurementData(folder,filename(iter1),LDV_scale{iter1});
    vel_snr = zeros(size(vel_signal,1),size(vel_signal,2),length(freq));
    force_snr = zeros(size(vel_signal,1),size(vel_signal,2),length(freq));

    for iter2 = 1:size(vel_signal,1)
        for iter3 = 1:size(vel_signal,2)
            vel_snr(iter2,iter3,:) = computeSNR(squeeze(vel_signal(iter2,iter3,:)-median(vel_signal(iter2,iter3,:)))...
                ,log_freqMap(freq,10,1000,10),50,vel_fs);
            force_snr(iter2,iter3,:) = computeSNR(squeeze(force_signal(iter2,iter3,:)-median(force_signal(iter2,iter3,:)))...
                ,log_freqMap(freq,10,1000,10),50,force_fs);
        end
    end
    loaded_vel{iter1} = squeeze(permute(mean(vel_snr,1),[1,3,2]))';
    loaded_force{iter1} = squeeze(permute(mean(force_snr,1),[1,3,2]))';
end

function freq_map = log_freqMap(freq,f1,f2,T)
    freq_map = [freq; T*log(freq/f1)/log(f2/f1)];
end
