
%% USB DAQ Measurements
MeasurementSignal.fs = 2500;
MeasurementSignal.forceCh = ["ai0", "ai1", "ai2", "ai4", "ai5", "ai6"]; %force channels on NI card
MeasurementSignal.refCh = "ai3";

%% Test Signal
TestSignal.fs = 96000;
TestSignal.refChannel = 2; %channel in which reference signal is connected
TestSignal.actuatorChannels = 1;
TestSignal.nActuators = length(TestSignal.actuatorChannels); %number of actuators (not including reference)

%signal params
TestSignal.PeakAmp = .03; %peak amp from Default_Params
TestSignal.delStart = 2; %time before stim start and end
TestSignal.bitDepth = 24; %bit depth of signal sent to Max
TestSignal.udpmessage = 'sweep';
TestSignal.f0 = 10; %start frequency
TestSignal.f1 = 1000; %end frequency
TestSignal.sweepType = 'log'; %type of sine sweep ('log' or 'linear')
TestSignal.delta = 1; %time between actuator sweeps (in seconds)
TestSignal.sigLength = 10; % signal length in seconds
TestSignal.DCOffset = 0; % 60 volts dc offset (4*15V Amp);
TestSignal.refVoltage = 0.5; % 0.1 volt ref
TestSignal.winLen = 20000; %20000 sample window ramp in/ramp out (10k each)

% generate sine sweep test signal
TestSignal.y  = sineSweep(TestSignal.f0,TestSignal.f1,TestSignal.sigLength,...
    TestSignal.fs,TestSignal.sweepType,TestSignal.winLen); 

freeFixedFilter = input('Free or Fixed: ','s'); % *Replace with velocity setting used on SLDV

%filter the test signal
if strcmp('free',freeFixedFilter)
    load('CalibrationFiles/Filter3.mat'); %*****
    TestSignal.filter = Ham2; %********
elseif strcmp('fixed',freeFixedFilter)
    load('CalibrationFiles/FreeFilter.mat');
    TestSignal.filter = Ham3; 
else
    error('Filter not found!');
end

TestSignal.filteredY = filter(TestSignal.filter,TestSignal.y);

% generate array of piezo driving signals
TestSignal.piezoSignals = PiezoSequentialSignal(TestSignal.filteredY, TestSignal.nActuators,...
    TestSignal.delta, TestSignal.fs, TestSignal.PeakAmp, TestSignal.DCOffset, TestSignal.refVoltage);

%% generate max test signals
%construct .wav file 
GenerateTestSignals_9_2('Utils/MaxUtils/MaxTestSignals/MetawaveSweep.wav', ...
    TestSignal.piezoSignals, TestSignal.fs, TestSignal.bitDepth, TestSignal.actuatorChannels);

%send message to max to load signal into buffer
MaxMSPLoadTestSignals('sweep');

%% Construct piezo-dependent gain for measuring to avoid clipping SLDV

%load script
%MeasurementInfo.calibrationFile = 'UniformGridCalibration_LowRes_11_5.mat';
%load(sprintf('CalibrationFiles/%s',MeasurementInfo.calibrationFile));
GridLocations.voltageLocs = [0,0];
MeasurementInfo.nRepetitions = 3;
MeasurementInfo.outputDir = 'Data/';
MeasurementInfo.fn = input('Please insert filename: ','s');
%MeasurementInfo.fn = 'Default';

MeasurementInfo.preload = 3.0; %measurement preload from force sensor (in Newtons)
MeasurementInfo.startLocOffset = 0; %start at first grid location (used if you need to complete a measurement after corruption of data)
MeasurementInfo.nLocations = size(GridLocations.voltageLocs,1);

%%
SLDVInfo.Velocity = input('LDV Velocity: ','s'); % *Replace with velocity setting used on SLDV
SLDVInfo.FreqResponseVal = input('LDV Frequency Response Value: '); % *Replace with Freq Response of SLDV (1,2,3,4 on device)
SLDVInfo.VoltageFactor = 13.33; % 30 Volt per MOTU Volt (1-1) (might be different if you measure with audio interface)
SLDVInfo.Type = 'SLDV'; %'Single-Point vs SLDV';

% Conversion from SLDV settings to values, see the Ometron spec sheet (i.e.
% the mouse pad)
freqRes = [5, 50, 500, 5000, 50000, 400000];
if strcmp(SLDVInfo.Type,'Single-Point')
    SLDVInfo.ScaleFactor = 5;
else
    if strcmp(SLDVInfo.Velocity,'Low')
        SLDVInfo.ScaleFactor = 1; % 1 mm/s per Volt
        SLDVInfo.FreqResponse = freqRes(SLDVInfo.FreqResponseVal);
    elseif strcmp(SLDVInfo.Velocity,'Medium')
        SLDVInfo.ScaleFactor = 10; % 10 mm/s per Volt
        SLDVInfo.FreqResponse = freqRes(SLDVInfo.FreqResponseVal+1);
    elseif strcmp(SLDVInfo.Velocity,'High')
        SLDVInfo.ScaleFactor = 100; % 100 mm/s per Volt
        SLDVInfo.FreqResponse = freqRes(SLDVInfo.FreqResponseVal+2);
    end
end