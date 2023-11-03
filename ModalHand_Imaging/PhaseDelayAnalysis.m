clear; clc; close all;

imaging = load("ImageData.mat");
zoom = 2;
rows = 3;

for iter1 = 1:length(imaging.zoom)
    amplitude = zeros(floor(length(imaging.tracking_cell{iter1,1}(1,2:end,1))/rows),rows,length(imaging.freqs));
    wave_speed = zeros(size(amplitude,1)-1,rows,length(imaging.freqs));
    for iter2 = 1:length(imaging.freqs)
        time_step = (1:length(imaging.tracking_cell{iter1,iter2}(:,1)))/imaging.frame_rate;
        
        % Single axis
        [sort_x,sort_idx] = sort(imaging.tracking_cell{iter1,iter2}(1,2:end,1));
        axis_idx = zeros(rows,floor(length(sort_idx)/rows));
        iter0 = 0;
        for iter3 = rows:rows:length(sort_idx)
            iter0 = iter0+1;
            column = imaging.tracking_cell{iter1,iter2}(1,sort_idx(iter3-rows+1:iter3)+1,2);
            [~,min_idx] = min(column);
            [~,middle_idx] = min(abs(column - median(column)));
            [~,max_idx] = max(column);
            axis_idx(1,iter0) = sort_idx(iter3-rows + min_idx)+1;
            axis_idx(2,iter0) = sort_idx(iter3-rows + middle_idx)+1;
            axis_idx(3,iter0) = sort_idx(iter3-rows + max_idx)+1;
        end

        x_pos = [imaging.tracking_cell{iter1,iter2}(1,axis_idx(1,:),1);...
            imaging.tracking_cell{iter1,iter2}(1,axis_idx(2,:),1); imaging.tracking_cell{iter1,iter2}(1,axis_idx(3,:),1)];
        pixel_scale = 0;
        for iter3 = 1:rows
            pixel_scale = pixel_scale + (3*10^-3)./(mean(x_pos(iter3,2:end)-x_pos(iter3,1:end-1)))/rows;
        end
        x_pos = (x_pos - min(x_pos,[],"all")) * pixel_scale; 
        
        % Surf Plots of Center Axis
        [tMesh,xMesh] = meshgrid(linspace(time_step(1),time_step(end),100),...
            linspace(x_pos(2,1),x_pos(2,end),100));
        zMesh = griddata(time_step,x_pos(2,:),imaging.displacement_cell{iter1,iter2}(:,axis_idx(2,:))',tMesh,xMesh,"cubic");
        figure;
        s = surf(xMesh,tMesh,zMesh);
        s.EdgeColor = 'none';
        colormap(colorcet('COOLWARM'));
        view(2)
        set(gca,'Ydir','reverse')

        % Fit cos to data at each location on finger
        phase_shift = zeros(size(axis_idx,2),rows);
        offset = zeros(size(axis_idx,2),rows);
        figure;
        subplot(1,2,1)
        for iter4 = 1:rows
            single_axis = imaging.displacement_cell{iter1,iter2}(:,axis_idx(iter4,:));
            for iter3 = 1:size(single_axis,2)
                single_sine = single_axis(:,iter3)';
                [amp_est ,shift_est] = max(single_sine);
                if shift_est > length(single_sine)/2
                    shift_est = shift_est - imaging.frame_rate/imaging.freqs(iter2);
                end
                shift_est = shift_est/imaging.frame_rate;
                % function to fit
                fit = @(b,t)  b(1)*cos(2*pi*imaging.freqs(iter2)*(t - b(2))) + b(3);
                fcn = @(b) sum((fit(b,time_step) - single_sine).^2);
                % call this to fit
                fitted_params = fminsearch(fcn, [amp_est; shift_est; 0]);  
                amplitude(iter3,iter4,iter2) = fitted_params(1);
                phase_shift(iter3,iter4) = fitted_params(2);
                offset(iter3,iter4) = fitted_params(3);
                plot(time_step,fit(fitted_params,time_step))
                hold on;
            end
        end
        subplot(1,2,2)
        for iter3 = 2:size(imaging.displacement_cell{iter1,iter2},2)
            plot(time_step,squeeze(imaging.displacement_cell{iter1,iter2}(:,iter3)))
            hold on;
        end
        hold off;

        % Compute wave speed and damping
        figure;
        for iter3 = 1:size(phase_shift,2)
            phase_shift(:,iter3) = unwrap(2*pi*imaging.freqs(iter2)*phase_shift(:,iter3));
            wave_speed(:,iter3,iter2) = imaging.freqs(iter2)*2*pi*(x_pos(iter3,2:end)-x_pos(iter3,1:end-1))'./-angdiff(phase_shift(2:end,iter3),phase_shift(1:end-1,iter3));
            subplot(1,3,1);
            plot(squeeze(x_pos(iter3,:)),squeeze(phase_shift(:,iter3)))
            hold on;
            subplot(1,3,2);
            plot(squeeze(x_pos(iter3,1:end-1)),squeeze(wave_speed(:,iter3,iter2)))
            hold on;
            subplot(1,3,3);
            plot(squeeze(x_pos(iter3,:)),squeeze(amplitude(:,iter3,iter2)))
            ylim([0,1.7])
            hold on;
        end
    end
    figure;
    plot(squeeze(median(x_pos(:,1:end-1),1)),squeeze(median(wave_speed(:,:,1),2)))
    hold on;
    plot(squeeze(median(x_pos(:,1:end-1),1)),squeeze(median(wave_speed(:,:,2),2)))
    figure;
    plot(squeeze(median(x_pos,1)),squeeze(median(amplitude(:,:,1),2)))
    hold on;
    plot(squeeze(median(x_pos,1)),squeeze(median(amplitude(:,:,2),2)))
    ylim([0,1.7])
end


