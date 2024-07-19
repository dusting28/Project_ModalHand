function [] = waterfallPlot2(data,offset,K,highRes,colors,include_probe)
    
    if include_probe
        yCord = highRes.yCord(1:3:end);  
    else
        yCord = highRes.yCord(2:3:end);
    end
    yUp = linspace(yCord(1),yCord(end),1000);
    dataUp = csapi(yCord,movmean(data,K),yUp);

    c_max = max(abs(dataUp),[],"all");

    xCord = offset + 1:size(data,1);

    [xMesh,yMesh] = meshgrid(yUp,xCord);
    zMesh = dataUp;
    
    waterfall(xMesh,yMesh,zMesh);
    set(gca,'Ydir','reverse')
    clim([-c_max,c_max])
    colormap(colors);
    colorbar;
    ylabel("Distance from Fingertip (mm)")
    xlabel("Distance from Center Axis (mm)")
    set(gca,'ytick',[])
    set(gca,'xtick',[])
end