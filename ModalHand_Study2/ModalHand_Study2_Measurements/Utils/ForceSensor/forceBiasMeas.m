function forceBias = forceBiasMeas(dq,bias_length)
% Function which identifies the bias currently experienced by the force
% sensor

recordedData = read(dq,bias_length,'OutputFormat','Matrix');
biasVec = recordedData(:,1:7);
forceBias = mean(biasVec);
end
