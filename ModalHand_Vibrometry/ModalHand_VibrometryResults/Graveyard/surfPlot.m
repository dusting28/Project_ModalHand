function [] = surfPlot(data,highRes,c_lim,colors,fig_title,log)
[xMesh,yMesh] = meshgrid(linspace(highRes.xCord(2),highRes.xCord(end),30),linspace(highRes.yCord(2),highRes.yCord(end),550));
zMesh = griddata(highRes.xCord(2:end),highRes.yCord(2:end),data(1:end),xMesh,yMesh);
figure
s = surf(xMesh,yMesh,zMesh);
s.EdgeColor = 'none';
colormap(colors);
set(gca,'Ydir','reverse')
if log
    set(gca,'ColorScale','log')
end
view(2)
clim(c_lim)
title(fig_title)
ylabel("Distance from Fingertip (mm)")
xlabel("Distance from Center Axis (mm)")
end