close all; clc; clear;
addpath("Data\ProcessedData");

%% Load Intensity Data
load("IntensityStudy_ProcessedData.mat")
forces = rawForce_matrix;

%% Load LowRes Data
lowRes = load("LowRes_ProcessedData.mat");

num_participants = size(lowRes.fixed_tf,1);

freq_idx = zeros(1,length(freq));
for iter1 = 1:length(freq)
    [~, freq_idx(iter1)] = min(abs(lowRes.freq-freq(iter1)));
end

%% Calculate Impedance
free_admittance = zeros(num_participants,length(freq));
fixed_admittance = zeros(num_participants,length(freq));
for iter1 = 1:num_participants
    for iter2 = 1:length(freq)
        free_admittance(iter1,iter2) = abs(lowRes.free_tf{iter1,1}(freq_idx(iter2)));
        fixed_admittance(iter1,iter2) = abs(lowRes.fixed_tf{iter1,1}(freq_idx(iter2)));
    end
end

%% Transform Data to Displacement
dis_free = zeros(size(forces,1)*size(free_admittance,1),length(freq));
dis_fixed = zeros(size(forces,1)*size(fixed_admittance,1),length(freq));
power_free = zeros(size(forces,1)*size(free_admittance,1),length(freq));
power_fixed = zeros(size(forces,1)*size(fixed_admittance,1),length(freq));
for iter1 = 1:length(freq)
    for iter2 = 1:size(free_admittance,1)
        dis_free((iter2-1)*size(forces,1)+1:(iter2)*size(forces,1),iter1) = 1000*(free_admittance(iter2,iter1).*forces(:,iter1*2))/(freq(iter1)*2*pi);
        dis_fixed((iter2-1)*size(forces,1)+1:(iter2)*size(forces,1),iter1) = 1000*(fixed_admittance(iter2,iter1).*forces(:,iter1*2-1))/(freq(iter1)*2*pi);
        power_free((iter2-1)*size(forces,1)+1:(iter2)*size(forces,1),iter1) = 1000*(free_admittance(iter2,iter1).*forces(:,iter1*2).^2);
        power_fixed((iter2-1)*size(forces,1)+1:(iter2)*size(forces,1),iter1) = 1000*(fixed_admittance(iter2,iter1).*forces(:,iter1*2-1).^2);
    end
end

%% Displacement Box Plots

jitter = .5;
figure
plot(freq,squeeze(median(20*log10(dis_free),1)),'r--');
hold on;
boxplot(20*log10(dis_free),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
plot(freq,squeeze(median(20*log10(dis_fixed),1)),'b--');
boxplot(20*log10(dis_fixed),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
title("Perception Data Transformed to Displacement")
ylabel("Point of Equivalent Perceptual Intensity (dB refrenced to 1 micron displacement")
xlabel("Frequency (Hz)")
xticklabels({'15','50','100','200','400'})

% % 20 dB
% verillo_magnitude = [23.8, 21.9, 16.8, 10.4, 6.4, 1.8, 1.8, 2.3, 2.8, 3.8];
% verillo_freq = [25, 40, 64, 100, 150, 200, 250, 350, 500, 700];
% semilogx(verillo_freq,verillo_magnitude)
% 
% % 40 dB
% verillo_magnitude = [41.5, 39, 36.2, 31.5, 26.6, 22.3, 22.3, 20.9, 19, 16.4];
% verillo_freq = [25, 40, 64, 100, 150, 200, 250, 350, 500, 700];
% semilogx(verillo_freq,verillo_magnitude,'k')

disp(20*log10(geomean(dis_free))-20*log10(geomean(dis_fixed)))

%% Power Box Plots
jitter = .5;
figure
plot(freq,squeeze(median(10*log10(power_free),1)),'r--');
hold on;
boxplot(10*log10(power_free),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
plot(freq,squeeze(median(10*log10(power_fixed),1)),'b--');
boxplot(10*log10(power_fixed),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);

disp(10*log10(geomean(power_free))-10*log10(geomean(power_fixed)))

%% Morioka
freq_morioka = [16, 31.5, 63, 125];
noSurround_morioka = [10^1.488, 10^.895, 10^-.202,10^-1.074];
surround_morioka = [10^.639, 10^.371, 10^-.129, 10^-.773];

disp(20*log10(noSurround_morioka)-20*log10(surround_morioka))
