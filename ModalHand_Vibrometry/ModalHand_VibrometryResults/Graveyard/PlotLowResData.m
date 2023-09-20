clear; clc; close all;

participants = ["P1","P2","P3","P4","P5","P6"];
conditions = ["Free", "Fixed"];
LDV = ["Low", "Med"];
location = ["Loc1", "Loc2", "Loc3", "Loc4", "Loc5"];

load("LowRes_STFTvel.mat");
load("LowRes_STFTforce.mat");

%% Load Data
probe_mass = 2.5;
freq = 10.^(1:.001:3);
admittance = zeros(length(freq),length(participants));

for iter1 = 1:length(conditions)
    for iter2 = 1:length(location)
        figure;
        for iter3 = 1:length(participants)
            select_idx = (iter3-1)*length(conditions)*length(location) + (iter1-1)*length(location) + iter2;
            admittance(:,iter3) = movmean(loaded_vel{select_idx},250)./(movmean(loaded_force{select_idx},250)-(10^-6)*probe_mass*2*pi*freq'.*movmean(loaded_vel{select_idx},250));
            semilogx(freq, admittance(:,iter3));
            hold on;
        end
        figure;
        mean_admittance = movmean(mean(admittance,2),250);
        std_admittance = movmean(std(admittance,0,2),250);
        semilogx(freq, mean_admittance,'r');
        hold on;
        semilogx(freq, mean_admittance-std_admittance,'k');
        hold on;
        semilogx(freq, mean_admittance+std_admittance,'k');
        hold off;
        set(gca, 'YLim', [0, round(get(gca, 'YLim')) * [0; 1]])
    end
end