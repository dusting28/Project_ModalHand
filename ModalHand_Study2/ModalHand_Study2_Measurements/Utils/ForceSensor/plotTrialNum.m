function [] = plotTrialNum(measuredForce,desiredForce,titleName,color,trial,figNum)
    fig_info = figure(figNum);
    line_color = get(fig_info,'Color');
    set(gcf,'Position',[2100 300 800 600])
    subplot(3,7,9:11)
    plot(0,0);
    set(gca,'Color',color)
    title(titleName)
    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
    set(gca,'XColor',line_color,'YColor',line_color,'TickDir','out')
    subplot(3,7,[6 7 13 14 20 21])
    maxBar = mean(desiredForce)*3;
    forceBar = max([min([measuredForce,maxBar]),0]);
    x = categorical({'Measured Force'});
    y = forceBar;
    bar(x,y,'r')
    ylim([0,maxBar]);
    hold on;
    yline(desiredForce(1),'k')
    hold on;
    yline(desiredForce(2),'k')
    hold off;
    title("Force on Probe")
    ylabel("Force (N)")
    sgtitle(strcat("Trial ",num2str(trial)));
end

