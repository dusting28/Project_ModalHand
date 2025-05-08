clc; clear; close all;
addpath("Videos/NaturalTouch/")

imaging = load("ImageData_NaturalTouch.mat");
dot_size = 30;
color_map = colorcet('COOLWARM');
acc_win = 5;
start_idx = [1,1,1,1,50];
start_frame = [1,1,12,7,60];
sig_len = 130;
remove_points = [0,0,2,5,2];
scenario = 5;
DIP_idx = 9;
PIP_idx = 18;
MCP_idx = 32;
select_idx = [5, 14, 25];

included_points = 2:3:size(imaging.tracking_cell{scenario},2);

x_pos = squeeze(imaging.tracking_cell{scenario}(:,included_points,1));
y_pos = squeeze(imaging.tracking_cell{scenario}(:,included_points,2));

figure;
for iter1 = 1:size(imaging.tracking_cell{scenario},2)
    plot(imaging.tracking_cell{scenario}(start_frame(scenario),iter1,1),-imaging.tracking_cell{scenario}(start_frame(scenario),iter1,2),"k.")
    hold on;
end
axis equal

[~,right_iter] = max(x_pos(1,:));
[~,left_iter] = min(x_pos(1,:));
pixel_to_mm = (3*39)/((x_pos(1,left_iter)-x_pos(1,right_iter))^2 + (y_pos(1,left_iter)-y_pos(1,right_iter))^2 )^.5;

amp_sig = zeros(length(included_points),1);
phase_sig = zeros(length(included_points),1);

acc_sig = zeros(sig_len-2*acc_win,length(included_points));
for iter2 = 1:length(included_points)
    acc_sig(:,iter2) = acc(pixel_to_mm*y_pos(start_idx(scenario):start_idx(scenario)+sig_len-1,iter2),acc_win,imaging.frame_rate(scenario));
    [max_val, max_idx] = max(abs(acc_sig(:,iter2)));
    amp_sig(iter2) = max_val;
    phase_sig(iter2) = max_idx;
end

x_pos = 3*(0:39); % in mm
x_up = linspace(x_pos(1),x_pos(end),1000);

%%

colormap =  turbo(length(included_points));

% Time Domain Signals
figure;
for iter2 = 1:length(included_points)
    plot(acc_sig(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

% Frequency Domain Signals
figure;
max_freq = zeros(1,length(included_points));
for iter1 = 1:length(included_points)
    idx = length(included_points)-iter1+1;
    magSpec = abs(fft(acc_sig(:,idx)))/length(acc_sig(:,idx));
    magSpec = magSpec(1:length(magSpec)/2+1);
    freq = (imaging.frame_rate(scenario)/length(acc_sig(:,idx)))*(0:(length(acc_sig(:,idx))/2));
    freq_up = linspace(freq(1),freq(end),1000);
    mag_up = csapi(freq,log10(magSpec),freq_up);
    [~, max_idx] = max(mag_up);
    max_freq(iter1) = freq_up(max_idx);
    if ismember(iter1,select_idx) 
        plot(freq_up,mag_up,"Color",colormap(idx,:))
        hold on;
    end
end
hold off;
xlim([15,400])
ylim([2.8,4.5])

%% Complementary Filters
cutoff_frequency = 100;
N = 100;

lowpass_filter = fir1(N, cutoff_frequency/(imaging.frame_rate(scenario)/2));
highpass_filter = fir1(N, cutoff_frequency/(imaging.frame_rate(scenario)/2), 'high');

low_sig = zeros(size(acc_sig,1),size(acc_sig,2));
high_sig = zeros(size(acc_sig,1),size(acc_sig,2));
for iter1 = 1:size(acc_sig,2)
    low_sig(:,iter1) = filter(lowpass_filter, 1, acc_sig(:,iter1));
    high_sig(:,iter1) = filter(highpass_filter, 1, acc_sig(:,iter1));
end

reconstruct = low_sig+high_sig;

figure;
for iter2 = 1:length(included_points)
    plot(low_sig(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

figure;
for iter2 = 1:length(included_points)
    plot(high_sig(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

figure;
for iter2 = 1:length(included_points)
    plot(reconstruct(:,iter2),"Color",colormap(iter2,:))
    hold on;
end
hold off;

lowAmp = csapi(x_pos,fliplr(movmean(max(abs(low_sig),[],1),3)),x_up);
highAmp = csapi(x_pos,fliplr(movmean(max(abs(high_sig),[],1),3)),x_up);
lowAmp = lowAmp/max(lowAmp);
highAmp = highAmp/max(highAmp);

figure;
plot(x_up, lowAmp,'b');
hold on;
plot(x_up, highAmp,'r');
xline(x_pos(PIP_idx), 'k');
xline(x_pos(DIP_idx), 'k');
xline(x_pos(MCP_idx), 'k');
hold off;
ylim([0,1])

%% Modelling
potts_upper = exp(-x_pos/12)/exp(-x_pos(1)/12);
potts_lower = exp(-x_pos/3)/exp(-x_pos(1)/3);
zhang_upper = exp(-x_pos*.045)/exp(-x_pos(1)*.045);
zhang_lower = exp(-x_pos*.085)/exp(-x_pos(1)*.085);
manfredi_lower = (x_pos(1).^1.35)./(x_pos.^1.35);
manfredi_upper = (x_pos(1).^1.1)./(x_pos.^1.1);

min_tissue = min([potts_lower; zhang_lower]);
max_tissue = max([potts_upper; zhang_upper]);


% amp_sig = max(abs(high_sig),[],1)';
normAmp = flipud(movmean(amp_sig,3))/max(movmean(amp_sig,3));

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
plot(x_pos, normAmp,'k');
hold on;
plot(x_pos, potts_upper, 'r');
plot(x_pos, zhang_upper, 'g');
plot(x_pos, manfredi_upper, 'b');
xline(x_pos(PIP_idx), 'k')
xline(x_pos(DIP_idx), 'k')
xline(x_pos(MCP_idx), 'k')
hold off;

saveas(gcf,"MATLAB_Plots/Fig1_AttenuationPlot","epsc")

figure;
plot(phase_sig);