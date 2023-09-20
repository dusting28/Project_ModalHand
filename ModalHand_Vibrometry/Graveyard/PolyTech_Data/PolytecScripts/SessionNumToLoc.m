%% Written by Gregory Reardon (reardon@ucsb.edu)
% Convert a session number to stimulus location
% -------------------------------------------------------------------------
% Inputs:
%         num: Session number as an integer (see Excel spreadsheet)
% Outputs:
%         loc: Stimulus location as a string
%       
%% MAIN BODY --------------------------------------------------------------

function loc = SessionNumToLoc(num)

switch num
    %impulses
    case {3,9,13}
        loc = 'Digit2-DP';
    case 15
        loc = 'Digit2-IP';
    case 17
        loc = 'Digit2-PP';
    case 20
        loc = 'Digit3-DP';
    case 25
        loc = 'Wrist-Dorsal';
    case 27
        loc = 'Wrist-Volar';
        
    % windowed sinusoids
    case 4
        loc = 'Digit2-DP';
    otherwise
        warning('Location Unknown')
end




end