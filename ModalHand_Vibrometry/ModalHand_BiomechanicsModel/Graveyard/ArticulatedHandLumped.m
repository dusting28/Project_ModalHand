clc; clear;
close all;

preload = 1.5; %N

l1 = 16*10^-3; %m - Alexander
l2 = 22*10^-3; %m - Alexander
l3 = 40*10^-3; %m - Alexander
l4 = 68*10^-3; %m - Alexander

actuator_mass = 0*10^-3; %kg
m0 = actuator_mass + (0.20*preload^0.26)*10^-3; %kg - Wiertluski
m1 = 4*10^-3; %kg
m2 = 9*10^-3; %kg
m3 = 22*10^-3; %kg
m4 = 320*10^-3; %kg

% I = 1/3*m*l^2
I1 = (1/3)*(m1)*(l1)^2;
I2 = (1/3)*(m2-m1)*(l2)^2;
I3 = (1/3)*(m3-m2)*(l3)^2;
I4 = (1/3)*(m4-m3)*(l1+l2+l3+l4)^2;

b0 = (1.78*preload^0.35); %N*s/m - Wiertluski
b1 = 0.9*10^-3; %N*m*s/rad - Jindrich
b2 = 3.3*10^-3; %N*m*s/rad - Jindrich
b3 = 3.1*10^-3; %N*m*s/rad - Jindrich
b4 = 63*10^-3; %N*m*s/rad - Kuchenbecker

k0 = (1.48*preload^0.35)*10^3; %N/m - Wiertluski
k1 = 120*10^-3; %N*m/rad - Jindrich
k2 = 290*10^-3; %N*m/rad - Jindrich
k3 = 540*10^-3; %N*m/rad - Jindrich
k4 = 6590*10^-3; %N*m/rad - Kuchenbecker

syms s
A = [-(m0*s^2+b0*s+k0), l1*(b0*s+k0), l2*(b0*s+k0), l3*(b0*s+k0), l4*(b0*s+k0); ...
        l1*(b0*s+k0), -(I1*s^2+(l1^2*b0+b1)*s+l1^2*k0+k1), -((l1*l2*b0-b1)*s+l1*l2*k0-k1), -l1*l3*(b0*s+k0), -l1*l4*(b0*s+k0);...
        0, b1*s+k1, -(I2*s^2+(b1+b2)*s+k1+k2), b2*s+k2, 0;...
        0, 0, b2*s+k2, -(I3*s^2+(b2+b3)*s+k2+k3), b3*s+k3;...
        0, 0, 0, b3*s+k3, -(I4*s^2+(b3+b4)*s+k3+k4)];
A_fixed = -(m0*s^2+b0*s+k0);

A_inverse = inv(A);
A_fixed_inverse = 1/A_fixed;

[~,den] = numden(A_inverse(1,1));
eigenfrequencies = vpa(solve(den,s));

frequency = 5:1000;
displacement = zeros(1,length(frequency));
theta1 = zeros(1,length(frequency));
theta2 = zeros(1,length(frequency));
theta3 = zeros(1,length(frequency));
theta4 = zeros(1,length(frequency));
displacement_fixed = zeros(1,length(frequency));

for iter1 = 1:length(frequency)
    s_sub = 2*pi*frequency(iter1)*1i;
    displacement(iter1) = subs(A_inverse(1,1),s,s_sub);
    theta1(iter1) = subs(A_inverse(2,1),s,s_sub);
    theta2(iter1) = subs(A_inverse(3,1),s,s_sub);
    theta3(iter1) = subs(A_inverse(4,1),s,s_sub);
    theta4(iter1) = subs(A_inverse(5,1),s,s_sub);
    displacement_fixed(iter1) = subs(A_fixed_inverse,s,s_sub);
end

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^1.*abs(displacement));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta1*l1/2+theta2*l2+theta3*l3+theta4*l4));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta2*l2/2+theta3*l3+theta4*l4));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta3*l3/2+theta4*l4));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta4*l4/2));
hold off;
legend('Contact Point','Distal Phalanx','Medial Phalanx','Proximal Phalanx','Metacarpal')
title('Measurement Predictions')
ylabel('x_{dot}/F (mm/Ns)')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^1.*abs(displacement));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta1*l1/2+theta2*l2+theta3*l3+theta4*l4));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta2*l2/2+theta3*l3+theta4*l4));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta3*l3/2+theta4*l4));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta4*l4/2));
hold off;
legend('Contact Point','Distal Phalanx','Medial Phalanx','Proximal Phalanx','Metacarpal')
title('Measurement Predictions')
ylabel('x_{dot}/F (mm/Ns)')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^1.*abs(displacement-theta1*l1-theta2*l2-theta3*l3-theta4*l4));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta1-theta2)*l1);
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta2-theta3)*(l1+l2));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta3-theta4)*(l1+l2+l3));
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta4)*(l1+l2+l3+l4));
hold off;
legend('FingerTip Compression','DIP','PIP','MCP','Wrist')
title('Contribution to Vibrations at Contact')
ylabel('$\frac{\dot{x}}{F}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^0.*abs(displacement-theta1*l1-theta2*l2-theta3*l3-theta4*l4));
plot(frequency,1000*(2*pi*frequency).^0.*abs(displacement_fixed));
hold off;
legend('Free Hand', 'Fixed Hand')
title('Local Skin Compression')
ylabel ('Displacment (mm)')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,(2*pi*frequency).^0.*abs(theta1-theta2));
plot(frequency,(2*pi*frequency).^0.*abs(theta2-theta3));
plot(frequency,(2*pi*frequency).^0.*abs(theta3-theta4));
plot(frequency,(2*pi*frequency).^0.*abs(theta4));
hold off;
legend('DIP','PIP','MCP','Wrist')
title('Joint Rotations')
ylabel('theta/F (rad/Ns)')
xlabel('Frequency (Hz)')
