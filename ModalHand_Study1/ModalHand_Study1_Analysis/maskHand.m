function [masking_matrix] = maskHand(binary_image)
    B = bwboundaries(binary_image);
    masking_matrix = poly2mask(B{2}(:,2),B{2}(:,1),...
        size(binary_image,1),size(binary_image,2));
end