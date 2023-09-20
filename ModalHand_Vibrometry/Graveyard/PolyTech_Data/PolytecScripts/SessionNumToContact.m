%% Written by Gregory Reardon (reardon@ucsb.edu)
% Convert a session number to stimulus location
% -------------------------------------------------------------------------
% Inputs:
%         num: Session number as an integer (see Excel spreadsheet)
% Outputs:
%         contact: Type of stimulus contact as a string
%       
%% MAIN BODY --------------------------------------------------------------

function contact = SessionNumToContact(num)

switch num
    %impulses
    case {3,15,17,20,25,27}
        contact = 'Large-Normal';
    case 9
        contact = 'Large-Shear';
    case 13
        contact = 'Small-Normal';
   
    %windowed sinusoids
    case 4
        contact = 'Large-Normal';

    otherwise
        warning('Contact Unknown')
end




end