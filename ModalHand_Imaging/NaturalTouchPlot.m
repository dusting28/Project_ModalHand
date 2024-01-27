clear; clc; close all;

imaging = load("ImageData_NaturalTouch.mat");

start_idx = [1, 1, 1, 1, 50];
sig_len = 100;
acc_win = 5;
sample_freqs = [15, 50, 100, 200, 400];

envolope = cell(length(imaging.scenarios),1);
for iter1 = 1:length(imaging.scenarios)
    fs = imaging.frame_rate(iter1);
    initial_y = imaging.tracking_cell{iter1}(1,:,2);
    initial_x = imaging.tracking_cell{iter1}(1,:,1);
    num_locs = size(imaging.tracking_cell{iter1},2);
    colormap =  turbo(num_locs);
    figure;
    y_pos = squeeze(imaging.tracking_cell{iter1}(start_idx(iter1):start_idx(iter1)+sig_len-1,:,2));
    envolope{iter1} = zeros(num_locs/3,2);
    iter0 = 0;
    for iter2 = 1:3:num_locs
        acc_sig = acc(squeeze(y_pos(:,iter2)),acc_win,fs);
        [max_val, max_idx] = max(abs(acc_sig));
        iter0 = iter0+1;
        envolope{iter1}(iter0,1) = max_val;
        envolope{iter1}(iter0,2) = max_idx;
        plot(acc_sig,"Color",colormap(iter2,:))
        hold on;
    end
    figure;
    decay = zeros(length(sample_freqs),num_locs/3);
    phase_lag = zeros(length(sample_freqs),num_locs/3);
    iter0 = 0;
    for iter2 = 1:3:num_locs
        acc_sig = acc(squeeze(y_pos(:,iter2)),acc_win,fs);
        % acc_sig = acc_sig-mean(acc_sig);
        fft_spec = fft(acc_sig);
        P2 = abs(fft_spec/sig_len);
        P1 = P2(1:sig_len/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        phase_angle = angle(fft_spec(1:(sig_len+1)/2));
        freq = fs/sig_len*(0:(sig_len/2));
        iter0 = iter0+1;
        for iter3 = 1:length(sample_freqs)
            [~,freq_idx] = min(abs(freq-sample_freqs(iter3)));
            decay(iter3,iter0) = P1(freq_idx);
            phase_lag(iter3,iter0) = phase_angle(freq_idx);
        end
        %plot(freq,20*log10(P1),"Color",colormap(iter2,:))
        plot(freq,P1,"Color",colormap(iter2,:))
        % ylim([90, 120]);
        xlim([15, 400]);
        hold on;
    end

    figure;
    for iter2 = 1:size(decay,1)
        plot_decay = movmean(squeeze(decay(iter2,:)),3);
        plot(plot_decay/plot_decay(end));
        hold on;
    end
    % ylim([0,1]);

    figure;
    for iter2 = 1:size(decay,1)
        unwrapped_phase = unwrap(phase_lag(iter2,:));
        plot((unwrapped_phase-unwrapped_phase(end)));
        hold on;
    end
end

figure;
for iter1 = 1:size(envolope,1)
    plot(envolope{iter1}(:,1)/envolope{iter1}(end,1));
    hold on;
end

figure;
for iter1 = 1:size(envolope,1)
    plot(envolope{iter1}(:,2)-envolope{iter1}(end,2));
    hold on;
end