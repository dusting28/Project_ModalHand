clc; clear; close all;

%% Direct Sound Driver
% sig_len = 2;
% 
% deviceWriter = audioDeviceWriter;
% devices = getAudioDevices(deviceWriter);
% 
% deviceWriter.Device = devices{1};
% info(deviceWriter)
% fs = deviceWriter.SampleRate;
% 
% setup(deviceWriter,zeros(sig_len*fs,2))
% 
% t = 0:(1/fs):sig_len;
% signal = repmat(sin(2*pi*100*t),2,1);
% 
% deviceWriter(signal')
% 
% release(deviceWriter)

%% ASIO Driver
channels = 3;%[3,4];
fs = 48000;
sig_len = 2;
amp = .04;
freq = 100;

num_channels = 4;
MotuDevice = audioPlayerRecorder('SampleRate',fs,'BitDepth','32-bit float');
devices = getAudioDevices(MotuDevice);
MotuDevice.Device = devices{3};

t = (0:fs*sig_len-1)/fs;
signal = amp*sin(2*pi*freq*t);

% ww1=hanning(length(signal)/2);
% ww=[ww1;zeros(length(signal)/2,1)];

ww=hanning(length(signal));

signal = signal.*ww';

motu_sig = zeros(length(signal),num_channels);
motu_sig(:,channels) = repmat(signal,length(channels),1)';

MotuDevice(motu_sig);
%pause(sig_len*5);


%release(MotuDevice)

%% DAQ approach
%dev = daqlist;