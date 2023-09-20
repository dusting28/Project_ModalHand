function [admittance] = waveAdmittance(skin_compression, yprobe, freq, ylocations, model_type)

% Damping and wavespeed from literature
sample_freq = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1250];
if strcmp(model_type, "Potts")
    sample_speed = [6, 8, 9, 9, 10, 11, 11, 8, 8, 8, 8, 8]*1000; % Potts (mm/s)
    sample_damping = 1./[11, 10, 9, 6, 4, 3, 3, 3, 3, 3, 3, 3]; % Potts (1/mm)
end
if strcmp(model_type,"Manfredi")
    sample_speed = [18, 18, 10, 7.5, 5, 6, 7.5, 8, 8, 8, 8, 8]*1000; % Manfredi (mm/s)
    sample_damping = [1.35, 1.15, 1.1, 1.15, 1.25, 1.15, 1.2, 1.25, 1.3, 1.35, 1.35, 1.35]; % Manfredi 
end
if strcmp(model_type, "Simple")
    sample_damping = 1/12*ones(1,length(sample_freq));
    sample_speed = 1000*8.5*ones(1,length(sample_freq));
end

% Interpolate to other frequencies
wave_speed = interp1(sample_freq, sample_speed, freq);
damping_coefficient = interp1(sample_freq, sample_damping, freq); 

% Format input velocity
distance = (ylocations-yprobe);
for iter1 = 1:length(distance)
    if distance(iter1) <= 0
        distance(iter1) = 0;
    end
end
input_matrix = repmat(1000*2*pi*1i*freq.*skin_compression,length(distance),1);

% Phase (from wave-speed)
k = freq./wave_speed;
phase = cos(2*pi*distance'*k) + 1i * sin(2*pi*distance'*k);

% Amplitude (from damping)
if strcmp(model_type, "Manfredi")
    amp = zeros(length(distance),length(freq));
    for iter1 = 1:length(freq)
        amp(:,iter1) = 1./(distance'.^damping_coefficient(iter1)); % Manfredi
    end
    for iter1 = 1:length(distance)
        if distance(iter1) < 1
            amp(iter1,:) = 1;
        end
    end
else
    amp = exp(-distance'*damping_coefficient); % Potts
end

% Calculate admittance
admittance =  amp.*phase.*input_matrix;
    
end