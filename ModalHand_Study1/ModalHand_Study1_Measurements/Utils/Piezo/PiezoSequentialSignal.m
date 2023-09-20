%% Generate a test signal for the piezo array
% Written by Gregory Reardon (reardon@ucbs.edu)

function yOut = PiezoSequentialSignal(yIn, nActuators, delta, fs, peakAmp, optDC, optRefVoltage)
%----------------------------------------------------------
% inputs:
%       yIn (array): test signal to be played through each piezo
%       nActuators (int): number of piezo actuators in array
%       delta (float): time between each test signal (in seconds)
%       fs (int): sa mpling rate
%       peakAmp (float): peak amplitude of driving signal (in volts)
%                    piezo amp multiplies this by 15...
%       optDC (float): add optional DC offset to output Signal
% outputs:
%       yOut (2D array): test signal to be played to the piezo actuators
%----------------------------------------------------------
plot = false;
refLength = 10000; %add extra signal length for reference signal 
endLength = 2000; %extra time at end of signal for decay
% refLength = 1;
% endLength = 1;

nSamps = length(yIn); %number of samples per test signal
nDelta = delta*fs; %number of samples between each test signal
signalIncrement = nSamps+nDelta+endLength;

yOut = zeros(refLength+(signalIncrement*nActuators),nActuators+1); % Bipolar (updated on 09/23/2019)

s = refLength;

for i = 1:nActuators
    yOut(s:s+nSamps-1,i) = yIn*peakAmp; % Bipolar (updated on 09/23/2019)    
    s = s+signalIncrement;
end

% optional DC offset
if exist('optDC','var')
    yOut = yOut+optDC;
end

% optional reference voltage
if exist('optRefVoltage','var')
    refVoltage = optRefVoltage;
else
    refVoltage = 0.2;
end

%reference pulses
yOut(:,nActuators+1) = 0;
refInd = refLength+(signalIncrement*(0:nActuators-1));
for i = 1:length(refInd)
    yOut(refInd(i):refInd(i)+50,nActuators+1) = refVoltage; % one reference pulse for each actuator
end

% Plot signals
nCols = min(nActuators+1,4); % Adaptive number of subplot columns (updated on 09/12/2019)
nRows = ceil(nActuators+1/nCols); % Adaptive number of subplot rows  (updated on 09/12/2019)
if plot
    for i = 1:size(yOut,2)        
        subplot(nRows,nCols,i); % Adaptive subplots
        plot((1:size(yOut,1))/fs,yOut(:,i)); % Plot the output signal on time axis
        xlabel('Time (secs)'); % Plot the output signal on time axis
        hold on
    end
end

end
