clc; clear; close all;
addpath("Videos/NaturalTouch/")

imaging = load("ImageData_NaturalTouch.mat");
dot_size = 30;
color_map = colorcet('COOLWARM');
acc_win = 5;
start_idx = [1,1,1,1,50];
sig_len = 100;
remove_points = [0,0,2,5,2];
scenario = 5;
MCP_idx = 32;

included_points = 1:3:size(imaging.tracking_cell{scenario},2);

y_pos = squeeze(imaging.tracking_cell{scenario}(:,included_points,2));
acc_sig = zeros(sig_len-2*acc_win,length(included_points));

amp_sig = zeros(length(included_points),1);
phase_sig = zeros(length(included_points),1);

for iter2 = 1:length(included_points)
    acc_sig(:,iter2) = acc(y_pos(start_idx(scenario):start_idx(scenario)+sig_len-1,iter2),acc_win,imaging.frame_rate(scenario));
    [max_val, max_idx] = max(abs(acc_sig(:,iter2)));
    amp_sig(iter2) = max_val;
    phase_sig(iter2) = max_idx;
end

colormap =  turbo(length(included_points));

figure;
for iter2 = 1:length(included_points)
    plot(acc_sig(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

% Modelling
x_pos = 3*(1:40); % in mm
potts_upper = exp(-x_pos/12)/exp(-x_pos(1)/12);
potts_lower = exp(-x_pos/3)/exp(-x_pos(1)/3);
zhang_upper = exp(-x_pos*.045)/exp(-x_pos(1)*.045);
zhang_lower = exp(-x_pos*.085)/exp(-x_pos(1)*.085);

x_pos = x_pos-3;

min_tissue = min([potts_lower; zhang_lower]);
max_tissue = max([potts_upper; zhang_upper]);

normAmp = flipud(movmean(amp_sig,3))/max(movmean(amp_sig,3));

linearCoefficients = polyfit(x_pos, normAmp, 1);          % Coefficients
yfit = polyval(linearCoefficients, x_pos);      % Estimated  Regression Line
%yfit = (x_pos(MCP_idx)-x_pos)/x_pos(MCP_idx);
%yfit(yfit<0) = 0;
SStot = sum((normAmp'-mean(normAmp)).^2);                    % Total Sum-Of-Squares
SSres = sum((normAmp'-yfit).^2);                       % Residual Sum-Of-Squares
Rsq = 1-SSres/SStot;
disp(Rsq);
disp(-linearCoefficients(2)/linearCoefficients(1)-x_pos(MCP_idx))

figure;
plot(x_pos, normAmp,'bo');
hold on;
plot(x_pos, yfit,'b');
hold off;

linearCoefficients = polyfit(x_pos, log(normAmp), 1);          % Coefficients
yfit = polyval(linearCoefficients, x_pos);          % Estimated  Regression Line
SStot = sum((log(normAmp)'-mean(log(normAmp))).^2);                    % Total Sum-Of-Squares
SSres = sum((log(normAmp)'-yfit).^2);                       % Residual Sum-Of-Squares
Rsq = 1-SSres/SStot;
disp(Rsq);
disp(linearCoefficients(1));

figure;
plot(x_pos, normAmp,'bo');
hold on;
plot(x_pos, exp(yfit),'b');
hold off;

figure;
plot(x_pos, normAmp,'b');
hold on;
plot(x_pos, min_tissue, 'k');
hold on;
plot(x_pos, max_tissue, 'k');
hold off;

figure;
plot(phase_sig);