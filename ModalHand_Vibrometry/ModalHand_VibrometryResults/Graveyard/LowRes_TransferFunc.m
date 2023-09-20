clear; clc; close all;

%% Load Data
participants = ["P1","P3","P4","P5","P6"]; % Note: Trigger signal for DAQ failed for P2
conditions = ["Free", "Fixed"];
LDV = ["Low", "Med"];
location = ["Loc1", "Loc2", "Loc3", "Loc4", "Loc5"];
bandpass = [10 1000];

fixed_tf = cell(length(participants),length(location));
free_tf = cell(length(participants),length(location));

% P2 listed in comments
yLoc1 = [15, 15, 15, 15, 15]; %15
yLoc2 = [18, 18, 18, 18, 18]; %18
yLoc3 = [38, 38, 38, 38, 40]; %44
yLoc4 = [63, 63, 64, 68, 64]; %74
yLoc5 = [144, 124, 131, 136, 136]; %144
yDIP = [25, 25, 25, 24, 28]; %30
yPIP = [50, 50, 50, 52, 51]; %58
yMCP = [101, 98, 107, 104, 105]; %111
yWrist = [182, 173, 186, 188, 195]; %198

additional_1 = ["P1_Free_Loc1_High.mat", "P1_Free_Loc2_High.mat", "P1_Free_Loc3_High.mat"];
%additional_2 = ["P2_Free_Loc1_High.mat", "P2_Free_Loc2_High.mat"];
additional_3 = ["P3_Free_Loc1_High.mat", "P3_Free_Loc2_High.mat"];
additional_4 = ["P4_Free_Loc1_High.mat", "P4_Free_Loc2_High.mat", "P4_Free_Loc3_High.mat"];
additional_5 = ["P5_Free_Loc1_High.mat", "P5_Free_Loc2_High.mat", "P1_Free_Loc3_High.mat"];
additional_6 = [];

additoinal = {additional_1, additional_3, additional_4, additional_5, additional_6};

folder = "Data/LowRes/";

LDV_scale = cell(1,length(participants)*length(conditions)*length(location));
for iter1 = 1:length(LDV_scale)
    LDV_scale{iter1} = 25;
end

loaded_vel = cell(1,length(participants)*length(conditions)*length(location));
loaded_force = cell(1,length(participants)*length(conditions)*length(location));

for iter1 = 1:length(participants)
    for iter2 = 1:length(conditions)
        for iter3 = 2:2
            for iter4 = 1:length(location)
                LDV_scale_temp = LDV_scale{iter1};
                filename = strcat(participants(iter1),"_", conditions(iter2), "_", location(iter4), "_", LDV(iter3), ".mat");
                if and(iter2 == 1, iter4 <= length(additoinal{iter1}))
                    LDV_scale_temp = 125;
                    filename = additoinal{iter1}(iter4);
                end
                all_data = load(strcat(folder,filename));
                [vel_signal, force_signal, vel_fs, force_fs] = chopMeasurementData(all_data,LDV_scale_temp);
                num_repitions = size(vel_signal,1);

                band_filt = designfilt('bandpassfir', 'FilterOrder', round(size(force_signal,3)/3)-1, ...
                    'CutoffFrequency1', bandpass(1), 'CutoffFrequency2', bandpass(2),...
                    'SampleRate', force_fs);
    
                stftFilt_vel = zeros(num_repitions,size(force_signal,3));
                stftFilt_force = zeros(num_repitions,size(force_signal,3));

                for iter5 = 1:num_repitions 
                    % Downsample velocity data
                    downsampled_vel = medianDownsample(squeeze(vel_signal(iter5,1,:)),length(force_signal(iter5,1,:)));
        
                    % Bandpass data
                    bandpass_vel = filtfilt(band_filt,downsampled_vel);
                    bandpass_force = filtfilt(band_filt,squeeze(force_signal(iter5,1,:))');
        
                    % Use "tracking" filter to reduce SNR
                    stftFilt_vel(iter5,:) = stftReconstruct(bandpass_vel,force_fs);
                    stftFilt_force(iter5,:) = stftReconstruct(bandpass_force,force_fs);
                end

                % Average signals over trials
                avg_vel = mean(stftFilt_vel,1);
                avg_force = mean(stftFilt_force,1);
        
                %% Compute Transfer Function
                [freq,fd_spec] = computeTransferFunc(avg_force,avg_vel,force_fs,bandpass);
                if mod(iter2,2)
                    free_tf{iter1,iter4} = fd_spec;
                else
                    fixed_tf{iter1,iter4} = fd_spec;
                end
            end
        end
    end
end

save LowRes_ProcessedData.mat free_tf fixed_tf freq yLoc1 yLoc2 yLoc3 yLoc4 yLoc5 yDIP yPIP yMCP yWrist


