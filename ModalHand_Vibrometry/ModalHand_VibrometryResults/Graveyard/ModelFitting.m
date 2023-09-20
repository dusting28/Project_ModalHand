clc; clear; close all;
addpath("Data\")
addpath("Functions\")
highRes = load("HighRes_ProcessedData.mat");

%% Filter
filter_band = [15, 900];
include_probe = true;
freq_downsample = 10;

start_idx = 1;
if ~include_probe
    start_idx = 2;
end

filter_idx = or(highRes.freq<filter_band(1),highRes.freq>filter_band(2));
freq = highRes.freq(~filter_idx);
fixed_admittance = zeros(length(freq),length(highRes.yCord)+1-start_idx);
free_admittance = zeros(length(freq),length(highRes.yCord)+1-start_idx);

for iter1 = start_idx:length(highRes.yCord)
    fixed_admittance(:,iter1+1-start_idx) = highRes.fixed_tf{iter1}(~filter_idx);
    free_admittance(:,iter1+1-start_idx) = highRes.free_tf{iter1}(~filter_idx);
end

pos_data = highRes.yCord(start_idx:end)-highRes.yProbe;

%% Looking at Phase and Stuff
% single_freq = [15, 50, 100, 200, 400];
% [~,freq_idx] = min(abs(freq'-single_freq));
% % for iter1 = 1:length(single_freq)
% %     linePlot(abs(fixed_admittance(freq_idx(iter1),:)),highRes,true,strcat("Fixed Hand - ", num2str(single_freq(iter1))," Hz Admittance"))
% %     linePlot(abs(free_admittance(freq_idx(iter1),:)),highRes,true,strcat("Free Hand - ", num2str(single_freq(iter1))," Hz Admittance"))
% %     linePlot(angle(fixed_admittance(freq_idx(iter1),:)),highRes,true,strcat("Fixed Hand - ", num2str(single_freq(iter1))," Hz Phase"))
% %     linePlot(angle(free_admittance(freq_idx(iter1),:)),highRes,true,strcat("Free Hand - ", num2str(single_freq(iter1))," Hz Phase"))
% % end
% 
% win_size = 0;
% fixed_admittance = (fixed_admittance(:,2:3:end)+fixed_admittance(:,3:3:end)+fixed_admittance(:,4:3:end))./3;
% % fixed_admittance = fixed_admittance(:,3:3:end);
% free_admittance = (free_admittance(:,2:3:end)+free_admittance(:,3:3:end)+free_admittance(:,4:3:end))./3;
% % free_admittance = free_admittance(:,3:3:end);
% for iter1 = 1:length(single_freq)
%     fixed_phase = angle(fixed_admittance(freq_idx(iter1):freq_idx(iter1)+win_size,:);
% %     fixed_phase = mod(fixed_phase-fixed_phase(:,1)+5,2*pi);
%     fixed_phaseDiff = fixed_phase(:,2:end)-fixed_phase(:,1:end-1);
%     free_phase = angle(free_admittance(freq_idx(iter1):freq_idx(iter1)+win_size,:));
% %     free_phase = mod(free_phase-free_phase(:,1)+5,2*pi);
%     free_phaseDiff = free_phase(:,2:end)-free_phase(:,1:end-1);
% 
%     figure
%     plot(highRes.yCord(4:3:end), fixed_phase,'r');
%     hold on;
%     plot(highRes.yCord(4:3:end), free_phase,'b');
%     hold off;
%     figure
%     semilogy(highRes.yCord(2:3:end), squeeze(abs(fixed_admittance(freq_idx(iter1),:))),'r');
%     hold on;
%     semilogy(highRes.yCord(2:3:end), squeeze(abs(free_admittance(freq_idx(iter1),:))),'b');
% end

%% Actual Model Fitting

% From Literature
waveSpeed_literature = 5*10^3; % Potts
damping_literature = 1/5; % Potts
m_literature = 3*10^-4; % Wiertluski
b_literature = 2; % Wiertluski
k_literature = 2*10^3; % Wiertluski

sampled_freqs = freq(1:freq_downsample:end);
g_fixed(:,:,1) = real(fixed_admittance(1:freq_downsample:end,:));
g_fixed(:,:,2) = imag(fixed_admittance(1:freq_downsample:end,:));
g_free(:,:,1) = real(free_admittance(1:freq_downsample:end,:));
g_free(:,:,2) = imag(free_admittance(1:freq_downsample:end,:));

g_0_fixed = zeros(1,length(sampled_freqs));
wave_speed_fixed = zeros(1,length(sampled_freqs));
damping_fixed = zeros(1,length(sampled_freqs));
error_fixed = zeros(1,length(sampled_freqs));

g_0_free = zeros(1,length(sampled_freqs));
wave_speed_free = zeros(1,length(sampled_freqs));
damping_free = zeros(1,length(sampled_freqs));
error_free = zeros(1,length(sampled_freqs));

%% Modeling contact mechanics


coef_guess = [m_literature, b_literature, k_literature] ;
lb = zeros(1,length(coef_guess)); 
training_data = (abs(g_free(:,1,1)).^2 + abs(g_free(:,1,2)).^2).^.5;
labels_data = sampled_freqs;

% iterations = 10^6;
% options = optimoptions('lsqcurvefit','MaxFunctionEvaluations',iterations);

[fitted_params,resnorm,residuals,exitflag,output] = ...
    lsqcurvefit(@localMechanics,coef_guess,labels_data,training_data,lb);


m_fixed = fitted_params(1);
b_fixed = fitted_params(2);
k_fixed = fitted_params(3);
error_free = resnorm;

positions = linspace(0,pos_data(end),100);
fitted_curve = g_0_free(iter1)*exp(-damping_free(iter1)*positions);

%% Modeling Wave Physics

% for iter1 = 1:length(sampled_freqs)
%     % Predictions
%     omega = 2*pi*sampled_freqs(iter1);
%     g_est = 1000*(omega*1i)/(-m_literature*omega^2+b_literature*omega*1i+k_literature);
% 
%     coef_guess = [damping_literature, waveSpeed_literature];
%     lb = zeros(1,length(coef_guess)); 
%     training_data = squeeze(g_fixed(iter1,2:end,:));
%     labels_data = [omega, g_fixed(iter1,1,1), g_fixed(iter1,1,2), pos_data(2:end)];
% 
%     % iterations = 10^6;
%     % options = optimoptions('lsqcurvefit','MaxFunctionEvaluations',iterations);
% 
%     [fitted_params,resnorm,residuals,exitflag,output] = ...
%         lsqcurvefit(@waveEqn,coef_guess,labels_data,training_data,lb);
% 
%     % g_0(iter1) = fitted_params(1)+fitted_params(2)*1i;
%     g_0(iter1) = (g_fixed(iter1,1,1).^2 + g_fixed(iter1,1,2).^2).^.5;
%     damping(iter1) = fitted_params(1);
%     wave_speed(iter1) = fitted_params(2);
% 
%     positions = linspace(0,pos_data(end),100);
%     fitted_curve = abs(g_0(iter1))*exp(-damping(iter1)*positions);
% 
%     % figure
%     % plot(pos_data(2:end),(training_data(:,1).^2+training_data(:,2).^2).^.5,'r.');
%     % hold on;
%     % plot(positions,fitted_curve,'r');
%     % hold off;
% end
% 
% %% Plot Properties
% window_size = 1;
% 
% figure
% plot(sampled_freqs,movmedian(abs(g_0),window_size))
% hold on;
% 
% figure
% plot(sampled_freqs,movmedian(wave_speed,window_size))
% 
% figure
% plot(sampled_freqs,movmedian(damping,window_size))

for iter1 = 1:length(sampled_freqs)
    % Predictions
    omega = 2*pi*sampled_freqs(iter1);
    g_est = 1000*(omega*1i)/(-m_literature*omega^2+b_literature*omega*1i+k_literature);
    g_0_fixed(iter1) = (abs(g_fixed(iter1,1,1)).^2 + abs(g_fixed(iter1,1,2)).^2).^.5;

    coef_guess = damping_literature;
    lb = zeros(1,length(coef_guess)); 
    training_data = squeeze((abs(g_fixed(iter1,2:end,1)).^2+abs(g_fixed(iter1,2:end,2)).^2).^.5);
    labels_data = [g_0_fixed(iter1), pos_data(2:end)];

    % iterations = 10^6;
    % options = optimoptions('lsqcurvefit','MaxFunctionEvaluations',iterations);

    [fitted_params,resnorm,residuals,exitflag,output] = ...
        lsqcurvefit(@dampingEqn,coef_guess,labels_data,training_data,lb);
    
    % g_0(iter1) = fitted_params(1)+fitted_params(2)*1i;
    
    damping_fixed(iter1) = fitted_params(1);
    error_fixed(iter1) = resnorm;

    positions = linspace(0,pos_data(end),100);
    fitted_curve = g_0_fixed(iter1)*exp(-damping_fixed(iter1)*positions);
    
    % figure
    % plot(pos_data(2:end),training_data,'r.');
    % hold on;
    % plot(positions,fitted_curve,'r');
    % hold off;
end

for iter1 = 1:length(sampled_freqs)
    % Predictions
    omega = 2*pi*sampled_freqs(iter1);
    g_est = 1000*(omega*1i)/(-m_literature*omega^2+b_literature*omega*1i+k_literature);
    g_0_free(iter1) = (abs(g_free(iter1,1,1)).^2 + abs(g_free(iter1,1,2)).^2).^.5;

    coef_guess = damping_literature;
    lb = zeros(1,length(coef_guess)); 
    training_data = squeeze((abs(g_free(iter1,2:end,1)).^2+abs(g_free(iter1,2:end,2)).^2).^.5);
    labels_data = [g_0_free(iter1), pos_data(2:end)];

    % iterations = 10^6;
    % options = optimoptions('lsqcurvefit','MaxFunctionEvaluations',iterations);

    [fitted_params,resnorm,residuals,exitflag,output] = ...
        lsqcurvefit(@dampingEqn,coef_guess,labels_data,training_data,lb);
    
    % g_0(iter1) = fitted_params(1)+fitted_params(2)*1i;
    
    damping_free(iter1) = fitted_params(1);
    error_free(iter1) = resnorm;

    positions = linspace(0,pos_data(end),100);
    fitted_curve = g_0_free(iter1)*exp(-damping_free(iter1)*positions);
    
    % figure
    % plot(pos_data(2:end),training_data,'r.');
    % hold on;
    % plot(positions,fitted_curve,'r');
    % hold off;
end

%% Plot Properties
window_size = 1;

figure
plot(sampled_freqs,movmedian(abs(g_0_fixed),window_size))
hold on;
plot(sampled_freqs,movmedian(abs(g_0_free),window_size))

figure
plot(sampled_freqs,movmedian(damping_fixed,window_size))
hold on;
plot(sampled_freqs,movmedian(damping_free,window_size))
hold off;

figure
plot(sampled_freqs,movmedian(error_fixed,window_size))
hold on;
plot(sampled_freqs,movmedian(error_free,window_size))
hold off;


%% Model

function g_out = waveEqn(coef,xdata)
    omega = xdata(1);
    g_0 = xdata(2) + xdata(3)*1i;
    position = xdata(4:end);
    pos_len = length(position);

    g_out = zeros(pos_len,2);
    for iter1 = 1:pos_len
        x = position(iter1);
        amp = exp(-x*coef(1));
        phase = -omega*x/coef(2);
        transform = amp*cos(phase)+amp*sin(phase)*1i;
        g_complex = g_0*transform;
        g_out(iter1,1) = real(g_complex);
        g_out(iter1,2) = imag(g_complex);
    end
end

function g_out = dampingEqn(coef,xdata)
    amp_0 = xdata(1);
    position = xdata(2:end);
    pos_len = length(position);

    g_out = zeros(1,pos_len);
    for iter1 = 1:pos_len
        x = position(iter1);
        g_out(iter1) = amp_0*exp(-x*coef(1));
    end
end

function g_out = localMechanics(coef,xdata)
    omega = xdata;
    g_out = abs(1000.*(omega.*1i)./(-ceof(1).*omega.^2+coef(2).*omega.*1i+coef(3)));
end
