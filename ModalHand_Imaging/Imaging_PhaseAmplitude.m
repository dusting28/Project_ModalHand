clear; clc; close all;

imaging = load("ImageData_MultiCycle.mat");

width = 1920;
height = 1080;
dot_size = 20;

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
        saveas(gcf,strcat("SurfPlot_",num2str(imaging.freqs(iter2)),"Hz"),"tiffn")

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
        saveas(gcf,strcat("Frame1_",num2str(imaging.freqs(iter2)),"Hz"),"epsc")

        % Plot input signal
        figure;
        plot(cut_displacement(:,1));
        saveas(gcf,strcat("InputSignal_",num2str(imaging.freqs(iter2)),"Hz"),"epsc")

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
        amplitude= 20*log10(amplitude/amplitude(1));
        

        figure;
        % color_map = colorcet('C5');
        color_map = (repmat([(1:2:256),fliplr(1:2:256)],3,1)/256)';
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
        saveas(gcf,strcat("PhaseShift_",num2str(imaging.freqs(iter2)),"Hz"),"epsc")

        figure;
        color_map = colormap("turbo");
        % color_map = colorcet('CET_C5s');
        for iter3 = 2:size(cut_displacement,2)
            color_idx = min([max([round((40+amplitude(1,iter3))*256/40),1]),256]);
            plot(squeeze(imaging.tracking_cell{iter1,iter2}(1,iter3,1)),...
                squeeze(imaging.tracking_cell{iter1,iter2}(1,iter3,2)),...
                '.','MarkerSize',dot_size,'Color',squeeze(color_map(color_idx,:)))
            hold on;
        end
        hold off;
        xlim([0,width]);
        ylim([0,height]);
        pbaspect([width height 1])
        saveas(gcf,strcat("Amplitude_",num2str(imaging.freqs(iter2)),"Hz"),"epsc")
       
    end
end