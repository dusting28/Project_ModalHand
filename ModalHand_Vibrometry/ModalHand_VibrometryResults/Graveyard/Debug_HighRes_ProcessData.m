clear; clc; close all;
addpath("Functions\")
addpath("Graveyard\")
%% Load Data

% File info
folder = "Data/HighRes/";
filename = ["Dustin_HighRes_Free-002.mat", "Dustin_HighRes_Fixed-001.mat", ...
    "Dustin_Free_ProbeTip.mat", "Dustin_Fixed_ProbeTip2.mat"];

% LDV settings
LDV_scale = cell(length(filename));
LDV_scale{1} = [10*ones(1,87), ones(1,60)];
LDV_scale{2} = [10*ones(1,9), ones(1,138)];
LDV_scale{3} = 10;
LDV_scale{4} = 10;

% Measurement locations
n_rows = 49;
n_columns = 3;
first_measurement = 18;
last_measurement = 175;
yProbe = 15;
yDIP = 25;
yPIP = 51;
yMCP = 104;
yWrist = 182;
spacing = (last_measurement-first_measurement)/(n_rows-1);
xCord = spacing*repmat((-(n_columns-1)/2:(n_columns-1)/2),1,n_rows);
yCord = first_measurement + spacing*(ceil((1:n_rows*n_columns)/n_columns)-1);
xCord = [0,xCord];
yCord = [yProbe,yCord];

% Cell for storing impulse responses
fixed_tf = cell(1,148);
free_tf = cell(1,148);

% Frequency content of interest
bandpass = [10, 1000];

for iter1 = 3%1:length(filename)
    % Data loaded here
    all_data = load(strcat(folder,filename(iter1)));

    %% Chop Data
    [vel_signal, force_signal, vel_fs, force_fs] = chopMeasurementData(all_data,LDV_scale{iter1});
    num_repitions = size(vel_signal,1);
    num_locations = size(vel_signal,2);

    %% Filter Data
    % Create zero-phase bandpass filter
    band_filt = designfilt('bandpassfir', 'FilterOrder', round(size(force_signal,3)/3)-1, ...
         'CutoffFrequency1', bandpass(1), 'CutoffFrequency2', bandpass(2),...
         'SampleRate', force_fs);
    
    ir_avg = 0;
    for iter2 = 1%1:num_locations
        stftFilt_vel = zeros(num_repitions,size(force_signal,3));
        stftFilt_force = zeros(num_repitions,size(force_signal,3));
        for iter3 = 1:num_repitions

            % Downsample velocity data
            
            %downsampled_vel = medianDownsample(squeeze(vel_signal(iter3,iter2,:)),length(force_signal(iter3,iter2,:)));

            % Bandpass data
            bandpass_vel = squeeze(vel_signal(iter3,iter2,:))';
            bandpass_force = filtfilt(band_filt,squeeze(force_signal(iter3,iter2,:))');

            bandpass_force = resample(bandpass_force,vel_fs,force_fs);

            [t1,ir1,freq1,tr1] = computeTransferFunc4(bandpass_force,bandpass_vel,vel_fs,bandpass);

            ir_avg = ir_avg+ir1/3;

            figure(11)
            subplot(3,1,1)
            plot(t1,ir1)
            hold on;
            subplot(3,1,2)
            plot(freq1,abs(tr1))
            hold on;
            subplot(3,1,3)
            plot(freq1,angle(tr1))
            hold on;

            % Use "tracking" filter to reduce SNR
            stftFilt_vel(iter3,:) = stftReconstruct(bandpass_vel,vel_fs);
            stftFilt_force(iter3,:) = stftReconstruct(bandpass_force,vel_fs);

            if iter3 == 1
                figure(1)
                subplot(5,1,1)
                plot(squeeze(vel_signal(iter3,iter2,:)))
                subplot(5,1,2)
                plot(downsampled_vel)
                subplot(5,1,3)
                plot(bandpass_vel)
                subplot(5,1,4)
                plot(squeeze(stftFilt_vel(iter3,:)))
                figure(2)
                subplot(4,1,1)
                plot(squeeze(force_signal(iter3,iter2,:)))
                subplot(4,1,2)
                plot(bandpass_force)
                subplot(4,1,3)
                plot(squeeze(stftFilt_force(iter3,:)))
                figure(3)
                subplot(5,1,1)
                plot(squeeze(vel_signal(iter3,iter2,round(9*end/10):end)))
                subplot(5,1,2)
                plot(squeeze(downsampled_vel(round(9*end/10):end)))
                subplot(5,1,3)
                plot(squeeze(bandpass_vel(round(9*end/10):end)))
                subplot(5,1,4)
                plot(squeeze(stftFilt_vel(iter3,round(9*end/10):end)))
                figure(4)
                subplot(4,1,1)
                plot(squeeze(force_signal(iter3,iter2,round(9*end/10):end)))
                subplot(4,1,2)
                plot(squeeze(bandpass_force(round(9*end/10):end)))
                subplot(4,1,3)
                plot(squeeze(stftFilt_force(iter3,round(9*end/10):end)))
            end
        end
        
        [~, tr_avg] = fft_spectral(ir_avg,vel_fs);

        % Average signals over trials
        avg_vel = mean(stftFilt_vel,1);
        avg_force = mean(stftFilt_force,1);
        
        figure(1)
        subplot(5,1,5)
        plot(avg_vel)
        figure(2)
        subplot(4,1,4)
        plot(avg_force)
        figure(3)
        subplot(5,1,5)
        plot(squeeze(avg_vel(round(9*end/10):end)))
        figure(4)
        subplot(4,1,4)
        plot(squeeze(avg_force(round(9*end/10):end)))
        
        disp(iter2)
        disp(max(abs(avg_vel)))

        %% Compute Transfer Function
        [t2,ir2,freq2,tr2] = computeTransferFunc2(avg_force,avg_vel,vel_fs,bandpass);
        [t3,ir3,freq3,tr3] = computeTransferFunc3(avg_force,avg_vel,vel_fs,bandpass);
        [t4,ir4,freq4,tr4] = computeTransferFunc4(avg_force,avg_vel,vel_fs,bandpass);
        [t5,ir5,freq5,tr5] = computeTransferFunc5(avg_force,avg_vel,vel_fs,bandpass);
        
        figure(5)
        subplot(3,1,1)
        plot(t2,ir2)
        subplot(3,1,2)
        plot(t3,ir3)
        subplot(3,1,3)
        plot(t4,ir4)

        figure(6)
        subplot(3,1,1)
        plot(freq2,abs(tr2))
        xlim([10,1000])
        subplot(3,1,2)
        plot(freq3,abs(tr3))
        xlim([10,1000])
        subplot(3,1,3)
        plot(freq4,abs(tr4))
        xlim([10,1000])

        figure(7)
        subplot(3,1,1)
        plot(freq2,unwrap(angle(tr2)))
        xlim([10,1000])
        subplot(3,1,2)
        plot(freq3,unwrap(angle(tr3)))
        xlim([10,1000])
        subplot(3,1,3)
        plot(freq4,unwrap(angle(tr4)))
        xlim([10,1000])

        figure(8)
        subplot(2,1,1)
        plot(t1,ir_avg)
        subplot(2,1,2)
        plot(t4,ir4)
        figure(9)
        subplot(2,1,1)
        plot(freq1,abs(tr_avg))
        subplot(2,1,2)
        plot(freq4,abs(tr4))
        figure(10)
        subplot(2,1,1)
        plot(freq1,unwrap(angle(tr_avg)))
        subplot(2,1,2)
        plot(freq4,unwrap(angle(tr4)))
    end
end
