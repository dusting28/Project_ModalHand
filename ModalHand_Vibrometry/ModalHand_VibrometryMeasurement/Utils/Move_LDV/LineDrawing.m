load('CalibrationFiles/Checkerboard_HighRes.mat');

sNI(1) = daq.createSession('ni');
sNI(1).Rate = 10000;
sNI(1).IsContinuous = 0;
AnalogOuts = sNI(1).addAnalogOutputChannel('Dev3',0:1 ,'Voltage');

epsilon = 10e-5;
gridSize = 19/32; %in inches
lastSquareSize = 6/32; % in inches (last square isn't fully calibrated because mirrors
lastSquareHeight = (lastSquareSize / gridSize);

yVals = linspace(0+epsilon, (-10-lastSquareHeight) + epsilon,1000);
xVals = linspace(0.5,0.5,1000);
lastSquareHeight = (lastSquareSize / gridSize);

for i = 1:length(yVals)
    
    worldSpaceCoord = [xVals(i),yVals(i)]; 
    squareNum = abs(ceil(worldSpaceCoord(2))) + 1;

    % normalize coord to second quadrant
    normCoord = worldSpaceCoord;
    if squareNum == 11
        normCoord(2) = (worldSpaceCoord(2) - ceil(worldSpaceCoord(2))) / lastSquareHeight;
    else
        normCoord(2) = worldSpaceCoord(2) - ceil(worldSpaceCoord(2));
    end
    
    x = normCoord(1);
    y = normCoord(2);
    
    boundingVoltages = cell2mat(Vertices(squareNum));
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
    interpolatedVoltage(i,:) = ((y2 - y)*(divY)*r1) + ((y - y1)*(divY)*r2);
    
end

nLoops = 5;
for j = 1:nLoops
    for i = 1:length(interpolatedVoltage)

        voltageLoc = interpolatedVoltage(i,:);
        outputSingleScan(sNI(1),[voltageLoc(1) voltageLoc(2)]);
       
        pause(0.001);
    end
end


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