clear; clc; close all;

imaging = load("NoDots_ImageData.mat");

for iter1 = 1:length(imaging.zoom)
    for iter2 = 1:length(imaging.freqs)
        time_step = (1:length(imaging.tracking_cell{iter1,iter2}(:,1)))/imaging.frame_rate;
        
        % Single axis
        [sort_x,sort_idx] = sort(imaging.tracking_cell{iter1,iter2}(1,2:end,1));
        sort_idx = sort_idx + 1;
        pixel_scale = .02/100; % Get actual value from probe dimensions
        tip_x = .4;
        x_pos = (tip_x-sort_x) * pixel_scale;
        x_pos = fliplr(x_pos);
        sorted_displacement = imaging.displacement_cell{iter1,iter2}(:,sort_idx);
        sorted_displacement = fliplr(sorted_displacement);

        % Resample
        delta_x = .003;
        p=2;
        q=1;
        % ensure an odd length filter
        n = 10*q+1;
        
        % use .25 of Nyquist range of desired sample rate
        cutoffRatio = .1;
        
        % construct lowpass filter 
        lpFilt = p * fir1(n, cutoffRatio * 1/q);

        [dis_vector, x_interp] = resample(sorted_displacement(1,:),x_pos,1/delta_x,p,q,lpFilt);
        displacement = zeros(size(imaging.displacement_cell{iter1,iter2},1),length(dis_vector));
        displacement(1,:) = dis_vector;
        for iter3 = 2:size(imaging.displacement_cell{iter1,iter2},1) 
            [dis_vector, ~] = resample(sorted_displacement(iter3,:),x_pos,1/delta_x,p,q,lpFilt);
            displacement(iter3,:) = dis_vector;
        end
        x_pos = x_interp;
        
        % Surf Plots of Center Axis
        [tMesh,xMesh] = meshgrid(linspace(time_step(1),time_step(end),1000),...
            linspace(x_pos(1),x_pos(end),1000));
        zMesh = griddata(time_step,x_pos,displacement',tMesh,xMesh,"cubic");
        figure;
        s = surf(xMesh,tMesh,zMesh);
        s.EdgeColor = 'none';
        colormap(colorcet('COOLWARM'));
        view(2)
        set(gca,'Ydir','reverse')

        % Fit cos to data at each location on finger
        phase_shift = zeros(1,size(displacement,2));
        offset = zeros(1,size(displacement,2));
        amplitude = zeros(1,size(displacement,2));
        figure;
        subplot(1,2,1)
        for iter3 = 1:size(displacement,2)
            single_sine = displacement(:,iter3)';
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
            amplitude(iter3) = fitted_params(1);
            phase_shift(iter3) = fitted_params(2);
            offset(iter3) = fitted_params(3);
            plot(time_step,fit(fitted_params,time_step))
            hold on;
        end
        subplot(1,2,2)
        for iter3 = 2:size(displacement,2)
            plot(time_step,squeeze(displacement(:,iter3)))
            hold on;
        end
        hold off;

        % Compute wave speed and damping
        phase_shift = unwrap(2*pi*imaging.freqs(iter2)*phase_shift);
        %phase_shift = lowpass(phase_shift,5,100);
        %derivative = angdiff(phase_shift(2:end),phase_shift(1:end-1))./(x_pos(2:end)-x_pos(1:end-1));
        derivative_guess = zeros(1,length(x_pos)+1);
        derivative = TVR_Derivative(phase_shift,derivative_guess,delta_x,500,.015);
        wave_speed = imaging.freqs(iter2)*2*pi./derivative;
        %wave_speed = lowpass(wave_speed,30,100);
        figure(10);
        subplot(1,3,1);
        plot(x_pos,phase_shift)
        hold on;
        subplot(1,3,2);
        plot([x_pos, x_pos(end)+delta_x],wave_speed)
        hold on;
        subplot(1,3,3);
        plot(x_pos,amplitude)
        ylim([0,1.7])
        hold on;
    end
    % figure;
    % plot(squeeze(median(x_pos(:,1:end-1),1)),squeeze(median(wave_speed(:,:,1),2)))
    % hold on;
    % plot(squeeze(median(x_pos(:,1:end-1),1)),squeeze(median(wave_speed(:,:,2),2)))
    % figure;
    % plot(squeeze(median(x_pos,1)),squeeze(median(amplitude(:,:,1),2)))
    % hold on;
    % plot(squeeze(median(x_pos,1)),squeeze(median(amplitude(:,:,2),2)))
    % ylim([0,1.7])
end
