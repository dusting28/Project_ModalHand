close all; clc; clear;

%% Intensity Study
disp("--------------Intensity Study--------------")
load("IntensityStudy_ProcessedData.mat")
rm_stats = force_matrix;
plot_lims = [-20, 20];

AT_intensity = stat_tests(rm_stats,freq,conditions,plot_lims);

%% Spatial Study
disp("--------------Spatial Study--------------")
load("SpatialStudy_ProcessedData.mat")
summed_response = squeeze(sum(filled_matrix,2));

red_map = [ones(256,1), linspace(1,0,256)', linspace(1,0,256)'];
blue_map = [linspace(1,0,256)', linspace(1,0,256)', ones(256,1)];

for iter1 = 1:num_stim
    figure;
    plot_num = 5*mod(iter1-1,2)+ceil(iter1/2);
    s = surf(x_mesh,y_mesh,squeeze(summed_response(iter1,:,:)));
    view(2);
    s.EdgeColor = 'none';
    colormap(flipud(gray))
    set(gca,'Ydir','reverse')
    clim([0, repetitions*num_participants]);
    saveas(gcf,strcat("Study1B_Perception_HandPlot_",num2str(freq(ceil(iter1/2))),"Hz_",conditions(2-mod(iter1,2)),".tif"))
end

x_vector = 80:1900;
y_vector = 890;
conversion = 182/(x_vector(end)-x_vector(1));
for iter1 = 1:num_stim
    if mod(iter1,2)
        figure
        plot(x_vector-x_vector(1),squeeze(summed_response(iter1,x_vector,y_vector)),'r');
    else
        plot(x_vector-x_vector(1),squeeze(summed_response(iter1,x_vector,y_vector)),'b');
        xlim([0,1820])
        saveas(gcf,strcat("Study1B_Perception_LinePlot_",num2str(freq(ceil(iter1/2))),"Hz.eps"))
    end
    ylim([0,repetitions*num_participants])
    hold on;
end
hold off;

distance_x(1,1,:) = 1:size(filled_matrix,3);
distance_y(1,1,1,:) = 1:size(filled_matrix,4);
x_weighting = repmat(distance_x,[size(filled_matrix,1),size(filled_matrix,2),1,size(filled_matrix,4)]);
y_weighting = repmat(distance_y,[size(filled_matrix,1),size(filled_matrix,2),size(filled_matrix,3),1]);

center_x = x_vector(1)-(sum(filled_matrix.*x_weighting,[3,4])./sum(filled_matrix,[3,4]))';
center_y = y_vector-(sum(filled_matrix.*y_weighting,[3,4])./sum(filled_matrix,[3,4]))';
percent_filled = (sum(filled_matrix,[3,4])./sum(masking_matrix,"all"))';

rm_stats = zeros(num_participants,num_stim);
for iter1 = 1:num_participants
    idx = (iter1-1)*repetitions;
    %rm_stats(iter1,:) = mean(percent_filled(idx+1:idx+repetitions,:),1);
    rm_stats(iter1,:) = conversion*mean((center_x(idx+1:idx+repetitions,:).^2+center_y(idx+1:idx+repetitions,:).^2).^.5,1);
end
rm_stats(isnan(rm_stats))=0;

plot_lims = [0, 1820*conversion];
AT_spatial = stat_tests(rm_stats,freq,conditions,plot_lims);