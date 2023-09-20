sNI(1) = daq.createSession('ni');
sNI(1).Rate = 10000;
sNI(1).IsContinuous = 0;

AnalogOuts = sNI(1).addAnalogOutputChannel('Dev3',0:1 ,'Voltage');

x = -3.6;
%y = -0.1;
%y = 0.8;
%y = -1.0;
%y = 3.72;
y = .5;

outputSingleScan(sNI(1),[x y]);
