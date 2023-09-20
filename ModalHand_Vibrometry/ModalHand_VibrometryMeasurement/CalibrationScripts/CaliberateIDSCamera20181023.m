%% Camera calibration for fixing fish eye distortion and getting a mapping from 
% pixel space to real space
% written by Yitian Shao

%% IDS Camera
dev_info = imaqhwinfo('winvideo',1);
imgFormat = dev_info.SupportedFormats;

vid = videoinput('winvideo',1,imgFormat{2});
% % % % % % preview(vid);

start(vid)
imgs = getdata(vid,5); 
stop(vid)

%% Checkboard caliberation to undistort fisheye
[imagePoints,boardSize] = detectCheckerboardPoints(imgs);

figure
imshow(imgs(:,:,:,1));
hold on
for i = 1:size(imagePoints,1)
    scatter(imagePoints(i,1,1),imagePoints(i,2,1),'r')
    text(imagePoints(i,1,1)+10,imagePoints(i,2,1)+10,num2str(i),'Color','r');
end
hold off

squareSize = 24; % millimeters

worldPoints = generateCheckerboardPoints(boardSize,squareSize);


%%
imageSize = [size(imgs,1) size(imgs,2)];
params = estimateFisheyeParameters(imagePoints,worldPoints,imageSize);

fisheyeScale = 0.036; % 10/22/2018
%fisheyeScale = 5.5; % 10/22/2018

J1 = undistortFisheyeImage(imgs(:,:,:,1),params.Intrinsics,...
    'ScaleFactor',fisheyeScale);

%J1 = undistortFisheyeImage(imgs(:,:,:,1),params.Intrinsics);

figure
imshowpair(imgs(:,:,:,1),J1,'montage')
title('Original Image (left) vs. Corrected Image (right)')

%% Automatically determine mapping
[correctedPoints,~] = detectCheckerboardPoints(J1);
imshow(J1)
hold on

%corner_loc = correctedPoints([1,6,49,54],:);% Automatically locate the corners
corner_loc = correctedPoints([1,6,37,42],:);% Automatically locate the corners


%picLoc = [corner_loc';ones(1,4)];
%realLoc = [-108,-108,36,36; -54,36,-54,36; 1,1,1,1]; % Unit: mm
%Mapping = realLoc/picLoc;

%% Validate the caliberated mapping
% xRange = linspace(-108,36,9); % Unit: mm
% yRange = linspace(-54,36,6); % Unit: mm
% [xG, yG] = meshgrid(xRange,yRange);
% pred_loc = Mapping\([xG(:),yG(:),ones(numel(xG),1)]');
% plot(pred_loc(1,:),pred_loc(2,:),'og')
% 
%err = abs(correctedPoints - pred_loc(1:2,:)');
% fprintf('Caliberation error = %.2f +/- %.2f mm\n',mean(err(:)),std(err(:)))
% 
%save('CameraCaliberation','params','Mapping','fisheyeScale','corner_loc','dev_info');
save('CameraCalibration','params','fisheyeScale','corner_loc','dev_info');

