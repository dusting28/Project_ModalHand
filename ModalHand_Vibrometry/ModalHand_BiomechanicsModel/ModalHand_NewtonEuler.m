clc; clear;
close all;

%% Load
current_folder  = pwd;
idcs   = strfind(current_folder,'\');
outer_folder = current_folder(1:idcs(end)-1);
addpath(strcat(outer_folder, "\ModalHand_ProcessedData"));
highRes = load("HighRes_ProcessedData.mat");

%% Parameters
preload = 3; %N

l1 = 25*10^-3; %m - Dustin
l2 = 26*10^-3; %m - Dustin
l3 = 53*10^-3; %m - Dustin
l4 = 78*10^-3; %m - Dustin

m0 = (0.20*preload^0.26)*10^-3; %kg - Wiertluski
m1 = (3)*10^-3; %kg
m2 = (9)*10^-3; %kg
m3 = (14)*10^-3; %kg
m4 = (362)*10^-3; %kg

% I = 1/12*m*l^2
I1 = (1/12)*(m1)*(l1)^2;
I2 = (1/12)*(m2)*(l2)^2;
I3 = (1/12)*(m3)*(l3)^2;
I4 = (1/12)*(m4)*(l4)^2;

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

%% Newton-Euler Equations
syms theta1 theta2 theta3 theta4 dtheta1 dtheta2 dtheta3 dtheta4 ...
    ddtheta1 ddtheta2 ddtheta3 ddtheta4 x1 x2 x3 x4 dx1 dx2 dx3 dx4 ...
    ddx1 ddx2 ddx3 ddx4 y0 y1 y2 y3 y4 dy0 dy1 dy2 dy3 dy4 ...
    ddy0 ddy1 ddy2 ddy3 ddy4 Fx1 Fx2 Fx3 Fx4 Fy1 Fy2 Fy3 Fy4 Fin

eqn1 = x1 == (l1/2)*cos(theta1)+l2*cos(theta2)+l3*cos(theta3)+l4*cos(theta4);
eqn2 = x2 == (l2/2)*cos(theta2)+l3*cos(theta3)+l4*cos(theta4);
eqn3 = x3 == (l3/2)*cos(theta3)+l4*cos(theta4);
eqn4 = x4 == (l4/2)*cos(theta4);
eqn5 = dx1 == -dtheta1*(l1/2)*sin(theta1)-dtheta2*l2*sin(theta2)-dtheta3*l3*sin(theta3)-dtheta4*l4*sin(theta4);
eqn6 = dx2 == -dtheta2*(l2/2)*sin(theta2)-dtheta3*l3*sin(theta3)-dtheta4*l4*sin(theta4);
eqn7 = dx3 == -dtheta3*(l3/2)*sin(theta3)-dtheta4*l4*sin(theta4);
eqn8 = dx4 == -dtheta4*(l4/2)*sin(theta4);
eqn9 = ddx1 == -ddtheta1*(l1/2)*sin(theta1)-dtheta1^2*(l1/2)*cos(theta1)...
    -ddtheta2*l2*sin(theta2)-dtheta2^2*l2*cos(theta2)-ddtheta3*l3*sin(theta3)...
    -dtheta3^2*l3*cos(theta3)-ddtheta4*l4*sin(theta4)-dtheta4^2*l4*cos(theta4);
eqn10 = ddx2 == -ddtheta2*(l2/2)*sin(theta2)-dtheta2^2*(l2/2)*cos(theta2)...
    -ddtheta3*l3*sin(theta3)-dtheta3^2*l3*cos(theta3)-ddtheta4*l4*sin(theta4)...
    -dtheta4^2*l4*cos(theta4);
eqn11 = ddx3 == -ddtheta3*(l3/2)*sin(theta3)-dtheta3^2*(l3/2)*cos(theta3)...
    -ddtheta4*l4*sin(theta4)-dtheta4^2*l4*cos(theta4);
eqn12 = ddx4 == -ddtheta4*(l4/2)*sin(theta4)-dtheta4^2*(l4/2)*cos(theta4);
eqn13 = y1 == (l1/2)*sin(theta1)+l2*sin(theta2)+l3*sin(theta3)+l4*sin(theta4);
eqn14 = y2 == (l2/2)*sin(theta2)+l3*sin(theta3)+l4*sin(theta4);
eqn15 = y3 == (l3/2)*sin(theta3)+l4*sin(theta4);
eqn16 = y4 == (l4/2)*sin(theta4);
eqn17 = dy1 == dtheta1*(l1/2)*cos(theta1)+dtheta2*l2*cos(theta2)+dtheta3*l3*cos(theta3)+dtheta4*l4*cos(theta4);
eqn18 = dy2 == dtheta2*(l2/2)*cos(theta2)+dtheta3*l3*cos(theta3)+dtheta4*l4*cos(theta4);
eqn19 = dy3 == dtheta3*(l3/2)*cos(theta3)+dtheta4*l4*cos(theta4);
eqn20 = dy4 == dtheta4*(l4/2)*cos(theta4);
eqn21 = ddy1 == ddtheta1*(l1/2)*cos(theta1)-dtheta1^2*(l1/2)*sin(theta1)...
    +ddtheta2*l2*cos(theta2)-dtheta2^2*l2*sin(theta2)+ddtheta3*l3*cos(theta3)...
    -dtheta3^2*l3*sin(theta3)+ddtheta4*l4*cos(theta4)-dtheta4^2*l4*sin(theta4);
eqn22 = ddy2 == ddtheta2*(l2/2)*cos(theta2)-dtheta2^2*(l2/2)*sin(theta2)...
    +ddtheta3*l3*cos(theta3)-dtheta3^2*l3*sin(theta3)+ddtheta4*l4*cos(theta4)...
    -dtheta4^2*l4*sin(theta4);
eqn23 = ddy3 == ddtheta3*(l3/2)*cos(theta3)-dtheta3^2*(l3/2)*sin(theta3)...
    +ddtheta4*l4*cos(theta4)-dtheta4^2*l4*sin(theta4);
eqn24 = ddy4 == ddtheta4*(l4/2)*cos(theta4)-dtheta4^2*(l4/2)*sin(theta4);
eqn25 = m1*ddx1 == Fx1 - (k1*(theta2-theta1)+b1*(dtheta2-dtheta1))*(2/l2)*sin(theta1);
eqn26 = m2*ddx2 == Fx2 - Fx1 -(k2*(theta3-theta2)+b2*(dtheta3-dtheta2)-...
    k1*(theta2-theta1)-b1*(dtheta2-dtheta1))*(2/l2)*sin(theta2);
eqn27 = m3*ddx3 == Fx3 - Fx2 -(k3*(theta4-theta3)+b3*(dtheta4-dtheta3)-...
    k2*(theta3-theta2)-b2*(dtheta3-dtheta2))*(2/l3)*sin(theta3);
eqn28 = m4*ddx4 == Fx4 - Fx3 -(k4*(-theta4)+b4*(-dtheta4)-...
    k4*(theta4-theta3)-b4*(dtheta4-dtheta3))*(2/l4)*sin(theta4);
eqn29 = m0*ddy0 == k0*(y1-y0)+b0*(dy1-dy0)+Fin;
eqn30 = m1*ddy1 == Fy1 + (k1*(theta2-theta1)+b1*(dtheta2-dtheta1))*(2/l1)*cos(theta1)-k0*(y1-y0)-b0*(dy1-dy0);
eqn31 = m2*ddy2 == Fy2 - Fy1 + (k2*(theta3-theta2)+b2*(dtheta3-dtheta2)+k1*(theta2-theta1)+b1*(dtheta2-dtheta1))*(2/l2)*cos(theta2);
eqn32 = m3*ddy3 == Fy3 - Fy2 + (k3*(theta4-theta3)+b3*(dtheta4-dtheta3)+k2*(theta3-theta2)+b2*(dtheta3-dtheta2))*(2/l3)*cos(theta3);
eqn33 = m4*ddy4 == Fy4 - Fy3 + (k4*(-theta4)+b4*(-dtheta4)+k3*(theta4-theta3)+b3*(dtheta4-dtheta3))*(2/l4)*cos(theta4);
eqn34 = I1*ddtheta1 == k1*(theta2-theta1)+b1*(dtheta2-dtheta1)+Fx1*(l1/2)*sin(theta1)-Fy1*(l1/2)*cos(theta1);
eqn35 = I2*ddtheta2 == k2*(theta3-theta2)+b2*(dtheta3-dtheta2)-...
    k1*(theta2-theta1)-b1*(dtheta2-dtheta1)+(Fx2+Fx1)*(l2/2)*sin(theta2)-(Fy2+Fy1)*(l2/2)*cos(theta2);
eqn36 = I3*ddtheta3 == k3*(theta4-theta3)+b3*(dtheta4-dtheta3)-...
    k2*(theta3-theta2)-b2*(dtheta3-dtheta2)+(Fx3+Fx2)*(l3/2)*sin(theta3)-(Fy3+Fy2)*(l3/2)*cos(theta3);
eqn37 = I4*ddtheta4 == k4*(-theta4)+b4*(-dtheta4)-...
    k3*(theta4-theta3)-b3*(dtheta4-dtheta3)+(Fx4+Fx3)*(l4/2)*sin(theta4)-(Fy4+Fy3)*(l4/2)*cos(theta4);

system1 = [eqn1, eqn2, eqn3, eqn4, eqn5, eqn6, eqn7, eqn8, eqn9, eqn10,...
    eqn11, eqn12, eqn13, eqn14, eqn15, eqn16, eqn17, eqn18, eqn19, eqn20,...
    eqn21, eqn22, eqn23, eqn24, eqn25, eqn26, eqn27, eqn28, eqn29, eqn30,...
    eqn31, eqn32, eqn33, eqn34, eqn35, eqn36, eqn37];

vars1 = [ddy0, ddtheta1, ddtheta2, ddtheta3, ddtheta4,...
    x1, x2, x3, x4, dx1, dx2, dx3, dx4, ddx1, ddx2, ddx3, ddx4, y1, y2, y3, y4, ...
    dy1, dy2, dy3, dy4, ddy1, ddy2, ddy3, ddy4, Fx1, Fx2, Fx3, Fx4, Fy1, Fy2, Fy3, Fy4];

vars2 = [dy0, y0, dtheta1, theta1, dtheta2, theta2, dtheta3, theta3, dtheta4, theta4];
values2 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

soln1 = solve(system1,vars1);
vars3 = [soln1.ddy0, soln1.ddtheta1, soln1.ddtheta2, soln1.ddtheta3, soln1.ddtheta4];

%% Linearize System
num_states = 10;
Jacobian = zeros(num_states,num_states);
B = zeros(num_states,num_states);

for iter1 = 1:num_states
    for iter2 = 1:num_states/2
        Jacobian(iter1,iter2*2-1) = subs(diff(vars3(iter2),vars2(iter1)),vars2,values2);
        B(1,iter2*2-1) = subs(diff(vars3(iter2),Fin),vars2,values2);
        if iter1 == iter2*2-1
            Jacobian(iter1,iter2*2) = 1;
        end
    end
end

syms s

identity = eye(num_states,num_states);
G = ((s*identity-Jacobian')^(-1))*B;

%% Fixed System (Already Linear)
A_fixed = -(m0*s^2+b0*s+k0);
A_fixed_inverse = 1/A_fixed;

%% Frequency Response
freq = highRes.freq;
y0_out = zeros(1,length(freq));
y1_out = zeros(1,length(freq));
y2_out = zeros(1,length(freq));
y3_out = zeros(1,length(freq));
y4_out = zeros(1,length(freq));
theta1_out = zeros(1,length(freq));
theta2_out = zeros(1,length(freq));
theta3_out = zeros(1,length(freq));
theta4_out = zeros(1,length(freq));
y_fixed = zeros(1,length(freq));

vars4 = [theta1,theta2,theta3,theta4];

for iter1 = 1:length(freq)
    s_sub = 2*pi*freq(iter1)*1i;

    y0_out(iter1) = subs(G(2,1),s,s_sub);
    theta1_out(iter1) = subs(G(4,1),s,s_sub);
    theta2_out(iter1) = subs(G(6,1),s,s_sub);
    theta3_out(iter1) = subs(G(8,1),s,s_sub);
    theta4_out(iter1) = subs(G(10,1),s,s_sub);

    values4 = [theta1_out(iter1),theta2_out(iter1),theta3_out(iter1),theta4_out(iter1)];
    
    y1_out(iter1) = (l1/2)*sin(theta1_out(iter1))+(l2)*sin(theta2_out(iter1))+...
                    (l3)*sin(theta3_out(iter1))+(l4)*sin(theta4_out(iter1));
    y2_out(iter1) = (l2/2)*sin(theta2_out(iter1))+...
                    (l3)*sin(theta3_out(iter1))+(l4)*sin(theta4_out(iter1));
    y3_out(iter1) = (l3/2)*sin(theta3_out(iter1))+(l4)*sin(theta4_out(iter1));
    y4_out(iter1) = (l4/2)*sin(theta4_out(iter1));

    y_fixed(iter1) = subs(A_fixed_inverse,s,s_sub);
end

%% Save Data
save NewtonEulerData.mat y_fixed y0_out y1_out y2_out y3_out y4_out...
    l1 l2 l3 l4... 
    theta1_out theta2_out theta3_out theta4_out freq
