close all; clc; clear;

%% Localization Demo
load("RelocalizationDemo_ProcessedData.mat")
rm_stats = zeros(num_participants,length(freq)*length(conditions));
iter0 = 0;
for iter1 = 1:length(freq)
    for iter2 = 1:length(conditions)
        iter0 = iter0+1;
        rm_stats(:,iter0) = 1-accuracy(:,iter2,iter1);
    end
end

jitter = 8;
figure;
plot(freq,squeeze(median(rm_stats(:,1:2:end),1)),'r--');
hold on;
boxplot(rm_stats(:,1:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
hold on;
plot(freq,squeeze(median(rm_stats(:,2:2:end),1)),'b--');
hold on;
boxplot(rm_stats(:,2:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
ylim([0,1]);
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
AT_localization = ranova(rm, 'WithinModel', 'Frequency*Condition');

uncorrected_p = zeros(1,length(freq)*length(conditions));
iter0 = 0;
for iter1 = 1:length(conditions)
    for iter2 = 1:length(freq)
        [~,p] = ttest(rm_stats(:,(iter2-1)*2+iter1)-.5);
        iter0 = iter0+1;
        uncorrected_p(iter0) = p;
    end
end

% Holm-Bonferroni Correction
[~, sorted_idx] = sort(uncorrected_p);
weighting = zeros(1,length(sorted_idx));
for iter1 = 1:length(sorted_idx)
    weighting(iter1) = 11 - find(~(iter1-sorted_idx));
end
p_vals = uncorrected_p.*weighting;
disp(p_vals)


%% Force Transmission Data
rm_stats = zeros(num_participants,length(freq)*length(conditions));
iter0 = 0;
for iter1 = 1:length(freq)
    for iter2 = 1:length(conditions)
        iter0 = iter0+1;
        %rm_stats(:,iter0) = accuracy(:,iter2,iter1);
        rm_stats(:,iter0) = 20*log10(amp_out(:,iter2,iter1)./amp_in(:,iter2,iter1));
    end
end

jitter = 8;
figure;
plot(freq,squeeze(median(rm_stats(:,1:2:end),1)),'r--');
hold on;
boxplot(rm_stats(:,1:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
hold on;
plot(freq,squeeze(median(rm_stats(:,2:2:end),1)),'b--');
hold on;
boxplot(rm_stats(:,2:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
ylim([-55,0]);
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
AT_transmission = ranova(rm, 'WithinModel', 'Frequency*Condition');

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