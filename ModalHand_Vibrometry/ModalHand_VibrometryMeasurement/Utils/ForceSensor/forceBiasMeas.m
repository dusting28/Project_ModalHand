function forceBias = forceBiasMeas(dq,bias_length)
% Function which identifies the bias currently experienced by the force
% sensor

recordedData = read(dq,seconds(bias_length),'OutputFormat','Matrix');
biasVec = recordedData(:,1:6);

%biasVec = [recordedData.Dev1_ai1, recordedData.Dev1_ai2, recordedData.Dev1_ai3,...
%                recordedData.Dev1_ai7, recordedData.Dev1_ai6, recordedData.Dev1_ai7];

forceBias = mean(biasVec);
end
