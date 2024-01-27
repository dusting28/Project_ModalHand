function [crossing_idx, crossing_sign] = zeroCrossingTime(signal,samples,threshold)
    
    % Find Zeros
    crossing_idx = find(signal(1:end-1).*signal(2:end)<0);
    crossing_sign = sign(signal(crossing_idx+1) - signal(crossing_idx));

    % Check sample requirements
    % sample_check = ones(1,length(crossing_idx));
    % for iter1 = 1:length(crossing_idx)
    %     for iter2 = 1:samples
    %         if and(crossing_idx(iter1)-iter2 > 0, crossing_idx(iter1)+iter2 < length(signal)+1)
    %             if signal(crossing_idx(iter1)-iter2)*signal(crossing_idx(iter1)+iter2)>0
    %                 sample_check(iter1) = 0;
    %             end
    %         end
    %     end
    % end
    % crossing_idx = crossing_idx(find(sample_check));
    % crossing_sign = crossing_sign(find(sample_check));

    threshold_check = ones(1,length(crossing_idx));
    abs_threshold = threshold*max(abs(signal));
    for iter1 = 1:length(crossing_idx)
        lower_idx = max([crossing_idx(iter1)-samples, 1]);
        upper_idx = min([crossing_idx(iter1)+samples, length(signal)]);
        if crossing_sign(iter1)>0
            left_check = min(signal(lower_idx:crossing_idx(iter1)));
            right_check = max(signal(crossing_idx(iter1):upper_idx));
        end
        if crossing_sign(iter1)<0
            left_check = max(signal(lower_idx:crossing_idx(iter1)));
            right_check = min(signal(crossing_idx(iter1):upper_idx));
        end
        if or(abs(left_check)<abs_threshold, abs(right_check)<abs_threshold)
            threshold_check(iter1) = 0;
        end
    end
    crossing_idx = crossing_idx(find(threshold_check));
    crossing_sign = crossing_sign(find(threshold_check));
end