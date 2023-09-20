function [new_points] = removeDots(points, radius, cut_box, cut_region)
    [~, sorted_idx] = sort(points.Metric);
    deleted_matrix = zeros(1,length(sorted_idx));
    iter0 = 0;
    for iter1 = 1:length(sorted_idx)
        idx = sorted_idx(iter1);
        if not(deleted_matrix(idx))
            x_position = points.Location(idx,1);
            y_position = points.Location(idx,2);
            if cut_region == "Q2"
                cut_condition = not(and(x_position<cut_box(1),y_position<cut_box(2)));
            end
            if cut_region == "Q3"
                cut_condition = not(and(x_position<cut_box(1),y_position>cut_box(2)));
            end
            if cut_condition
                iter0 = iter0+1;
                new_points(iter0,1) = x_position;
                new_points(iter0,2) = y_position;
            end
            for iter2 = 1:length(sorted_idx)
                idx2 = sorted_idx(iter2);
                distance = ((x_position-points.Location(idx2,1))^2 + (y_position-points.Location(idx2,2))^2)^.5;
                if distance < radius
                    deleted_matrix(idx2) = 1;
                end
            end
        end
    end
end