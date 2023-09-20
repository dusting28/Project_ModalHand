%% SLDV Calibration script
% Written by Gregory Reardon (reardon@ucsb.edu)
% See README.m for instructions on how to use the GUI

clc; clear;
close all; objects = imaqfind; %find video input objects in memory
delete(objects)

%% MAIN BODY
%--------------------------------------------------------------------------
addpath('Utils');
load('CalibrationFiles/CameraCalibration.mat')

%% Init NI card
sNI(1) = daq.createSession('ni');
sNI(1).Rate = 10000;
sNI(1).IsContinuous = 0;
AnalogOuts = sNI(1).addAnalogOutputChannel('Dev3',0:1 ,'Voltage');
amp = 5; %max amp of SLDV

%%
if amp > 5
    error('SLDV should not be driven above 5V')
end

% Display Initialization
figSize = [20,20,1200,750];
fig_h = figure('Name','NI Data Acquisition','Position',figSize,...
    'Color',[0.98,0.98,0.98]);

%% Initialize the IDS Camera (added on 01/28/2019)
camRes = [1600 1200];
warning('off','winvideo:propertyAdjusted'); % Suppress a warning
dev_info = imaqhwinfo('winvideo',1); % Get cam dev info
imgFormat = dev_info.SupportedFormats; % Supported cam format
vidInfo.video = videoinput('winvideo',1,imgFormat{4});
vidInfo.params = params;
vidInfo.scale = fisheyeScale;
triggerconfig(vidInfo.video,'manual');
start(vidInfo.video);

%% init plots
subplot('Position',[0.01, 0.22, 0.98, 0.75]);
img = getsnapshot(vidInfo.video);
plt_h(1) = imshow(img);

xlim([1 camRes(1)]);
ylim([1 camRes(2)]);

hold on
plt_h(2) = scatter([],[],'r', 'filled'); %for grid anchors
hold off

%%
nAnchors = 24;
anchorNames = sprintfc('A%i',1:nAnchors);

%--------------------------------------------------------------------------
%% UI ELEMENTS
%--------------------------------------------------------------------------
%% X Voltage UI Elements
% slider for controlling x voltage
uicontrol('Style', 'slider',...
    'Position', [30 120 80 20],...
    'Callback', {@adjustVoltage, plt_h, sNI},...
    'BackgroundColor',[1,1,1],...
    'Tag','slideX','SliderStep',[0.001,0.01],...
    'Max', amp, 'Min',-amp);

% label for x voltage slider
uicontrol('Style', 'text',...
    'Position', [30 140 100 15],...
    'BackgroundColor',[1,1,1],...
    'String','X Voltage');


%% Y Voltage UI Elements
% slider for controlling y voltage
uicontrol('Style', 'slider',...
    'Position', [65  20 20 80],...
    'Callback', {@adjustVoltage, plt_h, sNI},...
    'BackgroundColor',[1,1,1],...
    'Tag','slideY','SliderStep',[0.001,0.01],...
    'Max', amp, 'Min',-amp);

% label for y voltage slider
uicontrol('Style', 'text',...
    'Position', [30 100 100 15],...
    'BackgroundColor',[1,1,1],...
    'String','Y Voltage');

%% Anchor UI Elements
% button for storing anchors
uicontrol('Style', 'pushbutton',...
    'Position', [200 70 80 30],...
    'Callback', {@saveAnchor, vidInfo},...
    'BackgroundColor',[0.9,0,0],...
    'String','Save Anchor');

% popup menu for holding anchor positions
c = uicontrol('Style','popupmenu',...
    'Position', [200 90 100 40],...
    'Callback', {@editAnchor, plt_h, sNI},...
    'BackgroundColor', [1 1 1],...
    'String', anchorNames,...
    'Tag','anchorMenu');

% label for anchors
uicontrol('Style', 'text',...
    'Position', [200 130 100 15],...
    'BackgroundColor',[1,1,1],...
    'String','Anchors');

%% GRID SWEEP
% Editable text for controlling grid sweep speed
gridSweepObj = uicontrol('Style', 'edit',...
    'Position', [700 90 100 20],...
    'BackgroundColor',[1,1,1],...
    'String','100');

% label for grid sweep speed
uicontrol('Style', 'text',...
    'Position', [675 110 150 20],...
    'BackgroundColor',[1,1,1],...
    'String','LDV Sweep Update Rate (Hz)');

% button for building a measurement grid
grid = uicontrol('Style', 'pushbutton',...
    'Position', [550 80 100 60],...
    'Callback', {@checkerboardCalibration, plt_h, vidInfo, sNI, gridSweepObj, nAnchors},...
    'BackgroundColor',[0,0.8,0],...
    'String','Check Calibration');

%% Save UI Elements
% button for saving grid locations (and anchors) to calibration file
uicontrol('Style', 'pushbutton',...
    'Position', [1000 80 100 60],...
    'Callback', {@saveGrid, fig_h, nAnchors},...
    'BackgroundColor',[0,0.8,0.8],...
    'String','SAVE!');

%--------------------------------------------------------------------------
%% MAIN LOOP 
%--------------------------------------------------------------------------
gridEdges = ones(nAnchors,2); %data structure for plotting anchors
setappdata(grid.Parent,'isTakingSnapshot',false);
while ishandle(fig_h)
    
    % Use IDS camera to track the laser
    isTakingSnapshot = getappdata(grid.Parent,'isTakingSnapshot');
    if (isTakingSnapshot == false)
        img = getsnapshot(vidInfo.video);
        J1 = undistortFisheyeImage(img(:,:,:,1),vidInfo.params.Intrinsics,...
        'ScaleFactor',vidInfo.scale);

        if isvalid(plt_h(1))
            plt_h(1).CData = rot90(J1,2);
        end
    end
    
    %for each of four anchors 
    %(need to remove this hardcode if more anchors)
    for i = 1:nAnchors
        %construct variable names for accessing data with anchor locations
        varname = sprintf('Anchor%i',i);
        
        % if that anchor has been set, then set the anchor value to what
        % the user specified (c is anchor menu...bad variable names...)
        if isappdata(c.Parent,varname)
            gridLoc = getappdata(c.Parent,varname);
            gridEdges(i,1) = 200 + (120*gridLoc.voltageLoc(1));
            gridEdges(i,2) = (camRes(2)/2) + ((camRes(2)/10)*gridLoc.voltageLoc(2));
        end
    end
    
    %plot anchors
    set(plt_h(2),'XData',gridEdges(:,1),'YData',gridEdges(:,2));
    
    pause(0.1) %UI pause
end

%close udp port
%fclose(u);
stop(vidInfo.video); % stop video

%--------------------------------------------------------------------------
%% CALLBACK FUNCTIONS
%--------------------------------------------------------------------------


%%
function checkerboardCalibration(hObject, ~, plt, vidInfo, sNI, sweepSpeed, nAnchors)

    % remove hardcoding
    nSet = 0;
    for i = 1:nAnchors
        varname = sprintf('Anchor%i',i);
        if isappdata(hObject.Parent,varname)
            s = getappdata(hObject.Parent,varname);
            a(:,i) = s.voltageLoc;
            nSet = nSet+1;
        end
    end
    
    nPts = 100;
    nSquares = floor((nSet - 2) / 2);
    
    %check if the locations are empty
    if nSet > 4
        
        %create a progress bar
        w = waitbar(0,'Checking Calibration...');
        
        %make checkerboard squares
        locs = [];
        nStart = 1;
        for i = 1:nSquares
           tempLocs = makeSquare(a(:,nStart:nStart+3),nPts);
            
           if i == 1
               locs = tempLocs;
           else
               locs = [locs ; tempLocs];
           end
           nStart = nStart+2;
        end
        
        inc = 1/length(locs);%progress bar increment
        p = 0; % set progress to 0
        
        
        camFS = 30; %output camera frame each so often
        ldvFS = str2double(sweepSpeed.String);
        moduloCam = ceil(ldvFS / camFS);
        
        for i = 1:size(locs,1) %interate through each location
            
            %get the x,y locations
            x = locs(i,1);
            y = locs(i,2);

            %output laser
            outputSingleScan(sNI(1),[x y]);

            p = p+inc; %increment progress
            

            if (mod(i,moduloCam) == 0)
            
                img = getsnapshot(vidInfo.video);
                J1 = undistortFisheyeImage(img(:,:,:,1),vidInfo.params.Intrinsics,...
                    'ScaleFactor',vidInfo.scale);
                plt(1).CData = rot90(J1,2);
            end

            %update progress bar
            waitbar(p,w,'Checking Calibration...');

            %pause for user-specified duration of time
            pause(1/ldvFS);
        end
            
        %when the sweep is complete, update bar, pause, and then close
        %the progress bar
        waitbar(1,w,'Grid Sweep Complete!');
        pause(1);
        close(w);
    else
        error('Number of Anchors is less than 4. The LDV is not calibrated to the checkerboard.');
    end


end

%make a square to sweep over
function locs = makeSquare(corners, ptsPerEdge)
    
    if length(corners) ~= 4
        error('Number of corners is not 4, something is wrong');
    else
        %for x and y
        for j = 1:2
            t1(:,j) = linspace(corners(j,1),corners(j,2),ptsPerEdge);
            t2(:,j) = linspace(corners(j,2),corners(j,4),ptsPerEdge);
            t3(:,j) = linspace(corners(j,4),corners(j,3),ptsPerEdge);
            t4(:,j) = linspace(corners(j,3),corners(j,1),ptsPerEdge);
        end
        locs = [t1;t2;t3;t4]; 
    end
end


%% Save the grid when you're finished calibrating
function saveGrid(hObject, ~, f, nAnchors)

    nSet = 0;
    for i = 1:nAnchors
        varname = sprintf('Anchor%i',i);
        if isappdata(hObject.Parent,varname)
            s = getappdata(hObject.Parent,varname);
            Checkerboard(i,:) = s.voltageLoc;
            CheckerboardImage(i) = {s.image};
            nSet = nSet+1;
        end
    end
    
    nSquares = floor((nSet - 2) / 2);
    idx = 1;
    for j = 1:nSquares
        Vertices(j) = {Checkerboard(idx:idx+3,:)}; 
        idx = idx+2;
    end


    if nSet > 3
        fn = sprintf('CalibrationFiles/CheckerboardCalibration_%s.mat',datestr(now,'dd_mm_HH_MM_SS'));
        save(fn,'Checkerboard','CheckerboardImage','Vertices');
    else
        error('Number of Anchors is less than 4. The LDV is not calibrated to the checkerboard. Nothing was saved.');
    end
end

%% Adjust the laser position
function adjustVoltage(hObject,event, plt, sNI)

    %grab the slider values
    hX = findobj('Tag','slideX');
    hY = findobj('Tag','slideY');
    x = hX.Value;
    y = hY.Value;
    
    %plot current laser location
    set(plt(1), 'XData',x, 'YData',y);
    
    %change LDV voltage
    outputSingleScan(sNI(1),[x y]);
end

%% Save a given anchor
function saveAnchor(hObject,event, vidInfo)

    setappdata(hObject.Parent,'isTakingSnapshot',true);
    %grab current popup menu item number
    h = findobj('Tag','anchorMenu');
    menuNum = h.Value;
    
    %grab current slider values
    img = getsnapshot(vidInfo.video);
    %pixelLoc = laserToPixel(img, vidInfo.params, vidInfo.scale);
    hX = findobj('Tag','slideX');
    hY = findobj('Tag','slideY');
    xVal = hX.Value;
    yVal = hY.Value;
    
    %store image and laser voltage location
    location.image = rot90(undistortFisheyeImage(img(:,:,:,1),vidInfo.params.Intrinsics,...
        'ScaleFactor',vidInfo.scale),2);
    location.voltageLoc = [xVal, yVal];
    
    %set anchor
    varname = sprintf('Anchor%i',menuNum);
    setappdata(hObject.Parent,varname, location);
    
    %set the popup menu display - can be altered to pixel loc if neccessary
    menuItems = h.String; %cannot directly index into h.String cell array...very weird...
    newItem = sprintf('[%.2f, %.2f]', xVal, yVal);
    menuItems(menuNum) = {newItem};
    set(h,'String',menuItems);
    
    setappdata(hObject.Parent,'isTakingSnapshot',false);
end


%% Reset position of the LDV and UI to a saved anchor location if editing
function editAnchor(hObject,event, plt, sNI)

    %get the sliders
    hX = findobj('Tag','slideX');
    hY = findobj('Tag','slideY');
    
    %get the current anchor being modified (integer between [1,4])
    menuNum = hObject.Value;
    
    % construct variable name given the anchor number
    varname = sprintf('Anchor%i',menuNum);
    
    % if the anchor has been set...
    if isappdata(hObject.Parent,varname)
        
        % then get its value
        anchorLocation = getappdata(hObject.Parent,varname);
        
        
        % set the UI slider value to the stored value
        set(hX,'Value',anchorLocation.voltageLoc(1));
        set(hY,'Value',anchorLocation.voltageLoc(2));
        
        %send to Max via OSC
        %oscsend(u,'/loc','ff', anchorLocation.voltageLoc(1),anchorLocation.voltageLoc(2));   
        outputSingleScan(sNI(1),[anchorLocation.voltageLoc(1) anchorLocation.voltageLoc(2)]);
        
    end
end

%% ------------------- END ------------------------------------------------


