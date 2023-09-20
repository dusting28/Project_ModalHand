close all; clc; clear;

%% Intensity Study
load("IntensityStudy_ProcessedData.mat")
rm_stats = force_matrix;


jitter = 8;
figure(1)
plot(freq,squeeze(median(rm_stats(:,1:2:end),1)),'r--');
hold on;
boxplot(rm_stats(:,1:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
hold on;
plot(freq,squeeze(median(rm_stats(:,2:2:end),1)),'b--');
hold on;
boxplot(rm_stats(:,2:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
ylim([-20,20]);
hold on;


rm_table = array2table(rm_stats);
rm_labels = cell(1,length(freq)*length(conditions));
iter3 = 0;
for iter1 = 1:length(freq)
    for iter2 = 1:length(conditions)
        iter3=iter3+1;
        rm_labels{iter3} = convertStringsToChars(strcat(conditions(iter2),num2str(freq(iter1))));
    end
end
rm_table.Properties.VariableNames = rm_labels;

withinDesign = table(repelem(1:length(freq), length(conditions))',...
    repmat(1:length(conditions),1,length(freq))','VariableNames',{'Frequency','Condition'});
withinDesign.Frequency = categorical(withinDesign.Frequency);
withinDesign.Condition = categorical(withinDesign.Condition);

rm = fitrm(rm_table, strcat(rm_labels{1},"-",rm_labels{end},"~1"), 'WithinDesign', withinDesign);
AT_intensity = ranova(rm, 'WithinModel', 'Frequency*Condition');

uncorrected_p = zeros(1,length(freq));
for iter1 = 1:length(freq)
    [~,p] = ttest(rm_stats(:,(iter1-1)*2+1),rm_stats(:,(iter1-1)*2+2));
    uncorrected_p(iter1) = p;
end

% Holm-Bonferroni Correction
[~, sorted_idx] = sort(uncorrected_p);
weighting = zeros(1,length(sorted_idx));
for iter1 = 1:length(sorted_idx)
    weighting(iter1) = 6 - find(~(iter1-sorted_idx));
end
p_vals = uncorrected_p.*weighting;
disp(p_vals)

%% Spatial Study
load("SpatialStudy_ProcessedData.mat")
summed_response = squeeze(sum(filled_matrix,2));


red_map = [ones(256,1), linspace(1,0,256)', linspace(1,0,256)'];
blue_map = [linspace(1,0,256)', linspace(1,0,256)', ones(256,1)];

for iter1 = 1:num_stim
    figure;
    plot_num = 5*mod(iter1-1,2)+ceil(iter1/2);
    s = surf(x_mesh,y_mesh,squeeze(summed_response(iter1,:,:)));
    view(2);
    s.EdgeColor = 'none';
    colormap(flipud(gray))
    set(gca,'Ydir','reverse')
    clim([0, repetitions*num_participants]);
    saveas(gcf,strcat("Study1B_Perception_HandPlot_",num2str(freq(ceil(iter1/2))),"Hz_",conditions(2-mod(iter1,2)),".tif"))
end

x_vector = 80:1900;
y_vector = 890;
for iter1 = 1:num_stim
    if mod(iter1,2)
        figure
        plot(x_vector-x_vector(1),squeeze(summed_response(iter1,x_vector,y_vector)),'r');
    else
        plot(x_vector-x_vector(1),squeeze(summed_response(iter1,x_vector,y_vector)),'b');
        xlim([0,1820])
        saveas(gcf,strcat("Study1B_Perception_LinePlot_",num2str(freq(ceil(iter1/2))),"Hz.eps"))
    end
    ylim([0,repetitions*num_participants])
    hold on;
end
hold off;

%% Box Chart
distance_vector(1,1,:) = 1:size(filled_matrix,3);
distance_weighting = repmat(distance_vector,[size(filled_matrix,1),size(filled_matrix,2),1,size(filled_matrix,4)]);

center_mass = 1820-(sum(filled_matrix.*distance_weighting,[3,4])./sum(filled_matrix,[3,4]))'+x_vector(1);
percent_filled = (sum(filled_matrix,[3,4])./sum(masking_matrix,"all"))';
jitter = 8;

rm_stats = zeros(num_participants,num_stim);
for iter1 = 1:num_participants
    idx = (iter1-1)*repetitions;
    % rm_stats(iter1,:) = mean(percent_filled(idx+1:idx+repetitions,:),1);
    rm_stats(iter1,:) = mean(center_mass(idx+1:idx+repetitions,:),1);
end

figure
plot(freq,squeeze(median(rm_stats(:,1:2:end),1)),'r--');
hold on;
boxplot(rm_stats(:,1:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
plot(freq,squeeze(median(rm_stats(:,2:2:end),1)),'b--');
boxplot(rm_stats(:,2:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
ylim([0,1820])
hold off;

for iter1 = 1:size(rm_stats,2)/2
    figure;
    boxplot(rm_stats(:,iter1*2-1:iter1*2),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors',['r','b']);
    ylim([0,1820]);
end

between_subjects = repelem(1:num_participants,repetitions);
rm_table = array2table(rm_stats);
rm_labels = cell(1,length(freq)*length(conditions));
iter3 = 0;
for iter1 = 1:length(freq)
    for iter2 = 1:length(conditions)
        iter3=iter3+1;
        rm_labels{iter3} = convertStringsToChars(strcat(conditions(iter2),num2str(freq(iter1))));
    end
end
rm_table.Properties.VariableNames = rm_labels;

withinDesign = table(repelem(1:length(freq),length(conditions))',...
    repmat(1:length(conditions),1,length(freq))','VariableNames',{'Frequency','Condition'});
withinDesign.Frequency = categorical(withinDesign.Frequency);
withinDesign.Condition = categorical(withinDesign.Condition); % | = conditioned

rm = fitrm(rm_table, strcat(rm_labels{1},"-",rm_labels{end},"~1"), 'WithinDesign', withinDesign);
AT_spatial = ranova(rm, 'WithinModel', 'Frequency*Condition');


uncorrected_p = zeros(1,length(freq));
for iter1 = 1:length(freq)
    [~,p] = ttest(rm_stats(:,(iter1-1)*2+1),rm_stats(:,(iter1-1)*2+2));
    uncorrected_p(iter1) = p;
end

% Holm-Bonferroni Correction
[~, sorted_idx] = sort(uncorrected_p);
weighting = zeros(1,length(sorted_idx));
for iter1 = 1:length(sorted_idx)
    weighting(iter1) = 6 - find(~(iter1-sorted_idx));
end
p_vals = uncorrected_p.*weighting;
disp(p_vals)