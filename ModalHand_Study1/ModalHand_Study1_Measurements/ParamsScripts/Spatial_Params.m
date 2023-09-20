%% Measurement Specifications

MeasurementInfo.outputDir = sprintf('Data/SpatialStudy/');
MeasurementInfo.fn = "P12";
MeasurementInfo.startTrial = 1;
MeasurementInfo.nRepetitions = 5;
MeasurementInfo.random = true;
MeasurementInfo.preload = 3;
MeasurementInfo.preloadRange = [.75, 1.25]*MeasurementInfo.preload;

TestSignal.frequencies = [15, 50, 100, 200, 400];
TestSignal.conditions = ["Fixed","Free"];
loaded_factors = load("Data/PerceptualNorm/MedianVoltages");
TestSignal.scaleFactor = loaded_factors.scale_factors;
TestSignal.sigLength = 2;
TestSignal.delay = 0;

MeasurementSignal.fs = 2500;
MeasurementSignal.forceCh = ["ai0", "ai1", "ai2", "ai4", "ai5", "ai6"]; %force channels on NI card
MeasurementSignal.allChannel = [MeasurementSignal.forceCh];
MeasurementSignal.outputCh = "Port0/Line0";

%load("Scaling.mat");
%TestSignal.desiredAmp = .25;
%TestSignal.PeakAmp = .04;
%TestSignal.refscaleFactor = TestSignal.desiredAmp./[1, .1, 1, .5, 1, .7, .75, .35, .2, .4, .2, .2];
%TestSignal.refscaleFactor = TestSignal.desiredAmp./[1, .1, 1, .5, 1, .7, .75, .35, .2, .4];
%TestSignal.forceScaleFactor = scale_factors;
%TestSignal.dustinScaleFactor = [4 .7 1.8 .7 .8 .3 .6 .5 2 2.2].*TestSignal.refscaleFactor;

%TestSignal.williamScaleFactor = [4 .75 1.4 .7 .8 .45 .7 .3 1 1.2].*TestSignal.refscaleFactor;
%TestSignal.gregScaleFactor = [4 .55 1.5 1.05 1.1 .8 .7 .3 1.3 1.4].*TestSignal.refscaleFactor;
%TestSignal.scaleFactor = mean([TestSignal.dustinScaleFactor; TestSignal.williamScaleFactor; ...
    %TestSignal.gregScaleFactor]);