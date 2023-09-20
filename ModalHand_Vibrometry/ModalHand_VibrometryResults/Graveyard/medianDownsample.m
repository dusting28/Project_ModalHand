function [output] = medianDownsample(signal,desired_length)
    spacing = length(signal)/desired_length;
    output = zeros(1,desired_length);
    counter = 0;
    for iter1 = 1:desired_length
        output(iter1) = median(signal(floor(counter)+1:floor(counter+spacing)));
        counter = counter+spacing;
    end
end