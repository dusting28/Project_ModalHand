clc; clear; close all;

scenarios = ["Sliding1", "Sliding2", "Tapping1", "Tapping2", "Tapping3"];
frame_rate = [1000, 2000, 2000, 2000, 2000];
start_frame = [1,1,1,1,1]; 
tracking_win = 30;

tracking_cell= cell(length(scenarios),1);

addpath("Videos/NaturalTouch/")

for iter1 = 1:length(scenarios)

    % Read in image
    clear rawframes 
    file_name = strcat(scenarios(iter1),"_",num2str(frame_rate(iter1)),"FPS.tif");
    info = imfinfo(file_name);
    width = info(1).Width;
    height = info(1).Height;
    num_frames = size(info,1);
    rawframes = zeros(width,height,3,num_frames);
    for iter2 = 1:num_frames
        rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2 1 3]);
    end
   
    dotLocs = load(strcat(scenarios(iter1),"_DotLocs.mat"));
    dotLocs = dotLocs.dot_locs;
    point_locations = dotLocs;

    objectFrame = squeeze(rawframes(:,:,:,start_frame(iter1)));
    figure;
    for iter2 = 1:size(dotLocs,1)
        objectRegion = [dotLocs(iter2,1)-tracking_win/2, dotLocs(iter2,2)-tracking_win/2,...
            tracking_win+1, tracking_win+1];
        croppedImage = imcrop(objectFrame,objectRegion);
        imshow(croppedImage);
        points = detectKAZEFeatures(objectFrame(:,:,1),'ROI',objectRegion,'Threshold',.00001,'NumOctaves',2);
        single_point = selectStrongest(points,1);
        point_locations(iter2,1) = single_point.Location(1);
        point_locations(iter2,2) = single_point.Location(2);
        pointImage = insertMarker(objectFrame, point_locations(iter2,:),'+','Color','red');
        croppedImage = imcrop(pointImage,objectRegion);
        imshow(croppedImage);    
    end
        
    % Display selected points
    pointImage = insertMarker(objectFrame, point_locations,'+','Color','red');
    figure;
    imshow(pointImage);
    title('Detected interest points');

    % Track points
    tracker = vision.PointTracker('MaxBidirectionalError',1);
    initialize(tracker,point_locations,objectFrame);
    tracked_positions = zeros(num_frames-start_frame(iter1)+1,size(point_locations,1),size(point_locations,2));
    for iter2 = start_frame(iter1):num_frames
      frame = squeeze(rawframes(:,:,:,iter2));
      [tracked_points,validity] = tracker(frame);
      tracked_positions(iter2-start_frame(iter1)+1,:,:) = tracked_points; 
    end

    tracking_cell{iter1} = tracked_positions;
end

save ImageData_NaturalTouch.mat scenarios frame_rate tracking_cell
