clc; clear; close all;

zoom = "Zoom2";
freqs = [50,200];
frame_rate = 2000;
acc_win = 5;
desired_frames = 185;
color_map = colorcet('COOLWARM');

addpath("Videos/23_06_13/")

tracking_cell = cell(length(freqs),1);

for iter4 = 1:length(zoom)
    for iter1 = 1:length(freqs)
        clear rawframes 
        cycle = ceil(frame_rate/freqs(iter1));
        file_name = strcat(zoom(iter4),"_Dots_",num2str(freqs(iter1)),"Hz_",num2str(frame_rate),"fps.tif");
        info = imfinfo(file_name);
        width = info(1).Width;
        height = info(1).Height;
        num_frames = size(info,1);

        if zoom(iter4) == "Zoom2"
            start_frame = [50,14]; 
            dot_size = 35;
            if freqs(iter1) == 50
                cut_x = [70, 1500];
                cut_y = [935, 800];
                cut_thickness = 65;
                select_frames = [25, 31, 37, 43];
            end
            if freqs(iter1) == 200
                cut_x = [55, 1450];
                cut_y = [942, 655];
                cut_thickness = 65;
                select_frames = [7, 9, 11, 13];
            end
            input_x = [80 280];
            input_y = [1000 1200];
        end
    
        objectRegion = [cut_x(1) min(cut_y)-cut_thickness cut_x(2)-cut_x(1) max(cut_y)-min(cut_y)+2*cut_thickness];
        inputRegion = [input_x(1) input_y(1) input_x(2)-input_x(1) input_y(2)-input_y(1)];
        videoPlayer = vision.VideoPlayer('Position',objectRegion);
    
        rawframes = zeros(width,height,3,num_frames);
        for iter2 = 1:num_frames
            rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2,1,3]);
        end
    
        % Detect dots in single frame
        objectFrame = squeeze(rawframes(:,:,:,start_frame(iter1)));
        objectImage = insertShape(objectFrame,'rectangle',objectRegion,'Color','red');
        figure;
        imshow(objectImage);
        title('Red box shows object region');

        if zoom(iter4) == "Zoom2"
            points = detectKAZEFeatures(objectFrame(:,:,1),'ROI',objectRegion,'Threshold',.005,'NumOctaves',2);
            point_locations = maskDots(points,15,cut_x,cut_y,cut_thickness);
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

        [~,sorted_idx] = sort(tracked_positions(1,2:end,1));
        sorted_points = tracked_positions(:,sorted_idx+1,:);
        complete_points = zeros(size(sorted_points,1),120,size(sorted_points,3));
        dx = sorted_points(1,2:end,1) - sorted_points(1,1:end-1,1);
        [~,cut_idx] = maxk(dx,39);
        cut_idx = sort(cut_idx);
        cut_idx = [0, cut_idx, size(sorted_points,2)];
        skip_idx = 0;
        for iter2 = 1:length(cut_idx)-1
            [~,sorted_idx2] = sort(sorted_points(1,cut_idx(iter2)+1:cut_idx(iter2+1),2));
            group_size = length(sorted_idx2);
            complete_points(:,cut_idx(iter2)+1+skip_idx:cut_idx(iter2+1)+skip_idx,:) = sorted_points(:,cut_idx(iter2)+sorted_idx2,:);
            skip_idx = skip_idx + (3-group_size);
        end

        tracking_cell{iter1} = complete_points;
        
        [~, max_idx] = max(tracked_positions(1:cycle,1,2));
        cycle_positions = tracked_positions(max_idx:max_idx+desired_frames-1,:,:);
        y_displacement = squeeze(cycle_positions(:,:,2));

        acc_sig = zeros(size(y_displacement,1),size(y_displacement,2)-1);
        for iter2 = 2:size(y_displacement,2)
            acc_sig(:,iter2-1) = y_displacement(:,iter2) - movmean(y_displacement(:,iter2),round(frame_rate/freqs(iter1)));
        end
        % 
        % input_y = squeeze(y_displacement(:,1));
        % input_amp = (max(input_y) - min(input_y))/2;
        % input_y = input_y/input_amp;
        % y_displacement = y_displacement/input_amp;
        % 
        % figure;
        % plot(input_y);
        % saveas(gcf,strcat("InputSignal_",num2str(freqs(iter1)),"Hz"),"epsc")
    
        figure;
        imshow(squeeze(rawframes(:,:,:,start_frame(iter1)+max_idx-1)));
        hold on;
        for iter3 = 2:size(y_displacement,2)
                plot(squeeze(cycle_positions(1,iter3,1)),squeeze(cycle_positions(1,iter3,2)),...
                    '.','MarkerSize',dot_size,'Color','k')
        end
        hold off;
        

        % acc_sig = zeros(size(y_displacement,1)-2*acc_win,size(y_displacement,2)-1);
        % for iter2 = 2:size(y_displacement,2)
        %     acc_sig(:,iter2-1) = acc(y_displacement(1:size(y_displacement,1),iter2),acc_win,frame_rate);
        % end

        acc_sig = acc_sig./max(abs(acc_sig),[],"all");
        for iter2 = select_frames    
            figure;
            frame_num = start_frame(iter1)+iter2+max_idx-2;
            % imshow(squeeze((rawframes(:,:,:,frame_num)/4)+.75));
            imshow(0.75+0.25*rgb2gray(squeeze(rawframes(:,:,:,frame_num))));
            hold on;
            for iter3 = 1:size(acc_sig,2)
                color_idx = min([max([round((acc_sig(iter2,iter3)+1)*256/2),1]),256]);
                plot(cycle_positions(iter2,iter3+1,1),cycle_positions(iter2,iter3+1,2),...
                    '.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
                hold on;
            end
            hold off;
            saveas(gcf,strcat("MATLAB_Plots/FigS3_",num2str(freqs(iter1)),"Hz_Frame",num2str(iter2)),"tiffn")
        end
    end
end

save ImageData_EngineeredTouch.mat freqs frame_rate tracking_cell