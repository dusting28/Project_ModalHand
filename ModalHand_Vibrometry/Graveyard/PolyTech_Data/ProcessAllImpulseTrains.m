% Written by Gregory Reardon (reardon@ucsb.edu)
% Edited by Neeli Tummala

%TODO: add another for other subjects

%% CLEAR VARS
clear
clc
close all
currentFolder = pwd;
dataFolder = strcat(currentFolder,'\Shear_Impulse_Data\');
addpath('PolyTecScripts');
addpath('Shear_Impulse_Data');

%% PARAMS
subject = ["123","629","736","789","Bha"];
% subject = ["123","Bha"];
session_number = "09";

%% Parse data and return a formatted table
% filePrefix = sprintf('../Shear_Impulse_Data/Subject%s/',subject);
% dataFolder = dir([filePrefix, '/*.svd']);
% Will save impulse responses for every session in the subject's folder
for iter1 = 1:length(subject)
    fileSuffix = sprintf('Subject%s_Session%s',subject(iter1),session_number);
    subjFilename = sprintf('%sSubject%s_Session%s.svd',dataFolder,subject(iter1),session_number);
    sessionNum = str2num(session_number);%str2num(fileSuffix(end-5:end-4));
    
    %% Grab SLDV Data from Polytec
    [x,y,~] = GetPointData(subjFilename,'Time', 'Vib', 'Velocity', ...
        'Samples', 0,0);
    [xRef,yRef,~] = GetPointData(subjFilename,'Time', 'Ref1', 'Voltage',...
        'Samples', 0,0);
    coords = GetXYZCoordinates(subjFilename,0);
    
    % Get sampling rate
    fs = 1/(x(2) - x(1));
    
    %% Chop Impulses
    % Notes: if SR = 20 kHz then theres 100 ms per stimulus applied
    nReps = 10; % 10 impulses delivered to hand
    preDelay = 0.001*fs; % burn in samples before impulse --> 1 ms
    nSamps = 0.1*fs; % exactly 2000 samples separating stimuli
    yPreprocessed = ChopImpulseTrain(y, yRef, nReps, nSamps, preDelay, fs);
    
    %% Downsample if sampling rate is greater than 20 kHz
%     if fs > 20000
%         %resample to 20 kHz
%         resamplingTarget = 20000;
%         
%         %resample treats each column as independent channel
%         yPreprocessed = (resample(yPreprocessed', resamplingTarget,cast(fs,"int64")))';
%         yRef = (resample(yRef',resamplingTarget,cast(fs,"int64")))';
%     end
    
    %% Store data
    if exist('dataTable','var')
        tempTable = cell2table({yPreprocessed},'VariableNames',{'Vib'});
        tempTable.Ref1 = {yRef};
        tempTable.Coords = {coords};
        tempTable.Subject = subject;
        tempTable.SessionNum = sessionNum;
        tempTable.Location = {SessionNumToLoc(sessionNum)};
        tempTable.Contact = {SessionNumToContact(sessionNum)};
        tempTable.SamplingRate = 20000;
        tempTable.OriginalSamplingRate = fs; 
        tempTable.Filename = {fileSuffix};
        
        %concatenate temptable with the current data table
        dataTable = [dataTable; tempTable];
    else
        dataTable = cell2table({yPreprocessed},'VariableNames',{'Vib'});
        dataTable.Ref1 = {yRef};
        dataTable.Coords = {coords};
        dataTable.Subject = subject;
        dataTable.SessionNum = sessionNum;
        dataTable.Location = {SessionNumToLoc(sessionNum)};
        dataTable.Contact = {SessionNumToContact(sessionNum)};
        dataTable.SamplingRate = 20000;
        dataTable.OriginalSamplingRate = fs; 
        dataTable.Filename = {fileSuffix};
    end
    clear tempTable

%     %save the data table
%     save(['SLDV/ImpulseData/',subject,'/',fileSuffix(1:end-4),'_Impulses.mat'],...
%         'dataTable', '-v7.3');
end