function MaxMSPLoadTestSignals(sigType)

pause(2); %pause to make sure signal has been generated

if strcmp(sigType,'sweep')
   udpm = 'loadSweep';
elseif strcmp(sigType,'trf')
   udpm = 'loadTRF'; 
end

u = udp('127.0.0.1', 8000);  %local ip = 127.0.0.1, port 5000
fopen(u);
oscsend(u, '/sigType','s', udpm);

end