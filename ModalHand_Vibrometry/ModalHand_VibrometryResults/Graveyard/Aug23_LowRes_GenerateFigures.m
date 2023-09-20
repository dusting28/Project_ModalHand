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
filter_band = [15, 400];
kernal = 3;
filter_idx = or(lowRes.freq<filter_band(1),lowRes.freq>filter_band(2));

freq = lowRes.freq(~filter_idx);

%% Plot Admittance
free_admittance= zeros(num_participants,sum(~filter_idx));
fixed_admittance = zeros(num_participants,sum(~filter_idx));
for iter1 = 1:num_locations
    for iter2 = 1:num_participants
        fixed_admittance(iter2,:) = abs(lowRes.fixed_tf{iter2,iter1}(~filter_idx));
        free_admittance(iter2,:) = abs(lowRes.free_tf{iter2,iter1}(~filter_idx));
    end
    fixed_admittance_avg = movmean(mean(fixed_admittance,1),1);
    fixed_admittance_std = movmean(std(fixed_admittance,0,1),1);
    free_admittance_avg = movmean(mean(free_admittance,1),1);
    free_admittance_std = movmean(std(free_admittance,0,1),1);
    figure;
    plot(freq,fixed_admittance_avg,'r');
    hold on;
    lower = fixed_admittance_avg-fixed_admittance_std;
    lower(lower<0) = 0;
    plot(freq,lower,'r');
    hold on;
    plot(freq,fixed_admittance_avg+fixed_admittance_std,'r');
    hold off;
    figure;
    plot(freq,free_admittance_avg,'b');
    hold on;
    lower = free_admittance_avg-free_admittance_std;
    lower(lower<0) = 0;
    plot(freq,lower,'b');
    hold on;
    semilogx(freq,free_admittance_avg+free_admittance_std,'b');
    hold off;
end

%% Plot Admittance
free_admittance= zeros(num_participants,sum(~filter_idx));
fixed_admittance = zeros(num_participants,sum(~filter_idx));
for iter1 = 1:num_locations
    figure;
    for iter2 = 1:num_participants
        fixed_admittance(iter2,:) = abs(lowRes.fixed_tf{iter2,iter1}(~filter_idx));
        semilogy(freq,squeeze(fixed_admittance(iter2,:)),'r')
        hold on;
        ylim([10^-1,10^3])
    end
    figure;
    for iter2 = 1:num_participants
        free_admittance(iter2,:) = abs(lowRes.free_tf{iter2,iter1}(~filter_idx));
        semilogy(freq,squeeze(free_admittance(iter2,:)),'b')
        hold on;
        ylim([10^-1,10^3])
    end
end

%% Plot Impedance
free_impedance = zeros(num_participants,sum(~filter_idx));
fixed_impedance = zeros(num_participants,sum(~filter_idx));
for iter1 = 1:num_participants
    fixed_impedance(iter1,:) = 1./abs(lowRes.fixed_tf{iter1,1}(~filter_idx));
    free_impedance(iter1,:) = 1./abs(lowRes.free_tf{iter1,1}(~filter_idx));
end
[~,idx_100] = min(abs(freq-100)); 
fixed_impedance_dB = 20*log10(fixed_impedance./fixed_impedance(:,idx_100));
free_impedance_dB = 20*log10(free_impedance./fixed_impedance(:,idx_100));
fixed_impedance_avg = movmean(mean(fixed_impedance_dB,1),kernal);
fixed_impedance_std = movmean(std(fixed_impedance_dB,0,1),kernal);
free_impedance_avg = movmean(mean(free_impedance_dB,1),kernal);
free_impedance_std = movmean(std(free_impedance_dB,0,1),kernal);

figure;
plot(freq,fixed_impedance_avg,'r');
hold on;
plot(freq,fixed_impedance_avg-fixed_impedance_std,'r');
hold on;
plot(freq,fixed_impedance_avg+fixed_impedance_std,'r');
hold on;
plot(freq,free_impedance_avg,'b');
hold on;
plot(freq,free_impedance_avg-free_impedance_std,'b');
hold on;
plot(freq,free_impedance_avg+free_impedance_std,'b');
hold off;
ylim([-30, 20])
xticks([15 50 100 200 400])
xlim([15,400])