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
max_modes = 10;
inclusion_criteria = 0.02;

%% Generate Input Matrix

% Create input matrices from IRs
fixed_input = zeros(length(highRes.fixed_ir{1}),length(highRes.yCord)-not(include_probe));
free_input = zeros(length(highRes.free_ir{1}),length(highRes.yCord)-not(include_probe));
for iter1 = 1:(length(highRes.yCord)-not(include_probe))
    pos_idx = iter1 + not(include_probe);
    fixed_input(:,iter1) = highRes.fixed_ir{pos_idx} - mean(highRes.fixed_ir{pos_idx});
    free_input(:,iter1) = highRes.free_ir{pos_idx} - mean(highRes.free_ir{pos_idx});
end

% Take hilbert transform of each time-domain signal
for iter1 = 1:size(fixed_input,2)
    fixed_input(:,iter1) = hilbert(fixed_input(:,iter1));
    free_input(:,iter1) = hilbert(free_input(:,iter1));
end

%% POD

% Compute co-variance matrix
C_free = free_input.'*conj(free_input)/(size(free_input,1)-1);
C_free = (C_free'+C_free)/2; % Ensure that it is Hermitian
C_fixed = fixed_input.'*conj(fixed_input)/(size(fixed_input,1)-1);
C_fixed= (C_fixed'+C_fixed)/2; % Ensure that it is Hermitian

% Compute Eigenvalues and Eigenvectors
[free_eigVec, free_eigVal] = eig(C_free);
[fixed_eigVec, fixed_eigVal] = eig(C_fixed);

% Compute
free_coordinates = free_eigVec'*free_input.';
fixed_coordinates = fixed_eigVec'*fixed_input.';

% Reformat Eigenvalues (COVs) and Eigenvectors (COMs)
free_eigVal = flipud(diag(free_eigVal));
fixed_eigVal = flipud(diag(fixed_eigVal));
fixed_modes = zeros(max_modes,length(fixed_eigVal));
free_modes = zeros(max_modes,length(free_eigVal));
num_modes = [0,0];
for iter1 = 1:max_modes
    if fixed_eigVal(iter1)/sum(fixed_eigVal)>inclusion_criteria
        num_modes(1) = num_modes(1)+1;
    end    
    if free_eigVal(iter1)/sum(free_eigVal)>inclusion_criteria
        num_modes(2) = num_modes(2)+1;
    end
    fixed_modes(iter1,:) = fixed_eigVec(:,end-iter1+1)';
    free_modes(iter1,:) = free_eigVec(:,end-iter1+1)';
end


%% Decompose Data Set

% Break COMs into standing and traveling components
fixed_s = zeros(num_modes(1),size(fixed_modes,2));
fixed_t = zeros(num_modes(1),size(fixed_modes,2));
free_s= zeros(num_modes(2),size(free_modes,2));
free_t = zeros(num_modes(2),size(free_modes,2));
for iter1 = 1:max(num_modes)
    if iter1<=num_modes(1)
        c = real(fixed_modes(iter1,:));
        d = imag(fixed_modes(iter1,:));
        d_s = c*dot(d,c/norm(c))/norm(c);
        d_t = d-d_s;
        c_t = norm(d_t)*c/norm(c);
        c_s = c - c_t;
        fixed_s(iter1,:) = c_s + 1i * d_s;
        fixed_t(iter1,:) = c_t + 1i * d_t;
    end
    if iter1<=num_modes(2)
        c = real(free_modes(iter1,:));
        d = imag(free_modes(iter1,:));
        d_s = c*dot(d,c/norm(c))/norm(c);
        d_t = d-d_s;
        c_t = norm(d_t)*c/norm(c);
        c_s = c - c_t;
        free_s(iter1,:) = c_s + 1i * d_s;
        free_t(iter1,:) = c_t + 1i * d_t;
    end
end

% Reconstruct data set from standing and traveling components
% Note: This is close to correct, but something is slightly wrong
fixed_standing = zeros(size(fixed_input,1),size(fixed_input,2));
fixed_traveling = zeros(size(fixed_input,1),size(fixed_input,2));
free_standing = zeros(size(free_input,1),size(free_input,2));
free_traveling = zeros(size(free_input,1),size(free_input,2));
for iter1 = 1:size(free_eigVal,1)
    if iter1<=num_modes(1)
        fixed_standing = fixed_standing + (fixed_s(iter1,:).'*fixed_coordinates(end+1-iter1,:)).';
        fixed_traveling = fixed_traveling + (fixed_t(iter1,:).'*fixed_coordinates(end+1-iter1,:)).';
    end
    if iter1<=num_modes(2)
        free_standing = free_standing + (free_s(iter1,:).'*free_coordinates(end+1-iter1,:)).';
        free_traveling = free_traveling + (free_t(iter1,:).'*free_coordinates(end+1-iter1,:)).';
    end
end
fixed_reconstruct = real(fixed_standing + fixed_traveling);
fixed_standing = real(fixed_standing);
fixed_traveling = real(fixed_traveling);
free_reconstruct = real(free_standing + free_traveling);
free_standing = real(free_standing);
free_traveling = real(free_traveling);

% Compute FFT of each component
fixed_standing_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(fixed_standing,1)/2)+2)';
fixed_traveling_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(fixed_traveling,1)/2)+2)';
fixed_reconstruct_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(fixed_traveling,1)/2)+2)';
free_standing_fft = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_standing,1)/2)+2)';
free_reconstruct_fft  = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_traveling,1)/2)+2)';
free_traveling_fft  = zeros(length(highRes.yCord)-not(include_probe),floor(size(free_traveling,1)/2)+2)';
for iter1 = 1:length(highRes.yCord)-not(include_probe)
    [~,fixed_standing_fft(:,iter1)] = fft_spectral(size(fixed_input,1)*fixed_standing(:,iter1).',fs);
    [~,fixed_traveling_fft(:,iter1)] = fft_spectral(size(fixed_input,1)*fixed_traveling(:,iter1).',fs);
    [~,fixed_reconstruct_fft(:,iter1)] = fft_spectral(size(fixed_input,1)*fixed_reconstruct(:,iter1).',fs);
    [~,free_standing_fft(:,iter1)] = fft_spectral(size(free_input,1)*free_standing(:,iter1).',fs);
    [~,free_traveling_fft(:,iter1)] = fft_spectral(size(free_input,1)*free_traveling(:,iter1).',fs);
    [reconstruct_freq,free_reconstruct_fft(:,iter1)] = fft_spectral(size(free_input,1)*free_reconstruct(:,iter1).',fs);
end

% Plot standing and traveling components
unwrappedAdmittance(reconstruct_freq,highRes,fixed_standing_fft,include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,fixed_traveling_fft,include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,free_standing_fft,include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,free_traveling_fft,include_probe);

% Load raw data set
fixed_original = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
free_original = zeros(length(highRes.freq),length(highRes.yCord)-not(include_probe));
for iter1 = 1:length(highRes.yCord)-not(include_probe)
    pos_idx = iter1 + not(include_probe);
    fixed_original(:,iter1) = highRes.fixed_tf{pos_idx};
    free_original(:,iter1) =  highRes.free_tf{pos_idx};
end

% Plot reconstructed data set vs raw data set
unwrappedAdmittance(reconstruct_freq,highRes,fixed_reconstruct_fft,include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,free_reconstruct_fft,include_probe);
unwrappedAdmittance(highRes.freq,highRes,fixed_original,include_probe);
unwrappedAdmittance(highRes.freq,highRes,free_original,include_probe);


%% Plot COVs and Traveling Index

% Compute traveling index from condition number
fixed_index = zeros(1,max_modes);
free_index = zeros(1,max_modes);
for iter1 = 1:max_modes
    fixed_index(iter1) = 1/cond([real(fixed_modes(iter1,:)); imag(fixed_modes(iter1,:))]);
    free_index(iter1) = 1/cond([real(free_modes(iter1,:)); imag(free_modes(iter1,:))]);
end

% Plot traveling indices
figure;
b = bar(fixed_index,'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
ylim([0,1])

figure;
b = bar(free_index,'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
ylim([0,1])

% Plot COVs
figure;
b = bar(100*fixed_eigVal(1:max_modes)./sum(fixed_eigVal),'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
ylim([0,100])

figure;
b = bar(100*free_eigVal(1:max_modes)./sum(free_eigVal),'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
ylim([0,100])

%% Plot Individual Modes (Real + Imaginary)
color_map = colorcet('COOLWARM');
for iter1 = 1:max(num_modes)
    % Plot fixed modes
    if iter1<=num_modes(1)
        mag_lim = max(abs(real(fixed_modes(iter1,:))));
        surfPlot(real(fixed_modes(iter1,:)),highRes,[-mag_lim, mag_lim],color_map,strcat("Fixed - Mode ",num2str(iter1)),false,include_probe);
        surfPlot(imag(fixed_modes(iter1,:)),highRes,[-mag_lim, mag_lim],color_map,strcat("Fixed - Mode ",num2str(iter1)),false,include_probe);
    end
    % Plot free modes
    if iter1<=num_modes(2)
        mag_lim = max(abs(free_modes(iter1,:)));
        surfPlot(real(free_modes(iter1,:)),highRes,[-mag_lim, mag_lim],color_map,strcat("Free - Mode ",num2str(iter1)),false,include_probe);
        surfPlot(imag(free_modes(iter1,:)),highRes,[-mag_lim, mag_lim],color_map,strcat("Free - Mode ",num2str(iter1)),false,include_probe);
    end
end
