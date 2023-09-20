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
load('CalibrationFiles/Checkerboard_HighRes.mat');

%% Init NI card
sNI(1) = daq.createSession('ni');
sNI(1).Rate = 10000;
sNI(1).IsContinuous = 0;
AnalogOuts = sNI(1).addAnalogOutputChannel('Dev3',0:1 ,'Voltage');
amp = 5; %max amp of SLDV
gridSize = 19/32; %in inches
lastSquareSize = 6/32; % in inches (last square isn't fully calibrated because mirrors
lastSquareHeight = (lastSquareSize / gridSize);

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
vidInfo.res = camRes;
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
plt_h(3) = scatter([],[],8,'g', 'filled'); %for grid points
hold off

%%
nAnchors = length(Checkerboard);
nSquares = floor((nAnchors - 2) / 2);
epsilon = 0.0001;

%% UI ELEMENTS
%--------------------------------------------------------------------------

%%
% label for line position voltage slider
uicontrol('Style', 'text',...
    'Position', [30 200 100 15],...
    'BackgroundColor',[1,1,1],...
    'String','Line Start Position');

uicontrol('Style', 'slider',...
    'Position', [65  120 20 80],...
    'Callback', {@adjustVoltage, plt_h, sNI, Vertices, lastSquareHeight},...
    'BackgroundColor',[1,1,1],...
    'Tag','linePos','SliderStep',[0.001,0.01],...
    'Max', 0, 'Min', -(nSquares-1) - lastSquareHeight + epsilon);

%% Anchor UI Elements
% button for storing anchors
uicontrol('Style', 'pushbutton',...
    'Position', [150 70 80 30],...
    'Callback', {@saveLinePos, vidInfo, Vertices, lastSquareHeight},...
    'BackgroundColor',[0.9,0,0],...
    'String','Save Anchor');

% popup menu for holding anchor positions
c = uicontrol('Style','popupmenu',...
    'Position', [150 90 100 40],...
    'Callback', {@editLinePos, plt_h, sNI},...
    'BackgroundColor', [1 1 1],...
    'String', {'Fingertip','Wrist'},...
    'Tag','anchorMenu');

% label for anchors
uicontrol('Style', 'text',...
    'Position', [150 130 100 15],...
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

%%
gridResObj = uicontrol('Style', 'edit',...
    'Position', [850 90 100 20],...
    'BackgroundColor',[1,1,1],...
    'String','5');

% label for grid sweep speed
uicontrol('Style', 'text',...
    'Position', [825 110 150 30],...
    'BackgroundColor',[1,1,1],...
    'String','Uniform Measurement Grid Res (1/inches)');

%%
% button for drawing line across finger
drawLineObj = uicontrol('Style', 'pushbutton',...
    'Position', [30 70 100 40],...
    'Callback', {@drawLine, plt_h, vidInfo, sNI, gridSweepObj, Vertices, lastSquareHeight},...
    'BackgroundColor',[0,0.8,0.8],...
    'String','Draw Line');


% button for building a measurement grid
grid = uicontrol('Style', 'pushbutton',...
    'Position', [290 80 180 40],...
    'Callback', {@makeGrid, plt_h, vidInfo, sNI, Vertices, gridResObj, gridSize, lastSquareHeight},...
    'BackgroundColor',[0,0.8,0],...
    'String','Make Uniform Measurement Grid');

% % button for building a measurement grid
% grid = uicontrol('Style', 'pushbutton',...
%     'Position', [290 30 180 40],...
%     'Callback', {@makeGridLog, plt_h, vidInfo, sNI, Vertices, gridResObj},...
%     'BackgroundColor',[0,0.8,0],...
%     'String','Make Log Measurement Grid');

% button for building a measurement grid
sweepGridObj = uicontrol('Style', 'pushbutton',...
    'Position', [290 30 180 40],...
    'Callback', {@sweepGrid, plt_h, vidInfo, sNI, gridSweepObj},...
    'BackgroundColor',[0.8,0.8,0],...
    'String','Sweep Measurement Points');

%% Save UI Elements
% button for saving grid locations (and anchors) to calibration file
uicontrol('Style', 'pushbutton',...
    'Position', [1050 80 100 100],...
    'Callback', {@saveGrid, fig_h, Checkerboard, CheckerboardImage, Vertices, gridResObj},...
    'BackgroundColor',[0,0.8,0.8],...
    'String','SAVE!');


%%
%--------------------------------------------------------------------------
%% MAIN LOOP 
%--------------------------------------------------------------------------
gridEdges = ones(nAnchors,2); %data structure for plotting anchors
[xGridLocs, yGridLocs] = meshgrid((0:nSquares),(0:nSquares));
for i = 1:nAnchors
    %gridLoc = Checkerboard(i,:);
    gridEdges(i,1) = 200 + (60*xGridLocs(i));
%     if yGridLocs(i) < (nSquares-1)
%         yGridLocs(i) = -(nSquares-1) - lastSquareHeight;
%     end
    gridEdges(i,2) = (camRes(2)/4) + ((camRes(2)/20)*yGridLocs(i));

end

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
    
    %plot anchors
    set(plt_h(2),'XData',gridEdges(:,1),'YData',gridEdges(:,2));
    
    pause(0.1) %UI pause
end

stop(vidInfo.video); % stop video

%--------------------------------------------------------------------------
%% CALLBACK FUNCTIONS
%--------------------------------------------------------------------------


%% Save the grid when you're finished calibrating************************
function saveGrid(hObject, ~, f, Checkerboard, CheckerboardImage, Vertices, gridRes)

    if isappdata(hObject.Parent,'GridLocations')
        GridLocations = getappdata(hObject.Parent,'GridLocations');
        FingertipStruct = getappdata(hObject.Parent,'Anchor1');
        WristStruct = getappdata(hObject.Parent,'Anchor2');
        GridResolution = 1/str2double(gridRes.String);
        
        fn = sprintf('CalibrationFiles/UniformGridCalibration_%s.mat',datestr(now,'dd_mm_HH_MM_SS'));
        save(fn,'GridLocations','FingertipStruct','WristStruct','GridResolution','Checkerboard','CheckerboardImage','Vertices');
    else
        error('No Grid Locations were constructed! Nothing was saved.');
    end
end

%% 
function makeGrid(hObject, ~, plt_h, vidInfo, sNI, Vertices, gridResObj, gridSize, lastSquareHeight)
    
    nSet = 0;
    for i = 1:2
        varname = sprintf('Anchor%i',i);
        if isappdata(hObject.Parent,varname)
            s = getappdata(hObject.Parent,varname);
            anchors(i) = s.worldLoc(2);
            nSet = nSet+1;
        end
    end
    
    gridRes = (1/str2double(gridResObj.String))/gridSize;

    if nSet < 2
        error('Please position start and end of measurement grid')
    else
        div = 1 / gridRes;
        rem = 1 - (floor(div)*gridRes);
        
        %uniform gridding
        xVals = rem/2:gridRes:(1 - (rem/2));
        yVals = anchors(1):-gridRes:anchors(2);
        xVals = xVals(2:end-1); %remove edges of grid        
        [xGrid,yGrid] = meshgrid(xVals,yVals);
        
    end
    
    n = 1;
    for i = 1:size(xGrid,1)
        for j = 1:size(xGrid,2)
            locs(n,:) = [xGrid(i,j) yGrid(i,j)];
            voltage(n,:) = worldToVoltage(locs(n,:), Vertices, lastSquareHeight);
            n = n+1;
        end
    end
    
    GridLocations.voltageLocs = voltage;
    GridLocations.worldLocs = locs;
    GridLocations.xGrid = xGrid;
    GridLocations.yGrid = yGrid;
    
    setappdata(hObject.Parent, 'GridLocations', GridLocations);

    pltLocsX = 200 + (60*locs(:,1));
    pltLocsY = (vidInfo.res(2)/4) + ((vidInfo.res(2)/20)*abs(locs(:,2)));
    
    set(plt_h(3),'XData',pltLocsX,'YData',pltLocsY);

    
    fprintf('Number of measurement locations: %i\n', length(GridLocations.voltageLocs));
end


%% 
function sweepGrid(hObject, ~, plt, vidInfo, sNI, sweepSpeed)

    %yVal = findobj('Tag','linePos');
    GridLocations = getappdata(hObject.Parent,'GridLocations');
    voltageLocs = GridLocations.voltageLocs;
    
    ldvFS = str2double(sweepSpeed.String);
    camFS = 30; %output camera frame each so often
    moduloCam = ceil(ldvFS / camFS);
    
    for i = 1:length(voltageLocs)
        outputSingleScan(sNI(1),[voltageLocs(i,1) voltageLocs(i,2)]);
                
        if (mod(i,moduloCam) == 0)            
            img = getsnapshot(vidInfo.video);
            J1 = undistortFisheyeImage(img(:,:,:,1),vidInfo.params.Intrinsics,...
                'ScaleFactor',vidInfo.scale);
            plt(1).CData = rot90(J1,2);
        end
      
        pause(1/ldvFS);
    end
    
    
end

%%
function drawLine(hObject,~, plt, vidInfo, sNI, sweepSpeed, Vertices, lastSquareHeight)

    yVal = findobj('Tag','linePos').Value;
    xVals = linspace(0,1,50);
    
    ldvFS = str2double(sweepSpeed.String);
    camFS = 30; %output camera frame each so often
    moduloCam = ceil(ldvFS / camFS);

    voltageLocs = zeros(length(xVals),2);
    for i = 1:length(xVals)
        worldSpaceCoord = [xVals(i), yVal]; 
        voltageLocs(i,:) = worldToVoltage(worldSpaceCoord, Vertices, lastSquareHeight);
        %voltageLocs(i,:) = pointToVoltage(normCoord,cell2mat(Vertices(squareNum)));
    end
    
    for i = 1:length(xVals)
        outputSingleScan(sNI(1),[voltageLocs(i,1) voltageLocs(i,2)]);
                
        if (mod(i,moduloCam) == 0)            
            img = getsnapshot(vidInfo.video);
            J1 = undistortFisheyeImage(img(:,:,:,1),vidInfo.params.Intrinsics,...
                'ScaleFactor',vidInfo.scale);
            plt(1).CData = rot90(J1,2);
        end

        
        pause(1/ldvFS);
    end
      
end


%% Adjust the laser position
function adjustVoltage(hObject,event, plt, sNI, Vertices, lastSquareHeight)

    %grab the slider values
    hY = findobj('Tag','linePos');
    yVal = hY.Value;
    volts = worldToVoltage([0.5,yVal],Vertices, lastSquareHeight);
    
    %plot current laser location
    %set(plt(1), 'XData',x, 'YData',y);
    
    %change LDV voltage
    outputSingleScan(sNI(1),[volts(1) volts(2)]);
end

%% Utility Functions
function voltagePos = worldToVoltage(worldPos, Vertices, lastSquareHeight)
    
    [normCoord,squareNum] = normalizeWorldSpaceCoord(worldPos, length(Vertices), lastSquareHeight);
    voltagePos = pointToVoltage(normCoord,cell2mat(Vertices(squareNum)));
    
end

function [normCoord, squareNum] = normalizeWorldSpaceCoord(worldSpaceCoord, nSquares, lastSquareHeight)

    %get y 
    squareNum = abs(ceil(worldSpaceCoord(2))) + 1;


    % normalize coord to second quadrant
    normCoord = worldSpaceCoord;
    if squareNum == nSquares
        normCoord(2) = (worldSpaceCoord(2) - ceil(worldSpaceCoord(2))) / lastSquareHeight;
    else
        normCoord(2) = worldSpaceCoord(2) - ceil(worldSpaceCoord(2));
    end
    
end

%repeated linear interpolation (bilinear interp)
function interpolatedVoltage = pointToVoltage(coord, boundingVoltages)

    x = coord(1);
    y = coord(2);

    fQ11 = boundingVoltages(1,:);
    fQ21 = boundingVoltages(2,:);
    fQ12 = boundingVoltages(3,:);
    fQ22 = boundingVoltages(4,:);

    %perform bilinear interpolation in second quadrant
    x1 = 0;
    x2 = 1;
    y1 = 0;
    y2 = -1;

    %alg 
    divX = (1/(x2-x1));
    divY = (1/(y2-y1));
    r1 = ((x2 - x)*(divX)*fQ11) + ((x - x1)*(divX)*fQ21);
    r2 = ((x2 - x)*(divX)*fQ12) + ((x - x1)*(divX)* fQ22);
    interpolatedVoltage = ((y2 - y)*(divY)*r1) + ((y - y1)*(divY)*r2);

end



%% Save a given anchor
function saveLinePos(hObject,event, vidInfo, Vertices, lastSquareHeight)

    setappdata(hObject.Parent,'isTakingSnapshot',true);
    %grab current popup menu item number
    h = findobj('Tag','anchorMenu');
    menuNum = h.Value;
    
    %grab current slider values
    img = getsnapshot(vidInfo.video);
    hLine = findobj('Tag','linePos');
    
    yVal = hLine.Value;
    
    %store image and laser voltage location
    location.image = rot90(undistortFisheyeImage(img(:,:,:,1),vidInfo.params.Intrinsics,...
        'ScaleFactor',vidInfo.scale),2);
    location.worldLoc = [0.5 yVal];
    location.voltageLoc = worldToVoltage([0.5 yVal], Vertices, lastSquareHeight);
    
    %set anchor
    varname = sprintf('Anchor%i',menuNum);
    setappdata(hObject.Parent, varname, location);
    
    %set the popup menu display - can be altered to pixel loc if neccessary
    menuItems = h.String; %cannot directly index into h.String cell array...very weird...
    newItem = sprintf('[%.2f, %.2f]', 0.5, yVal);
    menuItems(menuNum) = {newItem};
    set(h,'String',menuItems);
    
    setappdata(hObject.Parent,'isTakingSnapshot',false);
end


%% Reset position of the LDV and UI to a saved anchor location if editing
function editLinePos(hObject,event, plt, sNI)

    %get the sliders
    hLine = findobj('Tag','linePos');

    %get the current anchor being modified (integer between [1,4])
    menuNum = hObject.Value;
    
    % construct variable name given the anchor number
    varname = sprintf('Anchor%i',menuNum);
    
    % if the anchor has been set...
    if isappdata(hObject.Parent,varname)
        
        % then get its value
        anchorLocation = getappdata(hObject.Parent,varname);
        
        % set the UI slider value to the stored value
        set(hLine,'Value',anchorLocation.worldLoc(2));
        
        %send to Max via OSC
        outputSingleScan(sNI(1),[anchorLocation.voltageLoc(1) anchorLocation.voltageLoc(2)]);
        
    end
end

%% ------------------- END ------------------------------------------------
