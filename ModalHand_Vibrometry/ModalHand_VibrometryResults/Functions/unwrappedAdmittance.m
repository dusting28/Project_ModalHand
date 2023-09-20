function [] = unwrappedAdmittance(freq,highRes,admittance,K,include_probe)
    
    single_axis = singleAxis(log10(abs(admittance)),include_probe);

    kernal = (1/(K^2))*ones(K);
    single_axis = imfilter(single_axis,kernal,"replicate");

    if include_probe
        [xMesh,yMesh] = meshgrid(freq,linspace(highRes.yCord(1),highRes.yCord(end),200));
        zMesh = griddata(freq,[highRes.yCord(1), highRes.yCord(3:3:end)],single_axis',xMesh,yMesh,"cubic");
    else
        [xMesh,yMesh] = meshgrid(freq,linspace(highRes.yCord(2),highRes.yCord(end),200));
        zMesh = griddata(freq,highRes.yCord(3:3:end),single_axis',xMesh,yMesh,"cubic");
    end

    figure;
    s = surf(xMesh,yMesh,zMesh);
    s.EdgeColor = 'none';
    colormap turbo;
    set(gca,'Ydir','reverse')
    view(2)
    clim([-1,3])
    ylabel("Distance from Fingertip (mm)")
    xlabel("Frequency (Hz)")
    xlim([15, 400]);
    set(gca,'ytick',[])
    set(gca,'xtick',[])
end