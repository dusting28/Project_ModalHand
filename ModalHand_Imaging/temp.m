clc; clear

imaging = load("ImageData_EngineeredTouch.mat");
scenario = 2;
tracked_positions = imaging.tracking_cell{scenario};


disp(complete_points(1,:,1));
disp(complete_points(1,:,2));
