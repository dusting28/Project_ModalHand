clc; clear; close all;

zoom = "Zoom3";
dots = "Dots";
freqs = 200;%[50,200];
frame_rate = 2800;
start_frame = [50,50];
reference_frame = [0,0];
num_images = 4;
numX = 3;
numY = 37;

% Create a cascade detector object.
tracker = vision.PointTracker('MaxBidirectionalError',1);

for iter1 = 1:length(freqs)
    cycle = frame_rate/freqs(iter1);
    file_name = strcat("Graveyard/Videos/",zoom,"_",num2str(freqs(iter1)),"Hz_",num2str(frame_rate),"fps.tif");
    info = imfinfo(file_name);
    width = info(1).Width;
    height = info(1).Height;
    num_frames = size(info,1);
    rawframes = zeros(width,height,3,num_frames);

    for iter2 = 1:num_frames
        rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2,1,3]);
    end

    %% After frames loaded

    driving_point = [683, 1727];
    x_points = linspace(440,500,numX);
    y_points = linspace(690,1745,numY);
    point_locations = table2array(round(combinations(y_points,x_points)));
    point_locations = flip(point_locations,2);

    for iter2 = 1:size(point_locations,1)
        point_locations(iter2,1) = point_locations(iter2,1) + 3*floor((iter2-1)/numX);
    end

    objectFrame = squeeze(rawframes(:,:,:,1));
    pointImage = insertMarker(objectFrame,point_locations,'+','Color','red');
    pointImage = insertMarker(pointImage,driving_point,'+','Color','green');
    figure;
    imshow(pointImage);
    title('Detected interest points');

    initialize(tracker,[driving_point; point_locations],objectFrame);
    
    tracked_positions = zeros(num_frames,size(point_locations,1)+1,size(point_locations,2));

    for iter2 = 1:num_frames
      frame = squeeze(rawframes(:,:,:,iter2));
      [tracked_points,validity] = tracker(frame);
      tracked_positions(iter2,:,:) = tracked_points; 
    end
    
    [~, max_idx] = max(tracked_positions(start_frame(iter1):start_frame(iter1)+cycle-1,1,2));
    start_frame(iter1) = start_frame(iter1) + max_idx - 1;

    final_positions = tracked_positions(start_frame(iter1):start_frame(iter1)+cycle-1,:,:);
    y_displacement = squeeze(final_positions(:,:,2));

    input_amp = (max(y_displacement(:,1)) - min(y_displacement(:,1)))/2;

    for iter2 = 1:size(y_displacement,2)
        y_displacement(:,iter2) = (y_displacement(:,iter2) - mean(y_displacement(:,iter2)))/input_amp;
    end

    colormap = colorcet('COOLWARM');

    for iter2 = 1:cycle
        fig = figure;
        imshow(squeeze(rawframes(:,:,:,start_frame(iter1)+iter2-1)))
        hold on;
        for iter3 = 2:size(y_displacement,2)
            color_idx = min([max([round((y_displacement(iter2,iter3)+1)*256/2),1]),256]);
            plot(squeeze(final_positions(iter2,iter3,1)),squeeze(final_positions(iter2,iter3,2)),...
                '.','MarkerSize',40,'Color',squeeze(colormap(color_idx,:)))
        end
        hold off;
        frame = getframe(fig);
        im{iter2} = frame2im(frame);
        close all;
    end

    filename = "testAnimated.gif"; % Specify the output file name
    for iter2 = 1:cycle
        [A,map] = rgb2ind(im{iter2},256);
        if iter2 == 1
            imwrite(A,map,filename,"gif","LoopCount",Inf,"DelayTime",1);
        else
            imwrite(A,map,filename,"gif","WriteMode","append","DelayTime",1);
        end
    end

    figure;
    for iter2 = 2:size(y_displacement,2)
        plot(squeeze(y_displacement(:,iter2)))
        hold on;
    end
    hold off;

    figure;
    for iter2 = 2:size(y_displacement,2)
        [max_val, max_idx] = max(squeeze(y_displacement(:,iter2)));
        subplot(1,2,1);
        plot(final_positions(1,iter2,1),max_val,'o');
        hold on;
        subplot(1,2,2);
        plot(final_positions(1,iter2,1),max_idx,'o');
        hold on;
    end
    hold off;
    
% release(videoPlayer);
end