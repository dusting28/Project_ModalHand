function frame = GetImage(vidInfo)

img = getsnapshot(vidInfo.video);
J1 = undistortFisheyeImage(img(:,:,:,1),vidInfo.params.Intrinsics,...
'ScaleFactor',vidInfo.scale);
frame = rot90(J1,2);

end