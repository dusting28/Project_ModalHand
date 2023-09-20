clc; clear; close all;
addpath("Data\")
highRes = load("HighRes_ProcessedData.mat");

%% Filter
filter_band = [15, 950];
freq_idx = find(and(highRes.freq>=filter_band(1),highRes.freq<=filter_band(2)));
position = highRes.yCord(2:end);
sample_freqs = [15, 50, 100, 200, 400];
sample_idx = zeros(1,length(sample_freqs));
for iter1 = 1:length(sample_freqs)
    [~, sample_idx(iter1)] = min(abs(highRes.freq(freq_idx)-sample_freqs(iter1)));
end

fixed_admittance = zeros(length(freq_idx),length(position));
free_admittance = zeros(length(freq_idx),length(position));

iter0 = 0;
for iter1 = freq_idx
    iter0 = iter0+1;
    for iter2 = 1:length(position)
        fixed_admittance(iter0,iter2) = highRes.fixed_tf{iter2+1}(iter1);
        free_admittance(iter0,iter2) = highRes.free_tf{iter2+1}(iter1);
    end
end

fixed_centroid = zeros(1,length(position));
fixed_resonance = zeros(1,length(position));
fixed_max = zeros(1,length(position));

free_centroid = zeros(1,length(position));
free_resonance = zeros(1,length(position));
free_max = zeros(1,length(position));

movmean_win = 50;
for iter1 = 1:length(position)
    [max_val,max_idx] = max(movmean(abs(fixed_admittance(:,iter1)),movmean_win));
    fixed_centroid(iter1) = sum(abs(fixed_admittance(:,iter1))'.*highRes.freq(freq_idx))./sum(abs(fixed_admittance(:,iter1)));
    fixed_resonance(iter1) = highRes.freq(freq_idx(max_idx));
    fixed_max(iter1) = max_val;

    [max_val,max_idx] = max(movmean(abs(free_admittance(:,iter1)),movmean_win));
    free_centroid(iter1) = sum(abs(free_admittance(:,iter1))'.*highRes.freq(freq_idx))./sum(abs(free_admittance(:,iter1)));
    free_resonance(iter1) = highRes.freq(freq_idx(max_idx));
    free_max(iter1) = max_val;
end

%% Line Plots
% Spectral
linePlot(fixed_resonance,highRes,true,"Fixed Hand - Resonant Frequencies")
linePlot(free_resonance,highRes,true,"Free Hand - Resonant Frequencies")
linePlot(fixed_centroid,highRes,true,"Fixed Hand - Spectral Centroid")
linePlot(free_centroid,highRes,true,"Free Hand - Spectral Centroid")

% Admittance
linePlot(fixed_max,highRes,true,"Fixed Hand - Max Admittance")
linePlot(free_max,highRes,true,"Free Hand - Max Admittance")
free_whiteNoise = abs(sum(free_admittance,1))./(size(free_admittance,1));
fixed_whiteNoise = abs(sum(fixed_admittance,1))./(size(fixed_admittance,1));
linePlot(fixed_whiteNoise,highRes,true,"Fixed Hand - White Noise Admittance")
linePlot(free_whiteNoise,highRes,true,"Free Hand - White Noise Admittance")
for iter1 = 1:length(sample_freqs)
    linePlot(abs(fixed_admittance(sample_idx(iter1),:)),highRes,true,strcat("Fixed Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"))
    linePlot(abs(free_admittance(sample_idx(iter1),:)),highRes,true,strcat("Free Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"))
end

%% Surf Plots on Hand

% Spectral
surfPlot(fixed_centroid,highRes,[75,450],jet,"Centroid - Fixed",true)
surfPlot(free_centroid,highRes,[75,450],jet,"Centroid - Free",true)
surfPlot(fixed_resonance,highRes,[15,450],jet,"Resonance - Fixed",true)
surfPlot(free_resonance,highRes,[15,450],jet,"Resonance - Free",true)

% Admittance
surfPlot(fixed_whiteNoise,highRes,[1,1000],flipud(gray),"White Noise Admittance - Fixed",true)
surfPlot(free_whiteNoise,highRes,[1,1000],flipud(gray),"White Noise Admittance - Free",true)
for iter1 = 1:length(sample_freqs)
    surfPlot(abs(fixed_admittance(sample_idx(iter1),:)),highRes,[2,1000],flipud(gray),strcat("Fixed Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"),true)
    surfPlot(abs(free_admittance(sample_idx(iter1),:)),highRes,[2,1000],flipud(gray),strcat("Free Hand - ", num2str(sample_freqs(iter1))," Hz Admittance"),true)
end


%% Frequency Response

DP_idx = find(and(highRes.yCord > 1, highRes.yCord <= highRes.yDIP));
MP_idx = find(and(highRes.yCord > highRes.yDIP, highRes.yCord <= highRes.yPIP));
PP_idx = find(and(highRes.yCord > highRes.yPIP, highRes.yCord <= highRes.yMCP));
M_idx = find(and(highRes.yCord > highRes.yMCP, highRes.yCord <= highRes.yWrist));

figure
subplot(2,1,1)
semilogx(highRes.freq,abs(mean(fixed_admittance(:,1),2)))
hold on;
semilogx(highRes.freq,abs(mean(fixed_admittance(:,DP_idx),2)))
hold on;
semilogx(highRes.freq,abs(mean(fixed_admittance(:,MP_idx),2)))
hold on;
semilogx(highRes.freq,abs(mean(fixed_admittance(:,PP_idx),2)))
hold on;
semilogx(highRes.freq,abs(mean(fixed_admittance(:,M_idx),2)))
hold off;
legend("Contact", "DP", "MP", "PP", "M");
xlim(filter_band)
ylabel("Admittance (mm/Ns)")
xlabel("Frequency (Hz)")
title('Fixed Hand')

subplot(2,1,2)
semilogx(highRes.freq,abs(mean(free_admittance(:,1),2)))
hold on;
semilogx(highRes.freq,abs(mean(free_admittance(:,DP_idx),2)))
hold on;
semilogx(highRes.freq,abs(mean(free_admittance(:,MP_idx),2)))
hold on;
semilogx(highRes.freq,abs(mean(free_admittance(:,PP_idx),2)))
hold on;
semilogx(highRes.freq,abs(mean(free_admittance(:,M_idx),2)))
hold off;
legend("Contact", "DP", "MP", "PP", "M");
xlim(filter_band)
ylabel("Admittance (mm/Ns)")
xlabel("Frequency (Hz)")
title('Fixed Hand')

sgtitle('Frequency Responses')

figure
plot(highRes.freq,20*log10(squeeze(abs(fixed_admittance(freq_idx(3),1)))./squeeze(abs(fixed_admittance(:,1)))),'r');
hold on;
plot(highRes.freq,20*log10(squeeze(abs(fixed_admittance(freq_idx(3),1)))./squeeze(abs(free_admittance(:,1)))),'b');

%% Look at Decay Plots
decay_freq = single_freq;

db_measures = [5 10];
magnitude_values = 10.^(-db_measures./20);

db_fixed = zeros(length(db_measures),length(decay_freq));
db_free = zeros(length(db_measures),length(decay_freq));

c = jet(length(decay_freq));
for iter1 = 1:length(decay_freq)
    [~,idx] = min(abs(highRes.freq - decay_freq(iter1)));
    normalized_fixed = [abs(fixed_admittance(idx,1)), mean([abs(fixed_admittance(idx,2:3:end));...
        abs(fixed_admittance(idx,3:3:end)); abs(fixed_admittance(idx,4:3:end))],1)];
    normalized_free = [abs(free_admittance(idx,1)), mean([abs(free_admittance(idx,2:3:end));...
        abs(free_admittance(idx,3:3:end)); abs(free_admittance(idx,4:3:end))],1)];
    normalized_fixed = normalized_fixed./normalized_fixed(1);
    normalized_free = normalized_free./normalized_free(1);
    for iter2 = 1:length(db_measures)
        y = [highRes.yCord(1), highRes.yCord(2:3:end)];
        db_idx = find(normalized_fixed<magnitude_values(iter2));
        db_fixed(iter2,iter1) = y(db_idx(1));
        db_idx = find(normalized_free<magnitude_values(iter2));
        db_free(iter2,iter1) = y(db_idx(1));
    end
    figure(100)
    subplot(2,1,1)
    plot([highRes.yCord(1), highRes.yCord(2:3:end)], movmean(normalized_fixed,1),'color',c(iter1,:))
    yline(magnitude_values)
    xlim([0,highRes.yWrist])
    ylim([0,1.5]);
    title("Fixed Hand")
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")
    hold on;
    subplot(2,1,2)
    plot([highRes.yCord(1), highRes.yCord(2:3:end)], movmean(normalized_free,1),'color',c(iter1,:))
    yline(magnitude_values)
    xlim([0,highRes.yWrist])
    ylim([0,1.5]);
    title("Free Hand")
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")
    hold on;

    figure(101)
    subplot(1,length(decay_freq),iter1)
    plot([highRes.yCord(1), highRes.yCord(2:3:end)], movmean(normalized_fixed,1),'r')
    hold on;
    plot([highRes.yCord(1), highRes.yCord(2:3:end)], movmean(normalized_free,1),'b')
    xlim([0,highRes.yWrist])
    ylim([0,1.5]);
    title(strcat(num2str(decay_freq(iter1))," Hz"))
    xlabel("Distance from Probe (mm)")
    ylabel("Normalized Admittance")
    hold off;
end
hold off;

figure;
for iter1 = 1:length(db_measures)
    subplot(1,length(db_measures),iter1)
    semilogx(decay_freq,db_fixed(iter1,:),'r.--');
    hold on;
    semilogx(decay_freq,db_free(iter1,:),'b.--');
    % ylim([0,highRes.yWrist])
    ylim([0,200])
    xlabel("Frequency (Hz)")
    ylabel("Distance from Probe (mm)")
    title(strcat(num2str(db_measures(iter1))," dB Dropoff"))
    hold off;
end

%% Unwrapped Admittance
[xMesh,yMesh] = meshgrid(highRes.freq(~filter_idx),linspace(highRes.yCord(2),highRes.yCord(end),490));

figure;
tiledlayout(1,2);
nexttile
zMesh = griddata(highRes.freq(~filter_idx),highRes.yCord(3:3:end),abs(fixed_admittance(~filter_idx,3:3:end))',xMesh,yMesh);
s = surf(xMesh,yMesh,zMesh);
s.EdgeColor = 'none';
colormap(flipud(gray));
set(gca,'Ydir','reverse')
set(gca,'XScale','log')
set(gca,'ColorScale','log')
view(2)
clim([.1,1000])
title("Admittance - Fixed")
ylabel("Distance from Fingertip (mm)")
xlabel("Frequency (Hz)")

nexttile
zMesh = griddata(highRes.freq(~filter_idx),highRes.yCord(3:3:end),abs(free_admittance(~filter_idx,3:3:end))',xMesh,yMesh);
s = surf(xMesh,yMesh,zMesh);
s.EdgeColor = 'none';
colormap(flipud(gray));
set(gca,'Ydir','reverse')
set(gca,'XScale','log')
set(gca,'ColorScale','log')
view(2)
clim([.1,1000])
title("Admittance - Free")
ylabel("Distance from Fingertip (mm)")
xlabel("Frequency (Hz)")