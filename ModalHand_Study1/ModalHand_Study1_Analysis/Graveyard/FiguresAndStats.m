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

alpha = .05/length(freq);
disp(alpha);
for iter1 = 1:length(freq)
    [~,p] = ttest(rm_stats(:,(iter1-1)*2+1),rm_stats(:,(iter1-1)*2+2));
    disp(p)
end

%% Spatial Study
load("SpatialStudy_ProcessedData.mat")
summed_response = squeeze(sum(filled_matrix,2));


red_map = [ones(256,1), linspace(1,0,256)', linspace(1,0,256)'];
blue_map = [linspace(1,0,256)', linspace(1,0,256)', ones(256,1)];

figure(2);
for iter1 = 1:num_stim
    plot_num = 5*mod(iter1-1,2)+ceil(iter1/2);
    plot_obj = subplot(2,5,plot_num);
    s = surf(x_mesh,y_mesh,squeeze(summed_response(iter1,:,:)));
    view(2);
    s.EdgeColor = 'none';
    if mod(iter1,2)
        colormap(plot_obj,red_map)
    else
        colormap(plot_obj,blue_map)
    end
    set(gca,'Ydir','reverse')
    clim([0, repetitions*num_participants]);
end

x_vector = 80:1900;
y_vector = 890;
for iter1 = 1:num_stim
    % figure(3);
    % subplot(1,2,mod(iter1-1,2)+1)
    % plot(x_vector-x_vector(1),movmean(movmedian(squeeze(summed_response(iter1,x_vector,y_vector)),20),100));
    % ylim([0,repetitions*num_participants])
    % hold on;
    figure(3);
    subplot(1,5,ceil(iter1/2))
    if mod(iter1,2)
        plot(x_vector-x_vector(1),movmean(movmedian(squeeze(summed_response(iter1,x_vector,y_vector)),1),1),'r');
    else
        plot(x_vector-x_vector(1),movmean(movmedian(squeeze(summed_response(iter1,x_vector,y_vector)),1),1),'b');
    end
    ylim([0,repetitions*num_participants])
    hold on;
end
hold off;

percent_filled = (sum(filled_matrix,[3,4])./sum(masking_matrix,"all"))';
jitter = 8;

% figure(5)
% plot(freq-5,squeeze(median(percent_filled(:,1:2:end),1)),'r--');
% hold on;
% boxplot(percent_filled(:,1:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
% hold on;
% plot(freq+5,squeeze(median(percent_filled(:,2:2:end),1)),'b--');
% hold on;
% boxplot(percent_filled(:,2:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
% ylim([0,1]);
% hold on;

rm_stats = zeros(num_participants,num_stim);
for iter1 = 1:num_participants
    idx = (iter1-1)*repetitions;
    rm_stats(iter1,:) = mean(percent_filled(idx+1:idx+repetitions,:),1);
end

figure(4)
plot(freq,squeeze(median(rm_stats(:,1:2:end),1)),'r--');
hold on;
boxplot(rm_stats(:,1:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
hold on;
plot(freq,squeeze(median(rm_stats(:,2:2:end),1)),'b--');
hold on;
boxplot(rm_stats(:,2:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
ylim([0,1]);
hold on;

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

alpha = .05/length(freq);
disp(alpha);
for iter1 = 1:length(freq)
    [~,p] = ttest(rm_stats(:,(iter1-1)*2+1),rm_stats(:,(iter1-1)*2+2));
    disp(p)
end