clc; clear; close all;

zoom = "Zoom3";
freqs = [30,200];
frame_rate = 2800;

desired_frames = 185;
tracking_cell= cell(length(zoom),length(freqs));
displacement_cell = cell(length(zoom),length(freqs));
gif = false;

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
            start_frame = [50,14]; 
            dot_size = 20;
            if freqs(iter1) == 15
                cut_x = [680, 1780];
                cut_y = [435, 585];
                cut_thickness = 35;
            end
            if freqs(iter1) == 30
                cut_x = [680, 1800];
                cut_y = [435, 575];
                cut_thickness = 35;
            end
            if freqs(iter1) == 50
                cut_x = [680, 1800];
                cut_y = [435, 570];
                cut_thickness = 35;
            end
            if freqs(iter1) == 200
                cut_x = [680, 1800];
                cut_y = [375, 580];
                cut_thickness = 35;
            end
            input_x = [1600 1750];
            input_y = [650 800];
        end
    
        objectRegion = [cut_x(1) min(cut_y)-cut_thickness cut_x(2)-cut_x(1) max(cut_y)-min(cut_y)+2*cut_thickness];
        inputRegion = [input_x(1) input_y(1) input_x(2)-input_x(1) input_y(2)-input_y(1)];
        videoPlayer = vision.VideoPlayer('Position',objectRegion);
    
        rawframes = zeros(height,width,3,num_frames);
        for iter2 = 1:num_frames
            rawframes(:,:,:,iter2) = rescale(imread(file_name,iter2));
        end
    
        % Detect dots in single frame
        objectFrame = squeeze(rawframes(:,:,:,start_frame(iter1)));
        objectImage = insertShape(objectFrame,'rectangle',objectRegion,'Color','red');
        figure;
        imshow(objectImage);
        title('Red box shows object region');

        if zoom(iter4) == "Zoom3"
            points = detectKAZEFeatures(objectFrame(:,:,1),'ROI',objectRegion,'Threshold',.000001,'NumOctaves',2);
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
        
        [~, max_idx] = max(tracked_positions(1:cycle,1,2));
        cycle_positions = tracked_positions(max_idx:max_idx+desired_frames-1,:,:);
        y_displacement = squeeze(cycle_positions(:,:,2));

        for iter2 = 1:size(y_displacement,2)
            y_displacement(:,iter2) = y_displacement(:,iter2) - movmean(y_displacement(:,iter2),round(frame_rate/freqs(iter1)));
        end
    
        input_y = squeeze(y_displacement(:,1));
        input_amp = (max(input_y) - min(input_y))/2;
        input_y = input_y/input_amp;
        y_displacement = y_displacement/input_amp;

        figure;
        plot(input_y);
        saveas(gcf,strcat("InputSignal_",num2str(freqs(iter1)),"Hz"),"epsc")
    
        figure;
        imshow(squeeze(rawframes(:,:,:,start_frame(iter1))));
        hold on;
        for iter3 = 2:size(y_displacement,2)
                plot(squeeze(cycle_positions(iter2,iter3,1)),squeeze(cycle_positions(iter2,iter3,2)),...
                    '.','MarkerSize',dot_size,'Color','k')
        end
        hold off;
        xlim([0,width]);
        ylim([0,height]);
        saveas(gcf,strcat("TrackedPoints_",num2str(freqs(iter1)),"Hz"),"tiffn")

        color_map = colorcet('COOLWARM');
        for iter2 = round(linspace(1,round(cycle/2),4))
            figure;
            imshow(squeeze(rawframes(:,:,:,start_frame(iter1)+max_idx+iter2-2)));
            hold on;

            for iter3 = 2:size(y_displacement,2)
                color_idx = min([max([round((y_displacement(iter2,iter3)+1)*256/2),1]),256]);
                plot(squeeze(cycle_positions(iter2,iter3,1)),squeeze(cycle_positions(iter2,iter3,2)),...
                    '.','MarkerSize',dot_size*2,'Color',squeeze(color_map(color_idx,:)))
                hold on;
            end
            hold off;
            xlim([0,width]);
            ylim([0,height]);
            pbaspect([width height 1])
            saveas(gcf,strcat("Frame",num2str(iter2),"_",num2str(freqs(iter1)),"Hz"),"tiffn")
            timepoint = (iter2-1)/frame_rate;
            disp(timepoint)
            figure;
            x = -pi:.01:3*pi;
            plot(x,sin(x))
            phase = 2*pi*timepoint*freqs(iter1)+pi/2;
            color_idx = min([max([round((sin(phase)+1)*256/2),1]),256]);
            hold on;
            plot(phase,sin(phase),'.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
            saveas(gcf,strcat("Input",num2str(iter2),"_",num2str(freqs(iter1)),"Hz"),"epsc")
        end
    
        tracking_cell{iter4,iter1} = cycle_positions;
        displacement_cell{iter4,iter1} = y_displacement;
    end
end

save ImageData_MultiCycle.mat zoom freqs frame_rate tracking_cell displacement_cell
