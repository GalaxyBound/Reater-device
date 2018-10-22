import matlab.net.*
import matlab.net.http.*

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
    
    % TODO: process the raw data here, then load into data (to send)
    data = raw;
    
    % General headers
%     body = matlab.net.http.MessageBody(data);
%     contentTypeField = matlab.net.http.field.ContentTypeField('text/plain');
%     type1 = matlab.net.http.MediaType('text/*');
%     type2 = matlab.net.http.MediaType('application/json','q','.5');
%     acceptField = matlab.net.http.field.AcceptField([type1 type2]);
%     header = [acceptField contentTypeField];
%     method = matlab.net.http.RequestMethod.POST;
%     
%     r = matlab.net.http.RequestMessage(method,header,body);

    uri = URI('http://127.0.0.1:8000/ehealth/test');
    resp = webwrite(uri, 'raw-data', raw, 'test-name1', 'test-value1')
%     resp = send(r,uri);
%     status = resp.StatusCode
    % bodyData = resp.Body.Data
    
    % you can split the bodyData up into whatever data you need
    postData = resp.post
    
    % Delay for 30s cause we dont want to spam server right now
    pause(10);
end

fclose(comport);