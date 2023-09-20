clc; clear; close all;
participants = ["Dustin", "Greg", "Quinten", "William"];

% PDF to PNG
freq = [15, 50, 100, 200, 400];
num_stim = 10;
pages = 5;
y_pixels = 1000;
x_pixels = 600;
anchor_points = [250 280; 250 940; 250 1600; 1700 285; 1700 940; 1700 1605];
colored_pixels = zeros(length(participants),pages*size(anchor_points,1),y_pixels,x_pixels);
summed_response = zeros(num_stim,y_pixels,x_pixels);
[x_mesh,y_mesh] = meshgrid(1:x_pixels,1:y_pixels);
for iter1 = 1:length(participants)
    iter4 = 0;
    pdfFile = strcat("UserStudy1 ",participants(iter1),".pdf");
    images = PDFtoImg(pdfFile);
    order_vector = load(strcat(participants(iter1),"_orderVectors.mat"));
    for iter2 = 1:pages
        for iter3 = 1:size(anchor_points,1)
            stim_order = order_vector.order_cell{1,1+floor(iter4/num_stim)}(mod(iter4,num_stim)+1);
            iter4 = iter4+1;
            
            temp_image = imread(images(iter2));
            
            reference_pixels = squeeze(temp_image(anchor_points(iter3,1):anchor_points(iter3,1)+y_pixels+499,...
                anchor_points(iter3,2):anchor_points(iter3,2)+x_pixels-1,1));
            [ref_y,ref_x] = find(reference_pixels(end-500:end,:)<225);
            ref_x = anchor_points(iter3,2)+ref_x-100;
            ref_y = anchor_points(iter3,1)+ref_y+y_pixels;
            [~,idx] = min(ref_x);

            red_pixels = squeeze(temp_image(ref_y(idx)-y_pixels+1:ref_y(idx),...
                ref_x(idx):ref_x(idx)+x_pixels-1,3));
            blue_pixels = squeeze(temp_image(ref_y(idx)-y_pixels+1:ref_y(idx),...
                ref_x(idx):ref_x(idx)+x_pixels-1,1));

            colored_pixels(iter1,iter4,:,:) = int8(red_pixels< 200 & blue_pixels > 225);
            summed_response(stim_order,:,:) = squeeze(summed_response(stim_order,:,:))...
                + squeeze(colored_pixels(iter1,iter4,:,:));
%             s = surf(x_mesh,y_mesh,red_pixels);
%             view(2);
%             s.EdgeColor = 'none';
%             colormap gray
        end
    end
end


%% Surf Plots
figure;
for iter1 = 1:num_stim
    subplot(2,5,5*mod(iter1,2)+ceil(iter1/2))
    s = surf(x_mesh,y_mesh,squeeze(summed_response(iter1,:,:)));
    view(2);
    s.EdgeColor = 'none';
    colormap gray
    set(gca,'Ydir','reverse')
end
colorbar;

%% Line Plots
for iter1 = 1:num_stim
    figure(2);
    subplot(1,2,mod(iter1-1,2)+1)
    x_vector = 160:840;
    plot(x_vector-x_vector(1),movmean(movmedian(squeeze(summed_response(iter1,x_vector,350)),20),100));
    ylim([0,12])
    hold on;
    figure(3);
    subplot(1,5,ceil(iter1/2))
    x_vector = 160:840;
    if mod(iter1,2)
        plot(x_vector-x_vector(1),movmean(movmedian(squeeze(summed_response(iter1,x_vector,350)),20),100),'r');
    else
        plot(x_vector-x_vector(1),movmean(movmedian(squeeze(summed_response(iter1,x_vector,350)),20),100),'b');
    end
    ylim([0,12])
    hold on;
end
hold off;

figure
plot(freq,squeeze(sum(summed_response(1:2:9,:,:),[2,3])),'o--')
hold on;
plot(freq,squeeze(sum(summed_response(2:2:10,:,:),[2,3])),'o--')
hold off;