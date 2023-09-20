clear; clc; close all;
%% Load Data

% File info
folder = "Data/";
filename = "BasePlate.mat";

% LDV settings
LDV_scale = cell(length(filename));
LDV_scale{1} = 5;

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

for iter1 = 1:length(filename)
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
    
    for iter2 = 1:num_locations
        stftFilt_vel = zeros(num_repitions,size(force_signal,3));
        stftFilt_force = zeros(num_repitions,size(force_signal,3));
        for iter3 = 1:num_repitions 
            % Downsample velocity data
            downsampled_vel = medianDownsample(squeeze(vel_signal(iter3,iter2,:)),length(force_signal(iter3,iter2,:)));

            % Bandpass data
            bandpass_vel = filtfilt(band_filt,downsampled_vel);
            bandpass_force = filtfilt(band_filt,squeeze(force_signal(iter3,iter2,:))');

            % Use "tracking" filter to reduce SNR
            stftFilt_vel(iter3,:) = stftReconstruct(bandpass_vel,force_fs);
            stftFilt_force(iter3,:) = stftReconstruct(bandpass_force,force_fs);
        end

        % Average signals over trials
        avg_vel = mean(stftFilt_vel,1);
        avg_force = mean(stftFilt_force,1);
        t = (1:length(avg_force))/force_fs;

        %% Compute Transfer Function
        [freq,base_tf] = computeTransferFunc(avg_force,avg_vel,force_fs,bandpass);
        
    end
end

save BasePlate_ProcessedData.mat base_tf freq
