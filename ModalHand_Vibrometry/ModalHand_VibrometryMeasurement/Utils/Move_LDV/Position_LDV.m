function Position_LDV(ldvStartLoc,loc,ldv)
    fr = 1/1000; % 1000 sample sr for moving laser slowly
    moveDist = sqrt(sum((ldvStartLoc - loc).^2));
    moveTime = ceil(moveDist*500);
    y = zeros(moveTime,2);
    y(:,1) = linspace(ldvStartLoc(1),loc(1),moveTime);
    y(:,2) = linspace(ldvStartLoc(2),loc(2),moveTime);

    for j = 1:moveTime
        outputSingleScan(ldv,[y(j,1) y(j,2)]);
        pause(fr);
    end
    pause(2); % Pause between locations (added on 09/12/2019)

end

