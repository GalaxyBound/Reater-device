if ~isempty(instrfind)
     fclose(instrfind);
      delete(instrfind);
end

% NEED TO MANUALLY SET BY USING ls /dev/tty.usbmodem* in terminal and replace below
% string
com_port = "/dev/tty.usbmodem1411";%com_list{end};
fprintf('Opening %s\n', com_port);
comport = serial(com_port, 'BaudRate', 115200);
fopen(comport);

a = 1

while (a==1)
    raw = fscanf(comport);
    disp(raw)
    
    % TODO: process the raw data here
end

fclose(comport);