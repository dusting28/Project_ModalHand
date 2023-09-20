clear; clc; close all;
addpath("Functions\")
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
fixed_ir = cell(1,148);
free_ir = cell(1,148);

% Frequency content of interest
bandpass = [10, 1000];
freq = bandpass(1):bandpass(2);

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
        ir_avg = 0;
        for iter3 = 1:num_repitions
            
            % Downsample velocity data
            downsampled_vel = resample(squeeze(vel_signal(iter3,iter2,:))',force_fs,vel_fs);

            % Bandpass data
            bandpass_vel = filtfilt(band_filt,downsampled_vel);
            bandpass_force = filtfilt(band_filt,squeeze(force_signal(iter3,iter2,:))');

            % Compute IR
            [t,ir] = computeIR_Kirkeby(bandpass_force,bandpass_vel,force_fs);

            % Average over trials
            ir_avg = ir_avg+ir/num_repitions;
        end
     

        %% Compute Transfer Function
        [freq,fd_spec] = fft_spectral(ir_avg,force_fs);
        fd_spec = fd_spec*length(ir_avg)/2;

        %% Save Data
        switch iter1
            case 1
                free_tf{iter2+1} = fd_spec; 
            case 2
                fixed_tf{iter2+1} = fd_spec;
            case 3
                free_tf{1} = fd_spec;
            case 4
                fixed_tf{1} = fd_spec;
            otherwise
                disp("Error")
        end

        switch iter1
            case 1
                free_ir{iter2+1} = ir_avg; 
            case 2
                fixed_ir{iter2+1} = ir_avg;
            case 3
                free_ir{1} = ir_avg;
            case 4
                fixed_ir{1} = ir_avg;
            otherwise
                disp("Error")
        end
    end
end

save HighRes_ProcessedData.mat yProbe yDIP yPIP yMCP yWrist xCord yCord ...
    free_tf fixed_tf freq free_ir fixed_ir t
