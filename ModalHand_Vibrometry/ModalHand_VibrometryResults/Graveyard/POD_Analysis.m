clc; clear; close all;

current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
addpath("Functions\");

highRes = load("HighRes_ProcessedData.mat");
fs = 2500;
bandwidth = [15, 400];
include_probe = true;
maxModes = 10;
criteria = 0.05;


%% Generate Input Matrix

% Create input matrices from IRs
fixed_input = zeros(length(highRes.fixed_ir{1}),length(highRes.yCord)-not(include_probe));
free_input = zeros(length(highRes.free_ir{1}),length(highRes.yCord)-not(include_probe));
for iter1 = 1:(length(highRes.yCord)-not(include_probe))
    pos_idx = iter1 + not(include_probe);
    fixed_input(:,iter1) = highRes.fixed_ir{pos_idx} - mean(highRes.fixed_ir{pos_idx});
    free_input(:,iter1) = highRes.free_ir{pos_idx} - mean(highRes.free_ir{pos_idx});
end

%% POD
C_free = free_input'*conj(free_input)/(size(free_input,1)-1);
[free_eigVec, free_eigVal] = eig(C_free);
free_basis = free_input*free_eigVec;
free_eigVal = flipud(diag(free_eigVal));

C_fixed = fixed_input'*conj(fixed_input)/(size(fixed_input,1)-1);
[fixed_eigVec, fixed_eigVal] = eig(C_fixed);
fixed_basis = fixed_input*fixed_eigVec;
fixed_basis2 = fixed_input*free_eigVec;
fixed_eigVal = flipud(diag(fixed_eigVal));

fixed_modes = zeros(maxModes,length(fixed_eigVal));
free_modes = zeros(maxModes,length(free_eigVal));
num_modes = [0,0];
for iter1 = 1:maxModes
    if fixed_eigVal(iter1)/sum(fixed_eigVal)>criteria
        num_modes(1) = num_modes(1)+1;
    end    
    if free_eigVal(iter1)/sum(free_eigVal)>criteria
        num_modes(2) = num_modes(2)+1;
    end
    fixed_modes(iter1,:) = fixed_eigVec(:,end-iter1+1)';
    % if fixed_modes(iter1,1)<0
    %     fixed_modes(iter1,:) = -fixed_modes(iter1,:);
    % end
    free_modes(iter1,:) = free_eigVec(:,end-iter1+1)';
    % if free_modes(iter1,1)<0
    %     free_modes(iter1,:) = -free_modes(iter1,:);
    % end
end

num_modes = [3,3];

%% Plot
close all;
color_map = colorcet('COOLWARM');
for iter1 = 1:max(num_modes)
    if iter1<=num_modes(1)
        mag_lim = max(abs(fixed_modes(iter1,:)));
        surfPlot(fixed_modes(iter1,:),highRes,[-mag_lim, mag_lim],color_map,strcat("Fixed - Mode ",num2str(iter1)),false,include_probe);
    end
    if iter1<=num_modes(2)
        mag_lim = max(abs(free_modes(iter1,:)));
        surfPlot(free_modes(iter1,:),highRes,[-mag_lim, mag_lim],color_map,strcat("Free - Mode ",num2str(iter1)),false,include_probe);
    end
end

%% Eigenvalues
color_map = [0, 0, 0; .3, .3, .3; .6, .6, .6];
figure;
b = bar(100*fixed_eigVal(1:5)./sum(fixed_eigVal),'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
% b.CData(1:num_modes(1),:) = color_map;
ylim([0,100])

figure;
b = bar(100*free_eigVal(1:5)./sum(free_eigVal),'FaceColor',[1, 1, 1]);
b.FaceColor = 'flat';
% b.CData(1:num_modes(2),:) = color_map;
ylim([0,100])


%% Time Analysis
centroid_fixed = zeros(num_modes(1),1);
centroid_free = zeros(num_modes(2),1);
for iter1 = 1:max(num_modes)
    if iter1<=num_modes(1)
        single_basis = fixed_basis(:,end+1-iter1);
        [freq,fft_basis] = fft_spectral(single_basis',fs);
        freq_idx = find(or(freq<=bandwidth(1),freq>=bandwidth(2)));
        fft_basis(freq_idx) = 0;

        figure(sum(num_modes)+3);
        semilogy(freq,movmean(abs(fft_basis),1)./max(movmean(abs(fft_basis),1)),'Color',color_map(iter1,:))
        hold on;
        xlim(bandwidth);
        ylim([10^-2, 1]);

        centroid_fixed(iter1) = sum(freq.*abs(fft_basis))./sum(abs(fft_basis));
    end
    
    if iter1<=num_modes(2)
       single_basis = free_basis(:,end+1-iter1);
       [freq,fft_basis] = fft_spectral(single_basis',fs);
       freq_idx = find(or(freq<=bandwidth(1),freq>=bandwidth(2)));
       fft_basis(freq_idx) = 0;

       figure(sum(num_modes)+4);
       semilogy(freq,movmean(abs(fft_basis),1)./max(movmean(abs(fft_basis),1)),'Color',color_map(iter1,:))
       hold on;
       xlim(bandwidth);
       ylim([10^-2, 1]);

       centroid_free(iter1) = sum(freq.*abs(fft_basis))./sum(abs(fft_basis));
    end
end

%% Single Axis
fixed_wavelength = zeros(num_modes(1),1);
free_wavelength = zeros(num_modes(2),1);
fixed_COM = zeros(num_modes(2),1);
free_COM = zeros(num_modes(2),1);
y = [highRes.yCord(1), highRes.yCord(3:3:end)];
for iter1 = 1:max(num_modes)
    if iter1<=num_modes(1)
       line1 = [fixed_modes(iter1,1), fixed_modes(iter1,2:3:end)];
       line2 = [fixed_modes(iter1,1), fixed_modes(iter1,3:3:end)];
       line3 = [fixed_modes(iter1,1), fixed_modes(iter1,4:3:end)];
       single_line = (line1+line2+line3)/3;
       y_up = linspace(y(1),y(end),length(single_line)*10);
       u = linspace(1,length(single_line),length(single_line)*10);
       sinc_interp = zeros(length(single_line)*10,1);
       x = linspace(1,length(single_line),length(single_line));
       for iter2=1:length(u)
        sinc_interp(iter2) = sum(single_line.*sinc(u(iter2) - x));           
       end

       figure(sum(num_modes)+5)
       plot(y_up,sinc_interp/max(abs(sinc_interp)),'Color',color_map(iter1,:));
       hold on;
       xline(highRes.yDIP);
       xline(highRes.yPIP);
       xline(highRes.yMCP);
       ylim([-1, 1]);

       figure(sum(num_modes)+7);
       [k,k_space] = fft_spectral([single_line, zeros(1,150)],1/3);
       plot(k,abs(k_space),'Color',color_map(iter1,:));
       hold on;

       fixed_COM(iter1) = sum(y_up'.*abs(sinc_interp))./sum(abs(sinc_interp));
       fixed_wavelength(iter1) = 1/(sum(k.*abs(k_space))./sum(abs(k_space)));
    end
    
    if iter1<=num_modes(2)
       line1 = [free_modes(iter1,1), free_modes(iter1,2:3:end)];
       line2 = [free_modes(iter1,1), free_modes(iter1,3:3:end)];
       line3 = [free_modes(iter1,1), free_modes(iter1,4:3:end)];
       single_line = (line1+line2+line3)/3;
       y_up = linspace(y(1),y(end),length(single_line)*10);
       u = linspace(1,length(single_line),length(single_line)*10);
       sinc_interp = zeros(length(single_line)*10,1);
       x = linspace(1,length(single_line),length(single_line));
       for iter2=1:length(u)
        sinc_interp(iter2) = sum(single_line.*sinc(u(iter2) - x));           
       end
       
       figure(sum(num_modes)+6)
       plot(y_up,sinc_interp/max(abs(sinc_interp)),'Color',color_map(iter1,:));
       hold on;
       xline(highRes.yDIP);
       xline(highRes.yPIP);
       xline(highRes.yMCP);
       ylim([-1, 1]);

       figure(sum(num_modes)+8);
       [k,k_space] = fft_spectral([single_line, zeros(1,150)],1/3);
       plot(k,abs(k_space),'Color',color_map(iter1,:));
       hold on;

       free_COM(iter1) = sum(y_up'.*abs(sinc_interp))./sum(abs(sinc_interp));
       free_wavelength(iter1) = 1/(sum(k.*abs(k_space))./sum(abs(k_space)));
    end
end

[~,exponential_fixed] = fit(highRes.yCord'-highRes.yProbe,squeeze(fixed_modes(1,:))','exp1');
[~,linear_fixed] = fit(highRes.yCord(highRes.yCord<=highRes.yMCP)'-highRes.yMCP,...
    squeeze(fixed_modes(1,highRes.yCord<=highRes.yMCP))',fittype({'x'}));
[~,exponential_free] = fit(highRes.yCord'-highRes.yProbe,squeeze(free_modes(1,:))','exp1');
[~,linear_free] = fit(highRes.yCord(highRes.yCord<=highRes.yMCP)'-highRes.yMCP,...
    squeeze(free_modes(1,highRes.yCord<=highRes.yMCP))',fittype({'x'}));

%% Reconstruction of Input Matrix
fixed_skeletal = zeros(size(fixed_input,1),size(fixed_input,2));
fixed_tissue = zeros(size(fixed_input,1),size(fixed_input,2));
free_skeletal = zeros(size(free_input,1),size(free_input,2));
free_tissue = zeros(size(free_input,1),size(free_input,2));
for iter1 = 1:size(free_eigVal,1)
    if iter1<=num_modes(1)
        fixed_skeletal = fixed_skeletal + fixed_basis2(:,end+1-iter1)*free_eigVec(:,end+1-iter1)';
        free_skeletal = free_skeletal + free_basis(:,end+1-iter1)*free_eigVec(:,end+1-iter1)';
    else
        fixed_tissue = fixed_tissue + fixed_basis2(:,end+1-iter1)*free_eigVec(:,end+1-iter1)';
        free_tissue = free_tissue + free_basis(:,end+1-iter1)*free_eigVec(:,end+1-iter1)';
    end
end

fixed_skeletal_fft = zeros(length(highRes.yCord),floor(size(fixed_skeletal,1)/2)+2)';
free_skeletal_fft = zeros(length(highRes.yCord),floor(size(free_skeletal,1)/2)+2)';
fixed_tissue_fft = zeros(length(highRes.yCord),floor(size(fixed_tissue,1)/2)+2)';
free_tissue_fft = zeros(length(highRes.yCord),floor(size(free_tissue,1)/2)+2)';
for iter1 = 1:length(highRes.yCord)
    [~,fixed_skeletal_fft(:,iter1)] = fft_spectral(size(fixed_input,1)*fixed_skeletal(:,iter1)',fs);
    [~,free_skeletal_fft(:,iter1)] = fft_spectral(size(free_input,1)*free_skeletal(:,iter1)',fs);
    [~,fixed_tissue_fft(:,iter1)] = fft_spectral(size(fixed_input,1)*fixed_tissue(:,iter1)',fs);
    [reconstruct_freq,free_tissue_fft(:,iter1)] = fft_spectral(size(free_input,1)*free_tissue(:,iter1)',fs);
end

unwrappedAdmittance(reconstruct_freq,highRes,fixed_skeletal_fft, include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,free_skeletal_fft, include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,fixed_tissue_fft, include_probe);
unwrappedAdmittance(reconstruct_freq,highRes,free_tissue_fft, include_probe);

fixed_original = zeros(length(highRes.freq),length(highRes.yCord));
free_original = zeros(length(highRes.freq),length(highRes.yCord));
for iter1 = 1:length(highRes.yCord)
    fixed_original(:,iter1) = highRes.fixed_tf{iter1};
    free_original(:,iter1) =  highRes.free_tf{iter1};
end
unwrappedAdmittance(highRes.freq,highRes,fixed_original, include_probe);
unwrappedAdmittance(highRes.freq,highRes,free_original, include_probe);
