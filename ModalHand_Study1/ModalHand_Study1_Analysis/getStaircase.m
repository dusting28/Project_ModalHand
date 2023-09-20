function [avg_factors,measured_force,comparison_force] = getStaircase(participant)
    
    folder = "D:\Dustin\Project_ModalHand\ModalHand_Study1\ModalHand_Study1_Analysis\Data\IntensityData\";
    
    freq = [15, 50, 100, 200, 400];
    condition = ["Fixed", "Free"];
    last_trials = 8;
    fs = 2500;
    
    %Look at scale factors
    file = strcat(participant,"_scaleFactors");
    factors = load(strcat(folder,file));
    avg_factors = factors.scale_factors;
    num_trials = zeros(length(factors.scale_factors),2);
    above_factors = zeros(length(avg_factors),1);
    below_factors = zeros(length(avg_factors),1);

    iter4 = 0;
    measured_force = zeros(length(avg_factors),2);
    comparison_force = zeros(length(avg_factors),2);
    for iter1 = 1:length(freq)
        for iter2 = 1:length(condition)
            iter4=iter4+1;
            
            file = strcat(participant,"_Staircase_",condition(iter2),"Condition_",num2str(freq(iter1)),"Hz.mat");
            temp_responses = load(strcat(folder,file));
            num_trials(iter4,1) = length(temp_responses.amp{1})-1;
            num_trials(iter4,2) = length(temp_responses.amp{2})-1;
            above_factors(iter4) = mean(temp_responses.amp{1}(end-last_trials-1:end-1));
            below_factors(iter4) = mean(temp_responses.amp{2}(end-last_trials-1:end-1));

%             figure(4)
%             subplot(2,2,1)
%             semilogy(temp_responses.amp{1}(1:end-1))
%             ylim([0,1.25*max([max(temp_responses.amp{1}),max(temp_responses.amp{2})])])
%             subplot(2,2,2)
%             semilogy(temp_responses.amp{2}(1:end-1))
%             ylim([0,1.25*max([max(temp_responses.amp{1}),max(temp_responses.amp{2})])])
%             sgtitle(strcat(condition(iter2)," - ",num2str(freq(iter1)),"Hz"))

            above_count = 0;
            below_count = 0;
            above_vector_measured = zeros(1,num_trials(iter4,1));
            below_vector_measured = zeros(1,num_trials(iter4,2));
            above_vector_comparison = zeros(1,num_trials(iter4,1));
            below_vector_comparison = zeros(1,num_trials(iter4,2));
            for iter3 = 1:num_trials(iter4,1)+num_trials(iter4,2)
                file = strcat(participant,"_Trial",num2str(iter3),"_",condition(iter2),"Condition_",num2str(freq(iter1)),"Hz.mat");
                trial_info = load(strcat(folder,file));
                
                if trial_info.interweave == 1
                    above_count = above_count+1;
                    if trial_info.presentation(1) == 1
                        filtered_sig = bandpass(trial_info.Fz_2,[freq(iter1)*.8,freq(iter1)*1.2],fs);
                        comparison_sig = bandpass(trial_info.Fz_1,[100*.8,100*1.2],fs);
                    else
                        filtered_sig = bandpass(trial_info.Fz_1,[freq(iter1)*.8,freq(iter1)*1.2],fs);
                        comparison_sig = bandpass(trial_info.Fz_2,[100*.8,100*1.2],fs);
                    end
                    sig_length = length(filtered_sig);
                    above_vector_measured(above_count) = max(filtered_sig(floor(.7*sig_length):floor(.9*sig_length)))/2-...
                        min(filtered_sig(floor(.7*sig_length):floor(.9*sig_length)))/2;
                    above_vector_comparison(above_count) = max(comparison_sig(floor(.7*sig_length):floor(.9*sig_length)))/2-...
                        min(comparison_sig(floor(.7*sig_length):floor(.9*sig_length)))/2;
                end
                if trial_info.interweave == 2
                    below_count = below_count+1;
                    if trial_info.presentation(1) == 1
                        filtered_sig = bandpass(trial_info.Fz_2,[freq(iter1)*.8,freq(iter1)*1.2],fs);
                        comparison_sig = bandpass(trial_info.Fz_1,[100*.8,100*1.2],fs);
                    else
                        filtered_sig = bandpass(trial_info.Fz_1,[freq(iter1)*.8,freq(iter1)*1.2],fs);
                        comparison_sig = bandpass(trial_info.Fz_2,[100*.8,100*1.2],fs);
                    end
                    sig_length = length(filtered_sig);
                    below_vector_measured(below_count) = max(filtered_sig(floor(.7*sig_length):floor(.9*sig_length)))/2-...
                        min(filtered_sig(floor(.7*sig_length):floor(.9*sig_length)))/2;
                    below_vector_comparison(below_count) = max(comparison_sig(floor(.7*sig_length):floor(.9*sig_length)))/2-...
                        min(comparison_sig(floor(.7*sig_length):floor(.9*sig_length)))/2;
                end
%                 figure(6);
%                 plot(comparison_sig);
            end
%             figure(4);
%             subplot(2,2,3)
%             semilogy(above_vector_measured)
%             ylim([0,1.25*max([max(below_vector_measured),max(above_vector_measured)])])
%             subplot(2,2,4)
%             semilogy(below_vector_measured)
%             ylim([0,1.25*max([max(below_vector_measured),max(above_vector_measured)])])
%             sgtitle(strcat(condition(iter2)," - ",num2str(freq(iter1)),"Hz"))
%     
%             figure(5);
%             subplot(1,2,1)
%             semilogy(above_vector_comparison)
%             ylim([.25/4,.25])
%             subplot(1,2,2)
%             semilogy(below_vector_comparison)
%             ylim([.25/4,.25])
%             sgtitle(strcat(condition(iter2)," - ",num2str(freq(iter1)),"Hz"))  
    
            measured_force(iter4,1) = mean(above_vector_measured(end-last_trials:end));
            measured_force(iter4,2) = mean(below_vector_measured(end-last_trials:end));
            comparison_force(iter4,1) = mean(above_vector_comparison(end-last_trials:end));
            comparison_force(iter4,2) = mean(below_vector_comparison(end-last_trials:end));
        end
    end
end