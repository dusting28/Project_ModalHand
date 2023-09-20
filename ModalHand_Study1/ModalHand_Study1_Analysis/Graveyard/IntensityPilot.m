clc; clear; close all;

load("PerceptualScaling.mat")

output_to_voltage = 1.346/.04;

freq = TestSignal.frequencies;
conditions = TestSignal.conditions;

scaleVoltage1 = TestSignal.dustinScaleFactor;
scaleVoltage2 = TestSignal.williamScaleFactor;
scaleVoltage3 = TestSignal.gregScaleFactor;

scaleForce = TestSignal.refscaleFactor;

figure;
subplot(1,2,1)
plot(freq,TestSignal.PeakAmp*output_to_voltage*scaleVoltage1(1:2:9),'o--')
hold on;
plot(freq,TestSignal.PeakAmp*output_to_voltage*scaleVoltage2(1:2:9),'o--')
hold on;
plot(freq,TestSignal.PeakAmp*output_to_voltage*scaleVoltage3(1:2:9),'o--')
hold off;
title("Fixed Condition")
ylabel("Voltage (V)")
xlabel("Frequency")
legend("Participant 1", "Participant 2", "Participant 3")
ylim([0,3.5]);
subplot(1,2,2)
plot(freq,TestSignal.PeakAmp*output_to_voltage*scaleVoltage1(2:2:10),'o--')
hold on;
plot(freq,TestSignal.PeakAmp*output_to_voltage*scaleVoltage2(2:2:10),'o--')
hold on;
plot(freq,TestSignal.PeakAmp*output_to_voltage*scaleVoltage3(2:2:10),'o--')
hold off;
title("Free Condition")
ylim([0,3.5]);

figure;
subplot(1,2,1)
plot(freq,TestSignal.desiredAmp*scaleVoltage1(1:2:9)./TestSignal.refscaleFactor(1:2:9),'o--')
hold on;
plot(freq,TestSignal.desiredAmp*scaleVoltage2(1:2:9)./TestSignal.refscaleFactor(1:2:9),'o--')
hold on;
plot(freq,TestSignal.desiredAmp*scaleVoltage3(1:2:9)./TestSignal.refscaleFactor(1:2:9),'o--')
hold off;
ylim([0,1]);
subplot(1,2,2)
plot(freq,TestSignal.desiredAmp*scaleVoltage1(2:2:10)./TestSignal.refscaleFactor(2:2:10),'o--')
hold on;
plot(freq,TestSignal.desiredAmp*scaleVoltage2(2:2:10)./TestSignal.refscaleFactor(2:2:10),'o--')
hold on;
plot(freq,TestSignal.desiredAmp*scaleVoltage3(2:2:10)./TestSignal.refscaleFactor(2:2:10),'o--')
hold off;
ylim([0,1]);

measured_forces = zeros(length(freq),length(conditions),3);
for trial_num = 1:30
    orderVectors = load("Quinten_orderVectors.mat");
    order_idx = orderVectors.order_cell{ceil(trial_num/(length(freq)*length(conditions)))}...
        (mod(trial_num-1,length(freq)*length(conditions))+1);
    condition_idx = mod(order_idx-1,length(conditions))+1;
    freq_idx = ceil(order_idx/length(conditions));
    filename = strcat("Quinten_Trial",num2str(trial_num),"_",...
        conditions(condition_idx),"Condition_",num2str(freq(freq_idx)),"Hz.mat");
    force = load(filename);
    fs = 2500;
    filtered_sig = bandpass(force.Fz,[freq(freq_idx)*.8,freq(freq_idx)*1.2],fs);
    sig_length = length(filtered_sig);
    amplitude = max(filtered_sig(floor(.4*sig_length):floor(.6*sig_length)))/2-...
        min(filtered_sig(floor(.4*sig_length):floor(.6*sig_length)))/2;
    measured_forces(freq_idx,condition_idx,ceil(trial_num/(length(freq)*length(conditions)))) = amplitude;
end

figure;
subplot(1,2,1)
plot(freq,squeeze(mean(measured_forces(:,1,:),3)),'o--');
title("Fixed Condition")
ylabel("Force (N)")
xlabel("Frequency")
ylim([0,.6]);
subplot(1,2,2)
plot(freq,squeeze(mean(measured_forces(:,2,:),3)),'o--');
title("Free Condition")
ylim([0,.6]);