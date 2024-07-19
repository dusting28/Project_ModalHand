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
find_travelling_nodes = false;
display_frames = false;

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
%b = bar(bars,'stacked');
b = bar(bars);
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

%Plot Input Signal
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

% Plot Individual Standing Modes
disp(strcat("DIP: ", num2str(highRes.yDIP)," mm"));
disp(strcat("MCP: ", num2str(highRes.yMCP)," mm"));
position = highRes.yCord(include_probe+2:3:end);

if display_frames
    % Plot frames of impulse modes
    color_map = colorcet('COOLWARM');
    mag_lim = max(abs(real(input_ensemble)),[],"all");
    disp(strcat("Impulse Response Magnitude: ", num2str(round(mag_lim,1))));
    for iter2 = 1:10
        time_frame = real(input_ensemble(360+(iter2)*5,:));
        surfPlot(time_frame,kernal,highRes,[-mag_lim, mag_lim],color_map,strcat("Impulse Response - Frame ", num2str(iter2)),false,include_probe);
        saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_WholeResponse",num2str(iter1),"_t",num2str(iter2-1)),'tiffn')
    end    

    % Plot frames of standing modes
    for iter1 = 1:num_modes
        single_mode = standing_component(:,iter1)*S(iter1)*V(iter1,:);
        mag_lim = max(abs(real(single_mode)),[],"all");
        disp(strcat("Mode ", num2str(iter1), " Standing Magnitude: ", num2str(round(mag_lim,1))));
        for iter2 = 1:10
            time_frame = real(single_mode(:,360+(iter2)*5))';
            surfPlot(time_frame,kernal,highRes,[-mag_lim, mag_lim],color_map,strcat("Standing Mode ",num2str(iter1), "- Frame ", num2str(iter2)),false,include_probe);
            saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Standing_Mode",num2str(iter1),"_t",num2str(iter2-1)),'tiffn')
        end    
    end

    % Plot frames of travelling modes
    for iter1 = 1:num_modes
        single_mode = travelling_component(:,iter1)*S(iter1)*V(iter1,:);
        mag_lim = max(abs(real(single_mode)),[],"all");
        disp(strcat("Mode ", num2str(iter1), " Travelling Magnitude: ", num2str(round(mag_lim,1))));
        for iter2 = 1:10
            time_frame = real(single_mode(:,360+(iter2)*5))';
            surfPlot(time_frame,kernal,highRes,[-mag_lim, mag_lim],color_map,strcat("Travelling Mode ",num2str(iter1), "- Frame ", num2str(iter2)),false,include_probe);
            saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Travelling_Mode",num2str(iter1),"_t",num2str(iter2-1)),'tiffn')
        end
    end
end

%% Waterfall plots
for iter1 = 1:num_modes
    figure;
    single_mode = real(standing_component(:,iter1)*S(iter1)*V(iter1,:))';
    max_osc = max(abs(single_mode),[],"all");
    for iter2 = 1:50
        single_axis = singleAxis(single_mode,include_probe);
        waterfallPlot(single_axis(360+(iter2),:),iter2-1,3,highRes,max_osc,flipud(colorcet('COOLWARM')),include_probe);
        hold on;
    end
    title(strcat("Mode ", num2str(iter1), " - Waterfall"))
    set(gcf, 'color', 'none');    
    set(gca, 'color', 'none');
    saveTransparent(gcf, strcat("MATLAB_Figs/StandingMode ", num2str(iter1), " - Waterfall.png"));
    figure;
    single_mode = real(travelling_component(:,iter1)*S(iter1)*V(iter1,:))';
    max_osc = max(abs(single_mode),[],"all");
    for iter2 = 1:50
        single_axis = singleAxis(single_mode,include_probe);
        waterfallPlot(single_axis(360+(iter2),:),iter2-1,3,highRes,max_osc,flipud(colorcet('COOLWARM')),include_probe);
        hold on;
    end
    title(strcat("Mode ", num2str(iter1), " - Waterfall"))
    set(gcf, 'color', 'none');    
    set(gca, 'color', 'none');
    saveTransparent(gcf, strcat("MATLAB_Figs/TravelingMode ", num2str(iter1), " - Waterfall.png"));
end

%% Finding Nodes
standing_nodes = zeros(num_modes,3);
for column = 1:3 
    for iter1 = 1:num_modes
        single_mode = real(squeeze(standing_component(:,iter1)));
        single_axis = single_mode(include_probe+column:3:end);
        crossing_idx = find(single_axis(1:end-1).*single_axis(2:end)<0);
        crossing_idx = crossing_idx(1);
        crossing_slope = (single_axis(crossing_idx+1)-single_axis(crossing_idx))/(position(crossing_idx+1)-position(crossing_idx));
        standing_nodes(iter1,column) = -single_axis(crossing_idx)/crossing_slope+position(crossing_idx);
    end
end

num_nodes = [2, 4, 12];
if find_travelling_nodes
    for column = 1:3
        zc = cell(num_modes,round((size(travelling_component,1)-include_probe)/3),2);
        for iter1 = 1:num_modes
            figure;
            single_mode = travelling_component(:,iter1)*S(iter1)*V(iter1,:);
            for iter2 = 1:round((size(single_mode,1)-include_probe)/3)
                single_axis = real(single_mode(include_probe+(iter2-1)*3+column,:))';
                [crossing_idx, signs] = zeroCrossingTime(single_axis,5,.1);
                plot(single_axis,'k');
                hold on;
                blue_cross = zeros(sum(signs==1),1);
                red_cross = zeros(sum(signs==-1),1);
                blue_iter = 0;
                red_iter = 0;
                for iter4 = 1:length(crossing_idx)
                    crossing_slope=(single_axis(crossing_idx(iter4)+1)-single_axis(crossing_idx(iter4)));
                    crossing=-single_axis(crossing_idx(iter4))./crossing_slope+crossing_idx(iter4);
                    if signs(iter4)>0
                        blue_iter = blue_iter+1;
                        blue_cross(blue_iter) = crossing;
                        xline(crossing,'b')
                    else
                        red_iter = red_iter+1;
                        red_cross(red_iter) = crossing;
                        xline(crossing,'r')
                    end
                end
                hold off;
                zc{iter1,iter2,1} = red_cross;
                zc{iter1,iter2,2} = blue_cross;
            end
        end
        travelling_nodes = cell(sum(num_nodes),1);
        iter0 = 0;
        for iter1 = 1:size(zc,1)
            figure;
            for iter2 = 1:size(zc,2)
                for iter3 = 1:size(zc,3)
                    for iter4 = 1:length(zc{iter1,iter2,iter3})
                        if iter3 == 1
                            plot(position(iter2),zc{iter1,iter2,iter3}(iter4),'ro')
                            hold on;
                        end
                        if iter3 == 2
                            plot(position(iter2),zc{iter1,iter2,iter3}(iter4),'bo')
                            hold on;
                        end
                    end
                end
            end
            hold off;
            for iter2 = 1:num_nodes(iter1)
                iter0 = iter0+1;
                title(strcat("Travelling node ", num2str(iter0), ": select adjacent points of same color"))
                node_estimands = ginput();
                node_actual = zeros(size(node_estimands,1), size(node_estimands,2));
                for iter3 = 1:size(node_estimands,1)
                    min_distance = Inf;
                    for iter4 = 1:size(zc,2)
                        for iter5 = 1:size(zc,3)
                            for iter6 = 1:length(zc{iter1,iter4,iter5})
                                distance = norm(node_estimands(iter3,:) - [position(iter4), zc{iter1,iter4,iter5}(iter6)]);
                                if distance < min_distance
                                    min_distance = distance;
                                    node_actual(iter3,:) = [position(iter4), zc{iter1,iter4,iter5}(iter6)];
                                end
                            end
                        end
                    end
                end
                travelling_nodes{iter0} = node_actual;
            end
        end
        load_name = strcat("TravellingNodes",num2str(column),".mat");
        save(load_name, "travelling_nodes")
    end
end

travelling_node_cell = cell(1,3);
for iter1 = 1:length(travelling_node_cell)
    load_name = strcat("TravellingNodes",num2str(iter1),".mat");
    loaded_modes = load(load_name);
    travelling_node_cell{iter1} = loaded_modes.travelling_nodes;
end

% Fit linear wave speed
wavespeed = zeros(3,sum(num_nodes));
for iter1 = 1:sum(num_nodes)
    common_pos = intersect(intersect(travelling_node_cell{1}{iter1}(:,1),travelling_node_cell{2}{iter1}(:,1)),...
        travelling_node_cell{3}{iter1}(:,1));
    common_nodes = zeros(3,length(common_pos));
    for iter2 = 1:length(common_pos)
        for iter3 = 1:3
            [~,node_idx] = min(abs(travelling_node_cell{iter3}{iter1}(:,1)-common_pos(iter2)));
            common_nodes(iter3,iter2) = travelling_node_cell{iter3}{iter1}(node_idx,2);
        end
    end
    % figure;
    % for iter2 = 1:3
    %     plot(common_pos,common_nodes(iter2,:),'o')
    %     hold on;
    %     pfit = polyfit(common_pos, common_nodes(iter2,:),1);
    %     plot(common_pos,polyval(pfit,common_pos));
    %     wavespeed(iter2,iter1) = fs/pfit(1)/1000;
    % end
end

speed1 = median(abs(wavespeed(:,1:num_nodes(1))),"all");
speed2 = median(abs(wavespeed(:,num_nodes(1)+1:num_nodes(1)+num_nodes(2))),"all");
speed3 = median(abs(wavespeed(:,num_nodes(1)+num_nodes(2)+1:sum(num_nodes))),"all");

% Find zero crossing at specific frames
plot_frames = 360+(1:10)*5;
zc_frame = zeros(num_modes,length(plot_frames),sum(num_nodes),3);
for iter1 = 1:num_modes
    for iter2 = 1:length(plot_frames)
        for iter3 = 1:num_nodes(iter1)
            if iter1 > 1
                node_idx = sum(num_nodes(1:iter1-1))+iter3;
            else
                node_idx = iter3;
            end
            for iter4 = 1:3
                if and(plot_frames(iter2) >= min(travelling_node_cell{iter4}{node_idx}(:,2)),...
                        plot_frames(iter2) <= max(travelling_node_cell{iter4}{node_idx}(:,2)))
                    zc_frame(iter1,iter2,node_idx,iter4) = interp1(travelling_node_cell{iter4}{node_idx}(:,2), ...
                        travelling_node_cell{iter4}{node_idx}(:,1), plot_frames(iter2));
                end
            end
        end
    end
end

%% Plot Nodes

if display_frames
    for iter1 = 1:size(standing_nodes,1)
        figure;
        plot(standing_nodes(iter1,:))
        hold on;
        yline(highRes.yCord(2-include_probe))
        yline(highRes.yCord(end))
        set(gca, 'YDir','reverse')
        saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Standing_Mode",num2str(iter1),"_NodeLocation"),'epsc')
        disp(strcat("Standing Node Location: ", num2str(mean(standing_nodes(iter1,:)))))
    end
    
    for iter1 = 1:size(zc_frame,1)
        for iter2 = 1:size(zc_frame,2)
            figure;
            for iter3 = 1:size(zc_frame,3)
                plot(squeeze(zc_frame(iter1,iter2,iter3,:)))
                hold on;
            end
            yline(highRes.yCord(2-include_probe))
            yline(highRes.yCord(end))
            set(gca, 'YDir','reverse')
            saveas(gcf,strcat("MATLAB_Figs/",hand_condition,"_Travelling_Mode",num2str(iter1),"_NodeLocation_t",num2str(iter2-1)),'epsc')
            disp(strcat("Standing Node Location: ", num2str(mean(standing_nodes(iter1,:)))))
        end
    end
end

%% Generate GIFs
if gif
    for iter1 = 1:num_modes
        mode = (standing_component(:,iter1)*S(iter1)*V(iter1,:)).';
        for iter2 = 350:1:500
            limit = max(abs(real(mode)),[],"all");
            gifPlot(real(mode(iter2,:)),1,highRes,[-limit,limit],flipud(colorcet('COOLWARM')),strcat("Standing Mode ",num2str(iter1)),include_probe)
        end
        mode = (travelling_component(:,iter1)*S(iter1)*V(iter1,:)).';
        for iter2 = 350:1:500
            limit = max(abs(real(mode)),[],"all");
            gifPlot(real(mode(iter2,:)),1,highRes,[-limit,limit],flipud(colorcet('COOLWARM')),strcat("Travelling Mode ",num2str(iter1)),include_probe)
        end
    end
end

%% Generate more GIFs
if gif
    mode = zeros(size(V(iter1,:),2),size(standing_component,1));
    for iter1 = 1:num_modes
        mode = mode+(standing_component(:,iter1)*S(iter1)*V(iter1,:)).';
    end
    for iter2 = 350:1:500
        limit = max(abs(real(mode)),[],"all");
        gifPlot(real(mode(iter2,:)),1,highRes,[-limit,limit],flipud(colorcet('COOLWARM')),strcat("Standing Modes 1-3"),include_probe)
    end
    for iter2 = 350:1:500
        limit = max(abs(real(input_ensemble)),[],"all");
        gifPlot(real(input_ensemble(iter2,:)),1,highRes,[-limit,limit],flipud(colorcet('COOLWARM')),strcat("Impulse Response"),include_probe)
    end
end