clc; clear; close all;
addpath("Data\")
highRes = load("HighRes_ProcessedData.mat");
fs = 2500;
bandwidth = [15, 950];

freq_idx = find(and(highRes.freq>=bandwidth(1),highRes.freq<=bandwidth(2)));

%% Generate White Noise

% 
% noise_len = 1;
% bandLimitedNoise(noise_len,fs,1,'uniform',bandwidth);

%% Generate White Noise
t = 0:1/fs:1;
fixed_noise = zeros(length(t),length(highRes.yCord)-1);
free_noise = zeros(length(t),length(highRes.yCord)-1);
for iter1 = freq_idx
    for iter2 = 1:length(highRes.yCord)-1
        fixed_noise(:,iter2) = fixed_noise(:,iter2)+abs(highRes.fixed_tf{iter2+1}(iter1))*sin(2*pi*highRes.freq(iter1)*t'+angle(highRes.fixed_tf{iter2+1}(iter1)));
        free_noise(:,iter2) = free_noise(:,iter2)+abs(highRes.free_tf{iter2+1}(iter1))*sin(2*pi*highRes.freq(iter1)*t'+angle(highRes.free_tf{iter2+1}(iter1)));
    end
end

%% POD
close all;
color_map = colorcet('COOLWARM');

C_fixed = fixed_noise'*fixed_noise/(length(t)-1);
[fixed_eigVec, fixed_eigVal] = eig(C_fixed);

fixed_mode1 = fixed_eigVec(:,end);
fixed_mode2 = fixed_eigVec(:,end-1);
fixed_mode3 = fixed_eigVec(:,end-2);

surfPlot(fixed_mode1,highRes,[-.3, .3],color_map,"Fixed - Mode 1",false);
surfPlot(fixed_mode2,highRes,[-.3, .3],color_map,"Fixed - Mode 2",false);
surfPlot(fixed_mode3,highRes,[-.3, .3],color_map,"Fixed - Mode 3",false);

C_free = free_noise'*free_noise/(length(t)-1);
[free_eigVec, free_eigVal] = eig(C_free);

free_mode1 = free_eigVec(:,end);
free_mode2 = free_eigVec(:,end-1);
free_mode3 = free_eigVec(:,end-2);
free_mode4 = free_eigVec(:,end-3);
free_mode5 = free_eigVec(:,end-4);

surfPlot(free_mode1,highRes,[-.3, .3],color_map,"Free - Mode 1",false);
surfPlot(free_mode2,highRes,[-.3, .3],color_map,"Free - Mode 2",false);
surfPlot(free_mode3,highRes,[-.3, .3],color_map,"Free - Mode 3",false);
surfPlot(free_mode4,highRes,[-.3, .3],color_map,"Free - Mode 4",false);
surfPlot(free_mode5,highRes,[-.3, .3],color_map,"Free - Mode 5",false);
