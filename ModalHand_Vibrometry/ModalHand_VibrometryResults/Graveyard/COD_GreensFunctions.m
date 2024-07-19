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
num_modes = [3, 1];
num_display = 3;
gif = true;

%% Generate Input Matrix

% Create input matrices from IRs
fixed_input = zeros(length(highRes.fixed_ir{1}),length(highRes.yCord)-not(include_probe));
free_input = zeros(length(highRes.free_ir{1}),length(highRes.yCord)-not(include_probe));
for iter1 = 1:(length(highRes.yCord)-not(include_probe))
    pos_idx = iter1 + not(include_probe);
    fixed_signal = highRes.fixed_ir{pos_idx};
    free_signal = highRes.free_ir{pos_idx};
    fixed_input(:,iter1) = fixed_signal - mean(fixed_signal);
    free_input(:,iter1) = free_signal- mean(free_signal);
end

% Take hilbert transform of each time-domain signal
for iter1 = 1:size(fixed_input,2)
    fixed_input(:,iter1) = hilbert(fixed_input(:,iter1));
    free_input(:,iter1) = hilbert(free_input(:,iter1));
end

%% SVD

% Compute Eigenvalues and Eigenvectors
[U_free, S_free, V_free] = svd(free_input.');
[U_fixed, S_fixed, V_fixed] = svd(fixed_input.');

% Trim Number of Modes
S_free = diag(S_free(1:size(free_input,2),1:size(free_input,2)));
S_fixed = diag(S_fixed(1:size(fixed_input,2),1:size(fixed_input,2)));

V_free = V_free';
V_fixed = V_fixed';

%% Decompose Data Set

% Break COMs into standing and traveling components
free_s= zeros(size(U_free,1),num_modes(1));
free_t = zeros(size(U_free,1),num_modes(1));
fixed_s = zeros(size(U_fixed,1),num_modes(2));
fixed_t = zeros(size(U_fixed,1),num_modes(2));
for iter1 = 1:num_display
    c = real(U_free(:,iter1));
    d = imag(U_free(:,iter1));
    d_s = c*dot(d,c/norm(c))/norm(c);
    d_t = d-d_s;
    c_t = norm(d_t)*c/norm(c);
    c_s = c - c_t;
    free_s(:,iter1) = c_s + 1i * d_s;
    free_t(:,iter1) = c_t + 1i * d_t;

    c = real(U_fixed(:,iter1));
    d = imag(U_fixed(:,iter1));
    d_s = c*dot(d,c/norm(c))/norm(c);
    d_t = d-d_s;
    c_t = norm(d_t)*c/norm(c);
    c_s = c - c_t;
    fixed_s(:,iter1) = c_s + 1i * d_s;
    fixed_t(:,iter1) = c_t + 1i * d_t;
end

% Reconstruct data set from standing and traveling components
free_standing = zeros(size(free_input,1),size(free_input,2));
free_traveling = zeros(size(free_input,1),size(free_input,2));
fixed_standing = zeros(size(fixed_input,1),size(fixed_input,2));
fixed_traveling = zeros(size(fixed_input,1),size(fixed_input,2));
for iter1 = 1:max(num_modes)
    if iter1<=num_modes(1)
        free_standing = free_standing + (free_s(:,iter1)*S_free(iter1)*V_free(iter1,:)).';
        free_traveling = free_traveling + (free_t(:,iter1)*S_free(iter1)*V_free(iter1,:)).';
    end
    if iter1<=num_modes(2)
        fixed_standing = fixed_standing + (fixed_s(:,iter1)*S_fixed(iter1)*V_fixed(iter1,:)).';
        fixed_traveling = fixed_traveling + (fixed_t(:,iter1)*S_fixed(iter1)*V_fixed(iter1,:)).';
    end
end

free_reconstruct = real(free_standing + fixed_input);
free_remainder = real(free_input-free_standing);
free_standing = real(free_standing);

% Compute FFT of each component
free_remainder_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_remainder,1)/2)+2)';
free_standing_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_standing,1)/2)+2)';
free_reconstruct_fft  = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_traveling,1)/2)+2)';
for iter1 = 1:length(highRes.yCord)-not(include_probe)
    [reconstruct_freq,free_standing_fft(:,iter1)] = fft_spectral(free_standing(:,iter1).',fs);
    [~,free_reconstruct_fft(:,iter1)] = fft_spectral(free_reconstruct(:,iter1).',fs);
    [~,free_remainder_fft(:,iter1)] = fft_spectral(free_remainder(:,iter1).',fs);
end
free_standing_fft = free_standing_fft * size(free_standing,1)/2;
free_reconstruct_fft = free_reconstruct_fft * size(free_reconstruct,1)/2;
free_remainder_fft = free_remainder_fft * size(free_remainder,1)/2;

% Load raw data set
fixed_original = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
free_original = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
for iter1 = 1:length(highRes.yCord)-not(include_probe)
    pos_idx = iter1 + not(include_probe);
    fixed_original(:,iter1) = highRes.fixed_tf{pos_idx};
    free_original(:,iter1) =  highRes.free_tf{pos_idx};
end

% Plot Data Set Deconstruction
unwrappedAdmittance(reconstruct_freq,highRes,free_standing_fft,kernal,include_probe);
title("Free - Standing Components")
unwrappedAdmittance(reconstruct_freq,highRes,free_remainder_fft,kernal,include_probe);
title("Free - Remaining (Non-standing) Components")
unwrappedAdmittance(highRes.freq,highRes,fixed_original,kernal,include_probe);
title("Fixed - Original Data")
unwrappedAdmittance(reconstruct_freq,highRes,free_reconstruct_fft,kernal,include_probe);
title("Free Standing + Fixed Original")
unwrappedAdmittance(highRes.freq,highRes,free_original,kernal,include_probe);
title("Free - Original Data")

% Plot RMS amplitude
for iter1 = 1:num_modes(1)
    rms_s = rms((free_s(:,iter1)*S_free(iter1)*V_free(iter1,:))',1);
    rms_t = rms((free_t(:,iter1)*S_free(iter1)*V_free(iter1,:))',1);
    
    surfPlot(rms_s,kernal,highRes,[log10(min(rms_s)), log10(max(rms_s))],turbo,strcat("RMS - Standing ", num2str(iter1)),true,include_probe);
    surfPlot(rms_t,kernal,highRes,[log10(min(rms_t)), log10(max(rms_t))],turbo,strcat("RMS - Travelling ", num2str(iter1)),true,include_probe);
end

%% GIFs
% if gif
%     for iter1 = 1:3%num_modes(1)
%         mode = (free_s(:,iter1)*S_free(iter1)*V_free(iter1,:)).';
%         for iter2 = 350:1:600
%             limit = max(abs(real(mode)),[],"all");
%             gifPlot(real(mode(iter2,:)),1,highRes,[-limit,limit],colorcet('COOLWARM'),strcat("Standing Mode ",num2str(iter1)),include_probe)
%         end
%     end
% end

% if gif
%     for iter1 = 1:3%num_modes(1)
%         mode = (free_t(:,iter1)*S_free(iter1)*V_free(iter1,:)).';
%         for iter2 = 350:1:600
%             limit = max(abs(real(mode)),[],"all");
%             gifPlot(real(mode(iter2,:)),1,highRes,[-limit,limit],colorcet('COOLWARM'),strcat("Travelling Mode ",num2str(iter1)),include_probe)
%         end
%     end
% end

% if gif
%     for iter1 = 1:1
%         mode = (fixed_s(:,iter1)*S_fixed(iter1)*V_fixed(iter1,:)).';
%         for iter2 = 350:1:600
%             limit = max(abs(real(mode)),[],"all");
%             gifPlot(real(mode(iter2,:)),1,highRes,[-limit,limit],colorcet('COOLWARM'),strcat("Fixed Standing Mode ",num2str(iter1)),include_probe)
%         end
%     end
% end

%% Pearson Correlations
mode_corr = zeros(1,size(free_original,1));
fixed_corr = zeros(1,size(free_original,1));
reconstruct_corr = zeros(1,size(free_original,1));
for iter1 = 1:size(free_original,1)
    coef = corrcoef(singleAxis(log10(abs(free_original(iter1,:))),include_probe), singleAxis(log10(abs(free_standing_fft(iter1,:))),include_probe));
    mode_corr(iter1) = coef(1,2);
    coef = corrcoef(singleAxis(log10(abs(free_original(iter1,:))),include_probe), singleAxis(log10(abs(fixed_original(iter1,:))),include_probe));
    fixed_corr(iter1) = coef(1,2);
    coef = corrcoef(singleAxis(log10(abs(free_original(iter1,:))),include_probe), singleAxis(log10(abs(free_reconstruct_fft(iter1,:))),include_probe));
    reconstruct_corr(iter1) = coef(1,2);
end

% Change NAN value to zero (no data in this bin anyway)
reconstruct_corr(1) = 0;

% Plot correlation values
figure;
freq_up = linspace(highRes.freq(1),highRes.freq(end),1000);
plot(freq_up,csapi(highRes.freq,movmean(mode_corr,kernal),freq_up));
hold on;
plot(freq_up,csapi(highRes.freq,movmean(fixed_corr,kernal),freq_up));
plot(freq_up,csapi(highRes.freq,movmean(reconstruct_corr,kernal),freq_up));
hold off;
xlim([15,400])
ylim([.6,1])
title("Correlation with Original Free Data Set")
legend(["Free (Standing Modes)", "Fixed Set", "Combined"])
ylabel("Pearson Correlation")

%% Plot COVs and Traveling Index

% Compute traveling index from condition number
free_index = zeros(1,num_display);
fixed_index = zeros(1,num_display);
for iter1 = 1:num_display
    free_index(iter1) = 1/cond([real(U_free(:,iter1))'; imag(U_free(:,iter1))']);
end

% Plot traveling indices
figure;
b = bar(free_index,'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
ylim([0,1])
title("Travelling Index (Free)")

% Plot COVs
figure;
b = bar(100*S_free(1:num_display).^2./sum(S_free.^2),'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
ylim([0,100])
title("Relative Energy (Free)")

%% Plot Modal Coordinates
figure;
for iter1 = 1:num_display
    [mc_freq, modal_coordinates] = fft_spectral(real(V_free(iter1,:)),fs);
    freq_idx = find(and(mc_freq>=15,mc_freq<=400));
    centroid = sum(abs(modal_coordinates(freq_idx)).*mc_freq(freq_idx))./sum(abs(modal_coordinates(freq_idx)));
    disp(strcat("Centroid for Mode ",num2str(iter1),": ",num2str(round(centroid))," Hz"));
    freq_up = linspace(mc_freq(1),mc_freq(end),1000);
    plot(freq_up,csapi(mc_freq,movmean(20*log10(abs(modal_coordinates)),kernal)-max(movmean(20*log10(abs(modal_coordinates)),kernal)),freq_up));
    hold on;
end
xlim([15,400])
ylim([-30, 1])
hold off;
title("Normailized Modal Coordinates (Free)")
legend(["Mode 1", "Mode 2", "Mode 3"]);

figure;
for iter1 = 1:num_display
    [mc_freq, modal_coordinates] = fft_spectral(free_index(iter1)*S_free(iter1)*real(V_free(iter1,:)),fs);
    freq_idx = find(and(mc_freq>=15,mc_freq<=400));
    contribution_t(:,iter1) = abs(modal_coordinates);
    freq_up = linspace(mc_freq(1),mc_freq(end),1000);
    plot(freq_up,csapi(mc_freq,movmean(10*log10(contribution_t(:,iter1)),kernal),freq_up));
    hold on;
end
xlim([15,400])
hold off;
title("Travelling Contribution to Modal Coordinates (Free)")
legend(["Mode 1", "Mode 2", "Mode 3"]);

figure;
for iter1 = 1:num_display
    [mc_freq, modal_coordinates] = fft_spectral((1-free_index(iter1))*S_free(iter1)*real(V_free(iter1,:)),fs);
    freq_idx = find(and(mc_freq>=15,mc_freq<=400));
    contribution_s(:,iter1) = abs(modal_coordinates);
    freq_up = linspace(mc_freq(1),mc_freq(end),1000);
    plot(freq_up,csapi(mc_freq,movmean(10*log10(contribution_s(:,iter1)),kernal),freq_up));
    hold on;
end
xlim([15,400])
hold off;
title("Standing Contribution to Modal Coordinates (Free)")
legend(["Mode 1", "Mode 2", "Mode 3"]);

figure;
plot(freq_up,csapi(mc_freq,movmean(10*log10(sum(contribution_s,2)./sum(contribution_t,2)),kernal),freq_up));
% hold on;
% plot(freq_up,csapi(mc_freq,movmean(20*log10(sum(contribution_s,2)),kernal),freq_up));
xlim([15,400])
hold off;
title("Standing Relative to Travelling Contribution (Free)")

%% Time Domain

% Plot Input Signal
t = (0:(730-330))/fs;
t_up = (0:0.001:(730-330))/fs;
t_zero = t(ceil((size(V_free,2)+1)/2)-330+1);
samp_idx = 31+5*(1:10);
impulse = zeros(1,size(V_free,2));
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


% Plot modal coordinates
for iter1 = 1:num_display
    figure;
    signal = -movmean(real(V_free(iter1,330:730)),kernal);
    plot(t-t_zero,signal);
    hold on;
    plot(t(samp_idx)-t_zero,signal(samp_idx),'.');
    hold off;
end

%% Plot Individual Standing Modes
color_map = colorcet('COOLWARM');
position = highRes.yCord(2-include_probe:3:end);
disp(strcat("DIP Location: ",num2str(highRes.yDIP)))
disp(strcat("MCP Location: ",num2str(highRes.yMCP)))
for iter1 = 1:num_display
    single_axis = singleAxis(real(free_s(:,iter1))',include_probe);
    crossing_idx=find(single_axis(1:end-1).*single_axis(2:end)<0);
    crossing_slope=(single_axis(crossing_idx(1)+1)-single_axis(crossing_idx(1)))./(position(crossing_idx(1)+1)-position(crossing_idx(1)));
    crossing=-single_axis(crossing_idx(1))./crossing_slope+position(crossing_idx(1));
    disp(strcat("Zero Crossing for Mode ", num2str(iter1),": ", num2str(round(crossing))))
    mag_lim = max(abs(real(free_s(:,iter1))));
    mode_sign = sign(real(free_s(1,iter1)));
    surfPlot(mode_sign*real(free_s(:,iter1))',kernal,highRes,[-mag_lim, mag_lim],color_map,strcat("Standing Real - Free ",num2str(iter1)),false,include_probe);
end

% Plot frames
color_map = colorcet('COOLWARM');
position = highRes.yCord(2-include_probe:3:end);
for iter1 = 1:num_display
    single_mode = free_s(:,iter1)*S_free(iter1)*V_free(iter1,:);
    mag_lim = max(abs(real(single_mode)),[],"all");
    for iter2 = 1:10
        time_frame = real(single_mode(:,360+(iter2)*5))';
        surfPlot(time_frame,kernal,highRes,[-mag_lim, mag_lim],color_map,strcat("Standing Mode ",num2str(iter1), " - Frame ", num2str(iter2)),false,include_probe);
    end    
end