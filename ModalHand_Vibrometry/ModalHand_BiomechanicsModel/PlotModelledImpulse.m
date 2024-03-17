clc; clear; close all;

%% Load Processed Data
current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
% addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
% addpath(strcat(outer_folder, "\ModalHand_VibrometryResults\Functions"));

newtonEuler = load("NewtonEulerData.mat");
highRes = load("HighRes_ProcessedData.mat");
% lowRes = load("LowRes_ProcessedData.mat");

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

articulated_impulse = zeros(size(articulated_admittance,1),2*size(articulated_admittance,2)-2);

for iter1 = 1:size(articulated_admittance,1)
    wrapped_impulse = ifft([0, articulated_admittance(iter1,2:end)/2, fliplr(articulated_admittance(iter1,2:end))/2],'symmetric');
    articulated_impulse(iter1,:) = [wrapped_impulse(end-374:end),wrapped_impulse(1:375)];
end

% plot(articulated_impulse(1,:))
% 
% for iter1 = 350:1:500
%     limit = max(abs(real(articulated_impulse)),[],"all");
%     gifPlot(-real(articulated_impulse(:,iter1))',1,highRes,[-limit,limit],flipud(colorcet('COOLWARM')),strcat("Impulse Response"),include_probe)
% end


%% Compare with other impulse data
figure;
normalization = zeros(1,size(articulated_impulse,1));
correlation = zeros(1,size(articulated_impulse,1));
for iter1 = 1:round(size(articulated_impulse,1))
    auto_correlation1 = xcorr(-real(articulated_impulse(iter1,:)), -real(articulated_impulse(iter1,:)));
    auto_correlation2 = xcorr(highRes.free_ir{iter1+1}, highRes.free_ir{iter1+1});

    normalization(iter1) = (auto_correlation1(round(end/2)) * auto_correlation2(round(end/2)))^.5;
    cross_correlation = xcorr(-real(articulated_impulse(iter1,:)),highRes.free_ir{iter1+1});
    correlation(iter1) = cross_correlation(round(end/2));
    plot(-real(articulated_impulse(iter1,:)));
    hold on;
    plot(highRes.free_ir{iter1+1});
    hold off;
end

normalized_correlation = sum(correlation)/sum(normalization);

