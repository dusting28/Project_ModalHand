clc; clear; close all;

%% Load Data
current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
addpath("Functions\");
highRes = load("HighRes_ProcessedData.mat");

%% Params
fs = 2500;
include_probe = false;
num_modes = [3, 3];
num_display = 3;

%% Generate Input Matrix
% Create input matrices from IRs
fixed_input = zeros(length(highRes.fixed_ir{1}),length(highRes.yCord)-not(include_probe));
free_input = zeros(length(highRes.free_ir{1}),length(highRes.yCord)-not(include_probe));
for iter1 = 1:(length(highRes.yCord)-not(include_probe))
    pos_idx = iter1 + not(include_probe);
    fixed_input(:,iter1) = highRes.fixed_ir{pos_idx} - mean(highRes.fixed_ir{pos_idx});
    free_input(:,iter1) = highRes.free_ir{pos_idx} - mean(highRes.free_ir{pos_idx});
end

%% SVD to Conduct POD
% Compute Eigenvalues and Eigenvectors
[U_free, S_free, V_free] = svd(free_input.');
[U_fixed, S_fixed, V_fixed] = svd(fixed_input.');

% POVs
S_free = diag(S_free(1:size(free_input,2),1:size(free_input,2)));
S_fixed = diag(S_fixed(1:size(fixed_input,2),1:size(fixed_input,2)));

V_free = V_free';
V_fixed = V_fixed';

%% Reconstruct Data Set from POMs
free_modes = zeros(size(free_input,1),size(free_input,2));
fixed_modes = zeros(size(fixed_input,1),size(fixed_input,2));
for iter1 = 1:max(num_modes)
    if iter1 <= num_modes(1) 
        free_modes = free_modes + (U_free(:,iter1)*S_free(iter1)*V_free(iter1,:)).';
    end
    if iter1 <= num_modes(2)
        fixed_modes = fixed_modes + (U_fixed(:,iter1)*S_fixed(iter1)*V_fixed(iter1,:)).';
    end
end

free_reconstruct = free_modes + fixed_input;
free_remainder = free_input - free_modes;

% Compute FFT of each component
free_modes_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_modes,1)/2)+2)';
free_remainder_fft  = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_remainder,1)/2)+2)';
free_reconstruct_fft  = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_reconstruct,1)/2)+2)';
for iter1 = 1:length(highRes.yCord)-not(include_probe)
    [reconstruct_freq,free_modes_fft(:,iter1)] = fft_spectral(free_modes(:,iter1).',fs);
    [~,free_remainder_fft(:,iter1)] = fft_spectral(free_remainder(:,iter1).',fs);
    [~,free_reconstruct_fft(:,iter1)] = fft_spectral(free_reconstruct(:,iter1).',fs);
end

free_modes_fft = free_modes_fft * size(free_modes,1)/2;
free_remainder_fft = free_remainder_fft * size(free_remainder,1)/2;
free_reconstruct_fft = free_reconstruct_fft * size(free_reconstruct,1)/2;

% Load raw data set
fixed_original = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
free_original = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
for iter1 = 1:length(highRes.yCord)-not(include_probe)
    pos_idx = iter1 + not(include_probe);
    fixed_original(:,iter1) = highRes.fixed_tf{pos_idx};
    free_original(:,iter1) =  highRes.free_tf{pos_idx};
end

% Plot reconstructed data set deconstruction
unwrappedAdmittance(reconstruct_freq,highRes,free_modes_fft,include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,free_remainder_fft,include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,free_reconstruct_fft,include_probe);
unwrappedAdmittance(highRes.freq,highRes,fixed_original,include_probe);
unwrappedAdmittance(highRes.freq,highRes,free_original,include_probe);

%% Pearson Correlations
mode_corr = zeros(1,size(free_original,1));
fixed_corr = zeros(1,size(free_original,1));
reconstruct_corr = zeros(1,size(free_original,1));
for iter1 = 1:size(free_original,1)
    coef = corrcoef(singleAxis(log10(abs(free_original(iter1,:))),include_probe), singleAxis(log10(abs(free_modes_fft(iter1,:))),include_probe));
    mode_corr(iter1) = coef(1,2);
    coef = corrcoef(singleAxis(log10(abs(free_original(iter1,:))),include_probe), singleAxis(log10(abs(fixed_original(iter1,:))),include_probe));
    fixed_corr(iter1) = coef(1,2);
    coef = corrcoef(singleAxis(log10(abs(free_original(iter1,:))),include_probe), singleAxis(log10(abs(free_reconstruct_fft(iter1,:))),include_probe));
    reconstruct_corr(iter1) = coef(1,2);
end

figure;
plot(highRes.freq,mode_corr);
hold on;
plot(highRes.freq,fixed_corr);
plot(highRes.freq,reconstruct_corr);
hold off;
xlim([15,400])

%% Plot POVs for Free Hand
% Plot POVs
figure;
b = bar(100*S_free(1:num_display).^2./sum(S_free.^2),'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
ylim([0,100])

%% Plot Modal Coordinates for Free Hand
figure;
for iter1 = 1:num_display
    [mc_freq, modal_coordinates] = fft_spectral(real(V_free(iter1,:)),fs);
    semilogy(mc_freq,abs(modal_coordinates)/max(abs(modal_coordinates)));
    hold on;
end
xlim([15,400])
hold off;

%% Plot Individual Modes (Real + Imaginary)
color_map = colorcet('COOLWARM');
for iter1 = 1:num_display
    mag_lim = max(abs(real(U_free(:,iter1))));
    surfPlot(U_free(:,iter1),highRes,[-mag_lim, mag_lim],color_map,strcat("Free - Mode ",num2str(iter1)),false,include_probe);
end
