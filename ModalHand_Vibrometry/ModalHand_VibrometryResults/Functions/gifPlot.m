function [] = gifPlot(data,K,highRes,c_lim,colors,fig_title,include_probe)
    % Smooth Data
    if include_probe
        data_2D = [data(1), data(2:3:end); data(1), data(3:3:end); data(1), data(4:3:end)];
    else
        data_2D = [data(1:3:end); data(2:3:end); data(3:3:end)];
    end

    kernal = (1/(K^2))*ones(K);
    data_2D = imfilter(data_2D,kernal,"replicate");

    if include_probe
        iter0 = 1;
        data(iter0) = data_2D(1,1);
        for iter1 = 1:size(data_2D,2)
            for iter2 = 1:size(data_2D,1)
                iter0 = iter0+1;
                data(iter0) = data_2D(iter2,iter1+1);
            end
        end
    else
        iter0 = 0;
        for iter1 = 1:size(data_2D,2)
            for iter2 = 1:size(data_2D,1)
                iter0 = iter0+1;
                data(iter0) = data_2D(iter2,iter1);
            end
        end
    end

    if include_probe
        [xMesh,yMesh] = meshgrid(linspace(highRes.xCord(2),highRes.xCord(4),50),linspace(highRes.yCord(1),highRes.yCord(end),1000));
        zMesh = griddata(highRes.xCord,highRes.yCord,data,xMesh,yMesh,"cubic");
    else
        [xMesh,yMesh] = meshgrid(linspace(highRes.xCord(2),highRes.xCord(4),50),linspace(highRes.yCord(2),highRes.yCord(end),1000));
        zMesh = griddata(highRes.xCord(2:end),highRes.yCord(2:end),data,xMesh,yMesh,"cubic");
    end

    x_line = linspace(highRes.xCord(2),highRes.xCord(4),50);
    y_line = linspace(0,highRes.yWrist,1000);
    z_line = 0;

    hFigure = figure;
    set(hFigure, 'MenuBar', 'none');
    set(hFigure, 'ToolBar', 'none');
    s = surf(xMesh,yMesh,zMesh);
    s.EdgeColor = 'none';
    hold on;
    plot3(x_line,zeros(1,size(x_line,1)),z_line*ones(1,size(x_line,1)),'Color','black','LineWidth',5)
    hold on;
    plot3(x_line,highRes.yDIP*ones(1,size(x_line,1))',z_line*ones(1,size(x_line,1))','Color','black','LineWidth',5)
    hold on;
    plot3(x_line,highRes.yPIP*ones(1,size(x_line,1)),z_line*ones(1,size(x_line,1)),'Color','black','LineWidth',5)
    hold on;
    plot3(x_line,highRes.yMCP*ones(1,size(x_line,1)),z_line*ones(1,size(x_line,1)),'Color','black','LineWidth',5)
    hold on;
    plot3(x_line,highRes.yWrist*ones(1,size(x_line,1)),z_line*ones(1,size(x_line,1)),'Color','black','LineWidth',5)
    hold on;
    plot3(highRes.xCord(2)*ones(1,size(y_line,1)),y_line,z_line*ones(1,size(y_line,1)),'Color','black','LineWidth',5)
    hold on;
    plot3(highRes.xCord(4)*ones(1,size(y_line,1)),y_line,z_line*ones(1,size(y_line,1)),'Color','black','LineWidth',5)
    hold off;

    colormap(colors);
    set(gca,'Ydir','reverse')
    clim(c_lim)
    xlim([-5, 5]);
    ylim([0,highRes.yWrist]);
    axis equal
    zlim(c_lim);
    title(fig_title)
    
    colorbar;
    ylabel("Distance from Fingertip (mm)")
    xlabel("Distance from Center Axis (mm)")
    % set(gca,'ztick',[])
    % set(gca,'ytick',[])
    % set(gca,'xtick',[])
    %axis off
    exportgraphics(gcf,strcat(fig_title,".gif"),'Append',true);
    close(hFigure) 
end