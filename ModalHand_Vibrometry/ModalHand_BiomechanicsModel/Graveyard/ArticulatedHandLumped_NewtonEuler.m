clc; clear;
close all;

preload = 3; %N

l1 = 16*10^-3; %m - Alexander
l2 = 22*10^-3; %m - Alexander
l3 = 40*10^-3; %m - Alexander
l4 = 68*10^-3; %m - Alexander

actuator_mass = 0*10^-3; %kg
m0 = actuator_mass + (0.20*preload^0.26)*10^-3; %kg - Wiertluski
% m0 = (10^-9)*(pi*5*7.5^2)*997; % density
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
% k0 = (2.1*preload+1.9)*10^3; %N/m - Pawluk
k1 = 120*10^-3; %N*m/rad - Jindrich
k2 = 290*10^-3; %N*m/rad - Jindrich
k3 = 540*10^-3; %N*m/rad - Jindrich
k4 = 6590*10^-3; %N*m/rad - Kuchenbecker

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

A_fixed = -(m0*s^2+b0*s+k0);
A_fixed_inverse = 1/A_fixed;

[eigenvectors, eigenvalues] = eig(Jacobian');
[~,den] = numden(A_fixed_inverse);
fixed_eigenfrequencies = vpa(solve(den,s));

complex_eigenvalues = (length(eigenvalues) - sum(imag(eigenvalues) == 0,'all'))/2;

eigenfrequencies = zeros(1,complex_eigenvalues);
eigenmodes = zeros(length(eigenvalues),complex_eigenvalues);
iter2 = 0;
for iter1 = 1:length(eigenvalues)/2
    if not(imag(eigenvalues(iter1*2,iter1*2)) == 0)
        iter2 = iter2+1;
        eigenfrequencies(iter2) = abs(eigenvalues(iter1*2,iter1*2))/2/pi;
        eigenmodes(:,iter2) = eigenvectors(:,iter1*2);
    end
end

unique_eigenfrequencies = eigenfrequencies(eigenfrequencies>0);

frequency = 10:1000;
y0_out = zeros(1,length(frequency));
y1_out = zeros(1,length(frequency));
y2_out = zeros(1,length(frequency));
y3_out = zeros(1,length(frequency));
y4_out = zeros(1,length(frequency));
theta1_out = zeros(1,length(frequency));
theta2_out = zeros(1,length(frequency));
theta3_out = zeros(1,length(frequency));
theta4_out = zeros(1,length(frequency));
y_fixed = zeros(1,length(frequency));

vars4 = [theta1,theta2,theta3,theta4];


for iter1 = 1:length(frequency)
    s_sub = 2*pi*frequency(iter1)*1i;

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

figure
loglog(frequency,1000*(2*pi*frequency).^1.*abs(y1_out),'r');
hold on;
loglog(frequency,1000*(2*pi*frequency).^1.*abs(y2_out),'Color',[0.9290 0.6940 0.1250]);
loglog(frequency,1000*(2*pi*frequency).^1.*abs(y3_out),'Color',[0 0.4470 0.7410]);
loglog(frequency,1000*(2*pi*frequency).^1.*abs(y4_out),'Color',[.85 0 .75]);
hold off;
legend('Distal Phalanx','Medial Phalanx','Proximal Phalanx','Metacarpal')
title('Admittance')
ylabel('$\frac{\dot{x}}{F}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency (Hz)')
ylim([10^-2,10^3]);

figure
semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y0_out),'k');
hold on;
semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y1_out),'r');
semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y2_out),'Color',[0.9290 0.6940 0.1250]);
semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y3_out),'Color',[0 0.4470 0.7410]);
semilogx(frequency,1000*(2*pi*frequency).^1.*abs(y4_out),'Color',[.85 0 .75]);
hold off;
legend('Distal Phalanx','Medial Phalanx','Proximal Phalanx','Metacarpal')
title('Admittance')
ylabel('$\frac{\dot{x}}{F}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency (Hz)')
ylim([0,500]);

figure
subplot(1,3,1)
semilogx(frequency,20*log10(1./((2*pi*frequency).^1.*abs(y0_out))),'k');
hold on;
semilogx(frequency,20*log10(1./((2*pi*frequency).^1.*abs(y1_out))),'r');
semilogx(frequency,20*log10(1./((2*pi*frequency).^1.*abs(y2_out))),'Color',[0.9290 0.6940 0.1250]);
semilogx(frequency,20*log10(1./((2*pi*frequency).^1.*abs(y3_out))),'Color',[0 0.4470 0.7410]);
semilogx(frequency,20*log10(1./((2*pi*frequency).^1.*abs(y4_out))),'Color',[.85 0 .75]);
hold off;
legend('Contact Point','Distal Phalanx','Medial Phalanx','Proximal Phalanx','Metacarpal')
title('Impedance')
ylabel('$\frac{F}{\dot{x}}$ (dB)','interpreter','latex')
xlabel('Frequency (Hz)')
subplot(1,3,2)
semilogx(frequency,20*log10(((2*pi*frequency).^1.*abs(y0_out))),'k');
hold on;
semilogx(frequency,20*log10(((2*pi*frequency).^1.*abs(y1_out))),'r');
semilogx(frequency,20*log10(((2*pi*frequency).^1.*abs(y2_out))),'Color',[0.9290 0.6940 0.1250]);
semilogx(frequency,20*log10(((2*pi*frequency).^1.*abs(y3_out))),'Color',[0 0.4470 0.7410]);
semilogx(frequency,20*log10(((2*pi*frequency).^1.*abs(y4_out))),'Color',[.85 0 .75]);
hold off;
legend('Contact Point','Distal Phalanx','Medial Phalanx','Proximal Phalanx','Metacarpal')
title('Admittance')
ylabel('$\frac{\dot{x}}{F}$ (dB)','interpreter','latex')
xlabel('Frequency (Hz)')
subplot(1,3,3)
semilogx(frequency,20*log10((2*pi*frequency).^1.*abs(y0_out-y1_out)),'k');
hold on;
semilogx(frequency,20*log10((2*pi*frequency).^1.*abs(theta1_out-theta2_out)*l1/2),'Color',[0.8500 0.3250 0.0980]);
semilogx(frequency,20*log10((2*pi*frequency).^1.*abs(theta2_out-theta3_out)*(l1/2+l2)),'Color',[0.4660 0.6740 0.1880]);
semilogx(frequency,20*log10((2*pi*frequency).^1.*abs(theta3_out-theta4_out)*(l1/2+l2+l3)),'Color',[0.7 0.2 0.8]);
semilogx(frequency,20*log10((2*pi*frequency).^1.*abs(theta4_out)*(l1/2+l2+l3+l4)),'m');
hold off;
legend('Skin Compression','DIP','PIP','MCP','Wrist')
title('Contribution to Contact Admittance')
ylabel('$\frac{\dot{x}}{F}$ (dB)','interpreter','latex')
xlabel('Frequency (Hz)')


figure
hold on;
plot(frequency,1000*(2*pi*frequency).^1.*abs(y0_out),'k');
plot(frequency,1000*(2*pi*frequency).^1.*abs(y1_out),'r');
plot(frequency,1000*(2*pi*frequency).^1.*abs(y2_out),'Color',[0.9290 0.6940 0.1250]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(y3_out),'Color',[0 0.4470 0.7410]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(y4_out),'Color',[.85 0 .75]);
hold off;
legend('Contact Point','Distal Phalanx','Medial Phalanx','Proximal Phalanx','Metacarpal')
title('Admittance')
ylabel('$\frac{\dot{x}}{F}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^1.*abs(y0_out-y1_out),'k');
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta1_out-theta2_out)*l1/2,'Color',[0.8500 0.3250 0.0980]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta2_out-theta3_out)*(l1/2+l2),'Color',[0.4660 0.6740 0.1880]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta3_out-theta4_out)*(l1/2+l2+l3),'Color',[0.7 0.2 0.8]);
plot(frequency,1000*(2*pi*frequency).^1.*abs(theta4_out)*(l1/2+l2+l3+l4),'m');
hold off;
legend('Skin Compression','DIP','PIP','MCP','Wrist')
title('Contribution to Contact Admittance')
ylabel('$\frac{\dot{x}}{F}$ (mm/Ns)','interpreter','latex')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,1000*(2*pi*frequency).^1.*abs(y1_out-y0_out));
plot(frequency,1000*(2*pi*frequency).^1.*abs(y_fixed));
hold off;
legend('Free Hand', 'Fixed Hand')
title('Local Skin Compression')
ylabel ('Displacment (mm)')
xlabel('Frequency (Hz)')

figure
hold on;
plot(frequency,(2*pi*frequency).^0.*abs(theta1_out-theta2_out));
plot(frequency,(2*pi*frequency).^0.*abs(theta2_out-theta3_out));
plot(frequency,(2*pi*frequency).^0.*abs(theta3_out-theta4_out));
plot(frequency,(2*pi*frequency).^0.*abs(theta4_out));
hold off;
legend('DIP','PIP','MCP','Wrist')
title('Joint Rotations')
ylabel('theta/F (rad/Ns)')
xlabel('Frequency (Hz)')

figure(10)
filename = 'Mode1.gif';
for n = 0:359
    phase = pi*n/180;
    theta4 = 100*abs(eigenmodes(10,1))*sin(phase + angle(eigenmodes(10,1)));
    theta3 = 100*abs(eigenmodes(8,1))*sin(phase + angle(eigenmodes(8,1)));
    theta2 = 100*abs(eigenmodes(6,1))*sin(phase + angle(eigenmodes(6,1)));
    theta1 = 100*abs(eigenmodes(4,1))*sin(phase + angle(eigenmodes(4,1)));
    compression = 100*abs(eigenmodes(2,1))*sin(phase + angle(eigenmodes(2,1)));
    node4_x = 0;
    node4_y = 0;
    node3_x = node4_x + l4*cos(theta4);
    node3_y = node4_y + l4*sin(theta4);
    node2_x = node3_x + l3*cos(theta3);
    node2_y = node3_y + l3*sin(theta3);
    node1_x = node2_x + l2*cos(theta2);
    node1_y = node2_y + l2*sin(theta2);
    node0_x = node1_x + l1*cos(theta1);
    node0_y = node1_y + l1*sin(theta1);
    nodec_x = node0_x;
    nodec_y = compression - 1.2*10^-2;
    x = [node4_x, node3_x, node2_x, node1_x, node0_x, nodec_x];
    y = [node4_y, node3_y, node2_y, node1_y, node0_y, nodec_y];
    plot(x,y,'o-');
    %title(append(unique_eigenfrequencies(1,1),"Hz Mode"))
    xlim([0,.15]);
    ylim([-.075, .075]);
    drawnow
    frame = getframe(10);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    if n == 0
      imwrite(imind,cm,filename,'gif','DelayTime',0.01,'Loopcount',inf);
    else
      imwrite(imind,cm,filename,'gif','DelayTime',0.01,'WriteMode','append');
    end
end

figure(11)
filename = 'Mode2.gif';
for n = 0:359
    phase = pi*n/180;
    theta4 = 100*abs(eigenmodes(10,2))*sin(phase + angle(eigenmodes(10,2)));
    theta3 = 100*abs(eigenmodes(8,2))*sin(phase + angle(eigenmodes(8,2)));
    theta2 = 100*abs(eigenmodes(6,2))*sin(phase + angle(eigenmodes(6,2)));
    theta1 = 100*abs(eigenmodes(4,2))*sin(phase + angle(eigenmodes(4,2)));
    compression = 100*abs(eigenmodes(2,2))*sin(phase + angle(eigenmodes(2,2)));
    node4_x = 0;
    node4_y = 0;
    node3_x = node4_x + l4*cos(theta4);
    node3_y = node4_y + l4*sin(theta4);
    node2_x = node3_x + l3*cos(theta3);
    node2_y = node3_y + l3*sin(theta3);
    node1_x = node2_x + l2*cos(theta2);
    node1_y = node2_y + l2*sin(theta2);
    node0_x = node1_x + l1*cos(theta1);
    node0_y = node1_y + l1*sin(theta1);
    nodec_x = node0_x;
    nodec_y = compression - 1.2*10^-2;
    x = [node4_x, node3_x, node2_x, node1_x, node0_x, nodec_x];
    y = [node4_y, node3_y, node2_y, node1_y, node0_y, nodec_y];
    plot(x,y,'o-');
    %title(append(unique_eigenfrequencies(1,2),"Hz Mode"))
    xlim([0,.15]);
    ylim([-.075, .075]);
    drawnow
    frame = getframe(11);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    if n == 0
      imwrite(imind,cm,filename,'gif','DelayTime',0.01,'Loopcount',inf);
    else
      imwrite(imind,cm,filename,'gif','DelayTime',0.01,'WriteMode','append');
    end
end
