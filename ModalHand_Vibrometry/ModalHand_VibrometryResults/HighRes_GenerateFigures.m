clc; clear; close all;

current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
addpath("Functions\");

highRes = load("HighRes_ProcessedData.mat");

%% Reformat Loaded Data
kernal = 3;
sample_freqs = [15, 50, 100, 200, 400];
include_probe = true;

sample_idx = zeros(1,length(sample_freqs));
for iter1 = 1:length(sample_freqs)
    [~, sample_idx(iter1)] = min(abs(highRes.freq-sample_freqs(iter1)));
end

position = highRes.yCord(1+not(include_probe):3:end);

fixed_admittance = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
free_admittance = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
for iter1 = 1:length(highRes.yCord)-not(include_probe)
    pos_idx = iter1 + not(include_probe);
    fixed_admittance(:,iter1) = highRes.fixed_tf{pos_idx};
    free_admittance(:,iter1) =  highRes.free_tf{pos_idx};
end

%% Surf Plots on Hand

% Admittance
desired_bandwidth = find(and(highRes.freq>=15, highRes.freq<=400));
free_whiteNoise = sum(abs(free_admittance(desired_bandwidth,:)),1)./length(desired_bandwidth);
fixed_whiteNoise = sum(abs(fixed_admittance(desired_bandwidth,:)),1)./length(desired_bandwidth);
disp(mean(20*log10(abs(free_whiteNoise)./abs(fixed_whiteNoise))));
%surfPlot(fixed_whiteNoise,kernal,highRes,[-1,3],turbo,"White Noise Admittance - Fixed",true,include_probe)
%surfPlot(free_whiteNoise,kernal,highRes,[-1,3],turbo,"White Noise Admittance - Free",true,include_probe)
dB_distance = zeros(1,length(sample_freqs));
for iter1 = 1:length(sample_freqs)
    %surfPlot(abs(fixed_admittance(sample_idx(iter1),:)),kernal,highRes,[-1,3],turbo,strcat("Fixed Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"),true,include_probe)
    %surfPlot(abs(free_admittance(sample_idx(iter1),:)),kernal,highRes,[-1,3],turbo,strcat("Free Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"),true,include_probe)
    dB_distance(iter1) = (mean(20*log10(abs(free_admittance(sample_idx(iter1),:))./abs(fixed_admittance(sample_idx(iter1),:)))));
end

disp(dB_distance)

%% Look at Decay Plots
db_measures = [5 10];
magnitude_values = 10.^(-db_measures./20);

db_fixed = zeros(length(db_measures),length(sample_freqs));
db_free = zeros(length(db_measures),length(sample_freqs));
rSquared_lin_free = zeros(1,length(sample_freqs));
rSquared_exp_free = zeros(1,length(sample_freqs));
rSquared_lin_fixed = zeros(1,length(sample_freqs));
rSquared_exp_fixed = zeros(1,length(sample_freqs));

c = jet(length(sample_freqs));

for iter1 = 1:length(sample_freqs)
    % Compress to Single Axis
    normalized_fixed = singleAxis(abs(fixed_admittance(sample_idx(iter1),:)),include_probe);
    normalized_free = singleAxis(abs(free_admittance(sample_idx(iter1),:)),include_probe);

    % Smooth Data
    normalized_fixed = movmean(normalized_fixed,kernal);
    normalized_free = movmean(normalized_free,kernal);

    % Normalize Data
    normalized_fixed = normalized_fixed/normalized_fixed(1);
    normalized_free = normalized_free/normalized_free(1);

    % Linear and Exponential Fits
    exp_fit = fit((position-highRes.yProbe)',normalized_free','exp1');
    exp_fit_free = exp_fit.a*exp((position-highRes.yProbe)*exp_fit.b);
    lin_fit = polyfit((position-highRes.yProbe)',normalized_free',1);
    lin_fit_free = lin_fit(1)*(position-highRes.yProbe) + lin_fit(2);
    exp_fit = fit((position-highRes.yProbe)',normalized_fixed','exp1');
    exp_fit_fixed = exp_fit.a*exp((position-highRes.yProbe)*exp_fit.b);
    lin_fit = polyfit((position-highRes.yProbe)',normalized_fixed',1);
    lin_fit_fixed = lin_fit(1)*(position-highRes.yProbe) + lin_fit(2);

    % Get R-Squared Values from Fits
    rSquared_lin_free(iter1) = rSquared(normalized_free,lin_fit_free);
    rSquared_exp_free(iter1) = rSquared(normalized_free,exp_fit_free);
    rSquared_lin_fixed(iter1) = rSquared(normalized_fixed,lin_fit_fixed);
    rSquared_exp_fixed(iter1) = rSquared(normalized_fixed,exp_fit_fixed);

    % Plot Data (5 Subplots)
    position_up = linspace(position(1),position(end),1000);
    figure
    plot(position_up, csapi(position,normalized_fixed,position_up),'r')
    hold on;
    plot(position_up, csapi(position,normalized_free,position_up),'b')
    xlim([0,highRes.yWrist])
    ylim([0,1.25]);
    title(strcat(num2str(sample_freqs(iter1))," Hz"))
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")
    hold off;

    % finger_decay = normalized_free(position<=highRes.yMCP);
    % ideal_slope = (1/(highRes.yProbe-highRes.yMCP));
    % ideal_linear = ideal_slope*position(position<=highRes.yMCP)+(1-ideal_slope*highRes.yProbe);
    % SStot = sum((finger_decay-mean(finger_decay)).^2);                    % Total Sum-Of-Squares
    % SSres = sum((finger_decay-ideal_linear).^2); 
    % Rsq = 1-SSres/SStot;
    % disp(strcat("Linear Fit:", num2str(Rsq)))
    
    % Residual Sum-Of-Squares
     
    mdl = fitlm(position(position<=highRes.yMCP),normalized_free(position<=highRes.yMCP));
    Rsq = 1-SSres/SStot;
    disp(strcat("Linear Fit:", num2str(mdl.Rsquared.Ordinary)))

    figure(100);
    plot(position_up, csapi(position,normalized_free,position_up))
    xline(highRes.yProbe, 'k')
    xline(63, 'k')
    xlim([0,highRes.yMCP])
    ylim([0,1.25]);
    title(strcat(num2str(sample_freqs(iter1))," Hz"))
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")

end
hold off;

disp(mean(rSquared_lin_free(1:3)))
disp(mean(rSquared_exp_fixed(1:3)))
disp(mean([rSquared_exp_free(4:5),rSquared_exp_fixed(4:5)]))

%% Unwrapped Admittance
unwrappedAdmittance(highRes.freq,highRes,fixed_admittance, kernal, include_probe);
unwrappedAdmittance(highRes.freq,highRes,free_admittance, kernal, include_probe);