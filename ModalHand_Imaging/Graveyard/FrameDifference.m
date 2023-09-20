clc; clear; close all;

zoom = "Zoom2";
dots = "Dots";
freqs = [50,200];
frame_rate = 2000;
start_frame = 200;
reference_frame = [0,0];
num_images = 4;

for iter1 = 1:length(freqs)
    cycle = frame_rate/freqs(iter1);
    file_name = strcat("Videos_22_06_13/",zoom,"_",dots,"_",num2str(freqs(iter1)),"Hz_",num2str(frame_rate),"fps.tif");
    sum_val = -10^10;
    max_val = 0;
    for iter2 = 1:cycle
        frame_idx = start_frame+iter2;
        im1 = imread(file_name,frame_idx);
        im2 = imread(file_name,frame_idx+round(cycle/2));
        diff = squeeze(int32(im2(:,:,3))-int32(im1(:,:,3)));
        new_max = max(abs(diff),[],'all');
        new_sum = sum(diff,'all');
        if new_sum > sum_val
            sum_val = new_sum;
            reference_frame(iter1) = start_frame+iter2;
        end
        if new_max > max_val
            max_val = new_max;
        end
    end
end

for iter1 = 1:length(freqs)
    cycle = frame_rate/freqs(iter1);
    spacing = cycle/num_images/2;
    file_name = strcat("Videos_22_06_13/",zoom,"_",dots,"_",num2str(freqs(iter1)),"Hz_",num2str(frame_rate),"fps.tif");
    for iter2 = 1:num_images
        frame_idx = round(reference_frame(iter1)+(iter2-1)*spacing);
        im1 = imread(file_name,frame_idx);
        im2 = imread(file_name,frame_idx+round(cycle/2));
        % For future: Make Black and White Here
        diff = squeeze(im2gray(int32(im2(:,:,1)))-im2gray(int32(im1(:,:,1))));
        figure((iter1-1)*num_images*2+iter1)
        subplot(num_images,1,iter2)
        time = linspace(0,2*cycle,100);
        time = time(1:end-1);
        t1 = cycle+frame_idx-reference_frame(iter1);
        t2 = cycle+frame_idx-reference_frame(iter1)+round(cycle/2);
        plot(time,-cos(2*pi*freqs(iter1)*time/frame_rate),'k')
        hold on;
        plot(t1,-cos(2*pi*freqs(iter1)*t1/frame_rate),'bo')
        hold on;
        plot(t2,-cos(2*pi*freqs(iter1)*t2/frame_rate),'ro')
        axis([0,round(frame_rate/20) -1 1])
        axis off
        figure;
        s = surf(diff);
        s.EdgeColor = 'none';
        colormap(colorcet('COOLWARM'));
        set(gca,'Ydir','reverse')
        clim([-max_val,max_val])
        view(2)
        axis equal
        axis off
        figure;
        image(im2)
        axis equal
        axis off
    end
end


%% Look at in-phase vs out of phase