function forceBias = forceBiasMeas(dq,bias_length)
% Function which identifies the bias currently experienced by the force
% sensor

recordedData = read(dq,seconds(bias_length));
biasVec = [recordedData.Dev1_ai0, recordedData.Dev1_ai1, recordedData.Dev1_ai2,...
                recordedData.Dev1_ai4, recordedData.Dev1_ai5, recordedData.Dev1_ai6];
forceBias = mean(biasVec);
end
