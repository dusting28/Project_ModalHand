function [admittance] = newtonEulerAdmittance(model, ylocations)
    l1 = ((model.l1 - ylocations/1000)/model.l1);
    l1(l1>1) = 1;
    l1(l1<0) = 0;
    l2 = ((model.l2 + model.l1 - ylocations/1000)/model.l2);
    l2(l2>1) = 1;
    l2(l2<0) = 0;
    l3 = ((model.l3 + model.l2 + model.l1 - ylocations/1000)/model.l3);
    l3(l3>1) = 1;
    l3(l3<0) = 0;
    l4 = ((model.l4 + model.l3 + model.l2 + model.l1 - ylocations/1000)/model.l4);
    l4(l4>1) = 1;
    l4(l4<0) = 0;
    
    dtheta1 = 2*pi*1i*model.freq.*model.theta1_out;
    dtheta2 = 2*pi*1i*model.freq.*model.theta2_out;
    dtheta3 = 2*pi*1i*model.freq.*model.theta3_out;
    dtheta4 = 2*pi*1i*model.freq.*model.theta4_out;
    
    admittance = 1000*(l4'*model.l4*dtheta4 + l3'*model.l3*dtheta3 + l2'*model.l2*dtheta2 + l1'*model.l1*dtheta1);

end