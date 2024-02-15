clc; clear; close all;
addpath("Videos/NaturalTouch/")

imaging = load("ImageData_NaturalTouch.mat");
dot_size = 30;
color_map = colorcet('COOLWARM');
acc_win = 5;
start_idx = [1,1,1,1,50];
sig_len = 100;
remove_points = [0,0,2,5,2];
scenario = 4;
cutoff = [50, 150];

% file_name = strcat(imaging.scenarios(scenario),"_",num2str(imaging.frame_rate(scenario)),"FPS.tif");
% info = imfinfo(file_name);
% width = info(1).Width;
% height = info(1).Height;
% num_frames = size(info,1);
% rawframes = zeros(width,height,3,num_frames);
% for iter2 = 1:num_frames
%     rawframes(:,:,:,iter2) = permute(rescale(imread(file_name,iter2)),[2 1 3]);
% end

% excluded_points = size(imaging.tracking_cell{scenario},2)-3*(remove_points(scenario)-1):3:size(imaging.tracking_cell{scenario},2);
% included_points = 1:size(imaging.tracking_cell{scenario},2);
% included_points(excluded_points) = [];

included_points = 1:3:size(imaging.tracking_cell{scenario},2);

x_pos = squeeze(imaging.tracking_cell{scenario}(:,included_points,1));
y_pos = squeeze(imaging.tracking_cell{scenario}(:,included_points,2));
acc_sig = zeros(sig_len-2*acc_win,length(included_points));
acc_low = acc_sig;
acc_high = acc_sig;

lowpass_filt = designfilt('lowpassfir', 'FilterOrder', round(size(acc_sig,1)/3)-1, ...
         'PassbandFrequency', 50, 'StopbandFrequency', 100,...
         'SampleRate', imaging.frame_rate(scenario));
highpass_filt = designfilt('highpassfir', 'FilterOrder', round(size(acc_sig,1)/3)-1, ...
         'PassbandFrequency', 100, 'StopbandFrequency', 50,...
         'SampleRate', imaging.frame_rate(scenario));

amp_low = zeros(length(included_points),1);
phase_low = zeros(length(included_points),1);
amp_high = zeros(length(included_points),1);
phase_high = zeros(length(included_points),1);

for iter2 = 1:length(included_points)
    acc_sig(:,iter2) = acc(y_pos(start_idx(scenario):start_idx(scenario)+sig_len-1,iter2),acc_win,imaging.frame_rate(scenario));
    acc_low(:,iter2) = filtfilt(lowpass_filt,acc_sig(:,iter2));
    acc_high(:,iter2) = filtfilt(highpass_filt,acc_sig(:,iter2));
    [max_val, max_idx] = max(abs(acc_low(:,iter2)));
    amp_low(iter2) = max_val;
    phase_low(iter2) = max_idx;
    [max_val, max_idx] = max(abs(acc_high(:,iter2)));
    amp_high(iter2) = max_val;
    phase_high(iter2) = max_idx;
end

colormap =  turbo(length(included_points));

figure;
for iter2 = 1:length(included_points)
    plot(acc_sig(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

figure;
for iter2 = 1:length(included_points)
    plot(acc_low(:,iter2)+acc_high(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

figure;
for iter2 = 1:length(included_points)
    plot(acc_low(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

figure;
for iter2 = 1:length(included_points)
    plot(acc_high(:,iter2),"Color",colormap(iter2,:))
    hold on;
end

% Modelling
x_model = 3*(1:40); % in mm
manfredi_upper = (x_model(1)^1.1)./(x_model.^1.1);
manfredi_lower = (x_model(1)^1.4)./(x_model.^1.4);
potts_upper = exp(-x_model/12)/exp(-x_model(1)/12);
potts_lower = exp(-x_model/3)/exp(-x_model(1)/3);
zhang_upper = exp(-x_model*.045)/exp(-x_model(1)*.045);
zhang_lower = exp(-x_model*.085)/exp(-x_model(1)*.085);

x_model = x_model-3;

min_tissue = min([manfredi_lower; potts_lower; zhang_lower]);
max_tissue = max([manfredi_upper; potts_upper; zhang_upper]);

normAmp_low = flipud(amp_low)/max(amp_low);
normAmp_high = flipud(amp_high)/max(amp_high);

linearCoefficients = polyfit(x_model, log(normAmp_low), 1);          % Coefficients
yfit_low = polyval(linearCoefficients, x_model);          % Estimated  Regression Line
SStot = sum((log(normAmp_low)'-mean(log(normAmp_low))).^2);                    % Total Sum-Of-Squares
SSres = sum((log(normAmp_low)'-yfit_low).^2);                       % Residual Sum-Of-Squares
Rsq = 1-SSres/SStot;
disp(Rsq);
disp(linearCoefficients(1));

linearCoefficients = polyfit(x_model, log(normAmp_high), 1);          % Coefficients
yfit_high = polyval(linearCoefficients, x_model);          % Estimated  Regression Line
SStot = sum((log(normAmp_high)'-mean(log(normAmp_high))).^2);                    % Total Sum-Of-Squares
SSres = sum((log(normAmp_high)'-yfit_high).^2);                       % Residual Sum-Of-Squares
Rsq = 1-SSres/SStot; 
disp(Rsq);
disp(linearCoefficients(1));

figure;
plot(x_model, normAmp_low,'bo');
hold on;
plot(x_model, exp(yfit_low),'b');
hold on;
plot(x_model, normAmp_high, 'ro');
hold on;
plot(x_model, exp(yfit_high), 'r');
hold on;
plot(x_model, min_tissue, 'k');
hold on;
plot(x_model, max_tissue, 'k');
hold off;

figure;
plot(phase_low);
hold on;
plot(phase_high);
hold off;