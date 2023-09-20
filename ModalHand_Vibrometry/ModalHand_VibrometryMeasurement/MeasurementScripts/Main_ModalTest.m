%% This script is for running tactile source cloaking illusion
% Adapted from Greg
%
% Written by Dustin Goetz
%------------------------------------------------------------------------
%% Load the params file - MAKE CHANGES IN PARAMS.M!
clc
clearvars -except forceBias
% objects = imaqfind; delete(objects); %find video input objects in memory and delete

folder = fileparts(which(mfilename));
addpath(genpath(folder));
Params_Sinesweep_9_29;
pause(1);

%% GUI Init
% Display Initialization
figSize = [20,20,1600,900];
fig_h = figure('Name','NI Data Acquisition','Position',figSize,...
    'Color',[0.98,0.98,0.98]);

%% Setup IDS Camera
% load('CalibrationFiles/CameraCalibration.mat')
% camRes = [1600 1200];
% warning('off','winvideo:propertyAdjusted'); % Suppress a warning
% dev_info = imaqhwinfo('winvideo',1); % Get cam dev info
% imgFormat = dev_info.SupportedFormats; % Supported cam format
% vidInfo.video = videoinput('winvideo',1,imgFormat{4});
% vidInfo.params = params;
% vidInfo.scale = fisheyeScale;
% triggerconfig(vidInfo.video,'manual');
% start(vidInfo.video);
% 
% vidInfo.fs = 30; %set camera fps to 30
% 
plots.imP = subplot('Position',[0, 0.22, 0.8, 0.6]);
% img = GetImage(vidInfo);
% plots.im = imshow(img);
% 
% xlim([1 camRes(1)]);
% ylim([1 camRes(2)]);

plots.t1 = text(50, 100, 'Min Force: ', 'Color','w');
plots.t2 = text(50, 150, 'Mean Force: ', 'Color','w');
plots.t3 = text(50, 200, 'Max Force: ', 'Color','w');

plots.p1 = subplot('Position',[0.81, 0.70, 0.16, 0.2]);
plot(ones(100,1))

plots.p2 = subplot('Position',[0.81, 0.40, 0.16, 0.2]);
plot(ones(100,1))

plots.p3 = subplot('Position',[0.81, 0.10, 0.16, 0.2]);
plot(ones(100,1))



%% Setup MOTU
% lenSecs = size(TestSignal.piezoSignals,1) / TestSignal.fs;  % Total measurement length
MeasurementSignalMOTU.fs = 96000;
MeasurementSignalMOTU.nBits = 24;
MeasurementSignalMOTU.nChannels = 2;
devID = 1;
devInfo = audiodevinfo;
recObj = audiorecorder(MeasurementSignalMOTU.fs, MeasurementSignalMOTU.nBits, ...
                        MeasurementSignalMOTU.nChannels, devID);

%% Setup the NI measurement device
dev_num = 'Dev1';
daq_in = daq('ni');
daq_in.Rate = MeasurementSignal.fs;

for iter1=1:length(MeasurementSignal.forceCh)
    analogInput = addinput(daq_in,dev_num,MeasurementSignal.forceCh(iter1),'Voltage');
    analogInput.TerminalConfig = 'SingleEnded'; %floating measurement signal
end
    
analogInput = addinput(daq_in,dev_num,MeasurementSignal.refCh,'Voltage');
analogInput.TerminalConfig = 'Differential';

%% Setup Scanning LDV
% ldv = daq.createSession('ni');
% ldv.Rate = 10000;
% ldv.IsContinuous = 0;
% AnalogOuts = ldv.addAnalogOutputChannel('Dev3',0:1 ,'Voltage');
% fr = 1/1000; % 1000 sample sr for moving laser slowly
% 
% %move to standard 0,0 location
% if exist('FingertipStruct','var')
%     ldvStartLoc = FingertipStruct.voltageLoc;
% else
%     ldvStartLoc = [0 0];
% end
% outputSingleScan(ldv,ldvStartLoc);
% pause(2); %wait for laser to stop vibrating %% SHOULD UNCOMMENT THIS FOR REAL MEASUREMENTS

%% Force Bias Measurement
if ~exist('forceBias','var')
    input('Re-taking force bias measurements. Please acknowledge that there is nothing contacting the force sensor')
    forceBias = forceBiasMeas(daq_in,12);
    input('Done taking bias measurements. Press Enter to continue');
end


%% MAIN LOOP
%isTakingSnapshot = false;
% moduloCam = ceil((1/fr) / vidInfo.fs);

axes(plots.imP);
trialText = text(1200, 100, 'Trial: ', 'Color','w');
plots.repText = text(1200,150, 'Repetition: ','Color','w');
nTrials = (size(GridLocations.voltageLocs,1)-MeasurementInfo.startLocOffset);

Signals.Motu = cell(nTrials,MeasurementInfo.nRepetitions);
Signals.Daq = cell(nTrials,MeasurementInfo.nRepetitions); 
Signals.Image = cell(nTrials,MeasurementInfo.nRepetitions);

%for i = 1:nTrials
for i = 1:nTrials
    %move to target location
    
    % Use IDS camera to track the laser 
%     img = GetImage(vidInfo);
%     plots.im.CData = img;
    trialText.String = sprintf('Trial: %i', i);
%     loc = GridLocations.voltageLocs(i+MeasurementInfo.startLocOffset,:); %get the current location
%     moveDist = sqrt(sum((ldvStartLoc - loc).^2));
%     moveTime = ceil(moveDist*500);
%     y = zeros(moveTime,2);
%     y(:,1) = linspace(ldvStartLoc(1),loc(1),moveTime);
%     y(:,2) = linspace(ldvStartLoc(2),loc(2),moveTime);
%     for j = 1:moveTime
%         if (mod(j,moduloCam) == 0)
%             img = GetImage(vidInfo);
%             plots.im.CData = img;
%         end
%         outputSingleScan(ldv,[y(j,1) y(j,2)]);
%         pause(fr);
%             
%     end
%     pause(2); % Pause between trials (added on 09/12/2019)

    MeasurementSignal.forceBias = forceBias;
    
    % MEASUREMENT LOOP
%     temp = MeasurementLoop_ModalTest(MeasurementSignal,MeasurementInfo,TestSignal,daq_in,recObj, vidInfo, SLDVInfo, plots);
    temp = MeasurementLoop_ModalTest(MeasurementSignal,MeasurementInfo,TestSignal,daq_in,recObj, 1, SLDVInfo, plots);
    Signals.Motu(i,:) = temp.Motu;
    Signals.Daq(i,:) = temp.Daq;
%     Signals.Image(i,:) = temp.Image;

    fprintf('Completed Trial %i\n',i);
%     ldvStartLoc = loc;
    
        %autosave feature every 10 measurements
    if (mod(i,25) == 0)
        fprintf('Autosaving - Trial %i\n',i);
        autoSaveFN = sprintf('Data/Autosave/Measurement-AutoSave_%s.mat',datestr(now,'dd_mm_HH_MM_SS'));
        save(autoSaveFN,'Signals','TestSignal','GridLocations','SLDVInfo','MeasurementInfo','MeasurementSignal','-v7.3');
    end
   

end

%% Save
if isfield(MeasurementInfo,'outputDir')
    outputDir = MeasurementInfo.outputDir;
else
    outputDir = 'MatFiles';
end

% Preferably, will save with a tagname fn if defined
if isfield(MeasurementInfo, 'fn')
    measFN = sprintf('%s/%s.mat',outputDir,MeasurementInfo.fn);
else
    measFN = sprintf('%s/Measurement_%s.mat',outputDir,datestr(now,'dd_mm_HH_MM_SS'));  % Define based on time, as backup
end

save(measFN,'Signals','TestSignal','GridLocations','SLDVInfo','MeasurementInfo','MeasurementSignal','-v7.3');