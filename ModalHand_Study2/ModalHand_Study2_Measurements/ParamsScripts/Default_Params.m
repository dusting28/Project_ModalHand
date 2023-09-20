%% Measurement Specifications
MeasurementInfo.ID = "Default";
MeasurementInfo.condition = "Free";
MeasurementInfo.nRepetitions = 20;
MeasurementInfo.fn = strcat(MeasurementInfo.ID,"_",MeasurementInfo.condition);
MeasurementInfo.outputDir = sprintf('Data/');
MeasurementInfo.startTrial = 1;
MeasurementInfo.random = true;
MeasurementInfo.preload = 3;
MeasurementInfo.preloadRange = [.75, 1.25]*MeasurementInfo.preload;

TestSignal.frequencies = [15, 50, 100, 200, 400];
TestSignal.locations = "Tip";%["Tip","Base"];
loaded_factors = load("MedianVoltages.mat");
TestSignal.scaleFactor = loaded_factors.scale_factors;
TestSignal.sigLength = 2;
TestSignal.delay = 0;

MeasurementSignal.fs = 2500;
MeasurementSignal.forceCh = ["ai0", "ai4", "ai1", "ai5", "ai2", "ai6"]; %force channels on NI card
MeasurementSignal.piezoCh = "ai3";
MeasurementSignal.allCh = [MeasurementSignal.forceCh, MeasurementSignal.piezoCh];

