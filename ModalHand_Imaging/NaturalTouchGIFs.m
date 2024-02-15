clc; clear; close all;
addpath("Videos/NaturalTouch/")

imaging = load("ImageData_NaturalTouch.mat");
dot_size = 35;
% color_map = flipud(colorcet('COOLWARM'));
color_map = colorcet('COOLWARM');
acc_win = 5;
start_idx = [1,1,1,1,60];
sig_len = 100;
remove_points = [0,0,2,5,2];

select_frames = [5, 15, 20, 25];

for iter1 = 5
    file_name = strcat(imaging.scenarios(iter1),"_",num2str(imaging.frame_rate(iter1)),"FPS.tif");
    info = imfinfo(file_name);
    width = info(1).Width;
    height = info(1).Height;
    num_frames = size(info,1);
    rawframes = zeros(width,height,3,num_frames);

    for iter2 = 1:num_frames
        rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2 1 3]);
    end

    
    excluded_points = size(imaging.tracking_cell{iter1},2)-3*(remove_points(iter1)-1):3:size(imaging.tracking_cell{iter1},2);
    included_points = 1:size(imaging.tracking_cell{iter1},2);
    included_points(excluded_points) = [];
    
    x_pos = squeeze(imaging.tracking_cell{iter1}(:,included_points,1));
    y_pos = squeeze(imaging.tracking_cell{iter1}(:,included_points,2));
    acc_sig = zeros(sig_len-2*acc_win,length(included_points));
    
    for iter2 = 1:length(included_points)
        acc_sig(:,iter2) = acc(y_pos(start_idx(iter1):start_idx(iter1)+sig_len-1,iter2),acc_win,imaging.frame_rate(iter1));
    end

    %fig = figure;
    acc_sig = acc_sig./max(abs(acc_sig),[],"all");
    for iter2 = select_frames    
        figure;
        frame_num = start_idx(iter1)+iter2-1;
        imshow(squeeze((rawframes(:,:,:,frame_num)/4)+.75));
        hold on;
        for iter3 = 1:length(included_points)
            color_idx = min([max([round((acc_sig(iter2,iter3)+1)*256/2),1]),256]);
            plot(x_pos(frame_num,iter3),y_pos(frame_num,iter3),...
                '.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
            hold on;
        end
        hold off;

    
        % [A,map] = rgb2ind(frame2im(getframe(fig)),256);
        % if iter2 == 1
        %     imwrite(A,map,strcat(imaging.scenarios(iter1),"_","GIF.gif"),"gif","LoopCount",Inf,"DelayTime",1);
        % else
        %     imwrite(A,map,strcat(imaging.scenarios(iter1),"_","GIF.gif"),"gif","WriteMode","append","DelayTime",1);
        % end
    end
end