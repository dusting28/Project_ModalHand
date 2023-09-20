clc; clear; close all;

freq = 10.^(1:.001:3);
ln_freq = 10:1:1000; %exp(2.3026:.005:6.9078);
ln_freq_idx = zeros(1,length(ln_freq));

for iter1 = 1: length(ln_freq_idx)
    [~, ln_freq_idx(iter1)] = min(abs(freq-ln_freq(iter1)));
end

load("highRes_STFTvel.mat")
load("highRes_STFTforce.mat")

probe_mass = 2.5;%;2.5; % g
probe_diameter = 15; % mm

free_inertial_force = (10^-6)*(probe_mass)*loaded_vel{3}.*freq*2*pi;
fixed_inertial_force = (10^-6)*(probe_mass)*loaded_vel{4}.*freq*2*pi;

free_probe_impedance = squeeze(loaded_vel{3}./(loaded_force{3}-free_inertial_force));
% figure;
% plot(freq,squeeze(loaded_force{3}))
% hold on;
% plot(freq,free_inertial_force)
% figure;
% plot(freq,squeeze(impedance));
% 

fixed_probe_impedance = squeeze(loaded_vel{4}./(loaded_force{4}-fixed_inertial_force));
% figure;
% plot(freq,squeeze(loaded_force{4}))
% hold on;
% plot(freq,fixed_inertial_force)
% figure;
% plot(freq,squeeze(impedance));

grid_spacing = 2.2;
probe_spacing = linspace(0,probe_diameter,probe_diameter);
free_spacing = linspace(18,175,size(loaded_vel{1},1)/3);
fixed_spacing = linspace(18,175,size(loaded_vel{2},1)/3);
DIP = 25;
PIP = 51;
MCP = 104;
Wrist = 182;

single_freq = 15;
[~,idx_singleFreq] = min(abs(freq-single_freq));

[resonance_amp, freq_idx] = max(free_probe_impedance);

free_probe_resonance = freq(freq_idx)*ones(1,length(probe_spacing));
free_probe_peakAmp = resonance_amp*ones(1,length(probe_spacing));
free_probe_energy = mean(free_probe_impedance(ln_freq_idx))*ones(1,length(probe_spacing));
free_probe_singleFreq = free_probe_impedance'*ones(1,length(probe_spacing));

[resonance_amp, freq_idx] = max(fixed_probe_impedance);

fixed_probe_resonance = freq(freq_idx)*ones(1,length(probe_spacing));
fixed_probe_peakAmp = resonance_amp*ones(1,length(probe_spacing));
fixed_probe_energy = mean(fixed_probe_impedance(ln_freq_idx))*ones(1,length(probe_spacing));
fixed_probe_singleFreq = fixed_probe_impedance'*ones(1,length(probe_spacing));

free_resonance = zeros(1,size(loaded_vel{1},1));
free_peakAmp = zeros(1,size(loaded_vel{1},1));
free_energy = zeros(1,size(loaded_vel{1},1));
free_singleFreq = zeros(length(freq),size(loaded_vel{1},1));

fixed_resonance = zeros(1,size(loaded_vel{2},1));
fixed_peakAmp = zeros(1,size(loaded_vel{2},1));
fixed_energy = zeros(1,size(loaded_vel{2},1));
fixed_singleFreq = zeros(length(freq),size(loaded_vel{2},1));

for iter1 = 1:size(loaded_vel{1},1)
    impedance = squeeze(loaded_vel{1}(iter1,:)./(loaded_force{1}(iter1,:)-free_inertial_force));
    free_energy(iter1) = mean(impedance(ln_freq_idx));
     w = gausswin(1, 1);
     w = w/sum(w);
    [free_peakAmp(iter1), freq_idx] = max(filter(w, 1, impedance));
    free_resonance(iter1) = freq(freq_idx);
    free_singleFreq(:,iter1) = impedance;
%     figure;
%     plot(freq,squeeze(loaded_force{1}(iter1,:)))
%     hold on;
%     plot(freq,free_inertial_force)
%     figure;
%     plot(freq,squeeze(impedance));
end

for iter1 = 1:size(loaded_vel{2},1)
    impedance = squeeze(loaded_vel{2}(iter1,:)./(loaded_force{2}(iter1,:)-fixed_inertial_force));
    fixed_energy(iter1) = mean(impedance(ln_freq_idx));
    w = gausswin(1, 1);
     w = w/sum(w);
    [fixed_peakAmp(iter1), freq_idx] = max(filter(w, 1, impedance));
    fixed_resonance(iter1) = freq(freq_idx);
    fixed_singleFreq(:,iter1) = impedance;
%     figure;
%     plot(freq,squeeze(loaded_force{2}(iter1,:)))
%     hold on;
%     plot(freq,fixed_inertial_force)
%     figure;
%     plot(freq,squeeze(impedance));
end

figure
plot([probe_spacing, free_spacing], [free_probe_resonance, free_resonance(1:3:end)])
hold on;
plot([probe_spacing, free_spacing], [free_probe_resonance, free_resonance(2:3:end)])
hold on;
plot([probe_spacing, free_spacing], [free_probe_resonance, free_resonance(3:3:end)])
xline(DIP, '--r');
xline(PIP, '--g');
xline(MCP, '--b');
xline(Wrist, '--m');
legend("Right Measurement", "Center Measurement", "Left Measurement", ...
    "DIP Joint", "PIP Joint", "MCP Joint", "Wrist");
hold off;
title("Free Hand - Resonant Frequencies")
ylabel("Resonance (Hz)")
xlabel("Distanct from Finger Tip (mm)");

figure
plot([probe_spacing, free_spacing], [free_probe_peakAmp, free_peakAmp(1:3:end)])
hold on;
plot([probe_spacing, free_spacing], [free_probe_peakAmp, free_peakAmp(2:3:end)])
hold on;
plot([probe_spacing, free_spacing], [free_probe_peakAmp, free_peakAmp(3:3:end)])
xline(DIP, '--r');
xline(PIP, '--g');
xline(MCP, '--b');
xline(Wrist, '--m');
legend("Right Measurement", "Center Measurement", "Left Measurement", ...
    "DIP Joint", "PIP Joint", "MCP Joint", "Wrist");
hold off;
title("Free Hand - Maximum Admittance")
ylabel("Admittance (mm/Ns)")
xlabel("Distanct from Finger Tip (mm)");

figure
plot([probe_spacing, free_spacing], [free_probe_singleFreq(idx_singleFreq,:)...
    , free_singleFreq(idx_singleFreq,1:3:end)])
hold on;
plot([probe_spacing, free_spacing], [free_probe_singleFreq(idx_singleFreq,:)...
    , free_singleFreq(idx_singleFreq,2:3:end)])
hold on;
plot([probe_spacing, free_spacing], [free_probe_singleFreq(idx_singleFreq,:)...
    , free_singleFreq(idx_singleFreq,3:3:end)])
xline(DIP, '--r');
xline(PIP, '--g');
xline(MCP, '--b');
xline(Wrist, '--m');
legend("Right Measurement", "Center Measurement", "Left Measurement", ...
    "DIP Joint", "PIP Joint", "MCP Joint", "Wrist");
hold off;
title("Free Hand - Admittance at "+ num2str(single_freq) + " Hz")
ylabel("Admittance (mm/Ns)")
xlabel("Distanct from Finger Tip (mm)");

figure
plot([probe_spacing, fixed_spacing], [fixed_probe_resonance, fixed_resonance(1:3:end)])
hold on;
plot([probe_spacing, fixed_spacing], [fixed_probe_resonance, fixed_resonance(2:3:end)])
hold on;
plot([probe_spacing, fixed_spacing], [fixed_probe_resonance, fixed_resonance(3:3:end)])
xline(DIP, '--r');
xline(PIP, '--g');
xline(MCP, '--b');
xline(Wrist, '--m');
legend("Right Measurement", "Center Measurement", "Left Measurement", ...
    "DIP Joint", "PIP Joint", "MCP Joint", "Wrist");
hold off;
title("Fixed Hand - Resonant Frequencies")
ylabel("Resonance (Hz)")
xlabel("Distanct from Finger Tip (mm)");

figure
plot([probe_spacing, fixed_spacing], [fixed_probe_peakAmp, fixed_peakAmp(1:3:end)])
hold on;
plot([probe_spacing, fixed_spacing], [fixed_probe_peakAmp, fixed_peakAmp(2:3:end)])
hold on;
plot([probe_spacing, fixed_spacing], [fixed_probe_peakAmp, fixed_peakAmp(3:3:end)])
xline(DIP, '--r');
xline(PIP, '--g');
xline(MCP, '--b');
xline(Wrist, '--m');
legend("Right Measurement", "Center Measurement", "Left Measurement", ...
    "DIP Joint", "PIP Joint", "MCP Joint", "Wrist");
hold off;
title("Fixed Hand - Maximum Admittance")
ylabel("Admittance (mm/Ns)")
xlabel("Distanct from Finger Tip (mm)");

figure
plot([probe_spacing, fixed_spacing], [fixed_probe_singleFreq(idx_singleFreq,:)...
    , fixed_singleFreq(idx_singleFreq,1:3:end)])
hold on;
plot([probe_spacing, fixed_spacing], [fixed_probe_singleFreq(idx_singleFreq,:)...
    , fixed_singleFreq(idx_singleFreq,2:3:end)])
hold on;
plot([probe_spacing, fixed_spacing], [fixed_probe_singleFreq(idx_singleFreq,:)...
    , fixed_singleFreq(idx_singleFreq,3:3:end)])
xline(DIP, '--r');
xline(PIP, '--g');
xline(MCP, '--b');
xline(Wrist, '--m');
legend("Right Measurement", "Center Measurement", "Left Measurement", ...
    "DIP Joint", "PIP Joint", "MCP Joint", "Wrist");
hold off;
title("Fixed Hand - Admittance at "+ num2str(single_freq) + " Hz")
ylabel("Admittance (mm/Ns)")
xlabel("Distanct from Finger Tip (mm)");


%% Frequency Response
distance_map = reshape(repmat(fixed_spacing,3,1),1,[]);

DP_idx = find(distance_map <= DIP);
MP_idx = find(and(distance_map > DIP, distance_map <= PIP));
PP_idx = find(and(distance_map > PIP, distance_map <= MCP));
M_idx = find(and(distance_map > MCP, distance_map <= Wrist));

figure
subplot(2,1,1)
semilogx(freq,movmean(squeeze(loaded_vel{3}./(loaded_force{3}-free_inertial_force)),31))
hold on;
semilogx(freq,movmean(squeeze(mean(loaded_vel{1}(DP_idx,:),1))./(squeeze(mean(loaded_force{1}(DP_idx,:),1))-free_inertial_force),31))
hold on;
semilogx(freq,movmean(squeeze(mean(loaded_vel{1}(MP_idx,:),1))./squeeze((mean(loaded_force{1}(MP_idx,:),1))-free_inertial_force),31))
hold on;
semilogx(freq,movmean(squeeze(mean(loaded_vel{1}(PP_idx,:),1))./squeeze((mean(loaded_force{1}(PP_idx,:),1))-free_inertial_force),31))
hold on;
semilogx(freq,movmean(squeeze(mean(loaded_vel{1}(M_idx,:),1))./squeeze((mean(loaded_force{1}(M_idx,:),1))-free_inertial_force),31))
hold off;
legend("Contact", "DP", "MP", "PP", "M");
ylim([0,200])
ylabel("Admittance (mm/Ns)")
xlabel("Frequency (Hz)")
title('Free Hand')

subplot(2,1,2)
semilogx(freq,movmean(squeeze(loaded_vel{4}./(loaded_force{4}-free_inertial_force)),31))
hold on;
semilogx(freq,movmean(squeeze(mean(loaded_vel{2}(DP_idx,:),1))./squeeze((mean(loaded_force{2}(DP_idx,:),1))-free_inertial_force),31))
hold on;
semilogx(freq,movmean(squeeze(mean(loaded_vel{2}(MP_idx,:),1))./squeeze((mean(loaded_force{2}(MP_idx,:),1))-free_inertial_force),31))
hold on;
semilogx(freq,movmean(squeeze(mean(loaded_vel{2}(PP_idx,:),1))./squeeze((mean(loaded_force{2}(PP_idx,:),1))-free_inertial_force),31))
hold on;
semilogx(freq,movmean(squeeze(mean(loaded_vel{2}(M_idx,:),1))./squeeze((mean(loaded_force{2}(M_idx,:),1))-free_inertial_force),31))
hold off;
legend("Contact", "DP", "MP", "PP", "M");
ylim([0,200])
ylabel("Admittance (mm/Ns)")
xlabel("Frequency (Hz)")
title('Fixed Hand')

sgtitle('Frequency Responses')


%% Analyze Distribution
[~,idx_40] = min(abs(freq-40));
[~,idx_300] = min(abs(freq-300));

% db_measures = [3 6 9 12 15];
db_measures = [5 10];
magnitude_values = 10.^(-db_measures./20);

free_db = free_spacing(end)*ones(length(db_measures),length(freq));
fixed_db = fixed_spacing(end)*ones(length(db_measures),length(freq));

figure
subplot(2,1,1)
plot_freq = [15, 50, 100, 200, 400, 800];
[~,plot_freq_idx] = min(abs(freq'-plot_freq));
c = parula(length(freq));
for iter0 = 1:length(plot_freq_idx)
    iter1 = plot_freq_idx(iter0);
    avg_free_singleFreq = [ones(1,probe_diameter)*free_probe_singleFreq(iter1,1),...
        mean([free_singleFreq(iter1,1:3:end); free_singleFreq(iter1,2:3:end);...
        free_singleFreq(iter1,3:3:end)],1)];
    interp_x = (1-probe_diameter):(free_spacing(end)-probe_diameter);
    interp_y = interp1([1-probe_diameter:0,free_spacing-probe_diameter],avg_free_singleFreq,interp_x);
    smoothed_singleFreq = movmean(interp_y,25);
    smoothed_singleFreq(probe_diameter) = free_probe_singleFreq(iter1,1);
    normalized = smoothed_singleFreq(probe_diameter:end)/smoothed_singleFreq(probe_diameter);
    for iter2 = length(normalized):-1:probe_diameter
        for iter3 = 1:length(db_measures)
            if 20*log10(normalized(iter2)) < -db_measures(iter3)
                free_db(iter3,iter1) = interp_x(iter2);
            end
        end
    end
%         /smoothed_singleFreq(probe_diameter)
    plot(interp_x(probe_diameter:end),smoothed_singleFreq(probe_diameter:end)...
        /smoothed_singleFreq(probe_diameter),'color',c(iter1,:));
%     plot(interp_x(probe_diameter:end),smoothed_singleFreq(probe_diameter:end)...
%             ,'color',c(iter1,:));
    if iter1 == idx_40
        smoothed_singleFreq_40 = smoothed_singleFreq;
    end
    if iter1 == idx_300
        smoothed_singleFreq_300 = smoothed_singleFreq;
    end
    hold on;


end
% plot(interp_x(probe_diameter:end),smoothed_singleFreq_300(probe_diameter:end)...
%         /smoothed_singleFreq_300(probe_diameter),'k','LineWidth',3);
% plot(interp_x(probe_diameter:end),smoothed_singleFreq_40(probe_diameter:end)...
%         /smoothed_singleFreq_40(probe_diameter),'k','LineWidth',3);
% plot(interp_x(probe_diameter:end),smoothed_singleFreq_40(probe_diameter:end)...
%         ,'k','LineWidth',3);
yline(magnitude_values)
hold off;
xlim([0,interp_x(end)])
ylim([0,1.2]);
title("Free Hand")
xlabel("Distance from Probe (mm)")
ylabel("Admittance")

subplot(2,1,2)
c = parula(length(freq));
for iter0 = 1:length(plot_freq_idx)
    iter1 = plot_freq_idx(iter0);
    avg_fixed_singleFreq = [ones(1,probe_diameter)*fixed_probe_singleFreq(iter1,1),...
        mean([fixed_singleFreq(iter1,1:3:end); fixed_singleFreq(iter1,2:3:end);...
        fixed_singleFreq(iter1,3:3:end)],1)];
    interp_x = (1-probe_diameter):(fixed_spacing(end)-probe_diameter);
    interp_y = interp1([1-probe_diameter:0,fixed_spacing-probe_diameter],avg_fixed_singleFreq,interp_x);
    smoothed_singleFreq = movmean(interp_y,25);
    smoothed_singleFreq(probe_diameter) = fixed_probe_singleFreq(iter1,1);
    normalized = smoothed_singleFreq(probe_diameter:end)/smoothed_singleFreq(probe_diameter);
    for iter2 = length(normalized):-1:probe_diameter
        for iter3 = 1:length(db_measures)
            if 20*log10(normalized(iter2)) < -db_measures(iter3)
                fixed_db(iter3,iter1) = interp_x(iter2);
            end
        end
    end
    plot(interp_x(probe_diameter:end),smoothed_singleFreq(probe_diameter:end)...
        /smoothed_singleFreq(probe_diameter),'color',c(iter1,:));
%     plot(interp_x(probe_diameter:end),smoothed_singleFreq(probe_diameter:end)...
%             ,'color',c(iter1,:));
    if iter1 == idx_40
        smoothed_singleFreq_40 = smoothed_singleFreq;
    end
    if iter1 == idx_300
        smoothed_singleFreq_300 = smoothed_singleFreq;
    end
    hold on;
end
% plot(interp_x(probe_diameter:end),smoothed_singleFreq_40(probe_diameter:end)...
%         /smoothed_singleFreq_40(probe_diameter),'k','LineWidth',3);
% plot(interp_x(probe_diameter:end),smoothed_singleFreq_300(probe_diameter:end)...
%         /smoothed_singleFreq_300(probe_diameter),'k','LineWidth',3);
% plot(interp_x(probe_diameter:end),smoothed_singleFreq_300(probe_diameter:end)...
%         ,'k','LineWidth',3);
yline(magnitude_values)
hold off;
xlim([0,interp_x(end)])
ylim([0,1.2]);
title("Fixed Hand")
xlabel("Distance from Probe (mm)")
ylabel("Admittance")

sgtitle("Signal Decay")


figure;
subplot(2,1,1)
for iter1 = 1:length(db_measures)
    semilogx(freq,movmean(squeeze(free_db(iter1,:)),31),'DisplayName', num2str(db_measures(iter1)+" dB"));
    hold on;
end
ylim([0,free_spacing(end)])
legend
xlabel("Frequency (Hz)")
ylabel("Distance from Probe (mm)")
subplot(2,1,2)
for iter1 = 1:length(db_measures)
    semilogx(freq,movmean(squeeze(fixed_db(iter1,:)),31),'DisplayName',num2str(db_measures(iter1)+" dB"));
    hold on;
end
ylim([0,fixed_spacing(end)])
xlabel("Frequency (Hz)")
ylabel("Distance from Probe (mm)")
legend


%% Admittance Surf Plot
avg_free_admittance = [free_probe_impedance',...
    (free_singleFreq(:,1:3:end)+free_singleFreq(:,2:3:end)+free_singleFreq(:,3:3:end))/3];
avg_fixed_admittance = [fixed_probe_impedance',...
    (fixed_singleFreq(:,1:3:end)+fixed_singleFreq(:,2:3:end)+fixed_singleFreq(:,3:3:end))/3];

[dist_mesh, freq_mesh] = meshgrid([0,free_spacing-probe_diameter],freq);

dist_resample = linspace(0,free_spacing(end)-probe_diameter,1000);
[dist_mesh_resample, freq_mesh_resample] = meshgrid(dist_resample,freq);
avg_free_admittance_resample = interp2(dist_mesh,freq_mesh,avg_free_admittance,dist_mesh_resample,freq_mesh_resample);
avg_fixed_admittance_resample = interp2(dist_mesh,freq_mesh,avg_fixed_admittance,dist_mesh_resample,freq_mesh_resample);

figure;
tiledlayout(2,1);
nexttile
s = surf(dist_mesh_resample,freq_mesh_resample,avg_free_admittance_resample);
s.EdgeColor = 'none';
colormap parula;
ylim([10,1000]);
set(gca,'YScale','log')
set(gca,'ColorScale','log')
view(2)
clim([10^-1,max(max(avg_free_admittance,[],'all'),max(avg_fixed_admittance,[],'all'))])
title("Free Hand")
xlabel("Distance from Contact (mm)")
ylabel("Frequency (Hz)")

nexttile
s = surf(dist_mesh_resample,freq_mesh_resample,avg_fixed_admittance_resample);
s.EdgeColor = 'none';
colormap parula;
ylim([10,1000]);
set(gca,'ColorScale','log')
set(gca,'YScale','log')
view(2)
clim([10^-1,max(max(avg_free_admittance,[],'all'),max(avg_fixed_admittance,[],'all'))])
title("Fixed Hand")
xlabel("Distance from Contact (mm)")
ylabel("Frequency (Hz)")

c = colorbar;
c.Layout.Tile = 'south';
c.Label.String = "Admittance (mm/Ns)";
sgtitle("Decay of Mechanical Signals")



%% Total Engery
theta = linspace(0,2*pi,25);
x_coordinates = [0, (probe_diameter/2)*cos(theta),...
    repmat([grid_spacing;0;-grid_spacing],size(loaded_vel{1},1)/3,1)'];
y_coordinates = [probe_diameter/2, probe_diameter/2 + (probe_diameter/2)*sin(theta),...
    reshape(repmat(fixed_spacing,3,1),1,[])];
[Xq,Yq] = meshgrid(linspace(-grid_spacing,grid_spacing,10), linspace(0,fixed_spacing(end)),100);

z_free= [free_probe_energy(1)*ones(1,1+length(theta)), free_energy];
z_fixed= [fixed_probe_energy(1)*ones(1,1+length(theta)), fixed_energy];

V_free = griddata(x_coordinates,y_coordinates,z_free,Xq,Yq);
V_fixed = griddata(x_coordinates,y_coordinates,z_fixed,Xq,Yq);

figure;
tiledlayout(2,1);
nexttile
s = surf(Xq,Yq,V_free);
s.EdgeColor = 'none';
colormap parula;
set(gca,'Ydir','reverse')
set(gca,'ColorScale','log')
view(2)
clim([10^0,max(max(V_free,[],'all'),max(V_fixed,[],'all'))])
clim([10^0,10^2])
title("Free Hand")
ylabel("Distance from Fingertip (mm)")
xlabel("Distance from Center Axis (mm)")

nexttile
s = surf(Xq,Yq,V_fixed);
s.EdgeColor = 'none';
colormap parula;
set(gca,'Ydir','reverse')
set(gca,'ColorScale','log')
view(2)
clim([10^0,max(max(V_free,[],'all'),max(V_fixed,[],'all'))])
clim([10^0,10^2])
title("Fixed Hand")
ylabel("Distance from Fingertip (mm)")
xlabel("Distance from Center Axis (mm)")

c = colorbar;
c.Layout.Tile = 'south';
c.Label.String = 'Energy';
sgtitle("Energy Distribution")


z_free= [free_probe_resonance(1)*ones(1,1+length(theta)), free_resonance];
z_fixed= [fixed_probe_resonance(1)*ones(1,1+length(theta)), fixed_resonance];

V_free = griddata(x_coordinates,y_coordinates,z_free,Xq,Yq);
V_fixed = griddata(x_coordinates,y_coordinates,z_fixed,Xq,Yq);

figure;
tiledlayout(2,1);
nexttile
s = surf(Xq,Yq,movmean(V_free,20));
s.EdgeColor = 'none';
colormap parula;
set(gca,'Ydir','reverse')
% set(gca,'ColorScale','log')
view(2)
clim([min(movmean(V_free,20),[],"all"),80])
title("Free Hand")
ylabel("Distance from Fingertip (mm)")
xlabel("Distance from Center Axis (mm)")

c = colorbar;
c.Layout.Tile = 'east';
c.Label.String = 'Frequency';

nexttile
s = surf(Xq,Yq,movmean(V_fixed,20));
s.EdgeColor = 'none';
colormap parula;
set(gca,'Ydir','reverse')
% set(gca,'ColorScale','log')
view(2)
clim([min(movmean(V_fixed,20),[],"all"),400])
title("Fixed Hand")
ylabel("Distance from Fingertip (mm)")
xlabel("Distance from Center Axis (mm)")

c = colorbar;
c.Layout.Tile = 'east';
c.Label.String = 'Frequency';
sgtitle("Resonant Frequency")