import matlab.net.*
import matlab.net.http.*

 % realtime.m
clear all;
close all;
 try
     fclose(instrfind) %close any bogus serial connections
 end

% Set up serial connection with Baud Rate and Input Buffer Size
s = serial('/dev/tty.usbmodem1411', 'BaudRate', 115200, 'InputBufferSize', 2500);

% Open the serial connection and display connection settings
fopen(s);
disp(get(s,'Name'));
prop=(get(s,'BaudRate'));
disp(['Baud Rate: ',num2str(prop)]);

% Initialize timer variables 
t = 1;                          % Counter for 250 tick window
n = 1;                          % Counter number of ti
wnd = 251;                      % Sampling window
uart_scale = 255;               % Uart scale (0 - 255)
volt_scale = 5;                 % Voltage scale (0 - 5)
scale = 1;                      % Scale select (0 => volt_scale, 1 => uart)
ave_scale = 10e3;                % Average output plot scale 2e3=2000
time = linspace(0, 3.5, wnd);   % Time array used to represent seconds

disp('Running...');
rd = 1;                         % Uart reading variable
out_uart = 128*ones(1,wnd);     % Output vector
out_volt = 2.5*ones(1,wnd);
threshold = 1000;               % Threshold to measure BPM
ave = zeros(1,wnd);             % Average output vector
dif = diff(ave);
difdif = diff(dif);
alpha = 0.99;                   % Weight for average function
below_thresh = 0;               % States to indicate above or below thresh
above_thresh = 1;
hr_state = 0;                   % Heart rate status (above or below thresh)
num_peak_history = 4;           % Keep track of 4 peaks
peak_times = zeros(1,num_peak_history); % Array to record thresh crossings
bpm_values = zeros(1,10);
bpm_count = 1;
ave_bpm = 0;

% Create a real-time plot of the output and add a quit button
figure(1)
outplot = plot(time, out_volt);
axis([0 3.5 0 volt_scale]);
grid on;
xlabel('Time (sec)');
ylabel('Output Voltage (V)');
title('Heart rate meter Output');
% Define the erase button
quitbutton = uicontrol('style','pushbutton',...
   'string','Close', ...
   'fontsize',12, ...
   'position',[450,10,50,20], ...
   'callback','quitit=1;fclose(s);delete(gcf);');%gcf - Current figure handle
quitit = 0;
bpmtext = uicontrol('style', 'text',...
    'string', ['BPM: '],...
    'fontsize', 12,...
    'position', [80, 10, 100, 20]);
drawnow;

% Run the program until button pressed
while (quitit == 0)
    while(t <= wnd && quitit == 0)
        
        % Query and read the Serial connection
        fprintf(s, '*IDN?'); %???????????
        readSTR = fscanf(s)
        
        if (strcmp(readSTR(1:1),'D') == 1)
            fprintf(s, '*IDN?');
            a = str2double(fscanf(s))
            heartrate = a;
            fprintf(s, '*IDN?');
            b = str2double(fscanf(s))
            spo2 = b;
            fprintf(s, '*IDN?');
            c = str2double(fscanf(s))
            volt = c;
            fprintf(s, '*IDN?');
            d = str2double(fscanf(s))
            temp = d;
            
            
            uri = URI('http://127.0.0.1:8000/ehealth/log/vitals/');
            resp = webwrite(uri, 'heartrate', heartrate, 'spo2', spo2, 'temp', temp)
                
        
            continue
        end
%   
rd
        
        % Insert measurement into the the t1 cell of output array
        if (t ~= 1)
            out_uart(t) = rd;
            out_volt(t) = rd*2*volt_scale/uart_scale;
                if ((out_uart(t)-uart_scale/2)^2 > ave(t-1))
                    ave(t) = (out_uart(t)-uart_scale/2)^2;
                else
                    ave(t) = alpha*ave(t-1)+(1-alpha)*...
                        (abs(out_uart(t)-uart_scale/2))^2;
                end
            
            dif(t-1) = ave(t) - ave(t-1);
            
            if (t > 2)
                difdif(t-2) = dif(t-1) - dif(t-2);
                if (dif(t-1) > threshold && difdif(t-2) > threshold)
                    peak_times(2) = peak_times(1);
                    peak_times(1) = time(t);
                    temp_time = peak_times(1);
%                     fprintf('Peak Time = %d\n', peak_times(1));
                    if (peak_times(1) < peak_times(2))
                        temp_time = temp_time + 3.50;
                    end
                    bpm = 1/(temp_time - peak_times(2))*60;
%                     bpm
                    % SEND TO SERVER
                    uri = URI('http://127.0.0.1:8000/ehealth/log/vitals/');
                    resp = webwrite(uri, 'heartrate', bpm)
                    %postData = resp.post
                    bpm
                    %print("SENT DATA");
                    pause(5);
                    % SENT TO SERVER
                    
                    
                    if (bpm > 60 && bpm < 90)
                        if (bpm_count > 10)
                            bpm_count = 1;
                            bpm_values = zeros(1,10);
                        end
                        bpm_values(bpm_count) = bpm;
                        ave_bpm = mean(bpm_values(1:bpm_count));
                        bpm_count = bpm_count + 1;
                        set(bpmtext, 'string', ['BPM: ',...
                            num2str(ave_bpm,4)]);
%                         fprintf('BPM = %f\n', bpm);

                    end
                end
            end

        % After collecting 250 samples, reset the output plot
        else
            last_ave = 0;
            ave = zeros(1,wnd);
            out_uart = 128*ones(1,wnd);
            out_uart(t) = rd;
            out_volt = 2.5*ones(1,wnd);
            out_volt(t) = rd*volt_scale/uart_scale;
            ave(t) = alpha*last_ave+(1-alpha)*...
                (abs(out_uart(t)-uart_scale/2))^2;
            
        end
        
        % Increment time
        t = t + 1;
        
        % Plot (or update the plot of) the output
        set(outplot, 'ydata', out_volt);
%         set(aveplot, 'ydata', dif);        
        drawnow;
    end

    % Reset the 250 tick window and increment runtime counter
    t = 1;
end

% Close the Serial connection
fclose(s);

% 
% while (a==1)
%     raw = fscanf(comport);
%     disp(raw)
%     
%     data = raw;
%     % TODO: process the raw data here
%     % [response,completedrequest,history] = send(request,uri)
%     % r = RequestMessage;
%     uri = URI('http://127.0.0.1:8000/ehealth/test');
%     resp = webwrite(uri, 'raw-data', raw, 'test-name1', 'test-value1')
%     % resp = send(r,uri);
%     % status = resp.StatusCode
%     % bodyData = resp.Body.Data
%     
%     postData = resp.post
%     % you can split the bodyData up into whatever data you need
%     
%     % Delay for 30s cause we dont want to spam server right now
%     pause(10);
% end

% fclose(comport);