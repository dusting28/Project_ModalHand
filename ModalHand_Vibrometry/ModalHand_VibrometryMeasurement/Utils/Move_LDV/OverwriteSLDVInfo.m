load('Data/Wavefields/7Actuator-340Pts.mat')

SLDVInfo.Velocity = 'Medium';
SLDVInfo.FreqResponseVal = 2;
SLDVInfo.VoltageFactor = 1;
SLDVInfo.ScaleFactor = 10;
SLDVInfo.FreqResponse = 500;

save('Data/Wavefields/7Actuator-340Pts-Overwritten.mat',...
    'GridLocations','MeasurementInfo','MeasurementSignal','Signals',...
    'SLDVInfo','TestSignal');
