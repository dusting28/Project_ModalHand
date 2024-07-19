clc; clear; close all;
addpath("Videos/NaturalTouch/")

imaging = load("ImageData_EngineeredTouch.mat");
dot_size = 30;
color_map = colorcet('COOLWARM');
acc_win = 5;
start_idx = [1,220];
sig_len = 100;
scenario = 1;
MCP_idx = 32;

included_points = 2:3:size(imaging.tracking_cell{scenario},2);

y_pos = squeeze(imaging.tracking_cell{scenario}(:,included_points,2));

colormap =  turbo(length(included_points));

figure;
for iter1 = 1:length(included_points)
    plot(y_pos(:,iter1),"Color",colormap(iter1,:))
    hold on;
end
hold off;

% Fit cos to data at each location on finger
cut_time = (0:imaging.frame_rate/imaging.freqs(scenario)-1)/imaging.frame_rate;
phase_sig = zeros(length(included_points),1);
amp_sig = zeros(length(included_points),1);
for iter1 = 1:length(included_points)
    single_sine = y_pos(start_idx(scenario):start_idx(scenario)...
        +imaging.frame_rate/imaging.freqs(scenario)-1,iter1)';
    single_sine = single_sine-mean(single_sine);
    [amp_est ,shift_est] = max(single_sine);
    if shift_est > length(single_sine)/2
        shift_est = shift_est - imaging.frame_rate/imaging.freqs(scenario);
    end
    shift_est = shift_est/imaging.frame_rate;
    % function to fit
    fit = @(b,t)  abs(b(1))*cos(2*pi*imaging.freqs(scenario)*(t - b(2))) + b(3);
    fcn = @(b) sum((fit(b,cut_time) - single_sine).^2);
    % call this to fit
    fitted_params = fminsearch(fcn, [amp_est; shift_est; 0]);  
    amp_sig(iter1) = abs(fitted_params(1));
    phase_sig(iter1) = fitted_params(2);
    hold on;
end

% Modelling
x_pos = 3*(1:40); % in mm
potts_upper = exp(-x_pos/12)/exp(-x_pos(1)/12);
potts_lower = exp(-x_pos/3)/exp(-x_pos(1)/3);
zhang_upper = exp(-x_pos*.045)/exp(-x_pos(1)*.045);
zhang_lower = exp(-x_pos*.085)/exp(-x_pos(1)*.085);

x_pos = x_pos-3;

min_tissue = min([potts_lower; zhang_lower]);
max_tissue = max([potts_upper; zhang_upper]);

normAmp = movmean(amp_sig,3)/max(movmean(amp_sig,3));

linearCoefficients = polyfit(x_pos, normAmp, 1);          % Coefficients
yfit = polyval(linearCoefficients, x_pos);      % Estimated  Regression Line
%yfit = (x_pos(MCP_idx)-x_pos)/x_pos(MCP_idx);
%yfit(yfit<0) = 0;
SStot = sum((normAmp'-mean(normAmp)).^2);                    % Total Sum-Of-Squares
SSres = sum((normAmp'-yfit).^2);                       % Residual Sum-Of-Squares
Rsq = 1-SSres/SStot;
disp(strcat("R-squared linear: ", num2str(Rsq)));
disp(strcat("Distance from zero-cross to MCP: ",num2str(-linearCoefficients(2)/linearCoefficients(1)-x_pos(MCP_idx))," mm"))

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
disp(strcat("R-squared exponential: ", num2str(Rsq)));
disp(strcat("Decay rate: ", num2str(linearCoefficients(1))));

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
plot(flipud(phase_sig));