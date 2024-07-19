function [] = saveTransparent(gcf,title)
    saveas(gcf, 'temp_figure.png');
    img = imread('temp_figure.png');
    [rows, cols, ~] = size(img);
    alpha = ones(rows, cols);
    
    % Define the background color to be made transparent (usually white)
    background_color = squeeze(img(1, 1, :));
    for k = 1:3
        alpha(img(:,:,k) == background_color(k)) = 0;
    end
    
    imwrite(img, title, 'Alpha', alpha);
    delete temp_figure.png
end