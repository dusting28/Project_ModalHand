close all; clear; clc;
t = 0:.0001:.1;
f = [40, 100];
y1 = sin(2*pi*f(1)*t);
y2 = sin(2*pi*f(2)*t);
f = figure(1);
f.Position = [100 100 300 120];
plot(t,y1,'k')
axis off
% title("Low Frequency Stimulus")
f = figure(2);
f.Position = [100 100 300 120];
set(gca,'XColor', 'none','YColor','none')
plot(t,y2,'k')
axis off
% title("High Frequency Stimulus")
