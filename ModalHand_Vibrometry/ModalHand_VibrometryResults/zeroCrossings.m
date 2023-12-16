function [crossing_idx] = zeroCrossings(signal,samples,num_zeros)
    
    % Find Zeros
    crossing_idx=find(signal(1:end-1).*signal(2:end)<0);

    % Check sample requirements
    sample_check = ones(1,length(crossing_idx));
    for iter1 = 1:length(crossing_idx)
        for iter2 = 1:samples
            if and(iter1-iter2 > 0, iter1+iter2 < length(crossing_idx)+1)
                if signal(crossing_idx(iter1)-iter2)*signal(crossing_idx(iter1)+iter2)>0
                    sample_check(iter1) = 0;
                end
            end
        end
    end
    crossing_idx = crossing_idx(find(sample_check));
    
    % Grab n strongest crossings
    if length(crossing_idx)-2 > num_zeros
        crossing_idx = [1,crossing_idx,length(signal)];
        crossing_strength = zeros(length(crossing_idx),1);
        for iter1 = 2:length(crossing_idx)-1
        crossing_strength(iter1) = max(abs(signal(crossing_idx(iter1-1):crossing_idx(iter1)))) + ...
            max(abs(signal(crossing_idx(iter1):crossing_idx(iter1+1))));
        end
        [~,max_idx] = maxk(crossing_strength,num_zeros);
        crossing_idx = crossing_idx(max_idx);
    end

    % % Check threshold
    % threshold = threshold*max(abs(signal));
    % threshold_check = ones(1,length(crossing_idx));
    % for iter1 = 2:length(crossing_idx)-1
    %     if(or(max(abs(signal(crossing_idx(iter1-1):crossing_idx(iter1)))) < threshold, ...
    %             max(abs(signal(crossing_idx(iter1):crossing_idx(iter1+1))))) < threshold)
    %         threshold_check(iter1) = 0;
    %     end
    % end
    % crossing_idx = crossing_idx(find(threshold_check));
    % crossing_idx = crossing_idx(2:end-1);
end