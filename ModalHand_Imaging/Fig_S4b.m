clear; clc; close all;

imaging = load("ImageData_MultiCycle.mat");

width = 1920;
height = 1080;
dot_size = 20;
MCP = 925;
finger = 1075;

for iter1 = 1:length(imaging.zoom)
    for iter2 = 1:length(imaging.freqs)
        time = (1:length(imaging.tracking_cell{iter1,iter2}(:,1)))/imaging.frame_rate;

        displacement = imaging.displacement_cell{iter1,iter2}(:,:);

        cut_displacement = displacement(1:floor(size(displacement,1)/2)+1,:);
        cut_time = time(1:floor(length(time)/2)+1)-time(1);
        
        % Sort based on distance from tip
        tip_x = 1815;
        tip_y = 595;
        tip_distance = ((imaging.tracking_cell{iter1,iter2}(1,2:end,1)-tip_x).^2 + ...
            (imaging.tracking_cell{iter1,iter2}(1,2:end,2)-tip_y).^2).^.5;
        [sorted_distance,sort_idx] = sort(tip_distance);
        sort_idx = sort_idx + 1;
        pixel_scale = .019/186; % Got value from probe dimensions
        sorted_distance = (sorted_distance) * pixel_scale;
        sorted_displacement = cut_displacement(:,sort_idx);

        % Surf plot of sorted points
        figure;
        colormap(colorcet('COOLWARM'));
        [tMesh,xMesh] = meshgrid(cut_time,sorted_distance);
        s = surf(xMesh,tMesh,sorted_displacement');
        s.EdgeColor = 'none';
        view(2)
        set(gca,'Ydir','reverse')
        xlim([0,sorted_distance(end)]);
        ylim([0,cut_time(end)]);
        saveas(gcf,strcat("MATLAB_Plots/FigS4_SurfPlot_",num2str(imaging.freqs(iter2)),"Hz"),"tiffn")

        % Plot first frame
        figure;
        color_map = colorcet('COOLWARM');
        for iter3 = 2:size(cut_displacement,2)
            color_idx = min([max([round((cut_displacement(1,iter3)+1)*256/2),1]),256]);
            plot(squeeze(imaging.tracking_cell{iter1,iter2}(1,iter3,1)),...
                squeeze(imaging.tracking_cell{iter1,iter2}(1,iter3,2)),...
                '.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
            hold on;
        end
        hold off;
        xlim([0,width]);
        ylim([0,height]);
        pbaspect([width height 1])
        saveas(gcf,strcat("MATLAB_Plots/FigS4_Frame1_",num2str(imaging.freqs(iter2)),"Hz"),"epsc")

        % Plot input signal
        figure;
        plot(cut_displacement(:,1));
        saveas(gcf,strcat("MATLAB_Plots/FigS4_InputSignal_",num2str(imaging.freqs(iter2)),"Hz"),"epsc")

        % Fit cos to data at each location on finger
        phase_shift = zeros(1,size(cut_displacement,2));
        offset = zeros(1,size(cut_displacement,2));
        amplitude = zeros(1,size(cut_displacement,2));
        figure;
        subplot(1,2,1)
        for iter3 = 1:size(cut_displacement,2)
            single_sine = cut_displacement(:,iter3)';
            [amp_est ,shift_est] = max(single_sine);
            if shift_est > length(single_sine)/2
                shift_est = shift_est - imaging.frame_rate/imaging.freqs(iter2);
            end
            shift_est = shift_est/imaging.frame_rate;
            % function to fit
            fit = @(b,t)  b(1)*cos(2*pi*imaging.freqs(iter2)*(t - b(2))) + b(3);
            fcn = @(b) sum((fit(b,cut_time) - single_sine).^2);
            % call this to fit
            fitted_params = fminsearch(fcn, [amp_est; shift_est; 0]);  
            amplitude(iter3) = fitted_params(1);
            phase_shift(iter3) = fitted_params(2);
            offset(iter3) = fitted_params(3);
            plot(cut_time,fit(fitted_params,cut_time))
            hold on;
        end
        subplot(1,2,2)
        for iter3 = 1:size(cut_displacement,2)
            plot(cut_time,squeeze(cut_displacement(:,iter3)))
            hold on;
        end
        hold off;

        for iter3 = 1:length(amplitude)
            if amplitude(iter3) < 0
                phase_shift(iter3) = phase_shift(iter3) + pi;
                amplitude(iter3) = -amplitude(iter3);
            end
        end
        phase_shift = wrapTo2Pi(2*pi*imaging.freqs(iter2)*(phase_shift-phase_shift(1)));
        amplitude= amplitude/amplitude(1);
        

        figure;
        color_map = colorcet('CBTC1');
        % color_map = (repmat([(1:2:256),fliplr(1:2:256)],3,1)/256)';
        for iter3 = 2:size(cut_displacement,2)
            color_idx = min([max([round(phase_shift(1,iter3)*256/2/pi),1]),256]);
            plot(squeeze(imaging.tracking_cell{iter1,iter2}(1,iter3,1)),...
                squeeze(imaging.tracking_cell{iter1,iter2}(1,iter3,2)),...
                '.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
            hold on;
        end
        hold off;
        xlim([0,width]);
        ylim([0,height]);
        pbaspect([width height 1])
        saveas(gcf,strcat("MATLAB_Plots/FigS4_PhaseShift_",num2str(imaging.freqs(iter2)),"Hz"),"epsc")
        
        figure;
        finger_phase = zeros(1,sum(imaging.tracking_cell{iter1,iter2}(1,2:end,1) >= finger));
        finger_amp = zeros(1,sum(imaging.tracking_cell{iter1,iter2}(1,2:end,1) >= finger));
        finger_x = zeros(1,sum(imaging.tracking_cell{iter1,iter2}(1,2:end,1) >= finger));
        iter0 = 0;
        for iter3 = 2:size(cut_displacement,2)
            if imaging.tracking_cell{iter1,iter2}(1,iter3,1) >= finger
                plot(imaging.tracking_cell{iter1,iter2}(1,iter3,1),phase_shift(1,iter3),'bo');
                hold on;
                iter0 = iter0+1;
                finger_phase(iter0) = phase_shift(1,iter3);
                finger_amp(iter0) = amplitude(1,iter3);
                finger_x(iter0) = imaging.tracking_cell{iter1,iter2}(1,iter3,1);
            else
                plot(imaging.tracking_cell{iter1,iter2}(1,iter3,1),phase_shift(1,iter3),'ro');
                hold on;
            end
        end
        hold off;

        [~, fingertip_idx] = max(finger_x);
        [~, MCP_idx] = min(finger_x);

        phase_lag = 180*(finger_phase(MCP_idx)-finger_phase(fingertip_idx))/pi;
        disp(strcat("Finger Phase Lag: ", num2str(phase_lag)))

        [~, palm_idx] = min(imaging.tracking_cell{iter1,iter2}(1,2:end,1));
        [~, fingertip_idx] = max(imaging.tracking_cell{iter1,iter2}(1,2:end,1));
        num_waves = (phase_shift(palm_idx+1)-phase_shift(fingertip_idx+1))/2/pi;
        if iter2 == 2
            num_waves = num_waves+1;
        end
        wave_length = pixel_scale*(imaging.tracking_cell{iter1,iter2}(1,fingertip_idx+1,1)...
            -imaging.tracking_cell{iter1,iter2}(1,palm_idx+1,1))/num_waves;
        wave_speed = imaging.freqs(iter2)*wave_length;
        disp(strcat("Wave Speed: ", num2str(wave_speed)))

        linearCoefficients = polyfit(finger_x, finger_amp, 1);          % Coefficients
        yfit = polyval(linearCoefficients, finger_x);          % Estimated  Regression Line
        SStot = sum((finger_amp-mean(finger_amp)).^2);                    % Total Sum-Of-Squares
        SSres = sum((finger_amp-yfit).^2); 
        Rsq = 1-SSres/SStot; 

        figure;
        plot(finger_x,finger_amp,'bo');
        hold on;
        plot(finger_x,finger_x*linearCoefficients(1)+linearCoefficients(2),'ro')
        zero_cross = -linearCoefficients(2)/linearCoefficients(1);

        disp(strcat("Linear Fit: ", num2str(Rsq)))
        disp(strcat("Distance to MCP: ", num2str(pixel_scale*(MCP-zero_cross))))

        linearCoefficients = polyfit(pixel_scale*imaging.tracking_cell{iter1,iter2}(1,2:end,1), log(amplitude(2:end)), 1);          % Coefficients
        yfit = polyval(linearCoefficients, pixel_scale*imaging.tracking_cell{iter1,iter2}(1,2:end,1));          % Estimated  Regression Line
        SStot = sum((log(amplitude(2:end))-mean(log(amplitude(2:end)))).^2);                    % Total Sum-Of-Squares
        SSres = sum((log(amplitude(2:end))-yfit).^2);                       % Residual Sum-Of-Squares
        Rsq = 1-SSres/SStot; 

        figure;
        plot(imaging.tracking_cell{iter1,iter2}(1,2:end,1),amplitude(2:end),'bo');
        hold on;
        plot(imaging.tracking_cell{iter1,iter2}(1,2:end,1),exp(pixel_scale*imaging.tracking_cell{iter1,iter2}(1,2:end,1)*linearCoefficients(1))...
            *exp(linearCoefficients(2)),'ro')

        disp(strcat("Exponential Fit: ", num2str(Rsq)))
        
        figure;
        color_map = colormap("turbo");
        % color_map = colorcet('CET_C5s');
        for iter3 = 2:size(cut_displacement,2)
            color_idx = min([max([round((40+20*log10(amplitude(1,iter3)))*256/40),1]),256]);
            plot(squeeze(imaging.tracking_cell{iter1,iter2}(1,iter3,1)),...
                squeeze(imaging.tracking_cell{iter1,iter2}(1,iter3,2)),...
                '.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
            hold on;
        end
        hold off;
        xlim([0,width]);
        ylim([0,height]);
        pbaspect([width height 1])
        saveas(gcf,strcat("MATLAB_Plots/FigS4_Amplitude_",num2str(imaging.freqs(iter2)),"Hz"),"epsc")

        figure(100+iter2);
        semilogy(sorted_distance,amplitude(sort_idx),'.','MarkerSize',20)
        xline(15*10^-3)
        xline(62*10^-3)
        ylim([.01,1]);
        hold on;
       
    end
end