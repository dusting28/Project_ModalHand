% Write 8-channel output signals for playing by Max MSP
% ref on channel 8
% actuator on 1-7

function GenerateTestSignals(filename, outputSignal, fs, bitdepth, optArgs)

nChans = size(outputSignal,2);
    
if nChans < 8
    temp = zeros(size(outputSignal,1),8);
    temp(:,optArgs) = outputSignal(:,1:(nChans-1)); %send non refs channels to mapped actuator channels
    temp(:,8) = outputSignal(:,nChans); %ref channel
    audiowrite(filename, temp, fs, 'BitsPerSample', bitdepth);
else
    %write out the signal with the given parameters
    audiowrite(filename, outputSignal, fs, 'BitsPerSample', bitdepth);
end

end