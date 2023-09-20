close all; clear; clc;
participants = ["P03","P04","P05","P06","P07","P08","P09","P10","P11","P12"];
freq = [15, 50, 100, 200, 400];
conditions = ["Fixed","Free"];
num_participants = length(participants);

force_matrix = zeros(num_participants,length(freq)*length(conditions));
voltage_matrix = zeros(num_participants,length(freq)*length(conditions));

for iter1 = 1:num_participants
    disp(iter1)
    [voltage, measured_force, comparison_force] = getStaircase(participants(iter1)); 
    
    db_force = 20*log10(measured_force./comparison_force);

    voltage_matrix(iter1,:) = voltage';
    force_matrix(iter1,:) = mean(db_force,2)';
end

scale_factors = median(voltage_matrix,1)';

save('IntensityStudy_ProcessedData', 'voltage_matrix', 'force_matrix', 'freq', 'conditions',...
    'num_participants','-v7.3');


