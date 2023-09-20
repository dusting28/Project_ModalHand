clc; clear; close all;

current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
addpath("Functions\");

highRes = load("HighRes_ProcessedData.mat");

%% Filter
kernal = 3;
filter_band = [15, 400];
freq_idx = find(and(highRes.freq>=filter_band(1),highRes.freq<=filter_band(2)));
sample_freqs = [15, 50, 100, 200, 400];
include_probe = false;

sample_idx = zeros(1,length(sample_freqs));
for iter1 = 1:length(sample_freqs)
    [~, sample_idx(iter1)] = min(abs(highRes.freq(freq_idx)-sample_freqs(iter1)));
end

if include_probe
    position = highRes.yCord(1:end);
else
    position = highRes.yCord(2:end);
end

fixed_admittance = zeros(length(freq_idx),length(position));
free_admittance = zeros(length(freq_idx),length(position));

iter0 = 0;
for iter1 = freq_idx
    iter0 = iter0+1;
    for iter2 = 1:length(position)
        fixed_admittance(iter0,iter2) = highRes.fixed_tf{iter2+not(include_probe)}(iter1);
        free_admittance(iter0,iter2) = highRes.free_tf{iter2+not(include_probe)}(iter1);
    end
end

fixed_centroid = zeros(1,length(position));
fixed_resonance = zeros(1,length(position));
fixed_max = zeros(1,length(position));

free_centroid = zeros(1,length(position));
free_resonance = zeros(1,length(position));
free_max = zeros(1,length(position));

movmean_win = 1;
for iter1 = 1:length(position)
    [max_val,max_idx] = max(movmedian(abs(fixed_admittance(:,iter1)),movmean_win));
    fixed_centroid(iter1) = sum(abs(fixed_admittance(:,iter1))'.*highRes.freq(freq_idx))./sum(abs(fixed_admittance(:,iter1)));
    fixed_resonance(iter1) = highRes.freq(freq_idx(max_idx));
    fixed_max(iter1) = max_val;

    [max_val,max_idx] = max(movmedian(abs(free_admittance(:,iter1)),movmean_win));
    free_centroid(iter1) = sum(abs(free_admittance(:,iter1))'.*highRes.freq(freq_idx))./sum(abs(free_admittance(:,iter1)));
    free_resonance(iter1) = highRes.freq(freq_idx(max_idx));
    free_max(iter1) = max_val;
end

free_whiteNoise = sum(abs(free_admittance),1)./(size(free_admittance,1));
fixed_whiteNoise = sum(abs(fixed_admittance),1)./(size(fixed_admittance,1));

%% Line Plots
% % Spectral
% linePlot(fixed_resonance,highRes,true,"Fixed Hand - Resonant Frequencies",include_probe)
% linePlot(free_resonance,highRes,true,"Free Hand - Resonant Frequencies",include_probe)
% linePlot(fixed_centroid,highRes,true,"Fixed Hand - Spectral Centroid",include_probe)
% linePlot(free_centroid,highRes,true,"Free Hand - Spectral Centroid",include_probe)
% 
% % Admittance
% linePlot(fixed_max,highRes,true,"Fixed Hand - Max Admittance",include_probe)
% linePlot(free_max,highRes,true,"Free Hand - Max Admittance",include_probe)
% linePlot(fixed_whiteNoise,highRes,true,"Fixed Hand - White Noise Admittance",include_probe)
% linePlot(free_whiteNoise,highRes,true,"Free Hand - White Noise Admittance",include_probe)
% for iter1 = 1:length(sample_freqs)
%     linePlot(abs(fixed_admittance(sample_idx(iter1),:)),highRes,true,strcat("Fixed Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"),include_probe)
%     linePlot(abs(free_admittance(sample_idx(iter1),:)),highRes,true,strcat("Free Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"),include_probe)
% end

%% Surf Plots on Hand
% Spectral
surfPlot(fixed_centroid,kernal,highRes,[15,400],pink,"Centroid - Fixed",false,include_probe)
surfPlot(free_centroid,kernal,highRes,[15,400],pink,"Centroid - Free",false,include_probe)
% surfPlot(fixed_resonance,highRes,[15,400],pink,"Resonance - Fixed",false,include_probe)
% surfPlot(free_resonance,highRes,[15,400],pink,"Resonance - Free",false,include_probe)

% Admittance
surfPlot(fixed_whiteNoise,kernal,highRes,[0.1,10^3],turbo,"White Noise Admittance - Fixed",true,include_probe)
surfPlot(free_whiteNoise,kernal,highRes,[0.1,10^3],turbo,"White Noise Admittance - Free",true,include_probe)
for iter1 = 1:length(sample_freqs)
    surfPlot(abs(fixed_admittance(sample_idx(iter1),:)),kernal,highRes,[0.1,10^3],turbo,strcat("Fixed Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"),true,include_probe)
    surfPlot(abs(free_admittance(sample_idx(iter1),:)),kernal,highRes,[0.1,10^3],turbo,strcat("Free Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"),true,include_probe)
    disp(mean(20*log10(abs(free_admittance(sample_idx(iter1),:))./abs(fixed_admittance(sample_idx(iter1),:)))));
end

%% Frequency Response

if include_probe
    DP_idx = find(and(highRes.yCord > 1, highRes.yCord <= highRes.yDIP));
else
    DP_idx = find(and(highRes.yCord > highRes.yProbe, highRes.yCord <= highRes.yDIP));
end
MP_idx = find(and(highRes.yCord > highRes.yDIP, highRes.yCord <= highRes.yPIP));
PP_idx = find(and(highRes.yCord > highRes.yPIP, highRes.yCord <= highRes.yMCP));
M_idx = find(and(highRes.yCord > highRes.yMCP, highRes.yCord <= highRes.yWrist));

figure
subplot(2,1,1)
if include_probe
    loglog(highRes.freq(freq_idx),abs(fixed_admittance(:,1)),'k');
    hold on;
end
loglog(highRes.freq(freq_idx),abs(mean(fixed_admittance(:,DP_idx-not(include_probe)),2)))
hold on;
loglog(highRes.freq(freq_idx),abs(mean(fixed_admittance(:,MP_idx-not(include_probe)),2)))
hold on;
loglog(highRes.freq(freq_idx),abs(mean(fixed_admittance(:,PP_idx-not(include_probe)),2)))
hold on;
loglog(highRes.freq(freq_idx),abs(mean(fixed_admittance(:,M_idx-not(include_probe)),2)))
hold off;
xlim([15, 400])
ylim([10^-1, 10^3])
ylabel("Admittance (mm/Ns)")
xlabel("Frequency (Hz)")
title('Fixed Hand')
if include_probe
    legend("Contact", "DP", "MP", "PP", "M");
else
    legend("DP", "MP", "PP", "M");
end

subplot(2,1,2)
if include_probe
    loglog(highRes.freq(freq_idx),abs(mean(free_admittance(:,1),2)))
    hold on;
end
loglog(highRes.freq(freq_idx),abs(mean(free_admittance(:,DP_idx-not(include_probe)),2)))
hold on;
loglog(highRes.freq(freq_idx),abs(mean(free_admittance(:,MP_idx-not(include_probe)),2)))
hold on;
loglog(highRes.freq(freq_idx),abs(mean(free_admittance(:,PP_idx-not(include_probe)),2)))
hold on;
loglog(highRes.freq(freq_idx),abs(mean(free_admittance(:,M_idx-not(include_probe)),2)))
hold off;
xlim([15, 400])
ylim([10^-1, 10^3])
ylabel("Admittance (mm/Ns)")
xlabel("Frequency (Hz)")
title('Fixed Hand')
if include_probe
    legend("Contact", "DP", "MP", "PP", "M");
else
    legend("DP", "MP", "PP", "M");
end

sgtitle('Frequency Responses')

%% Look at Decay Plots
db_measures = [5 10];
magnitude_values = 10.^(-db_measures./20);

db_fixed = zeros(length(db_measures),length(sample_freqs));
db_free = zeros(length(db_measures),length(sample_freqs));

c = jet(length(sample_freqs));
for iter1 = 1:length(sample_freqs)
    % Compress to Single Axis
    normalized_fixed = singleAxis(fixed_admittance(sample_idx(iter1),:),include_probe);
    normalized_free = singleAxis(free_admittance(sample_idx(iter1),:),include_probe);

    % Smooth Data
    normalized_fixed = movmean(normalized_fixed,kernal);
    normalized_free = movmean(normalized_free,kernal);

    % Normalize Data
    normalized_fixed = normalized_fixed/normalized_fixed(1);
    normalized_free = normalized_free/normalized_free(1);

    % Position Axis
    y = position(1:3:end);

    % Plot Data (2 Subplots)
    figure(100)
    subplot(2,1,1)
    plot(y, movmean(normalized_fixed,1),'color',c(iter1,:))
    yline(magnitude_values)
    xlim([0,highRes.yWrist])
    ylim([0,1.5]);
    title("Fixed Hand")
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")
    hold on;
    subplot(2,1,2)
    plot(y, movmean(normalized_free,1),'color',c(iter1,:))
    yline(magnitude_values)
    xlim([0,highRes.yWrist])
    ylim([0,1.5]);
    title("Free Hand")
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")
    hold on;

    % Plot Data (5 Subplots)
    figure(101)
    subplot(1,length(sample_freqs),iter1)
    plot(y, movmean(normalized_fixed,1),'r')
    hold on;
    plot(y, movmean(normalized_free,1),'b')
    xlim([0,highRes.yWrist])
    ylim([0,1.25]);
    title(strcat(num2str(sample_freqs(iter1))," Hz"))
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")
    hold off;

    % dB Drop-Off Calculations
    for iter2 = 1:length(db_measures)      
        db_idx = find(normalized_fixed<magnitude_values(iter2));
        db_fixed(iter2,iter1) = y(db_idx(1));
        db_idx = find(normalized_free<magnitude_values(iter2));
        db_free(iter2,iter1) = y(db_idx(1));
    end

end
hold off;

figure;
for iter1 = 1:length(db_measures)
    subplot(1,length(db_measures),iter1)
    semilogx(sample_freqs,db_fixed(iter1,:),'r.--');
    hold on;
    semilogx(sample_freqs,db_free(iter1,:),'b.--');
    ylim([0,highRes.yWrist])
    xlabel("Frequency (Hz)")
    ylabel("Distance from Probe (mm)")
    title(strcat(num2str(db_measures(iter1))," dB Dropoff"))
    hold off;
end

%% Unwrapped Admittance
unwrappedAdmittance(highRes.freq(freq_idx),highRes,fixed_admittance, kernal, include_probe);
unwrappedAdmittance(highRes.freq(freq_idx),highRes,free_admittance, kernal, include_probe);