function [single_axis] = singleAxis(data,include_probe)
    if include_probe
        axis1 = [data(:,1), data(:,2:3:end)];
        axis2 = [data(:,1), data(:,3:3:end)];
        axis3 = [data(:,1), data(:,4:3:end)];
        single_axis = (axis1+axis2+axis3)/3;
    else
        axis1 = data(:,1:3:end);
        axis2 = data(:,2:3:end);
        axis3 = data(:,3:3:end);
        single_axis = (axis1+axis2+axis3)/3;
    end
end