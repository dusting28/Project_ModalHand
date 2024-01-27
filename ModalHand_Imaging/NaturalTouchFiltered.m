clc; clear; close all;
addpath("Videos/NaturalTouch/")

imaging = load("ImageData_NaturalTouch.mat");
dot_size = 30;
color_map = colorcet('COOLWARM');
acc_win = 5;
start_idx = [1,1,1,1,50];
sig_len = 100;
remove_points = [0,0,2,5,2];
scenario = 4;
cutoff = [50, 100];

% file_name = strcat(imaging.scenarios(scenario),"_",num2str(imaging.frame_rate(scenario)),"FPS.tif");
% info = imfinfo(file_name);
% width = info(1).Width;
% height = info(1).Height;
% num_frames = size(info,1);
% rawframes = zeros(width,height,3,num_frames);
% for iter2 = 1:num_frames
%     rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2 1 3]);
% end

% excluded_points = size(imaging.tracking_cell{scenario},2)-3*(remove_points(scenario)-1):3:size(imaging.tracking_cell{scenario},2);
% included_points = 1:size(imaging.tracking_cell{scenario},2);
% included_points(excluded_points) = [];

included_points = 1:3:size(imaging.tracking_cell{scenario},2);

x_pos = squeeze(imaging.tracking_cell{scenario}(:,included_points,1));
y_pos = squeeze(imaging.tracking_cell{scenario}(:,included_points,2));
acc_sig = zeros(sig_len-2*acc_win,length(included_points));
acc_low = acc_sig;
acc_high = acc_sig;

lowpass = designfilt('lowpassfir', 'FilterOrder', round(size(acc_sig,1)/3)-1, ...
         'PassbandFrequency', cutoff(1), 'StopbandFrequency', cutoff(2),...
         'SampleRate', imaging.frame_rate(scenario));
highpass = designfilt('highpassfir', 'FilterOrder', round(size(acc_sig,1)/3)-1, ...
         'PassbandFrequency', cutoff(2), 'StopbandFrequency', cutoff(1),...
         'SampleRate', imaging.frame_rate(scenario));

amp_low = zeros(length(included_points),1);
phase_low = zeros(length(included_points),1);
amp_high = zeros(length(included_points),1);
phase_high = zeros(length(included_points),1);

for iter2 = 1:length(included_points)
    acc_sig(:,iter2) = acc(y_pos(start_idx(scenario):start_idx(scenario)+sig_len-1,iter2),acc_win,imaging.frame_rate(scenario));
    acc_low(:,iter2) = filtfilt(lowpass,acc_sig(:,iter2));
    acc_high(:,iter2) = filtfilt(highpass,acc_sig(:,iter2));
    [max_val, max_idx] = max(abs(acc_low(:,iter2)));
    amp_low(iter2) = max_val;
    phase_low(iter2) = max_idx;
    [max_val, max_idx] = max(abs(acc_high(:,iter2)));
    amp_high(iter2) = max_val;
    phase_high(iter2) = max_idx;
end

colormap =  turbo(length(included_points));

figure;
for iter2 = 1:length(included_points)
    plot(acc_sig(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

figure;
for iter2 = 1:length(included_points)
    plot(acc_low(:,iter2)+acc_high(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

figure;
for iter2 = 1:length(included_points)
    plot(acc_low(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

figure;
for iter2 = 1:length(included_points)
    plot(acc_high(:,iter2),"Color",colormap(iter2,:))
    hold on;
end


figure;
plot(amp_low/max(amp_low));
hold on;
plot(amp_high/max(amp_high));
hold off;

figure;
plot(phase_low);
hold on;
plot(phase_high);
hold off;