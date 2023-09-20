function [r_squared] = rSquared(y_data,y_model)
    SSR = sum((y_data-y_model).^2);
    SST = sum((mean(y_data)-y_data).^2);
    r_squared = 1-SSR/SST;
end