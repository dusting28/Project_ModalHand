function [new_points] = maskDots(points, radius, cut_x, cut_y, cut_thickness)
    [~, sorted_idx] = sort(points.Metric);
    deleted_matrix = zeros(1,length(sorted_idx));
    slope = (cut_y(2)-cut_y(1))/(cut_x(2)-cut_x(1));
    iter0 = 0;
    for iter1 = 1:length(sorted_idx)
        idx = sorted_idx(iter1);
        cut_condition = true;
        if not(deleted_matrix(idx))
            x_position = points.Location(idx,1);
            y_position = points.Location(idx,2);
            if and(x_position>=cut_x(1),x_position<=cut_x(2))
                y_est = cut_y(1) + (x_position-cut_x(1))*slope;
                if or (y_position > y_est+cut_thickness, y_position<y_est-cut_thickness)
                    cut_condition = false;
                end
            else
                cut_condition = false;
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