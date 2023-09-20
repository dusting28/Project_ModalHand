%% Measurement Specifications
ParamsType = 'Default';

MeasurementInfo.outputDir = sprintf('Data/PerceptualNorm/');
MeasurementInfo.fn = "P12";
MeasurementInfo.startTrial = 1;
MeasurementInfo.random = true;
MeasurementInfo.preload = 3;
MeasurementInfo.preloadRange = [.75, 1.25]*MeasurementInfo.preload;

TestSignal.frequencies = [15, 50, 100, 200, 400];
TestSignal.conditions = ["Fixed","Free"];
TestSignal.defaultVoltages = .85*[1.35 2.24 .53 .55 .30 .25 .30 .35 2.41 1.35];
TestSignal.output_to_voltage = 1.346/.04;
TestSignal.defaultOutputs = TestSignal.defaultVoltages./TestSignal.output_to_voltage;
TestSignal.sigLength = 1;
TestSignal.delay = 0;

MeasurementSignal.fs = 2500;
MeasurementSignal.forceCh = ["ai0", "ai1", "ai2", "ai4", "ai5", "ai6"]; %force channels on NI card
MeasurementSignal.allChannel = [MeasurementSignal.forceCh];
MeasurementSignal.outputCh = "Port0/Line0";