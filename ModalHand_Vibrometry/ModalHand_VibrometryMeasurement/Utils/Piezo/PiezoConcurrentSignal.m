%% Generate a test signal for the piezo array
% Written by Gregory Reardon (reardon@ucbs.edu)

function yOut = PiezoConcurrentSignal(yIn, nActuators, delta, fs, peakAmp, optDC)
%----------------------------------------------------------
% inputs:
%       yIn (array): test signal to be played through each piezo
%       nActuators (int): number of piezo actuators in array
%       delta (float): time between each test signal (in seconds)
%       fs (int): sa mpling rate
%       p2p (float): peak-to-peak amplitude of driving signal (in volts)
%                    piezo amp multiplies this by 15...
% outputs:
%       yOut (2D array): test signal to be played to the piezo actuators
%----------------------------------------------------------
refLength = 20000; %add extra signal length for reference signal 
endLength = 8000; %extra time at end of signal for decay

nSamps = length(yIn); %number of samples per test signal
nDelta = delta*fs; %number of samples between each test signal
signalIncrement = nSamps+nDelta+endLength;


% yOut = zeros(refLength+(signalIncrement*nActuators)+endLength,nActuators+1) + (0.5*p2p); % Unipolar, p2p (updated on 09/12/2019)
%yOut = zeros(refLength+(signalIncrement*nActuators),nActuators+1); % Bipolar (updated on 09/23/2019)
yOut = zeros(refLength+(signalIncrement),nActuators+1); % Bipolar (updated on 09/23/2019)

s = refLength;

nCols = min(nActuators,4); % Adaptive number of subplot columns (updated on 09/12/2019)
nRows = ceil(nActuators/nCols); % Adaptive number of subplot rows  (updated on 09/12/2019)
for i = 1:nActuators
    yOut(s:s+nSamps-1,i) = yIn*peakAmp(i); % Bipolar (updated on 09/23/2019)
    %s = s+signalIncrement;
    subplot(nRows,nCols,i); % Adaptive subplots (updated on 09/12/2019)
    plot((1:size(yOut,1))/fs,yOut(:,i)); % Plot the output signal on time axis
    xlabel('Time (secs)'); % Plot the output signal on time axis (updated on 09/12/2019)    
    hold on
    plot((refLength+(signalIncrement))/fs,1,'+r'); % Plot reference signal
end


% optional DC offset
if exist('optDC','var')
    yOut = yOut+optDC;
end

%TODO: add pulses
% yOut(4000,nActuators+1) = 0.1; %reference pulse - 2 Volts P2P
yOut(:,nActuators+1) = 0;
%yOut(:,:) = 0;
%refInd = refLength+(signalIncrement*(0:nActuators-1));
refInd = refLength;
 
yOut(refInd,nActuators+1) = 0.2; % one reference pulse for each actuator (updated on 09/12/2019)
end
