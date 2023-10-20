function [ANOVA_Results] = stat_tests(rm_stats, freq, conditions, plot_lims)
    jitter = 8;
    figure
    plot(freq,squeeze(median(rm_stats(:,1:2:end),1)),'r--');
    hold on;
    boxplot(rm_stats(:,1:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','r','Positions',freq-jitter);
    plot(freq,squeeze(median(rm_stats(:,2:2:end),1)),'b--');
    boxplot(rm_stats(:,2:2:end),'BoxStyle','filled','MedianStyle','target','Symbol','.','Colors','b','Positions',freq+jitter);
    ylim(plot_lims)
    hold off;
    
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
    ANOVA_Results = ranova(rm, 'WithinModel', 'Frequency*Condition');
    
    
    uncorrected_p = zeros(1,length(freq));
    wilcox_p = zeros(1,length(freq));
    for iter1 = 1:length(freq)
        figure;
        paired_distribution = rm_stats(:,(iter1-1)*2+1)-rm_stats(:,(iter1-1)*2+2);
        qqplot(paired_distribution-mean(paired_distribution))
        y_lim = get(gca, 'YLim');
        ylim([-max(abs(y_lim)), max(abs(y_lim))]);
        disp(strcat(num2str(freq(iter1)),"Hz  outliers: ", num2str(sum(isoutlier(rm_stats(:,(iter1-1)*2+1)-rm_stats(:,(iter1-1)*2+2))))))
        [~,p] = ttest(rm_stats(:,(iter1-1)*2+1),rm_stats(:,(iter1-1)*2+2));
        uncorrected_p(iter1) = p;
        [p,~] = signrank(rm_stats(:,(iter1-1)*2+1),rm_stats(:,(iter1-1)*2+2));
        wilcox_p(iter1) = p;
    end
    
    % Holm-Bonferroni Correction
    [~, sorted_idx] = sort(uncorrected_p);
    weighting = zeros(1,length(sorted_idx));
    for iter1 = 1:length(sorted_idx)
        weighting(iter1) = 6 - find(~(iter1-sorted_idx));
    end
    p_vals = uncorrected_p.*weighting;
    disp("t-test pvals:")
    disp(p_vals)
    
    [~, sorted_idx] = sort(wilcox_p);
    weighting = zeros(1,length(sorted_idx));
    for iter1 = 1:length(sorted_idx)
        weighting(iter1) = 6 - find(~(iter1-sorted_idx));
    end
    p_vals = wilcox_p.*weighting;
    disp("wilcox pvals:")
    disp(p_vals)
    
    disp("sphericity:")
    disp(mauchly(rm))
    disp("epsilon:")
    disp(epsilon(rm))
    group_means = mean(rm_stats,1);
    demeaned = rm_stats - ones(size(rm_stats,1),1)*group_means;
    subject_means = mean(demeaned,2);
    residuals = rm_stats - ones(size(rm_stats,1),1)*group_means - subject_means * ones(1,size(rm_stats,2));
    %residuals = table2array(rm_table - predict(rm,rm_table));
    residuals = reshape(residuals ,1,[]);
    figure;
    qqplot(residuals)
    y_lim = get(gca, 'YLim');
    ylim([-max(y_lim), max(y_lim)]);
    disp(strcat("residual outliers: ", num2str(sum(isoutlier(residuals)))))
end