close all; clear; clc;

current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
addpath("Functions\");

lowRes = load("LowRes_ProcessedData.mat");

%% Load Data
num_participants = size(lowRes.fixed_tf,1);
num_locations = size(lowRes.fixed_tf,1);
kernal = 3;

freq = lowRes.freq;

%% Plot Impedance
free_impedance = zeros(num_participants,length(freq));
fixed_impedance = zeros(num_participants,length(freq));
for iter1 = 1:num_participants
    fixed_impedance(iter1,:) = 1./abs(lowRes.fixed_tf{iter1,1});
    free_impedance(iter1,:) = 1./abs(lowRes.free_tf{iter1,1});
end
[~,idx_100] = min(abs(freq-100)); 
fixed_impedance_dB = 20*log10(fixed_impedance./fixed_impedance(:,idx_100));
free_impedance_dB = 20*log10(free_impedance./fixed_impedance(:,idx_100));
fixed_impedance_avg = movmean(mean(fixed_impedance_dB,1),kernal);
fixed_impedance_std = movmean(std(fixed_impedance_dB,0,1),kernal);
free_impedance_avg = movmean(mean(free_impedance_dB,1),kernal);
free_impedance_std = movmean(std(free_impedance_dB,0,1),kernal);

figure;
freq_up = linspace(freq(1),freq(end),1000);
plot(freq_up,csapi(freq,fixed_impedance_avg,freq_up),'r');
hold on;
plot(freq_up,csapi(freq,fixed_impedance_avg-fixed_impedance_std,freq_up),'r');
hold on;
plot(freq_up,csapi(freq,fixed_impedance_avg+fixed_impedance_std,freq_up),'r');
hold on;
plot(freq_up,csapi(freq,free_impedance_avg,freq_up),'b');
hold on;
plot(freq_up,csapi(freq,free_impedance_avg-free_impedance_std,freq_up),'b');
hold on;
plot(freq_up,csapi(freq,free_impedance_avg+free_impedance_std,freq_up),'b');
hold off;
ylim([-30, 30])
xticks([15 50 100 200 400])
xlim([15,400])