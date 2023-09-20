%% Look at Phase
clc; clear; close all;
addpath("Data\")
highRes = load("HighRes_ProcessedData.mat");
bandwidth = [15, 950];

freq_idx = find(and(highRes.freq>=bandwidth(1),highRes.freq<=bandwidth(2)));
position = highRes.yCord(2:end);

start_idx = 4000;%6000;
width_idx = 50;
disp(highRes.freq(start_idx));

close all;
colormap = jet(width_idx);
fixed_phase = zeros(length(freq_idx),length(highRes.yCord)-1);
free_phase = zeros(length(freq_idx),length(highRes.yCord)-1);
iter0 = 0;
for iter1 = freq_idx
    iter0 = iter0+1;
    for iter2 = 1:length(position)
        fixed_phase(iter0,iter2) = angle(highRes.fixed_tf{iter2+1}(iter1));
        free_phase(iter0,iter2) = angle(highRes.free_tf{iter2+1}(iter1));
    end
    if and(iter1>start_idx, iter1<start_idx+width_idx)
        for iter3 = 1:3
            subplot(1,2,1)
            plot(position(iter3:3:end),fixed_phase(iter0,iter3:3:end),'Color',colormap(iter1-start_idx,:));
            hold on;
            subplot(1,2,2)
            plot(position(iter3:3:end),free_phase(iter0,iter3:3:end),'Color',colormap(iter1-start_idx,:));
            hold on;
        end
    end
end

% window_size = 750;
% figure;
% plot(freq_samples,.003*2*pi*freq_samples./movmedian(median_phase_shift,window_size))
% figure;
% plot(freq_samples,.003*2*pi*freq_samples./movmedian(mean_phase_shift,window_size))

%% k-space analysis
% ks = 1/(position(2)-position(1));
% for iter1 = 1:length(freq_samples)
%     figure;
%     for iter2 = 1:num_frames
%         [k,k_amp] = fft_spectral(smoothed,ks);
%         plot(k,abs(k_amp));
%         hold on;
%     end
% end
