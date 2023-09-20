clc; clear;
addpath('C:\Users\Dustin Goetz\Documents\LinearStageCode\Sample-Source-Code\Sample Code\USB 64-bit DLL');
% addpath('C:\Program Files (x86)\Arcus Technology\Drivers, Libraries, Source\Performax USB v4.01');

[notfound,warnings] = loadlibrary('PerformaxCom.dll','PerformaxCom.h','mfilename','mxproto');

calllib('PerformaxCom','fnPerformaxComGetNumDevices',libpointer)
calllib('PerformaxCom','fnPerformaxComGetProductString',uint64(0),libpointer,uint64(0))
unloadlibrary PerformaxCom

