clc; clear; close all;
addpath("Data\")
addpath("Functions\")
highRes = load("HighRes_ProcessedData.mat");

%% Create GIFs
freq_samples = highRes.freq(150:8000);
position = highRes.yCord(3:3:end);
num_frames = 20;
sine_response_1 = zeros(length(freq_samples), num_frames, length(position));
sine_response_2 = zeros(length(freq_samples), num_frames, length(position));
sine_response_3 = zeros(length(freq_samples), num_frames, length(position));

amp_info = zeros(length(freq_samples), length(position), 3);
phase_info = zeros(length(freq_samples), length(position), 3);

for iter1 = 1:length(freq_samples)
    [~, freq_idx] = min(abs(highRes.freq - freq_samples(iter1)));
    iter0 = 0;
    for iter2 = linspace(-pi,pi,num_frames)
        iter0 = iter0+1;
        for iter3 = 1:length(position)
            complex_info_1 = highRes.fixed_tf{iter3*3-1}(freq_idx);
            complex_info_2 = highRes.fixed_tf{iter3*3}(freq_idx);
            complex_info_3 = highRes.fixed_tf{iter3*3+1}(freq_idx);
            phase_info(iter1,iter3,:) = [angle(complex_info_1), angle(complex_info_2), angle(complex_info_3)];
            amp_info(iter1,iter3,:) = [abs(complex_info_1), abs(complex_info_2), abs(complex_info_3)];
            sine_response_1(iter1,iter0,iter3) = abs(complex_info_1)*sin(angle(complex_info_1)+iter2);
            sine_response_2(iter1,iter0,iter3) = abs(complex_info_2)*sin(angle(complex_info_2)+iter2);
            sine_response_3(iter1,iter0,iter3) = abs(complex_info_3)*sin(angle(complex_info_3)+iter2);
        end
    end
    % hFigure = figure;
    % set(hFigure, 'MenuBar', 'none');
    % set(hFigure, 'ToolBar', 'none');
    % axis_lim = max(abs([sine_response_1(iter1,:,:), sine_response_2(iter1,:,:), sine_response_3(iter1,:,:)]),[],'all');
    % for iter2 = 1:num_frames
    %     p = plot(position,squeeze(sine_response_1(iter1,iter2,:)),...
    %         position,squeeze(sine_response_2(iter1,iter2,:)),...
    %         position,squeeze(sine_response_3(iter1,iter2,:)));
    %     ylim([-1.1*axis_lim, 1.1*axis_lim])
    %     xlim([0, 200]);
    %     hold on;
    %     xline(25,'k');
    %     xline(51,'k');
    %     xline(104,'k');
    %     xline(182,'k');
    %     exportgraphics(gcf,strcat("Default_Free_",num2str(freq_samples(iter1)),"Hz",".gif"),'Append',true);
    %     hold off;
    % end
end

%% Smoothed
close all;
for iter1 = 1:length(freq_samples)
    % hFigure = figure;
    % set(hFigure, 'MenuBar', 'none');
    % set(hFigure, 'ToolBar', 'none');
    axis_lim = max(abs([sine_response_1(iter1,:,:), sine_response_2(iter1,:,:), sine_response_3(iter1,:,:)]),[],'all');
    for iter2 = 1:num_frames
        unsmoothed = [squeeze(sine_response_1(iter1,iter2,:)),...
            squeeze(sine_response_2(iter1,iter2,:)),...
            squeeze(sine_response_3(iter1,iter2,:))];
        sliding_filt = ones(3)/9;
        smoothed = filter2(sliding_filt,unsmoothed,'valid');
        % plot(position(2:end-1),smoothed);
        % ylim([-1.1*axis_lim, 1.1*axis_lim])
        % xlim([0, 200]);
        % hold on;
        % xline(25,'k');
        % xline(51,'k');
        % xline(104,'k');
        % xline(182,'k');
        % hold off;
        % exportgraphics(gcf,strcat("Smoothed_Fixed_",num2str(freq_samples(iter1)),"Hz",".gif"),'Append',true);
    end
end