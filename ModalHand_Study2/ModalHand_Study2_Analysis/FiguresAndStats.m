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
figure
plot(freq,squeeze(median(rm_stats(:,1:2:end),1)),'r--');
hold on;
boxplot(rm_stats(:,1:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
plot(freq,squeeze(median(rm_stats(:,2:2:end),1)),'b--');
boxplot(rm_stats(:,2:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
ylim([0, 1])
hold off;

uncorrected_p = zeros(1,length(freq)*length(conditions));
wilcox_p = zeros(1,length(freq)*length(conditions));
iter0 = 0;
for iter1 = 1:length(conditions)
    for iter2 = 1:length(freq)
        figure;
        distribution = rm_stats(:,(iter2-1)*2+iter1);
        qqplot(distribution-mean(distribution))
        y_lim = get(gca, 'YLim');
        ylim([-max(abs(y_lim)), max(abs(y_lim))]);
        [~,p] = ttest(distribution-.5);
        iter0 = iter0+1;
        uncorrected_p(iter0) = p;
        [p,~] = signrank(distribution-.5);
        wilcox_p(iter0) = p;
    end
end

% Holm-Bonferroni Correction
[~, sorted_idx] = sort(uncorrected_p);
weighting = zeros(1,length(sorted_idx));
for iter1 = 1:length(sorted_idx)
    weighting(iter1) = 11 - find(~(iter1-sorted_idx));
end
p_vals = uncorrected_p.*weighting;
disp("ttest pvals:")
disp(p_vals)

[~, sorted_idx] = sort(wilcox_p);
    weighting = zeros(1,length(sorted_idx));
    for iter1 = 1:length(sorted_idx)
        weighting(iter1) = 11 - find(~(iter1-sorted_idx));
    end
p_vals = wilcox_p.*weighting;
disp("wilcox pvals:")
disp(p_vals)

%% Force Transmission Data
rm_stats = zeros(num_participants,length(freq)*length(conditions));
iter0 = 0;
for iter1 = 1:length(freq)
    for iter2 = 1:length(conditions)
        iter0 = iter0+1;
        rm_stats(:,iter0) = 20*log10(amp_out(:,iter2,iter1)./amp_in(:,iter2,iter1));
    end
end

plot_lims = [-55, 0];
AT_transmission = stat_tests(rm_stats,freq,conditions,plot_lims);