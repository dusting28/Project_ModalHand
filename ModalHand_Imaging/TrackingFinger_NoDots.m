clc; clear; close all;

zoom = "Zoom3";
freqs = [30,50,200];
frame_rate = 2800;

num_selected = 5;
tracking_cell= cell(length(zoom),length(freqs));
displacement_cell = cell(length(zoom),length(freqs));
gif = true;

addpath("Videos/23_04_12/")

for iter4 = 1:length(zoom)
    for iter1 = 1:length(freqs)
        clear rawframes 
        cycle = ceil(frame_rate/freqs(iter1));
        file_name = strcat(zoom(iter4),"_",num2str(freqs(iter1)),"Hz_",num2str(frame_rate),"fps.tif");
        info = imfinfo(file_name);
        width = info(1).Width;
        height = info(1).Height;
        num_frames = size(info,1);
    
        if zoom(iter4) == "Zoom3"
            start_frame = [50,180,280]; 
            dot_size = 40;
            if freqs(iter1) == 30
                cut_x = [680, 1800];
                cut_y = [435, 575];
                cut_thickness = 15;
            end
            if freqs(iter1) == 50
                cut_x = [680, 1800];
                cut_y = [435, 570];
                cut_thickness = 15;
            end
            if freqs(iter1) == 200
                cut_x = [680, 1800];
                cut_y = [375, 575];
                cut_thickness = 15;
            end
            input_x = [1600 1750];
            input_y = [650 800];
        end
    
        objectRegion = [cut_x(1) min(cut_y)-cut_thickness cut_x(2)-cut_x(1) max(cut_y)-min(cut_y)+2*cut_thickness];
        inputRegion = [input_x(1) input_y(1) input_x(2)-input_x(1) input_y(2)-input_y(1)];
        videoPlayer = vision.VideoPlayer('Position',objectRegion);
    
        %rawframes = zeros(width,height,3,num_frames);
        rawframes = zeros(height,width,3,num_frames);
        for iter2 = 1:num_frames
            % rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2,1,3]);
            rawframes(:,:,:,iter2) = rescale(imread(file_name,iter2));
        end
    
        % Detect dots in single frame
        objectFrame = squeeze(rawframes(:,:,:,start_frame(iter1)));
        objectImage = insertShape(objectFrame,'rectangle',objectRegion,'Color','red');
        figure;
        imshow(objectImage);
        title('Red box shows object region');

        if zoom(iter4) == "Zoom3"
            points = detectKAZEFeatures(objectFrame(:,:,1),'ROI',objectRegion,'Threshold',.000005,'NumOctaves',2);
            point_locations = maskDots(points,20,cut_x,cut_y,cut_thickness);
        end
        input_points = detectKAZEFeatures(im2gray(objectFrame),'ROI',inputRegion,'Threshold',.0003,'NumOctaves',2);
        driving_point = selectStrongest(input_points,1);
        driving_point = driving_point.Location;
        
        % Display selected points
        pointImage = insertMarker(objectFrame,[driving_point; point_locations],'+','Color','red');
        figure;
        imshow(pointImage);
        title('Detected interest points');
    
        % Track points
        tracker = vision.PointTracker('MaxBidirectionalError',1);
        initialize(tracker,[driving_point; point_locations],objectFrame);
        tracked_positions = zeros(num_frames-start_frame(iter1)+1,size(point_locations,1)+1,size(point_locations,2));
        for iter2 = start_frame(iter1):num_frames
          frame = squeeze(rawframes(:,:,:,iter2));
          [tracked_points,validity] = tracker(frame);
          tracked_positions(iter2-start_frame(iter1)+1,:,:) = tracked_points; 
        end
        
        [~, max_idx] = max(tracked_positions(cycle+1:cycle*2,1,2));
        max_idx = max_idx + cycle;
        cycle_positions = tracked_positions(max_idx:max_idx+cycle-1,:,:);
        y_displacement = squeeze(cycle_positions(:,:,2));
    
        input_amp = (max(y_displacement(:,1)) - min(y_displacement(:,1)))/2;
    
        input_y = squeeze(tracked_positions(max_idx-cycle:max_idx+cycle-1,1,2));
        input_y = (input_y-mean(input_y))/input_amp;
    
        for iter2 = 1:size(y_displacement,2)
            y_displacement(:,iter2) = (y_displacement(:,iter2) - mean(y_displacement(:,iter2)))/input_amp;
        end
    
        color_map = colorcet('COOLWARM');
        select_frames = round(linspace(1,cycle/2,num_selected));
        iter0 = 0;
        for iter2 = 1:cycle
            fig = figure;
            grayscale = rgb2gray(squeeze(rawframes(:,:,:,start_frame(iter1)+max_idx+iter2-2)));
            imshow(grayscale./2 + .5);
            hold on;
            for iter3 = 1:size(y_displacement,2)
                color_idx = min([max([round((y_displacement(iter2,iter3)+1)*256/2),1]),256]);
                plot(squeeze(cycle_positions(iter2,iter3,1)),squeeze(cycle_positions(iter2,iter3,2)),...
                    '.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
            end
            hold off;
            frame = getframe(fig);
            im{iter2} = frame2im(frame);
    
            if ismember(iter2, select_frames)
                iter0 = iter0+1;
                %saveas(gcf,strcat("Frame",num2str(iter0),"_",num2str(freqs(iter1)),"Hz.tiff"))
                figure;
                plot(input_y)
                hold on;
                color_idx = min([max([round((input_y(iter2+cycle)+1)*256/2),1]),256]);
                plot(iter2+cycle,input_y(cycle+iter2),'.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
                xlim([0 80]);
                hold off;
                %saveas(gcf,strcat("Input",num2str(iter0),"_",num2str(freqs(iter1)),"Hz.eps"))
            end
            close all;
        end
    
        if gif
            filename = strcat(zoom(iter4),"_",num2str(freqs(iter1)),"Hz_GIF.gif");
            for iter2 = 1:cycle
                [A,map] = rgb2ind(im{iter2},256);
                if iter2 == 1
                    imwrite(A,map,filename,"gif","LoopCount",Inf,"DelayTime",1);
                else
                    imwrite(A,map,filename,"gif","WriteMode","append","DelayTime",1);
                end
            end
        end
    
        tracking_cell{iter4,iter1} = cycle_positions;
        displacement_cell{iter4,iter1} = y_displacement;
    end
end

save NoDots_ImageData.mat zoom freqs frame_rate tracking_cell displacement_cell

