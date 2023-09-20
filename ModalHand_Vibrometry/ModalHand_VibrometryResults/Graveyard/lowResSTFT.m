clear; clc; close all;
%% Load Data
probe_mass = 2.5;
freq = 10.^(1:.001:3);

participants = ["P1","P2","P3","P4","P5","P6"];
conditions = ["Free", "Fixed"];
LDV = ["Low", "Med"];
location = ["Loc1", "Loc2", "Loc3", "Loc4", "Loc5"];

additional_1 = ["P1_Free_Loc1_High.mat", "P1_Free_Loc2_High.mat", "P1_Free_Loc3_High.mat"];
additional_2 = ["P2_Free_Loc1_High.mat", "P2_Free_Loc2_High.mat"];
additional_3 = ["P3_Free_Loc1_High.mat", "P3_Free_Loc2_High.mat"];
additional_4 = ["P4_Free_Loc1_High.mat", "P4_Free_Loc2_High.mat", "P4_Free_Loc3_High.mat"];
additional_5 = ["P5_Free_Loc1_High.mat", "P5_Free_Loc2_High.mat", "P1_Free_Loc3_High.mat"];
additional_6 = [];

additoinal = {additional_1, additional_2, additional_3, additional_4, additional_5, additional_6};

folder = "Data/LowRes/";

LDV_scale = cell(1,length(participants)*length(conditions)*length(location));
for iter1 = 1:length(LDV_scale)
    LDV_scale{iter1} = 25;
end

loaded_vel = cell(1,length(participants)*length(conditions)*length(location));
loaded_force = cell(1,length(participants)*length(conditions)*length(location));

iter7 = 0;
for iter1 = 1:length(participants)
    for iter2 = 1:length(conditions)
        for iter3 = 2:2
            for iter4 = 1:length(location)
                iter7 = iter7+1;
                LDV_scale_temp = LDV_scale{iter1};
                filename = strcat(participants(iter1),"_", conditions(iter2), "_", location(iter4), "_", LDV(iter3), ".mat");
                if and(iter2 == 1, iter4 <= length(additoinal {iter1}))
                    LDV_scale_temp = 125;
                    filename = additoinal{iter1}(iter4);
                end
                [vel_signal, force_signal, vel_fs, force_fs] = chopMeasurementData(folder,filename,LDV_scale_temp);
                vel_snr = zeros(size(vel_signal,1),size(vel_signal,2),length(freq));
                force_snr = zeros(size(vel_signal,1),size(vel_signal,2),length(freq));

                for iter5 = 1:size(vel_signal,1)
                    for iter6 = 1:size(vel_signal,2)
                        vel_snr(iter5,iter6,:) = computeSNR(squeeze(vel_signal(iter2,iter6,:)-median(vel_signal(iter2,iter6,:)))...
                            ,log_freqMap(freq,10,1000,10),50,vel_fs);
                        force_snr(iter5,iter6,:) = computeSNR(squeeze(force_signal(iter5,iter6,:)-median(force_signal(iter5,iter6,:)))...
                            ,log_freqMap(freq,10,1000,10),50,force_fs);
                    end
                end
                loaded_vel{iter7} = squeeze(permute(mean(vel_snr,1),[1,3,2]))';
                loaded_force{iter7} = squeeze(permute(mean(force_snr,1),[1,3,2]))';
            end
        end
%         figure
%         semilogx(freq,loaded_vel{iter7-4}./loaded_force{iter7-4})
%         hold on;
%         semilogx(freq,loaded_vel{iter7-3}./loaded_force{iter7-3})
%         hold on;
%         semilogx(freq,loaded_vel{iter7-2}./loaded_force{iter7-2})
%         hold on;
%         semilogx(freq,loaded_vel{iter7-1}./loaded_force{iter7-1})
%         hold on;
%         semilogx(freq,loaded_vel{iter7}./loaded_force{iter7})
%         hold off;
%         ylim([0,450])
%         title(filename)
    end
end

for iter1 = 1:length(conditions)
    for iter2 = 1:length(location)
        figure;
        for iter3 = 1:length(participants)
            select_idx = (iter3-1)*length(conditions)*length(location) + (iter1-1)*length(location) + iter2;
            admittance = movmean(loaded_vel{select_idx}./(loaded_force{select_idx}-(10^-6)*probe_mass*2*pi*freq'.*loaded_vel{select_idx}),250);
            semilogx(freq, admittance)
            hold on;
        end
        hold off;
    end
end

function freq_map = log_freqMap(freq,f1,f2,T)
    freq_map = [freq; T*log(freq/f1)/log(f2/f1)];
end
