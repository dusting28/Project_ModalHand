function [reg] = Rectangle_Regularizer(freq,bandwidth,beta)
    reg = zeros(1,length(freq));
    for iter1 = 1:length(freq)
        if freq(iter1) < bandwidth(1)
            reg(iter1) = beta(1);
        end
        if freq(iter1) > bandwidth(2)
            reg(iter1) = beta(2);
        end
    end
end