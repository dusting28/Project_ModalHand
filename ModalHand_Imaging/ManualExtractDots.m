clc; clear; close all;

scenarios = ["Sliding1", "Sliding2", "Tapping1", "Tapping2", "Tapping3"];
frame_rate = [1000, 2000, 2000, 2000, 2000];
start_frame = [1,1,1,1,1]; 
num_dots = [114, 114, 120, 120,120];

addpath("Videos/NaturalTouch/")

for iter1 = 5:length(scenarios)

    % Read in image
    clear rawframes 
    file_name = strcat(scenarios(iter1),"_",num2str(frame_rate(iter1)),"FPS.tif");
    info = imfinfo(file_name);
    frame = permute(rescale(imread(file_name,1)),[2 1 3]);

    dot_locs = zeros(num_dots(iter1),2);

    figure;
    for iter2 = 1:num_dots(iter1)
        pointImage = insertMarker(frame, dot_locs,'*','Color','red','Size',10);
        imshow(pointImage);
        title(num2str(iter2));
        [x_click,y_click] = ginput(1);
        dot_locs(iter2,1) = x_click;
        dot_locs(iter2,2) = y_click;
    end

    save(strcat(scenarios(iter1),"_DotLocs.mat"),"dot_locs")
end
    