% participants = ["P1","P2","P3","P4","P5","P6"];
% conditions = ["Free", "Fixed"];
% LDV = ["Low", "Med"];
% location = ["Loc1", "Loc2", "Loc3", "Loc4", "Loc5"];

participants = ["P2"];
conditions = ["Fixed"];
LDV = ["Low"];
location = ["Loc1"];

folder = "Data/LowRes/";

for iter1 = 1:length(participants)
    for iter2 = 1:length(conditions)
        for iter3 = 1:length(LDV)
            for iter4 = 1:length(location)
                filename = strcat(participants(iter1),"_", conditions(iter2), "_", location(iter4), "_", LDV(iter3), ".mat");
                all_data = load(strcat(folder,filename));
                for iter5 = 1:3
                    figure
                    plot(all_data.Signals.Motu{iter5}(:,1));
                    title(filename)
                end
            end
        end
    end
end