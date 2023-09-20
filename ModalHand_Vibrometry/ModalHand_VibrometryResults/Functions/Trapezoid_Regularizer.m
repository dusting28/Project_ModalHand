function [reg] = Trapezoid_Regularizer(freq,bandwidth,beta,epsilon)
    reg = zeros(1,length(freq));
    for iter1 = 1:length(freq)
        if freq(iter1) < bandwidth(1)
            reg(iter1) = min([beta(1) ,(bandwidth(1) - freq(iter1)) * beta(1) / epsilon(1)]);
        end
        if freq(iter1) > bandwidth(2)
            reg(iter1) = min([beta(2), (freq(iter1) - bandwidth(2)) * beta(2) / epsilon(2)]);
        end
        
    end
end