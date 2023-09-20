clc; clear; close all;

% Study Info
participants = ["P03","P04","P05","P06","P07","P08","P09","P10","P11","P12"];
freq = [15, 50, 100, 200, 400];
conditions = ["Fixed","Free"];
repetitions = 20;
num_participants = length(participants);
fs = 2500;

accuracy = zeros(num_participants,length(conditions),length(freq));
amp_in = zeros(num_participants,length(conditions),length(freq),repetitions);
amp_out = zeros(num_participants,length(conditions),length(freq),repetitions);

folder = "Data\";
for iter1 = 1:length(participants)
    for iter2 = 1:length(conditions)
        for iter3 = 1:length(freq)
            for iter4 = 1:repetitions
                filename = strcat(participants(iter1),"_",conditions(iter2),"_Trial",num2str(iter4),...
                    "_",num2str(freq(iter3)),"Hz_Tip.mat");
                all_data = load(strcat(folder,filename));
                F_in = squeeze(all_data.Fz(:,1));
                F_out = squeeze(all_data.Fz(:,2));
                amp_in(iter1,iter2,iter3,iter4) = getForceAmp(F_in,freq(iter3),fs);
                amp_out(iter1,iter2,iter3,iter4) = getForceAmp(F_out,freq(iter3),fs);
                accuracy(iter1,iter2,iter3) = accuracy(iter1,iter2,iter3)+all_data.correct/repetitions;
            end
        end
    end
end

%%
for iter1 = 1:length(participants)
    figure(1)
    plot(freq,squeeze(accuracy(iter1,1,:)),'r-o')
    hold on;
    plot(freq,squeeze(accuracy(iter1,2,:)),'b-o')
    hold on;
    ylim([0,1])
    xlim([freq(1),freq(end)])
    figure(2)
    plot(freq,squeeze(mean(20*log10(amp_out(iter1,1,:,:)./amp_in(iter1,1,:,:)),4)),'r-o')
    hold on;
    plot(freq,squeeze(mean(20*log10(amp_out(iter1,2,:,:)./amp_in(iter1,2,:,:)),4)),'b-o')
    hold on;
    ylim([-40,0])
    xlim([freq(1),freq(end)])
end

%%
for iter2 = 1:length(conditions)
    for iter3 = 1:length(freq)
        [~,p] = ttest(squeeze(accuracy(:,iter2,iter3)),0.5);
        disp(p)
    end
end

%%
save('RelocalizationDemo_ProcessedData', 'accuracy', 'amp_in', 'amp_out', ...
    'freq', 'conditions','num_participants', 'repetitions','-v7.3');


