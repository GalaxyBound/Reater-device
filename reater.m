import matlab.net.*
import matlab.net.http.*

if ~isempty(instrfind)
     fclose(instrfind);
      delete(instrfind);
end

% NEED TO MANUALLY SET BY USING ls /dev/tty.usbmodem* in terminal and replace below
% string
com_port = "/dev/tty.usbmodem14311";%com_list{end};
fprintf('Opening %s\n', com_port);
comport = serial(com_port, 'BaudRate', 115200);
fopen(comport);

a = 1

while (a==1)
    raw = fscanf(comport);
    disp(raw)
    
    data = raw;
    % TODO: process the raw data here
    % [response,completedrequest,history] = send(request,uri)
    % r = RequestMessage;
    uri = URI('http://127.0.0.1:8000/ehealth/test');
    resp = webwrite(uri, 'raw-data', raw, 'test-name1', 'test-value1')
    % resp = send(r,uri);
    % status = resp.StatusCode
    % bodyData = resp.Body.Data
    
    postData = resp.post
    % you can split the bodyData up into whatever data you need
    
    % Delay for 30s cause we dont want to spam server right now
    pause(10);
end

fclose(comport);