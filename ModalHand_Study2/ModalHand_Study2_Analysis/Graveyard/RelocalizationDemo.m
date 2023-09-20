clc; clear; close all;

% Study Info
participants = ["TallStand_15_400"];
freq = [35, 200];
location = ["Tip", "Base"];
conditions = "Fixed";%["Fixed","Free"];
repetitions = 3;
num_stim = length(freq)*length(location);
num_participants = length(participants);
fs = 2500;


folder = "C:\Users\Dustin Goetz\Desktop\ReTouch_Lab\Lab_Projects\Project_ModalHand\ModalHand_Study2\ModalHand_Study2_Analysis\Data\";
for iter1 = 1:length(participants)
    for iter2 = 1:length(conditions)
        accuracy = zeros(1,num_stim);
        amp_in = zeros(num_stim,repetitions);
        amp_out = zeros(num_stim,repetitions);
        for iter3 = 1:repetitions
            for iter4 = 1:num_stim
                filename = strcat(participants(iter1),"_",conditions(iter2),...
                    "_Trial",num2str(iter3),"_Stim",num2str(iter4),".mat");
                all_data = load(strcat(folder,filename));
                if iter4<=length(freq)
                    F_in = squeeze(all_data.Fz(:,1));
                    F_out = squeeze(all_data.Fz(:,2));
                    if strcmp(all_data.location,location(1))
                        accuracy(iter4) = accuracy(iter4) + 1/repetitions;
                    end
                else
                    F_in = squeeze(all_data.Fz(:,2));
                    F_out = squeeze(all_data.Fz(:,1));
                    if strcmp(all_data.location,location(2))
                        accuracy(iter4) = accuracy(iter4) + 1/repetitions;
                    end
                end
                freq_idx = mod(iter4-1,length(location))+1;
                amp_in(iter4,iter3) = getForceAmp(F_in,freq(freq_idx),fs);
                amp_out(iter4,iter3) = getForceAmp(F_out,freq(freq_idx),fs);
            end
        end
    end
end

save('RelocalizationDemo_ProcessedData', 'accuracy', 'amp_in', 'amp_out', 'location',...
    'freq', 'conditions','num_participants', 'repetitions', 'num_stim','-v7.3');


