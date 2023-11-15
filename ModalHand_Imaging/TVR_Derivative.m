function [derivative] = TVR_Derivative(y, u_guess, delta_x, steps, alpha)
    eps = 10^-6; % from other person's code
    n = length(y);
    D = -[(1/delta_x)*eye(n), zeros(n,1)] + [zeros(n,1), (1/delta_x)*eye(n)];
    A = [(.5*delta_x)*tril(ones(n)), zeros(n,1)] + [zeros(n,1), (.5*delta_x)*tril(ones(n))];
    u = u_guess;
    for iter1 = 1:steps
        E = zeros(n);
        for iter2 = 1:n
            t = (D(iter2,:)*u')^2;
            E(iter2,iter2) = (t+eps)^(-.5);
        end
        L = delta_x*(D'*E*D); 
        g = A'*A*u'-A'*(y'-y(1))+alpha*L*u';
        H = A'*A+alpha*L;
        s = mldivide(-H,g);
        u = u + s';
    end
    derivative = u;
end