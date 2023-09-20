close all; clear; clc;
addpath("Data\")
lowRes = load("LowRes_ProcessedData.mat");

%% Load Data
num_participants = size(lowRes.fixed_tf,1);
num_locations = size(lowRes.fixed_tf,1);
filter_band = [15, 900];
downsample_factor = 10;
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
    semilogx(freq(1:downsample_factor:end),fixed_admittance_avg(1:downsample_factor:end),'r');
    hold on;
    lower = fixed_admittance_avg(1:downsample_factor:end)-fixed_admittance_std(1:downsample_factor:end);
    lower(lower<0) = 0;
    semilogx(freq(1:downsample_factor:end),lower,'r');
    hold on;
    semilogx(freq(1:downsample_factor:end),fixed_admittance_avg(1:downsample_factor:end)+fixed_admittance_std(1:downsample_factor:end),'r');
    hold off;
    figure;
    semilogx(freq(1:downsample_factor:end),free_admittance_avg(1:downsample_factor:end),'b');
    hold on;
    lower = free_admittance_avg(1:downsample_factor:end)-free_admittance_std(1:downsample_factor:end);
    lower(lower<0) = 0;
    semilogx(freq(1:downsample_factor:end),lower,'b');
    hold on;
    semilogx(freq(1:downsample_factor:end),free_admittance_avg(1:downsample_factor:end)+free_admittance_std(1:downsample_factor:end),'b');
    hold off;
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
fixed_impedance_avg = movmean(mean(fixed_impedance_dB,1),1);
fixed_impedance_std = movmean(std(fixed_impedance_dB,0,1),1);
free_impedance_avg = movmean(mean(free_impedance_dB,1),1);
free_impedance_std = movmean(std(free_impedance_dB,0,1),1);

figure;
plot(freq(1:downsample_factor:end),fixed_impedance_avg(1:downsample_factor:end),'r');
hold on;
plot(freq(1:downsample_factor:end),fixed_impedance_avg(1:downsample_factor:end)-fixed_impedance_std(1:downsample_factor:end),'r');
hold on;
plot(freq(1:downsample_factor:end),fixed_impedance_avg(1:downsample_factor:end)+fixed_impedance_std(1:downsample_factor:end),'r');
hold on;
plot(freq(1:downsample_factor:end),free_impedance_avg(1:downsample_factor:end),'b');
hold on;
plot(freq(1:downsample_factor:end),free_impedance_avg(1:downsample_factor:end)-free_impedance_std(1:downsample_factor:end),'b');
hold on;
plot(freq(1:downsample_factor:end),free_impedance_avg(1:downsample_factor:end)+free_impedance_std(1:downsample_factor:end),'b');
hold off;
ylim([-30, 30])
xticks([15 50 100 200 400])
xlim([15,400])