clc; clear; close all;

% Study Info
participants = ["P03","P04","P05","P06","P07","P08","P09","P10","P11","P12"];
freq = [15, 50, 100, 200, 400];
conditions = ["Fixed","Free"];
repetitions = 5;
num_stim = length(freq)*length(conditions);
num_participants = length(participants);

% PNG Info
pages = num_stim*repetitions;
y_pixels = 2000;
x_pixels = 1500;

% Storage matrices
filled_matrix = zeros(num_stim,repetitions*num_participants,y_pixels,x_pixels);
[x_mesh,y_mesh] = meshgrid(1:x_pixels,1:y_pixels);

% Mask off hand
folder = "C:\Users\Dustin\Documents\ReTouch\Project_Soft_Interface\ModalHand_Study1\ModalHand_Study1_Analysis\Data\SpatialData\";
filename = strcat(folder,"SpatialStudySingle.png");
template = imread(filename);
[ref_y,ref_x] = find(template<225);
ref_x = ref_x+50;
ref_y = ref_y-50;
[~,idx] = min(ref_x);
binary_image = squeeze(template(ref_y(idx)-y_pixels+1:ref_y(idx),...
    ref_x(idx):ref_x(idx)+x_pixels-1,1))<200;
masking_matrix = maskHand(binary_image);

for iter1 = 1:num_participants
    order = load(strcat(folder,participants(iter1),"_orderVectors.mat"));
    for iter2 = 1:pages
        repetition_num = ceil(iter2/num_stim);
        stim_order = order.order_cell{1,repetition_num}(mod((iter2-1),num_stim)+1);

        filename = strcat(folder,"SpatialStudy",participants(iter1),"/Page",num2str(iter2),".png");
        temp_image = imread(filename);

        [ref_y,ref_x] = find(temp_image<225);
        ref_x = ref_x+50;
        ref_y = ref_y-50;
        [~,idx] = min(ref_x);

        red_pixels = squeeze(temp_image(ref_y(idx)-y_pixels+1:ref_y(idx),...
            ref_x(idx):ref_x(idx)+x_pixels-1,3));
        blue_pixels = squeeze(temp_image(ref_y(idx)-y_pixels+1:ref_y(idx),...
            ref_x(idx):ref_x(idx)+x_pixels-1,1));

        filled_pixels = masking_matrix.*(red_pixels< 200 & blue_pixels > 225);

        filled_matrix(stim_order,(iter1-1)*repetitions+repetition_num,:,:) = filled_pixels;
    end
end

save('SpatialStudy_ProcessedData', 'filled_matrix', 'masking_matrix', 'x_mesh', 'y_mesh',...
    'freq', 'conditions','num_participants', 'repetitions', 'num_stim','-v7.3');


