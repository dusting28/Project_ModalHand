clear; clc; close all;

imaging = load("ImageData.mat");

amplitude = zeros(length(imaging.freqs),size(imaging.tracking_cell{1},2));
phase_shift = zeros(length(imaging.freqs),size(imaging.tracking_cell{1},2));
offset = zeros(length(imaging.freqs),size(imaging.tracking_cell{1},2));
for iter1 = 1:size(phase_shift,1)
    figure;
    for iter2 = 1:size(phase_shift,2)
        single_sine = imaging.tracking_cell{iter1}(:,iter2)';
        time_step = (1:length(single_sine))/imaging.frame_rate;
        [amp_est ,shift_est] = max(single_sine);
        if shift_est > length(single_sine)/2
            shift_est = shift_est - imaging.frame_rate/imaging.freqs(iter1);
        end
        shift_est = shift_est/imaging.frame_rate;
        fit = @(b,t)  b(1)*cos(2*pi*imaging.freqs(iter1)*(t - b(2))) + b(3);    % Function to fit
        fcn = @(b) sum((fit(b,time_step) - single_sine).^2);
        s = fminsearch(fcn, [amp_est; shift_est; 0]);  
        amplitude(iter1,iter2) = s(1);
        phase_shift(iter1,iter2) = s(2);
        offset(iter1,iter2) = s(3);
        plot(time_step,fit(s,time_step))
        hold on;
    end
end

percent_shift = zeros(size(phase_shift,1),size(phase_shift,2)-1);
max_shift = zeros(size(phase_shift,1),1);
for iter1 = 1:size(phase_shift,1)
    figure;
    plot(360*imaging.freqs(iter1)*phase_shift(iter1,:))
    figure;
    plot(amplitude(iter1,:))
    for iter2 = 2:size(phase_shift,2)
        percent_shift(iter1,iter2-1) = imaging.freqs(iter1)*(phase_shift(iter1,iter2) - phase_shift(iter1,1))/(iter2-1);
    end
    max_shift(iter1) = (360)*imaging.freqs(iter1)*(max(phase_shift(iter1,:))-min(phase_shift(iter1,:)));
end

wave_speed = imaging.freqs'.*3*(10^-3)./mean(percent_shift,2);