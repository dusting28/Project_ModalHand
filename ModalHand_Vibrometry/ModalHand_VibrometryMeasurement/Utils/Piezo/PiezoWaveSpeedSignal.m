%% Generate a test signal for the piezo array
% Written by Gregory Reardon (reardon@ucbs.edu)

function yOut = PiezoWaveSpeedSignal(yIn, nSpeeds, delta, fs, peakAmp, bandwidth, waveBand)
%----------------------------------------------------------
% inputs:
%       yIn (array): test signal to be played through a single piezo
%       nSpeeds (int): number of wavespeeds to estimate
%       delta (float): time between each test signal (in seconds)
%       fs (int): sampling rate
%       peakAmp (float): peak amplitude of driving signal (in volts)
%                    piezo amp multiplies this by 15...
%       bandwidth (float): width of each test signal in Hz (20 Hz)
%       waveBand (array): bandwidth of waves to be estimated (i.e. [50 800]) 
% outputs:
%       yOut (2D array): test signal to be played to the piezo actuators
%----------------------------------------------------------
refLength = 20000; %add extra signal length for reference signal 
endLength = 8000; %extra time at end of signal for decay

nSamps = length(yIn); %number of samples per test signal
nDelta = delta*fs; %number of samples between each test signal
signalIncrement = nSamps+nDelta+endLength;

yOut = zeros(refLength+(signalIncrement*nSpeeds),1); % Bipolar (updated on 09/23/2019)

s = refLength;

nCols = min(nSpeeds,4); % Adaptive number of subplot columns (updated on 09/12/2019)
nRows = ceil(nSpeeds/nCols); % Adaptive number of subplot rows  (updated on 09/12/2019)

fund = linspace(waveBand(1),waveBand(2),nSpeeds);
hbw = bandwidth/2;

for i = 1:nSpeeds
    
    %filter
    temp = yIn;

    [b,a] = butter(2, [fund(i)-hbw fund(i)+hbw] / (fs/2));
    temp = filter(b, a, temp);
    
    %norm
    temp = temp ./ max(abs(temp));
    
    %set output
    yOut(s:s+nSamps-1,1) = temp*peakAmp;
    s = s+signalIncrement;
    
    %plotting
    [yfft,f]=spectr(temp,fs,[0 1000]);
    subplot(nRows,nCols,i); % Adaptive subplots (updated on 09/12/2019)
    plot(f,20*log10(yfft));
    %plot((1:size(yOut,1))/fs,yOut(:,1)); % Plot the output signal on time axis
    %xlabel('Time (secs)'); % Plot the output signal on time axis (updated on 09/12/2019)    
    hold on
    %plot((refLength+(signalIncrement*(i-1)))/fs,p2p,'+r'); % Plot reference signal
end

%set reference pulses
yOut(:,2) = 0;
refInd = refLength+(signalIncrement*(0:nSpeeds-1));
yOut(refInd,2) = 0.2; % one reference pulse for each actuator (updated on 09/12/2019)

end
