fr = 0.1;

%% Init NI card
sNI(1) = daq.createSession('ni');
sNI(1).Rate = 10000;
sNI(1).IsContinuous = 0;
AnalogOuts = sNI(1).addAnalogOutputChannel('Dev3',0:1 ,'Voltage');

%%
%loc = [-3.5, 0.5];
%loc = [-4.5, -1.5];
loc = [-0.59, 2.08];
outputSingleScan(sNI(1),[loc(1) loc(2)]);
pause(fr);

%%
%scattering lens ends at 2.15...so all points with x < 2.15 are valid