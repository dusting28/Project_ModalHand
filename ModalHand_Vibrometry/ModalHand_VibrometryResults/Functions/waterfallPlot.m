function [] = waterfallPlot(data,offset,K,highRes,c_max,colors,include_probe)
    
    if include_probe
        yCord = highRes.yCord(1:3:end);  
    else
        yCord = highRes.yCord(2:3:end);
    end

    yUp = linspace(yCord(1),yCord(end),1000);
    dataUp = round(csapi(yCord,movmean(1000*data/c_max,K),yUp));

    xOffset = (2*offset)*600;
    xUp = xOffset-1200:xOffset+1200;

    [xMesh,yMesh] = meshgrid(xUp,yUp);
    zMesh = NaN(size(xMesh));
    for iter1 = 1:length(dataUp)
        zMesh(iter1,1000+dataUp(iter1):1400+dataUp(iter1)) = c_max*dataUp(iter1)/1000;
    end
    
    s = surf(xMesh,yMesh,zMesh);
    s.EdgeColor = 'none';
    colormap(colors);
    set(gca,'Ydir','reverse')
    view(2)
    clim([-c_max,c_max])
    %axis equal
    colorbar;
    ylabel("Distance from Fingertip (mm)")
    xlabel("Distance from Center Axis (mm)")
    set(gca,'ytick',[])
    set(gca,'xtick',[])
end