function [derivative] = Euler_Derivative(x,y,step)
    derivative = (y(step:end)-y(1:end-step+1))./(x(step:end)-x(1:end-step+1));
end