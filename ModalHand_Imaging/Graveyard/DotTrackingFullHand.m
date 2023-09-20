clc; clear; close all;

zoom = "Zoom2";
dots = "Dots";
freqs = 50;%[50,200];
frame_rate = 2000;
start_frame = [180,180];
reference_frame = [0,0];
num_images = 4;

% Create a cascade detector object.
tracker = vision.PointTracker('MaxBidirectionalError',1);

% zoom1_xbox = [175, 165, 1315, 1325]+179;
% zoom1_ybox = [403, 305, 227, 355]+48;

% zoom1_xbox = [170, 160, 1320, 1330];
% zoom1_ybox = [433, 295, 217, 385];

for iter1 = 1:length(freqs)
    cycle = frame_rate/freqs(iter1);
    file_name = strcat("Videos_22_06_13/",zoom,"_",dots,"_",num2str(freqs(iter1)),"Hz_",num2str(frame_rate),"fps.tif");
    info = imfinfo(file_name);
    width = info(1).Width;
    height = info(1).Height;
    num_frames = size(info,1);
    rawframes = zeros(width,height,3,num_frames);

    if freqs(iter1) == 200
        zoom1_xbox = [80 80 1400 1400];
        zoom1_ybox = [615 975 615 975];
        cut_box = [500 ,250];
    end
    
    if freqs(iter1) == 50
        zoom1_xbox = [100 100 1460 1460];
        zoom1_ybox = [730 970 730 970];
        cut_box = [500 ,250];
    end

    input_xbox = [70 70 420 420];
    input_ybox = [950 1250 950 1250];

%     objectRegion = [round(.03*height) round(.2*width) round(.9*height) round(.3*width)];
    objectRegion = [min(zoom1_xbox) min(zoom1_ybox) max(zoom1_xbox)-min(zoom1_xbox) max(zoom1_ybox)-min(zoom1_ybox)];
    inputRegion = [min(input_xbox) min(input_ybox) max(input_xbox)-min(input_xbox) max(input_ybox)-min(input_ybox)];
    videoPlayer = vision.VideoPlayer('Position',objectRegion);

    for iter2 = 1:num_frames
        rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2,1,3]);
    end

    % Read a video frame and run the face detector
    objectFrame = squeeze(rawframes(:,:,:,1));
    objectImage = insertShape(objectFrame,'rectangle',objectRegion,'Color','red');
    figure;
    imshow(objectImage);
    title('Red box shows object region');

    % points = detectKAZEFeatures(im2gray(objectFrame),'ROI',objectRegion,'Threshold',.005,'NumOctaves',2);
    points = detectKAZEFeatures(im2gray(objectFrame),'ROI',objectRegion,'Threshold',.003,'NumOctaves',2);
    input_points = detectKAZEFeatures(im2gray(objectFrame),'ROI',inputRegion,'Threshold',.0003,'NumOctaves',2);
    driving_point = selectStrongest(input_points,1);
    driving_point = driving_point.Location;
    point_locations = removeDots(points,15,cut_box);

    pointImage = insertMarker(objectFrame,point_locations,'+','Color','red');
    figure;
    imshow(pointImage);
    title('Detected interest points');

    initialize(tracker,[driving_point; point_locations],objectFrame);
    
    tracked_positions = zeros(num_frames,size(point_locations,1)+1,size(point_locations,2));

    for iter2 = 1:num_frames
      frame = squeeze(rawframes(:,:,:,iter2));
      [tracked_points,validity] = tracker(frame);
      tracked_positions(iter2,:,:) = tracked_points; 
%       out = insertMarker(frame,tracked_points(validity, :),'+');
%       videoPlayer(out);
%       %videoPlayer(out(objectRegion(2):objectRegion(2)+objectRegion(4),...
%           %objectRegion(1):objectRegion(1)+objectRegion(3)));
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
    
% release(videoPlayer);
end