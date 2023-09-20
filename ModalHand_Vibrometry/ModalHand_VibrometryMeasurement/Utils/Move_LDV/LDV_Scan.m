%load('Calibration_Meta_22Pts.mat');

%% MANUALLY LOAD CALIBRATION FILE FOR QUICK SCAN
fr = 0.1;

%% Init NI card
sNI(1) = daq.createSession('ni');
sNI(1).Rate = 10000;
sNI(1).IsContinuous = 0;
AnalogOuts = sNI(1).addAnalogOutputChannel('Dev3',0:1 ,'Voltage');

for i = 1:length(GridLocations.voltageLocs)
    loc = GridLocations.voltageLocs(i,:);
    outputSingleScan(sNI(1),[loc(1) loc(2)]);
    pause(fr);
end
