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

% I = 1/12*m*l^2
I1 = (1/12)*(m1)*(l1)^2;
I2 = (1/12)*(m2-m1)*(l2)^2;
I3 = (1/12)*(m3-m2)*(l3)^2;
I4 = (1/12)*(m4-m3)*(l4)^2;

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

A = [0, 1, 0, 0, 0, -l1/2, -l2, -l3, -l4, 0, 0, 0, 0;...
    0, 0, 1, 0, 0, 0, -l2/2, -l3, -l4, 0, 0, 0, 0;...
    0, 0, 0, 1, 0, 0, 0, -l3/2, -l4, 0, 0, 0, 0;...
    0, 0, 0, 0, 1, 0, 0, 0, -l4/2, 0, 0, 0, 0;...
    m0*s^2+b0*s+k0, -b0*s-k0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;...
    -b0*s-k0, m1*s^2+b0*s+k0, 0, 0, 0, (b1*s+k1)*2/l1, -(b1*s+k1)*2/l1, 0, 0, -1, 0, 0, 0;...
    0, 0, m2*s^2, 0, 0, (b1*s+k1)*2/l2, (b2*s+k2-b1*s-k1)*2/l2, -(b2*s+k2)*2/l2, 0, 1, -1, 0, 0;...
    0, 0, 0, m3*s^2, 0, 0, (b2*s+k2)*2/l3, (b3*s+k3-b2*s-k2)*2/l3, -(b3*s+k3)*2/l3, 0, 1, -1, 0;...
    0, 0, 0, 0, m4*s^2, 0, 0, (b3*s+k3)*2/l4, (b4*s+k4-b3*s-k3)*2/l4, 0, 0, 1, -1;...
    0, 0, 0, 0, 0, I1*s^2+b1*s+k1, -(b1*s+k1), 0, 0, l1/2, 0, 0, 0;...
    0, 0, 0, 0, 0, -(b1*s+k1), I2*s^2+(b1+b2)*s+k1+k2, -(b2*s+k2), 0, l2/2, l2/2, 0, 0;...
    0, 0, 0, 0, 0, 0, -(b2*s+k2), I3*s^2+(b2+b3)*s+k2+k3, -(b3*s+k3), 0, l3/2, l3/2, 0;...
    0, 0, 0, 0, 0, 0, 0, -(b3*s+k3), I4*s^2+(b3+b4)*s+k3+k4, 0, 0, l4/2, l4/2];
A_fixed = -(m0*s^2+b0*s+k0);

A_inverse = inv(A);
A_fixed_inverse = 1/A_fixed;

[~,den] = numden(A_inverse(1,5));
eigenfrequencies = vpa(solve(den,s));

frequency = 5:1000;
y0 = zeros(1,length(frequency));
y1 = zeros(1,length(frequency));
y2 = zeros(1,length(frequency));
y3 = zeros(1,length(frequency));
y4 = zeros(1,length(frequency));
theta1 = zeros(1,length(frequency));
theta2 = zeros(1,length(frequency));
theta3 = zeros(1,length(frequency));
theta4 = zeros(1,length(frequency));
displacement_fixed = zeros(1,length(frequency));

for iter1 = 1:length(frequency)
    s_sub = 2*pi*frequency(iter1)*1i;
    y0(iter1) = subs(A_inverse(1,5),s,s_sub);
    y1(iter1) = subs(A_inverse(2,5),s,s_sub);
    y2(iter1) = subs(A_inverse(3,5),s,s_sub);
    y3(iter1) = subs(A_inverse(4,5),s,s_sub);
    y4(iter1) = subs(A_inverse(5,5),s,s_sub);
    theta1(iter1) = subs(A_inverse(6,5),s,s_sub);
    theta2(iter1) = subs(A_inverse(7,5),s,s_sub);
    theta3(iter1) = subs(A_inverse(8,5),s,s_sub);
    theta4(iter1) = subs(A_inverse(9,5),s,s_sub);
    displacement_fixed(iter1) = subs(A_fixed_inverse,s,s_sub);
end

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^1.*abs(y0),'k');
plot(frequency,1000*(2*pi*frequency).^1.*abs(y1),'r');
plot(frequency,1000*(2*pi*frequency).^1.*abs(y2),'Color',[0.9290 0.6940 0.1250]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(y3),'Color',[0 0.4470 0.7410]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(y4),'Color',[0.7 0 1]);
hold off;
legend('Contact Point','Distal Phalanx','Medial Phalanx','Proximal Phalanx','Metacarpal')
title('Admittance')
ylabel('$\frac{\dot{x}}{F}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^1.*abs(y1-y0),'k');
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta1-theta2)*l1/2,'Color',[0.8500 0.3250 0.0980]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta2-theta3)*(l1/2+l2),'Color',[0.4660 0.6740 0.1880]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta3-theta4)*(l1/2+l2+l3),'Color',[0.6 0.2 0.6]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta4)*(l1/2+l2+l3+l4),'m');
hold off;
legend('Skin Compression','DIP','PIP','MCP','Wrist')
title('Contribution to Contact Admittance')
ylabel('$\frac{\dot{x}}{F}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^0.*abs(y1-y0));
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
