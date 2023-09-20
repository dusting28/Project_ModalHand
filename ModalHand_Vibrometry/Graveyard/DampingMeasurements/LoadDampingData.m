reload = true;
folder = fileparts(which(mfilename));
addpath(genpath(folder));
close all; clc; 
if reload == true
    clear;

    type = ["Fixed", "Free"];
    frequency = [20,50,100,200,250,300,500,1000];
    location = [2,4,8,16,32,64];

    force_data = cell(length(type),length(frequency),length(location));
    displacement_data = cell(length(type),length(frequency),length(location));
    rms_displacement = zeros(length(type),length(frequency),length(location));
    rms_force = zeros(length(type),length(frequency),length(location));
    
    loaded_force = cell(length(frequency),1);
    loaded_displacement = cell(length(frequency),1);
    loaded_rms_force = zeros(length(frequency),1);
    loaded_rms_displacement = zeros(length(frequency),1);
    
    fixed_force = cell(length(frequency),1);
    fixed_displacement = cell(length(frequency),1);
    fixed_rms_force = zeros(length(frequency),1);
    fixed_rms_displacement = zeros(length(frequency),1);

    currentFolder = pwd;
    
    for iter2 = 1:length(frequency)
        for iter1 = 1:length(type)
            for iter3 = 1:length(location)
                scale_factor = 25;
                if iter3==6
                    scale_factor = 5;
                end
                filename = strcat(pwd,'/HumanHandDustin/',num2str(location(iter3))...
                        ,'mm/',num2str(frequency(iter2)),'Hz-',type(iter1),'.mat');
                if iter1 == 2 && iter2 == 2 && iter3 == 6
                    filename = strcat(pwd,'/HumanHandDustin/',num2str(location(iter3))...
                        ,'mm/',num2str(frequency(iter2)),'Hz-Clip.mat');
                    scale_factor = 25;
                end
                [temp_force,temp_rms_force,temp_displacement,temp_rms_displacement] = LoadVibrationData(filename,scale_factor,frequency(iter2));
                [~,~,~,stand_rms] = LoadVibrationData(strcat(pwd,...
                    '/HumanHandDustin/1mm/',num2str(frequency(iter2)),'Hz-Fixed.mat'),5,frequency(iter2));

                force_data{iter1,iter2,iter3} = temp_force;
                rms_force(iter1,iter2,iter3) = temp_rms_force;
                displacement_data{iter1,iter2,iter3} = temp_displacement;
                rms_displacement(iter1,iter2,iter3) = temp_rms_displacement;
                
                if iter1 == 1
                    rms_displacement(iter1,iter2,iter3) = abs(temp_rms_displacement - stand_rms);
                end
            end
        end
        filename = strcat(pwd,'/HumanHandDustin/1mm/',num2str(frequency(iter2)),'Hz-LoadedActuator.mat');
        [loaded_force{iter2},loaded_rms_force(iter2),loaded_displacement{iter2},loaded_rms_displacement(iter2)] = LoadVibrationData(filename,125,frequency(iter2));
        filename = strcat(pwd,'/HumanHandDustin/1mm/',num2str(frequency(iter2)),'Hz-Fixed.mat');
        [fixed_force{iter2},fixed_rms_force(iter2),fixed_displacement{iter2},fixed_rms_displacement(iter2)] = LoadVibrationData(filename,5,frequency(iter2));
    end
end

% Y = fft(squeeze(displacement_data{1,2,1,1}(:,1)));
% L = length(displacement_data{1,2,1,1}(:,1));
% P2 = abs(Y/L);
% P1 = P2(1:L/2+1);
% P1(2:end-1) = 2*P1(2:end-1);
% f = fs*(0:(L/2))/L;
% 
% figure();
% plot(f,P1) 
alpha = zeros(length(type),length(frequency));
beta = zeros(length(type),length(frequency));
for iter1 = 1:length(frequency)
    exp_fit_1 = polyfit(location,squeeze(log(rms_displacement(1,iter1,:)))',1);
    alpha(1,iter1) = -exp_fit_1(1);
    beta(1,iter1) = exp(exp_fit_1(2));
    exp_fit_2 = polyfit(location,squeeze(log(rms_displacement(2,iter1,:)))',1);
    alpha(2,iter1) = -exp_fit_2(1);
    beta(2,iter1) = exp(exp_fit_2(2));
    
    figure()
    plot(location,exp(exp_fit_1(2))*exp(exp_fit_1(1).*location),'b')
    hold on;
    plot(location,exp(exp_fit_2(2))*exp(exp_fit_2(1).*location),'r')
    hold on;
    plot(location,squeeze(rms_displacement(1,iter1,:)),'bo')
    hold on;
    plot(location,squeeze(rms_displacement(2,iter1,:)),'ro')
    hold off;
    legend('Fixed Hand','Free Hand');
    title(strcat(num2str(frequency(iter1))," Hz"));
    ylabel('RMS Displacement (mm)')
    xlabel('Distance (mm)')
%     figure()
%     plot(location,squeeze(log(rms_displacement(1,iter1,:))),'bo')
%     hold on;
%     plot(location,exp_fit_1(2)+exp_fit_1(1).*location,'b')
%     hold on;
%     plot(location,squeeze(log(rms_displacement(2,iter1,:))),'ro')
%     hold on;
%     plot(location,exp_fit_2(2)+exp_fit_2(1).*location,'r')
%     legend('Fixed','Free');
%     hold off;

    figure()
    plot(location,squeeze(rms_force(1,iter1,:)),'bo-')
    hold on;
    plot(location,squeeze(rms_force(2,iter1,:)),'ro-')
    hold off;
    legend('Fixed Hand','Free Hand');
    title(strcat(num2str(frequency(iter1))," Hz"));
    ylabel('RMS Force (mm)')
    xlabel('Distance (mm)')
end

figure()
plot(frequency,20*log10(squeeze(fixed_rms_displacement'./beta(1,:))),'o-')
title('Support Structure Vibrations')
ylabel('RMS Displacement (dB)')
xlabel('Frequency');

figure()
plot(frequency,20*log10(squeeze((frequency*2*pi).^2.*loaded_rms_displacement')/8000./loaded_rms_force'))
hold on;
plot(frequency,20*log10(squeeze((frequency*2*pi).^2.*beta(1,:))/8000./rms_force(1,:,1)))
hold on;
plot(frequency,20*log10(squeeze((frequency*2*pi).^2.*beta(2,:))/8000./rms_force(2,:,1)))
hold off;
title('Transfer Functions')
ylabel('$\frac{\ddot{x}}{V}$ (dB)','interpreter','latex')
xlabel('Frequency');
legend('Actuator','Fixed Hand','Free Hand');

figure()
for iter1 = 3:size(rms_displacement,3)
    plot(frequency,squeeze((frequency*2*pi).^1.*rms_displacement(2,:,iter1)./rms_force(2,:,iter1)))
    hold on;
end
hold off;
title('Transfer Functions - Free')
ylabel('$\frac{\dot{x}}{N}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency');
legend('DIP','PIP','MCP','Metacarpal');

figure()
for iter1 = 3:size(rms_displacement,3)
    plot(frequency,squeeze((frequency*2*pi).^1.*rms_displacement(1,:,iter1)./rms_force(1,:,iter1)))
    hold on;
end
hold off;
title('Transfer Functions - Fixed')
ylabel('$\frac{\dot{x}}{N}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency');
legend('DIP','PIP','MCP','Metacarpal');

figure()
plot(frequency,squeeze(alpha(1,:)))
hold on;
plot(frequency,squeeze(alpha(2,:)))
hold off;
title('Damping')
ylabel('Damping Coefficent (1/mm)')
xlabel('Frequency');
legend('Fixed Hand','Free Hand');