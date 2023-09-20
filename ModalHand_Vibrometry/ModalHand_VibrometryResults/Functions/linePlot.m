function [] = linePlot(data,highRes,show_joints,title_name,include_probe)

    figure
    if include_probe
        plot([highRes.yCord(1), highRes.yCord(2:3:end)], [data(1), data(2:3:end)],'r.')
        hold on;
        plot([highRes.yCord(1), highRes.yCord(3:3:end)], [data(1), data(3:3:end)],'r.')
        hold on;
        plot([highRes.yCord(1), highRes.yCord(4:3:end)], [data(1), data(4:3:end)],'r.')
        hold on;
        plot([highRes.yCord(1), highRes.yCord(2:3:end)], [data(1), mean([data(2:3:end); data(3:3:end); data(4:3:end);],1)],'r')
    else
        plot([highRes.yCord(2:3:end)], [data(1:3:end)],'r.')
        hold on;
        plot([highRes.yCord(3:3:end)], [data(2:3:end)],'r.')
        hold on;
        plot([highRes.yCord(4:3:end)], [data(3:3:end)],'r.')
        hold on;
        plot([highRes.yCord(2:3:end)], [mean([data(1:3:end); data(2:3:end); data(3:3:end);],1)],'r')
    end
    
    if show_joints
        xline(highRes.yDIP, '-k');
        xline(highRes.yPIP, '-k');
        xline(highRes.yMCP, '-k');
        xline(highRes.yWrist, '-k');
    end
    hold off;
    title(title_name)
    xlabel("Distanct from Finger Tip (mm)");
end
