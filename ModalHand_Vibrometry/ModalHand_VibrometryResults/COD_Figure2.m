clc; clear; close all;

%% Load Data

current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
addpath("Functions\");
highRes = load("HighRes_ProcessedData.mat");

%% Params
kernal = 3;
fs = 2500;
include_probe = false;
hand_condition = "Free";
num_modes = 3;
gif = false;

%% Generate Input Matrix

% Create ensemble matrix from IRs
if strcmp(hand_condition,"Free")
    original_fft = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
    input_ensemble = zeros(length(highRes.free_ir{1}),length(highRes.yCord)-not(include_probe));
    for iter1 = 1:(length(highRes.yCord)-not(include_probe))
        pos_idx = iter1 + not(include_probe);
        original_fft(:,iter1) = highRes.free_tf{pos_idx};
        input_signal = highRes.free_ir{pos_idx};
        input_ensemble(:,iter1) = input_signal- mean(input_signal);
    end
end
if strcmp(hand_condition,"Fixed")
    original_fft = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
    input_ensemble = zeros(length(highRes.fixed_ir{1}),length(highRes.yCord)-not(include_probe));
    for iter1 = 1:(length(highRes.yCord)-not(include_probe))
        pos_idx = iter1 + not(include_probe);
        original_fft(:,iter1) = highRes.fixed_tf{pos_idx};
        input_signal = highRes.fixed_ir{pos_idx};
        input_ensemble(:,iter1) = input_signal- mean(input_signal);
    end
end

% Take hilbert transform of each time-domain signal
for iter1 = 1:size(input_ensemble,2)
    input_ensemble(:,iter1) = hilbert(input_ensemble(:,iter1));
end

%% SVD

% Compute Eigenvalues and Eigenvectors
[U, S, V] = svd(input_ensemble.');

% Trim Number of Modes
S = diag(S(1:size(input_ensemble,2),1:size(input_ensemble,2)));

V = V';

%% Decompose Data Set

% Break COMs into standing and traveling components
standing_component= zeros(size(U,1),num_modes(1));
travelling_component = zeros(size(U,1),num_modes(1));
for iter1 = 1:num_modes
    c = real(U(:,iter1));
    d = imag(U(:,iter1));
    d_s = c*dot(d,c/norm(c))/norm(c);
    d_t = d-d_s;
    c_t = norm(d_t)*c/norm(c);
    c_s = c - c_t;
    standing_component(:,iter1) = c_s + 1i * d_s;
    travelling_component(:,iter1) = c_t + 1i * d_t;
end

% Reconstruct Data set from first n modes
standing_reconstruct = zeros(size(input_ensemble,1),size(input_ensemble,2));
travelling_reconstruct = zeros(size(input_ensemble,1),size(input_ensemble,2));
for iter1 = 1:max(num_modes)
    standing_reconstruct = standing_reconstruct + (standing_component(:,iter1)*S(iter1)*V(iter1,:)).';
    travelling_reconstruct = travelling_reconstruct + (travelling_component(:,iter1)*S(iter1)*V(iter1,:)).';
end

standing_reconstruct = real(standing_reconstruct);
travelling_reconstruct = real(travelling_reconstruct);
combined_reconstruct = real(travelling_reconstruct+standing_reconstruct);

% Compute FFT of each component
standing_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(standing_reconstruct,1)/2)+2)';
travelling_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(travelling_reconstruct,1)/2)+2)';
combined_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(combined_reconstruct,1)/2)+2)';
for iter1 = 1:length(highRes.yCord)-not(include_probe)
    [reconstruct_freq,standing_fft(:,iter1)] = fft_spectral(standing_reconstruct(:,iter1).',fs);
    [~,travelling_fft(:,iter1)] = fft_spectral(travelling_reconstruct(:,iter1).',fs);
    [~,combined_fft(:,iter1)] = fft_spectral(combined_reconstruct(:,iter1).',fs);
end
standing_fft = standing_fft * size(standing_reconstruct,1)/2;
travelling_fft = travelling_fft * size(travelling_reconstruct,1)/2;
combined_fft = combined_fft * size(combined_reconstruct,1)/2;

% Plot Data Set Deconstruction
unwrappedAdmittance(highRes.freq,highRes,original_fft,kernal,include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,standing_fft,kernal,include_probe);
saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_StandingUnwrapped"),'tiffn')
unwrappedAdmittance(reconstruct_freq,highRes,travelling_fft,kernal,include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,combined_fft,kernal,include_probe);

%% Plot COVs

% Compute traveling index from condition number
travelling_index = zeros(1,num_modes);
for iter1 = 1:num_modes
    travelling_index(iter1) = 1/cond([real(U(:,iter1))'; imag(U(:,iter1))']);
end

% Contribution Bar Chart
bars = [1-travelling_index',travelling_index'].*repmat(100*S(1:num_modes).^2./sum(S.^2),[1,2]);
figure;
b = bar(bars,'stacked');
set(b,'FaceColor','Flat')
b(1).CData = [0.5 0.5 0.5];
b(2).CData = [1 1 1];
ylim([0,100])
saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_COVs"),'epsc')

%% Plot Modal Coordinates
figure;
for iter1 = 1:num_modes
    [mc_freq, modal_coordinates] = fft_spectral(real(V(iter1,:)),fs);
    freq_idx = find(and(mc_freq>=15,mc_freq<=400));
    centroid = sum(abs(modal_coordinates(freq_idx)).*mc_freq(freq_idx))./sum(abs(modal_coordinates(freq_idx)));
    disp(strcat("Mode ", num2str(iter1), " Centroid: ", num2str(round(centroid))," Hz"));
    freq_up = linspace(mc_freq(1),mc_freq(end),1000);
    plot(freq_up,csapi(mc_freq,movmean(20*log10(abs(modal_coordinates)),kernal)-max(movmean(20*log10(abs(modal_coordinates)),kernal)),freq_up));
    hold on;
end
xlim([15,400])
ylim([-30, 1])
hold off;
saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_ModalCoordinates"),'epsc')

figure;
contribution_t = zeros(floor(size(V,2)/2)+2,num_modes);
for iter1 = 1:num_modes
    [mc_freq, modal_coordinates] = fft_spectral(travelling_index(iter1)*S(iter1)*real(V(iter1,:)),fs);
    freq_idx = find(and(mc_freq>=15,mc_freq<=400));
    contribution_t(:,iter1) = abs(modal_coordinates);
    freq_up = linspace(mc_freq(1),mc_freq(end),1000);
    plot(freq_up,csapi(mc_freq,movmean(20*log10(contribution_t(:,iter1)),kernal),freq_up));
    hold on;
end
xlim([15,400])
hold off;

figure;
contribution_s = zeros(floor(size(V,2)/2)+2,num_modes);
for iter1 = 1:num_modes
    [mc_freq, modal_coordinates] = fft_spectral((1-travelling_index(iter1))*S(iter1)*real(V(iter1,:)),fs);
    freq_idx = find(and(mc_freq>=15,mc_freq<=400));
    contribution_s(:,iter1) = abs(modal_coordinates);
    freq_up = linspace(mc_freq(1),mc_freq(end),1000);
    plot(freq_up,csapi(mc_freq,movmean(20*log10(contribution_s(:,iter1)),kernal),freq_up));
    hold on;
end
xlim([15,400])
hold off;

figure;
plot(freq_up,csapi(mc_freq,movmean(20*log10(sum(contribution_s,2)./sum(contribution_t,2)),kernal),freq_up));
xlim([15,400])
ylim([-4,8]);
hold off;
saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_StandingContribution"),'epsc')

%% Time Domain

% Plot Input Signal
t = (0:(730-330))/fs;
t_up = (0:0.001:(730-330))/fs;
t_zero = t(ceil((size(V,2)+1)/2)-330+1);
samp_idx = 31+5*(1:10);
impulse = zeros(1,size(V,2));
impulse(ceil(length(impulse)/2)) = 1;
bandpass = [10, 1000];
band_filt = designfilt('bandpassfir', 'FilterOrder', round(length(impulse)/3)-1, ...
         'CutoffFrequency1', bandpass(1), 'CutoffFrequency2', bandpass(2),...
         'SampleRate', fs);
impulse = filtfilt(band_filt,impulse);
impulse_up = spline(t,impulse(330:730),t_up);
figure;
plot(t_up-t_zero,impulse_up);
hold on;
plot(t(samp_idx)-t_zero,impulse(329+samp_idx),'.');
hold off;
saveas(gcf,strcat("MATLAB_Figs/","Impulse"),'epsc')


% Plot modal coordinates
for iter1 = 1:num_modes
    figure;
    signal = -movmean(real(V(iter1,330:730)),kernal);
    plot(t-t_zero,signal);
    hold on;
    plot(t(samp_idx)-t_zero,signal(samp_idx),'.');
    hold off;
    saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Mode",num2str(iter1),"_Coordinates"),'epsc')
end

%% Plot Individual Standing Modes
%Plot RMS amplitude
disp(strcat("DIP: ", num2str(highRes.yDIP)," mm"));
disp(strcat("MCP: ", num2str(highRes.yMCP)," mm"));
position = highRes.yCord(2-include_probe:3:end);
for iter1 = 1:num_modes
    rms_s = rms((standing_component(:,iter1)*S(iter1)*V(iter1,:))',1);
    rms_t = rms((travelling_component(:,iter1)*S(iter1)*V(iter1,:))',1);

    s_lim = [0, max(rms_s)];
    t_lim = [0, max(rms_t)];

    surfPlot(rms_s,kernal,highRes,s_lim,turbo,strcat("RMS - Standing ", num2str(iter1)),false,include_probe);
    surfPlot(rms_t,kernal,highRes,t_lim,turbo,strcat("RMS - Travelling ", num2str(iter1)),false,include_probe);
end

% % Plot frames of impulse modes
% color_map = colorcet('COOLWARM');
% mag_lim = max(abs(real(input_ensemble)),[],"all");
% disp(strcat("Impulse Response Magnitude: ", num2str(round(mag_lim,1))));
% for iter2 = 1:10
%     time_frame = real(input_ensemble(360+(iter2)*5,:));
%     surfPlot(time_frame,kernal,highRes,[-mag_lim, mag_lim],color_map,strcat("Impulse Response - Frame ", num2str(iter2)),false,include_probe);
%     saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_WholeResponse",num2str(iter1),"_t",num2str(iter2-1)),'tiffn')
% end    
% 
% % Plot frames of standing modes
% for iter1 = 1:num_modes
%     single_mode = standing_component(:,iter1)*S(iter1)*V(iter1,:);
%     mag_lim = max(abs(real(single_mode)),[],"all");
%     disp(strcat("Mode ", num2str(iter1), " Standing Magnitude: ", num2str(round(mag_lim,1))));
%     for iter2 = 1:10
%         time_frame = real(single_mode(:,360+(iter2)*5))';
%         surfPlot(time_frame,kernal,highRes,[-mag_lim, mag_lim],color_map,strcat("Standing Mode ",num2str(iter1), "- Frame ", num2str(iter2)),false,include_probe);
%         saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Standing_Mode",num2str(iter1),"_t",num2str(iter2-1)),'tiffn')
%     end    
% end
% 
% % Plot frames of travelling modes
% for iter1 = 1:num_modes
%     single_mode = travelling_component(:,iter1)*S(iter1)*V(iter1,:);
%     mag_lim = max(abs(real(single_mode)),[],"all");
%     disp(strcat("Mode ", num2str(iter1), " Travelling Magnitude: ", num2str(round(mag_lim,1))));
%     for iter2 = 1:10
%         time_frame = real(single_mode(:,360+(iter2)*5))';
%         surfPlot(time_frame,kernal,highRes,[-mag_lim, mag_lim],color_map,strcat("Travelling Mode ",num2str(iter1), "- Frame ", num2str(iter2)),false,include_probe);
%         saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Travelling_Mode",num2str(iter1),"_t",num2str(iter2-1)),'tiffn')
%     end
% end

% Zero Crossings
zcs_3 = zeros(2,num_modes,3,15,410-365+1);
for iter1 = 1:num_modes
    single_mode = standing_component(:,iter1)*S(iter1)*V(iter1,:);
    for iter2 = 365:410
        for iter3 = 1:3
            single_axis = real(single_mode(include_probe+iter3:3:end,iter2))';
            % single_axis = singleAxis(real(single_mode(:,iter2))',include_probe);
            crossing_idx=zeroCrossings(single_axis,0,5);
            for iter4 = 1:length(crossing_idx)
                crossing_slope=(single_axis(crossing_idx(iter4)+1)-single_axis(crossing_idx(iter4)))./(position(crossing_idx(iter4)+1)-position(crossing_idx(iter4)));
                crossing=-single_axis(crossing_idx(iter4))./crossing_slope+position(crossing_idx(iter4));
                zcs_3(1,iter1,iter3,iter4,iter2-365+1) = crossing;
            end
        end
    end
end
for iter1 = 1:num_modes
    single_mode = travelling_component(:,iter1)*S(iter1)*V(iter1,:);
    for iter2 = 365:410
        for iter3 = 1:3
            single_axis = real(single_mode(include_probe+iter3:3:end,iter2))';
            % single_axis = singleAxis(real(single_mode(:,iter2))',include_probe);
            crossing_idx=zeroCrossings(single_axis,0,5);
            for iter4 = 1:length(crossing_idx)
                crossing_slope=(single_axis(crossing_idx(iter4)+1)-single_axis(crossing_idx(iter4)))./(position(crossing_idx(iter4)+1)-position(crossing_idx(iter4)));
                crossing=-single_axis(crossing_idx(iter4))./crossing_slope+position(crossing_idx(iter4));
                zcs_3(2,iter1,iter3,iter4,iter2-365+1) = crossing;
            end
        end
    end
end

zcs_1 = zeros(2,num_modes,3,15,410-365+1);
for iter1 = 1:num_modes
    single_mode = standing_component(:,iter1)*S(iter1)*V(iter1,:);
    for iter2 = 365:410
        for iter3 = 1:3
            single_axis = real(single_mode(include_probe+iter3:3:end,iter2))';
            % single_axis = singleAxis(real(single_mode(:,iter2))',include_probe);
            crossing_idx=zeroCrossings(single_axis,0,1);
            for iter4 = 1:length(crossing_idx)
                crossing_slope=(single_axis(crossing_idx(iter4)+1)-single_axis(crossing_idx(iter4)))./(position(crossing_idx(iter4)+1)-position(crossing_idx(iter4)));
                crossing=-single_axis(crossing_idx(iter4))./crossing_slope+position(crossing_idx(iter4));
                zcs_1(1,iter1,iter3,iter4,iter2-365+1) = crossing;
            end
        end
    end
end
for iter1 = 1:num_modes
    single_mode = travelling_component(:,iter1)*S(iter1)*V(iter1,:);
    for iter2 = 365:410
        for iter3 = 1:3
            single_axis = real(single_mode(include_probe+iter3:3:end,iter2))';
            % single_axis = singleAxis(real(single_mode(:,iter2))',include_probe);
            crossing_idx=zeroCrossings(single_axis,0,1);
            for iter4 = 1:length(crossing_idx)
                crossing_slope=(single_axis(crossing_idx(iter4)+1)-single_axis(crossing_idx(iter4)))./(position(crossing_idx(iter4)+1)-position(crossing_idx(iter4)));
                crossing=-single_axis(crossing_idx(iter4))./crossing_slope+position(crossing_idx(iter4));
                zcs_1(2,iter1,iter3,iter4,iter2-365+1) = crossing;
            end
        end
    end
end

color_map = colormap(winter(3));
for iter1 = 1:size(zcs_3,1)
    for iter2 = 1:size(zcs_3,2)
        figure;
        for iter3 = 1:size(zcs_3,3)
            for iter4 = 1:size(zcs_3,4)
                for iter5 = 1:size(zcs_3,5)
                    plot(iter5,zcs_3(iter1,iter2,iter3,iter4,iter5),'.','Color',color_map(iter3,:))
                    hold on;
                    if mod(iter5,5) == 1
                        plot(iter5,zcs_1(iter1,iter2,iter3,1,iter5),'o','Color',color_map(iter3,:))
                    end
                    hold on;
                end
            end
        end
        hold off;
    end
end

color_map = colormap(winter(3));
for iter1 = 1:size(zcs_3,1)
    for iter2 = 1:size(zcs_3,2)
        iter0 = 0;
        for iter5 = 1:size(zcs_3,5)
            if mod(iter5,5) == 1
                figure;
                yline(highRes.yCord(2))
                yline(median(squeeze(zcs_1(iter1,iter2,:,1,iter5))))
                yline(highRes.yCord(end))
                if iter1 == 1
                    saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Standing_ZeroCrossing_Mode",num2str(iter2),"_t",num2str(iter0)),'epsc')
                end
                if iter1 == 2
                    saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Travelling_ZeroCrossing_Mode",num2str(iter2),"_t",num2str(iter0)),'epsc')
                end
                iter0 = iter0+1;
            end
        end
    end
end

% Generate GIFs
if gif
    for iter1 = 1:num_modes
        mode = (standing_component(:,iter1)*S(iter1)*V(iter1,:)).';
        for iter2 = 350:1:600
            limit = max(abs(real(mode)),[],"all");
            gifPlot(real(mode(iter2,:)),1,highRes,[-limit,limit],colorcet('COOLWARM'),strcat("Standing Mode ",num2str(iter1)),include_probe)
        end
    end
end