clc; clear; close all;

zoom = "Zoom1";
dots = "Dots";
freqs = [50,200];
frame_rate = 2000;
start_frame = [280,280]; %[280,280];
reference_frame = [0,0];
num_selected = 5;
tracking_cell = cell(length(freqs),1);

addpath("Videos/23_06_13/")

for iter1 = 1:length(freqs)
    clear rawframes 
    cycle = frame_rate/freqs(iter1);
    file_name = strcat(zoom,"_",dots,"_",num2str(freqs(iter1)),"Hz_",num2str(frame_rate),"fps.tif");
    info = imfinfo(file_name);
    width = info(1).Width;
    height = info(1).Height;
    num_frames = size(info,1);
    rawframes = zeros(width,height,3,num_frames);

    if freqs(iter1) == 200
        zoom1_xbox = [160 160 1340 1340];
        zoom1_ybox = [215 420 215 420];
        cut_box = [500 ,260];
        cut_region = "Q2";
    end
    
    if freqs(iter1) == 50
        zoom1_xbox = [180 180 1380 1380];
        zoom1_ybox = [260 430 260 430];
        cut_box = [450 ,410];
        cut_region = "Q3";
    end

    input_xbox = [170 170 520 520];
    input_ybox = [500 850 500 850];

    objectRegion = [min(zoom1_xbox) min(zoom1_ybox) max(zoom1_xbox)-min(zoom1_xbox) max(zoom1_ybox)-min(zoom1_ybox)];
    inputRegion = [min(input_xbox) min(input_ybox) max(input_xbox)-min(input_xbox) max(input_ybox)-min(input_ybox)];
    videoPlayer = vision.VideoPlayer('Position',objectRegion);

    for iter2 = 1:num_frames
        rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2,1,3]);
    end

    % Detect dots in single frame
    objectFrame = squeeze(rawframes(:,:,:,start_frame(iter1)));
    objectImage = insertShape(objectFrame,'rectangle',objectRegion,'Color','red');
    figure;
    imshow(objectImage);
    title('Red box shows object region');

    points = detectKAZEFeatures(im2gray(objectFrame),'ROI',objectRegion,'Threshold',.0003,'NumOctaves',2);
    input_points = detectKAZEFeatures(im2gray(objectFrame),'ROI',inputRegion,'Threshold',.0003,'NumOctaves',2);
    driving_point = selectStrongest(input_points,1);
    driving_point = driving_point.Location;
    point_locations = removeDots(points,30,cut_box,cut_region);
    
    % Display selected points
    pointImage = insertMarker(objectFrame,point_locations,'+','Color','red');
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
        for iter3 = 2:size(y_displacement,2)
            color_idx = min([max([round((y_displacement(iter2,iter3)+1)*256/2),1]),256]);
            plot(squeeze(cycle_positions(iter2,iter3,1)),squeeze(cycle_positions(iter2,iter3,2)),...
                '.','MarkerSize',50,'Color',squeeze(color_map(color_idx,:)))
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
            plot(iter2+cycle,input_y(cycle+iter2),'.','MarkerSize',45,'Color',squeeze(color_map(color_idx,:)))
            xlim([0 80]);
            hold off;
            %saveas(gcf,strcat("Input",num2str(iter0),"_",num2str(freqs(iter1)),"Hz.eps"))
        end
        close all;
    end

    filename = strcat(num2str(freqs(iter1)),"Hz_GIF.gif");
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
        plot(cycle_positions(1,iter2,1),max_val,'o');
        hold on;
        subplot(1,2,2);
        plot(cycle_positions(1,iter2,1),max_idx,'o');
        hold on;
    end
    hold off;


    % Single Axis
    [sort_x,sort_idx] = sort(cycle_positions(1,2:end,1));
    singleAxis_idx = zeros(1,floor(length(sort_idx)/3));
    iter0 = 0;
    for iter2 = 3:3:length(sort_idx)
        iter0 = iter0+1;
        column = cycle_positions(1,sort_idx(iter2-2:iter2)+1,2);
        [~,middle_idx] = min(abs(column - median(column)));
        singleAxis_idx(iter0) = sort_idx(iter2-3 + middle_idx)+1;
    end
    
    time = (0:cycle-1)/freqs(iter1);
    x_pos = squeeze(cycle_positions(1,singleAxis_idx,1)-cycle_positions(1,singleAxis_idx(1),1));

    [tMesh,xMesh] = meshgrid(linspace(time(1),time(end),100),linspace(x_pos(1),x_pos(end),100));
    zMesh = griddata(time,x_pos,y_displacement(:,singleAxis_idx)',tMesh,xMesh,"cubic");
    
    figure;
    s = surf(xMesh,tMesh,zMesh);
    s.EdgeColor = 'none';
    colormap(color_map);
    view(2)
    set(gca,'Ydir','reverse')

    % 
    tracking_cell{iter1} = y_displacement(:,singleAxis_idx);
end

save ImageData.mat freqs tracking_cell frame_rate

%% Plot Input Signals
figure;
t = (1:200)/100;
y = sin(t*2*pi);
plot(t,y);

