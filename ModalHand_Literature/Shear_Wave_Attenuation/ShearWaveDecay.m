clear; clc; close all;

folder = fileparts(which(mfilename));
addpath(genpath(folder));
interp_frequencies = [20, 50, 100, 200, 300, 400, 500, 1000];
interp_distances = 0:200;

% K-V Model
mu = (100*10^3); %Pa
rho = 1000; %kg/m^3
eta = 150; %Pa*s
alpha_kv = ((2*pi*interp_frequencies).^2.*eta.*(rho)^.5)/(2*mu^1.5)/1000;

% Dustin - Measurements
load("alpha_fixed.mat");
load("alpha_free.mat");

% Bharat - SpatioTemporal
frequency_bharat = [40,50,60,70,80,90,120,140,160,180,230,280,330,380,460,540,640];
half_energy = [89,84,73,60,46,41,43,42,43,44,40,35,36,36,31,30,24];
alpha_bharat = -log(1/2)./half_energy;


% Manfredi - Surface Wave Propogation
measured_frequencies = [20, 50, 100, 200, 300, 400, 500, 1000];
distances = [1, 2, 4, 8, 16, 32, 64];
decay_exponent = [1.35, 1.3, 1.14, 1.12, 1.16, 1.28, 1.16, 1.35];
alpha_manfredi = zeros(1,length(measured_frequencies));
for iter1 = 1:length(measured_frequencies)
    displacements = 1./(distances.^decay_exponent(iter1));
    exp_fit = polyfitZero(distances,log(displacements),1);
    alpha_manfredi(iter1) = -exp_fit(1);
end

% Potts - Dynamic Mechanical Properties
decay_distance = [11, 11, 10, 9, 6, 3, 2.5, 2.5];
alpha_potts = 1./decay_distance;

% Zhang - Surface Wave
frequency_zhang = [100, 150, 200, 250, 300, 350];
alpha_zhang = [0.047, 0.05, 0.056, 0.062, 0.073, 0.082];

figure
% plot(interp_frequencies,alpha_kv)
% hold on;
% plot(interp_frequencies,alpha_fixed)
% hold on;
plot(frequency_bharat,alpha_bharat)
hold on;
plot(interp_frequencies,alpha_manfredi)
hold on;
plot(interp_frequencies,alpha_potts)
hold on;
plot(frequency_zhang,alpha_zhang,'k')
hold on;
plot(interp_frequencies,alpha_fixed)
hold on;
plot(interp_frequencies,alpha_free)
hold off;
title('Damping')
ylabel('Damping Coefficent (1/mm)')
xlabel('Frequency');
legend('Dandu','Manfredi','Potts', 'Zhang', 'Fixed Hand', 'Free Hand');

figure
% plot(interp_frequencies,log(.1)./-alpha_kv)
% hold on;
% plot(interp_frequencies,log(.1)./-alpha_fixed)
% hold on;
% plot(interp_frequencies,log(.1)./-alpha_free)
% hold on;
plot(frequency_bharat,log(.1)./-alpha_bharat)
hold on;
plot(interp_frequencies,log(.1)./-alpha_manfredi)
hold on;
plot(interp_frequencies,log(.1)./-alpha_potts)
hold off;
% 
% figure
% for iter1 = 1:length(interp_frequencies)
%     subplot(1,length(interp_frequencies),iter1)
% %     plot(interp_distances,exp(-alpha_kv(iter1).*interp_distances))
% %     hold on;
% %     plot(interp_distances,exp(-alpha_fixed(iter1).*interp_distances))
% %     hold on;
% %     plot(interp_distances,exp(-alpha_free(iter1).*interp_distances))
% %     hold on;
%     plot(interp_distances,exp(-alpha_bharat(iter1).*interp_distances))
%     hold on;
%     plot(interp_distances,exp(-alpha_manfredi(iter1).*interp_distances))
%     hold on;
%     plot(interp_distances,exp(-alpha_potts(iter1).*interp_distances))
%     hold off;
%     
% end

figure()
subplot(1,2,1)
plot(interp_distances,exp(-alpha_bharat(2).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_manfredi(2).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_potts(2).*interp_distances))
hold off;
title('50 Hz')
ylabel('RMS Displacement')
xlabel('Distance (mm)');
legend('Dandu','Manfredi','Potts');
subplot(1,2,2)
plot(interp_distances,exp(-alpha_bharat(6).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_manfredi(3).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_potts(3).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_zhang(1).*interp_distances),'k')
hold off;
title('100 Hz')
ylabel('RMS Displacement')
xlabel('Distance (mm)');
legend('Dandu','Manfredi','Potts','Zhang');

figure()
plot(interp_distances,exp(-alpha_bharat(2).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_manfredi(2).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_potts(2).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_fixed(2).*interp_distances))
hold on;
plot(interp_distances,exp(-alpha_free(2).*interp_distances))
hold off;
title('50 Hz')
ylabel('RMS Displacement')
xlabel('Distance (mm)');
legend('Dandu', 'Manfredi', 'Potts', 'Fixed Hand','Free Hand');
