function [derivative] = TVR_Derivative(signal, fs, alpha)
    n = length(signal);
    D = fs*(-ones(n)+circshift(ones(n),1,2));
    D = D(1:end-1,:);
    A = fs*tril(n-1);
end