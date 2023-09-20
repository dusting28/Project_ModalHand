%% Written by Gregory Reardon (reardon@ucsb.edu)
% Chops a repeated measurement using a detection function and returns
% the median of the repeated measurements
% -------------------------------------------------------------------------
% Inputs:
%         y: signals to be chopped
%         yRef: reference voltage channel for chopping signals
%         nReps: number of stimulus repetition applied
%         nSamps: length of each stimulus
%         preDelay: number of prior to stimulus start to be grabbed(required
%                   because the thresholding of the detection function grabs 
%                   the signal just after its begun)
%         thresh: value used to pick the beginning of stimulus from the
%                 detection function (set heuristically)
%                   --> might need to be improved...can take 0.8*max
%                       of aggregate signal or something like that....
% Outputs:
%         yOut: median of the repeated measurements for all locations
%       
%% MAIN BODY --------------------------------------------------------------
function yOut = ChopImpulseTrain(y, yRef, nReps, nSamps, preDelay, fs)

%make aggregate detection signal
aggRef = sum(yRef,1);
detectionFn = abs(diff(aggRef));
plot(detectionFn);
thresh = max(detectionFn)*0.75; % thresh based on detection function

yPreprocessed = zeros(size(y,1),nSamps, nReps);
temp = detectionFn;
tempY = y;
for i = 1:nReps
    
    %find stimulus start
    idx = find(temp > thresh,1);
    sIdx = idx - preDelay; %add a pre-delay to capture beginning of stimulus
    yPreprocessed(:,:,i) = tempY(:,sIdx:sIdx+nSamps-1); %store in output variable
    
    %remove section from these temp variables that have already been processed
    temp = temp(sIdx+nSamps-preDelay:end);
    tempY = tempY(:,sIdx+nSamps-preDelay:end);

    %subplot(2,1,1)
    %plot(aggRef)
    %subplot(2,1,2)
    %plot(temp);
    
end

yOut = median(yPreprocessed,3); %compute median of responses over 10 stimuli --> removes outliers

aggOut = sum(yOut,1); %observe the aggregated response over all measurement locations
plot(aggOut);

% Plot all individual time responses
for i=1:nReps
    subplot(5, 2, i)
    Y = yPreprocessed(300, :, i);
    t = (1:length(Y))/fs;
    plot(t, Y);
    grid on
    xlabel('Time (s)')
    ylabel('Velocity (m/s)')
    title('Impulse response')
end

figure;
% Plot final frequency response
Y = fft(yOut, [], 2);
nBins = size(Y, 2) / 2;
Y = Y(:, 1:nBins);
% normalize the FFT
Y = Y./nBins;
resolution = 0.5*fs/nBins;
% Plot frequency response
freqs = (0:nBins-1) * resolution;
magnitude = abs(Y);
plot(freqs(freqs<=1000), magnitude(:, freqs<=1000));
grid on
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title('Impulse response')

%view frequency responses of measurements
%[yfft, freqs] = spectr(yOut',fs,[0 1000]);
%plot(freqs, yfft);

