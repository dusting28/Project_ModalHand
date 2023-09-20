function [] = surfPlot(data,K,highRes,c_lim,colors,fig_title,log,include_probe)
    if log
        data = log10(data);
    end

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
    
    % Mask    
    y_pixels = 1950;
    x_pixels = 1705;
    
    pixel_convert = highRes.yWrist/y_pixels;
    
    % Mask off hand
    template = imread("SpatialStudySingle.png");
    [ref_y,ref_x] = find(template<225);
    ref_x = ref_x+65;
    ref_y = ref_y-65;
    [~,idx] = min(ref_x);
    binary_image = squeeze(template(ref_y(idx)-y_pixels+1:ref_y(idx),...
        ref_x(idx):ref_x(idx)+x_pixels-1,1))<200;
    [outline,masking_matrix] = maskHand(binary_image);

    [xMesh,yMesh] = meshgrid(pixel_convert*linspace(-x_pixels/2,x_pixels/2,x_pixels),...
    pixel_convert*linspace(0,y_pixels,y_pixels));
    if include_probe
        % extrapolate
        % zMesh = griddata([3*highRes.xCord(2) 3*highRes.xCord(4), highRes.xCord, 3*highRes.xCord(2:3:end), 3*highRes.xCord(4:3:end)],...
        %     [0, 0, highRes.yCord, highRes.yCord(2:3:end), highRes.yCord(4:3:end)],...
        %     [data(1), data(1), data, data(2:3:end), data(4:3:end)]...
        %     ,xMesh,yMesh);
        % raw data
        zMesh = griddata(highRes.xCord,highRes.yCord,data,xMesh,yMesh,"cubic");
    else
        zMesh = griddata(highRes.xCord(2:end),highRes.yCord(2:end),data,xMesh,yMesh,"cubic");
    end
    zMesh = zMesh.*masking_matrix;
    zMesh(zMesh==0) = NaN;
    
    figure
    s = surf(xMesh,yMesh,zMesh);
    s.EdgeColor = 'none';
    colormap(colors);
    set(gca,'Ydir','reverse')
    view(2)
    hold on;
    plot3(xMesh(1,outline(:,2)),yMesh(outline(:,1),2),ones(1,size(outline,1))*max(zMesh,[],"all"),'k')
    clim(c_lim)
    title(fig_title)
    axis equal
    colorbar;
    ylabel("Distance from Fingertip (mm)")
    xlabel("Distance from Center Axis (mm)")
    set(gca,'ytick',[])
    set(gca,'xtick',[])
end