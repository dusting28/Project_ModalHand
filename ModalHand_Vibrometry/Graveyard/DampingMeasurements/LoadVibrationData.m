function [force,rms_force,displacement,rms_disp] = LoadVibrationData(filename,scale_factor,frequency)
    raw_data = load(filename);
    force = raw_data.Signals(:,:,3);

    displacement = scale_factor*...
        raw_data.Signals(:,:,7)/(2*pi*frequency);
    fs = raw_data.MeasurementSignal.fs;
    rms_disp_vector = zeros(size(displacement,2),1);
    rms_force_vector = zeros(size(force,2),1);
    for iter1 = 1:size(displacement,2)
        rms_disp_vector(iter1) = rms(squeeze(bandpass(displacement(round(.1*end):round(.9*end),...
            iter1),[frequency*.8,frequency*1.2],fs)));
        rms_force_vector(iter1) = rms(squeeze(bandpass(force(round(.1*end):round(.9*end),...
            iter1),[frequency*.8,frequency*1.2],fs)));
    end
    rms_disp = median(rms_disp_vector);
    rms_force = median(rms_force_vector);
end

