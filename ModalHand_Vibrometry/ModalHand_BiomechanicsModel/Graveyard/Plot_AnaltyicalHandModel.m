clc; clear; close all;

NewtonEuler = load("NewtonEulerData.mat");

%% Articulated Structure
distance = linspace(0,NewtonEuler.l1/2+NewtonEuler.l2+NewtonEuler.l3+NewtonEuler.l4,1000);
distance = distance(1:end-1);

l4_distance = linspace(0,NewtonEuler.l4,500);
l4_distance = l4_distance(2:end);
l3_distance = linspace(0,NewtonEuler.l3,500);
l3_distance = l3_distance(2:end);
l2_distance = linspace(0,NewtonEuler.l2,500);
l2_distance = l2_distance(2:end);
l1_distance = linspace(0,NewtonEuler.l1/2,500);
l1_distance = l1_distance(2:end);

l4_response = 1000*l4_distance'*(2*pi*NewtonEuler.freq.^1.*NewtonEuler.theta4_out);
l3_response = ones(499,1)*l4_response(end,:)+1000*l3_distance'*(2*pi*NewtonEuler.freq.^1.*NewtonEuler.theta3_out);
l2_response = ones(499,1)*l3_response(end,:)+1000*l2_distance'*(2*pi*NewtonEuler.freq.^1.*NewtonEuler.theta2_out);
l1_response = ones(499,1)*l2_response(end,:)+1000*l1_distance'*(2*pi*NewtonEuler.freq.^1.*NewtonEuler.theta1_out);

articulated_distance = [l4_distance, NewtonEuler.l4+l3_distance,NewtonEuler.l4+NewtonEuler.l3+l2_distance,NewtonEuler.l4+NewtonEuler.l3+NewtonEuler.l2+l1_distance];
articulated_response = [l4_response', l3_response', l2_response', l1_response'];

[temp_dist_mesh, temp_freq_mesh] = meshgrid(abs(articulated_distance-articulated_distance(end)),NewtonEuler.freq);
[dist_mesh, freq_mesh] = meshgrid(distance,NewtonEuler.freq);

articulated_mesh = interp2(temp_dist_mesh,temp_freq_mesh,articulated_response,dist_mesh,freq_mesh);

%% Shear Wave Propagation
u0 = NewtonEuler.y0_out - NewtonEuler.y1_out;

E = 111*10^3; % Pa - Wiertluski
eta = 162; % Pa*s - Wiertluski
rho = 1000; % kg/m^3

poissons = .5;

G = E/(2*poissons+1);
eta2 = eta/(2*poissons+1);

% G = 18*10^3; % Pa Kearny
% eta2 = 2; % Pa*s Kearny

% potts_freq = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];
% potts_speed = [4.5, 6.5, 6.5, 6, 5.5, 6, 6.5, 7, 7.5, 8.5];
% potts_damping = 1000./[7.5, 6, 4, 3, 4, 4.5, 5, 5.5, 6, 6];
% 
% wave_speed = interp1(potts_freq,potts_speed,frequency);
% damping_coefficient = interp1(potts_freq,potts_damping,frequency);

% potts_freq = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];
% potts_speed = [4.5, 6.5, 6.5, 6, 5.5, 6, 6.5, 7, 7.5, 8.5];
% potts_damping = 1000./[7.5, 6, 4, 3, 4, 4.5, 5, 5.5, 6, 6];
% 
% wave_speed = interp1(potts_freq,potts_speed,frequency);
% damping_coefficient = interp1(potts_freq,potts_damping,frequency);

wave_speed = 5;
damping_coefficient = 200;
damping_factor = 1.3;

% wave_speed = (1/(2*rho))*(4*rho*G - eta2^2)^.5;
% damping_coefficient = ones(length(frequency),1)*eta2/(4*rho*G - eta2^2)^.5;
% 
% tau = (eta2/G)*(frequency)*2*pi;

% wave_speed = (G/rho)^.5;
% damping_coefficient = eta2*((frequency*2*pi).^2)/2/rho/wave_speed^3;


u0_phase = angle(u0);
new_phase = angle(u0)'*ones(1,length(distance)) + ((2*pi*frequency./wave_speed)'*distance);

% 
% tissue_mesh = 1000*abs(2*pi*frequency.*u0)'*ones(1,length(distance)).*...
%     complex(cos(new_phase),sin(new_phase)).*...
%     (exp(-damping_coefficient'*distance));

tissue_mesh = 1000*abs(2*pi*frequency.*u0)'*ones(1,length(distance)).*...
    complex(cos(new_phase),sin(new_phase)).*...
    (1./((1000*distance).^damping_factor));

%%
figure;
tiledlayout(3,1);
nexttile
s = surf(dist_mesh,freq_mesh,abs(articulated_mesh));
s.EdgeColor = 'none';
colormap parula;
ylim([10,1000]);
set(gca,'YScale','log')
set(gca,'ColorScale','log')
view(2)
clim([10^-1,max(max(abs(articulated_mesh+tissue_mesh),[],'all'),max(abs(tissue_mesh),[],'all'))])
title("Articulated Structure Response")
xlabel("Distance from Contact (mm)")
ylabel("Frequency (Hz)")

nexttile
s = surf(dist_mesh,freq_mesh,abs(tissue_mesh));
s.EdgeColor = 'none';
colormap parula;
ylim([10,1000]);
set(gca,'YScale','log')
set(gca,'ColorScale','log')
view(2)
clim([10^-1,max(max(abs(articulated_mesh+tissue_mesh),[],'all'),max(abs(tissue_mesh),[],'all'))])
title("Shear Wave Response")
xlabel("Distance from Contact (mm)")
ylabel("Frequency (Hz)")

nexttile
s = surf(dist_mesh,freq_mesh,abs(articulated_mesh+tissue_mesh));
s.EdgeColor = 'none';
colormap parula;
ylim([10,1000]);
set(gca,'YScale','log')
set(gca,'ColorScale','log')
view(2)
clim([10^-1,max(max(abs(articulated_mesh+tissue_mesh),[],'all'),max(abs(tissue_mesh),[],'all'))])
title("Superposition")
xlabel("Distance from Contact (mm)")
ylabel("Frequency (Hz)")

c = colorbar;
c.Layout.Tile = 'east';
c.Label.String = "Admittance (mm/Ns)";
sgtitle("Decay of Mechanical Signals")


% figure
% semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y1_out),'r');
% 
% figure
% semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y_fixed),'k');
% 
% figure
% semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y2_out),'Color',[0.9290 0.6940 0.1250]);
% 
% figure
% semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y_fixed).*exp(-damping_coefficient*(l1/2+l2/2)),'k');
% 
% figure
% semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y3_out),'Color',[0 0.4470 0.7410]);
% 
% figure
% semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y_fixed).*exp(-damping_coefficient*(l1/2+l2+l3/2)),'k');
% 
% figure
% semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y4_out),'Color',[.85 0 .75]);
% 
% figure
% semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y_fixed).*exp(-damping_coefficient*(l1/2+l2+l3+l4/2)),'k');

