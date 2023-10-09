clc; clear; close all;

%% Load Processed Data
current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
addpath(strcat(outer_folder, "\ModalHand_VibrometryResults\Functions"));

newtonEuler = load("NewtonEulerData.mat");
highRes = load("HighRes_ProcessedData.mat");
lowRes = load("LowRes_ProcessedData.mat");

%% Parameters
kernal = 3;
include_probe = false;
wave_model = "Manfredi";

%% HighRes Projection
if include_probe
    y_locations = highRes.yCord;
else
    y_locations = highRes.yCord(2:end);
end

freq = newtonEuler.freq;

articulated_admittance = newtonEulerAdmittance(newtonEuler,y_locations);
wave_admittance = waveAdmittance(newtonEuler.y0_out-newtonEuler.y1_out,...
    1000*newtonEuler.l1/2, freq, y_locations, wave_model);
sup_admittance = articulated_admittance + wave_admittance;
wave_admittance = waveAdmittance(newtonEuler.y_fixed,...
    1000*newtonEuler.l1/2, freq, y_locations, wave_model);

unwrappedAdmittance(freq,highRes,wave_admittance', kernal, include_probe);
unwrappedAdmittance(freq,highRes,articulated_admittance', kernal, include_probe);
unwrappedAdmittance(freq,highRes,sup_admittance', kernal, include_probe);

%% Generate Line Plots
position = highRes.yCord(1+not(include_probe):3:end);
position_up = linspace(position(1),position(end),1000);
sample_freqs = [15, 50, 100, 200, 400];
for iter1 = 1:length(sample_freqs)
    [~, sample_idx] = min(abs(freq-sample_freqs(iter1)));
    normalized_sup = singleAxis(abs(sup_admittance(:,sample_idx))',include_probe);
    normalized_wave = singleAxis(abs(wave_admittance(:,sample_idx))',include_probe);
    
    % Smooth Data
    normalized_sup = movmean(normalized_sup,kernal);
    normalized_wave = movmean(normalized_wave,kernal);

    % Normalize Data
    normalized_sup = normalized_sup/normalized_sup(1);
    normalized_wave = normalized_wave/normalized_wave(1);

    % Plot Data (5 Subplots)
    figure
    plot(position_up, csapi(position,normalized_wave,position_up),'r')
    hold on;
    plot(position_up, csapi(position,normalized_sup,position_up),'b')
    title(strcat(num2str(sample_freqs(iter1))," Hz"))
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")
    ylim([0, 1.25])
    xlim([0,highRes.yWrist])
    hold off;
end

%% LowRes Projection
y_locations = [1000*newtonEuler.l1/2, lowRes.yLoc2(1), lowRes.yLoc3(1), lowRes.yLoc4(1), lowRes.yLoc5(1)];

articulated_admittance = newtonEulerAdmittance(newtonEuler,y_locations);
wave_admittance = waveAdmittance(newtonEuler.y0_out-newtonEuler.y1_out,...
    1000*newtonEuler.l1/2, freq, y_locations, wave_model);
sup_admittance = articulated_admittance + wave_admittance;
wave_admittance = waveAdmittance(newtonEuler.y_fixed,...
    1000*newtonEuler.l1/2, freq, y_locations, wave_model);

num_plots = length(y_locations)-not(include_probe);
for iter1 = 1:num_plots
    loc_idx = iter1 + not(include_probe);

    figure
    freq_up = linspace(freq(1),freq(end),1000);
    for iter2 = 1:size(lowRes.free_ir,1)
        plot(freq_up,csapi(freq,movmean(log10(abs(lowRes.free_tf{iter2,loc_idx})),kernal),freq_up),'k')
        hold on
    end
    plot(freq_up,csapi(freq,movmean(log10(abs(sup_admittance(loc_idx,:))),kernal),freq_up),'g')
    plot(freq_up,csapi(freq,movmean(log10(abs(wave_admittance(loc_idx,:))),kernal),freq_up),'m')
    xlim([15,400])
    ylim([-1, 3])
    hold off

    figure
    for iter2 = 1:size(lowRes.fixed_ir,1)
        plot(freq_up,csapi(freq,movmean(log10(abs(lowRes.fixed_tf{iter2,loc_idx})),kernal),freq_up),'k')
        hold on
    end
    plot(freq_up,csapi(freq,movmean(log10(abs(sup_admittance(loc_idx,:))),kernal),freq_up),'g')
    plot(freq_up,csapi(freq,movmean(log10(abs(wave_admittance(loc_idx,:))),kernal),freq_up),'m')
    xlim([15,400])
    ylim([-1, 3])
    hold off 
end

%% Correlation Values
num_plots = length(y_locations)-not(include_probe);
freq_idx = find(and(lowRes.freq>=15,lowRes.freq<=400));
for iter1 = 1:num_plots
    loc_idx = iter1 + not(include_probe);

    corr_free_sup = zeros(size(lowRes.free_ir,1),1);
    corr_free_wave = zeros(size(lowRes.free_ir,1),1);
    for iter2 = 1:size(lowRes.free_ir,1)
        corr_sup = corrcoef(log10(abs(lowRes.free_tf{iter2,loc_idx}(freq_idx))),log10(abs(sup_admittance(loc_idx,freq_idx))));
        corr_free_sup(iter2) = corr_sup(1,2);
        corr_wave = corrcoef(log10(abs(lowRes.free_tf{iter2,loc_idx}(freq_idx))),log10(abs(wave_admittance(loc_idx,freq_idx))));
        corr_free_wave(iter2) = corr_wave(1,2);
    end
    figure
    boxplot([corr_free_sup,corr_free_wave],'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors',lines(2))
    ylim([-1, 1])

    corr_fixed_sup = zeros(size(lowRes.free_ir,1),1);
    corr_fixed_wave = zeros(size(lowRes.free_ir,1),1);
    for iter2 = 1:size(lowRes.free_ir,1)
        corr_sup = corrcoef(log10(abs(lowRes.fixed_tf{iter2,loc_idx}(freq_idx))),log10(abs(sup_admittance(loc_idx,freq_idx))));
        corr_fixed_sup(iter2) = corr_sup(1,2);
        corr_wave = corrcoef(log10(abs(lowRes.fixed_tf{iter2,loc_idx}(freq_idx))),log10(abs(wave_admittance(loc_idx,freq_idx))));
        corr_fixed_wave(iter2) = corr_wave(1,2);
    end
    figure
    boxplot([corr_fixed_sup,corr_fixed_wave],'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors',lines(2))
    ylim([-1, 1])
end

%% Look at Contribution to Driving Point Impedance

DIP = (newtonEuler.l1/2)*2*pi*1i*freq.*(newtonEuler.theta1_out-newtonEuler.theta2_out)*1000;
PIP = (newtonEuler.l2 + newtonEuler.l1/2)*2*pi*1i*freq.*(newtonEuler.theta2_out-newtonEuler.theta3_out)*1000;
MCP = (newtonEuler.l3 + newtonEuler.l2 + newtonEuler.l1/2)*2*pi*1i*freq.*(newtonEuler.theta3_out-newtonEuler.theta4_out)*1000;
Wrist = (newtonEuler.l4 + newtonEuler.l3 + newtonEuler.l2 + newtonEuler.l1/2)*2*pi*1i*freq.*newtonEuler.theta4_out*1000;

figure;
[~,idx_100] = min(abs(freq-100)); 
disp(abs(wave_admittance(1,idx_100)))
plot(freq_up,csapi(freq,movmean(20*log10(abs(wave_admittance(1,idx_100))./abs(sup_admittance(1,:))),kernal),freq_up),'b');
hold on;
plot(freq_up,csapi(freq,movmean(20*log10(abs(wave_admittance(1,idx_100))./abs(wave_admittance(1,:))),kernal),freq_up),'r');
plot(freq_up,csapi(freq,movmean(20*log10(abs(wave_admittance(1,idx_100))./abs(Wrist)),kernal),freq_up),'k');
plot(freq_up,csapi(freq,movmean(20*log10(abs(wave_admittance(1,idx_100))./abs(MCP)),kernal),freq_up),'k');
plot(freq_up,csapi(freq,movmean(20*log10(abs(wave_admittance(1,idx_100))./abs(PIP)),kernal),freq_up),'k');
plot(freq_up,csapi(freq,movmean(20*log10(abs(wave_admittance(1,idx_100))./abs(DIP)),kernal),freq_up),'k');
hold off;

ylim([-30, 30])
xticks([15 50 100 200 400])
xlim([15,400])

