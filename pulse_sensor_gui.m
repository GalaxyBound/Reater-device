function varargout = pulse_sensor_gui(varargin)
% PULSE_SENSOR_GUI MATLAB code for pulse_sensor_gui.fig
%      PULSE_SENSOR_GUI, by itself, creates a new PULSE_SENSOR_GUI or raises the existing
%      singleton*.
%
%      H = PULSE_SENSOR_GUI returns the handle to a new PULSE_SENSOR_GUI or the handle to
%      the existing singleton*.
%
%      PULSE_SENSOR_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PULSE_SENSOR_GUI.M with the given input arguments.
%
%      PULSE_SENSOR_GUI('Property','Value',...) creates a new PULSE_SENSOR_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pulse_sensor_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pulse_sensor_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pulse_sensor_gui

% Last Modified by GUIDE v2.5 19-Oct-2016 16:39:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pulse_sensor_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @pulse_sensor_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before pulse_sensor_gui is made visible.
function pulse_sensor_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pulse_sensor_gui (see VARARGIN)

% Choose default command line output for pulse_sensor_gui
handles.output = hObject;

% Intialise the figure data
set(handles.raw_plot, 'UserData', zeros(500,1));

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pulse_sensor_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function mainfn(hObject, eventdata, handles)
%

%% Get the COM port and initialise the connection
% NEED TO MANUALLY SET BY USING ls /dev/tty.usbmodem* in terminal and replace below
% string
handles.data.com = "/dev/tty.usbmodem1421";%com_list{end};
fprintf('Opening %s\n', handles.data.com);
comport = serial(handles.data.com, 'BaudRate', 115200);
fopen(comport);
set(handles.com_text, 'String', sprintf('Connected to %s', handles.data.com));

%% Initialise the plot
samp_rate = 50;
raw_data = get(handles.raw_plot, 'UserData');
tbuf = (0:length(raw_data)-1)/samp_rate;
rawplot = plot(handles.raw_plot, tbuf, raw_data);
axis([tbuf(1) tbuf(end) -0.1 1.1])

%% Set the x value
set(rawplot, 'XData', tbuf);
set(filtplot, 'XData', tbuf);
set(thresplot, 'XData', tbuf);

%% Initialise the threshold parameters
threshold = 200;

%% Read samples and process them
try
     while(get(handles.StartStopButton,'UserData') == true)
         % Read a new sample
         raw = fscanf(comport);
         % Extract the value
         new_samp = str2double(raw(2:end));
         % Store the new sample to the plot
         raw_data(1:end-1) = raw_data(2:end);
         raw_data(end) = new_samp;
         set(rawplot, 'YData', raw_data);
         % Apply median filter if selected
         filt_data(1:end-1,1) = filt_data(2:end,1);
         med_filt = update_med_filter(hObject, eventdata, handles);
         if (med_filt.enable == true)
             filt_data(end,1) = median(raw_data((end-(med_filt.size-1)):end));
         else
             filt_data(end,1) = raw_data(end);
         end
         % Apply low pass filter if selected
         filt_data(1:end-1,2) = filt_data(2:end,2);
         lpf = update_lpf(hObject, eventdata, handles);
         if (lpf.enable == true)
             filt_data(end,2) = lpf.num * filt_data(end:-1:end-(length(lpf.num)-1),1) - ...
                lpf.den(2:end) * filt_data(end-1:-1:(end-(length(lpf.den)-1)),2);
         else
             filt_data(end,2) = filt_data(end,1);
         end         
         set(filtplot, 'YData', filt_data(:,end));
         % Apply thresholding
         thres = update_threshold(hObject, eventdata, handles);
         thres_data(1:end-1) = thres_data(2:end);
         thres_data(end) = filt_data(end,end) > thres.value;
         set(thresplot, 'YData', thres_data(:,end));
         % Write the code calculate the heart rate from the processed
         % signal
         % ........
         count=0;
         for i = 1:length(thres_data)-1
             if (thres_data(i) == 0 && thres_data(i+1) == 1)
                 count = count +1;
                 disp(count);
             end
         end
         
         hr_bpm = count*6;
         set(handles.hr_text, 'String', sprintf('Heart Rate: %d bpm', hr_bpm));
         pause(0.01)
     end
    set(handles.com_text, 'String', 'Not connected');
    set(handles.raw_plot, 'UserData', raw_data);
catch
    fprintf('Catch - Exiting\n')
    e = lasterror
    fclose(comport);
end
fclose(comport);

function med_filt = update_med_filter(hObject, eventdata, handles)
%% Initialise the median filter parameters
med_filt.enable = get(handles.med_filt_checkbox, 'Value') == 1;
new_size = str2double(get(handles.med_filt_size, 'String'));
% if (med_filt.size ~= new_size)
%     fprintf('Med filt size: %d\n', med_filt.size);
% end
med_filt.size = new_size;


function lpf = update_lpf(hObject, eventdata, handles)
%% Initialise the low pass filter parameters
lpf.enable = get(handles.lpf_checkbox, 'Value') == 1;
Wp = get(handles.lpf_wp_slider, 'Value')/25; 
set(handles.lpf_text, 'String', sprintf('%2.2f Hz', get(handles.lpf_wp_slider, 'Value')));
% fprintf('Wp slider: %d\n', get(handles.lpf_wp_slider, 'Value'));
Ws = 22/25;
Rp = 0.1; Rs = 40;
[n,wp] = ellipord(Wp,Ws,Rp,Rs);
[b,a] = ellip(n,Rp,Rs,wp);
lpf.n = n;
lpf.wp = wp;
lpf.num = b;
lpf.den = a;

function thres = update_threshold(hObject, eventdata, handles)
thres.value = get(handles.thres_slider, 'Value');
set(handles.thres_text, 'String', sprintf('Level: %d', round(thres.value)));
% fprintf('Thres: %f\n', thres.value);

% --- Outputs from this function are returned to the command line.
function varargout = pulse_sensor_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
% global acq_enable;
% global acq_state; 
% global acq_quit;
% acq_enable = 0;
% acq_state = 'idle';
% acq_quit = 0;
% main(hObject, eventdata, handles);

% Get default command line output from handles structure
varargout{1} = handles.output;

function coms = get_com_list()
% !ls /dev/tty.*
coms = "/dev/tty.usbmodem1421";
% 
% % WINDOWS BELOW
% Skey = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM';
% % Find connected serial devices and clean up the output
% [~, list] = dos(['REG QUERY ' Skey]);
% list = strread(list,'%s','delimiter',' ');
% coms = 0;
% for i = 1:numel(list)
%   if strcmp(list{i}(1:3),'COM')
%       if ~iscell(coms)
%           coms = list(i);
%       else
%           coms{end+1} = list{i};
%       end
%   end
% end
% coms = sort(coms);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% close(handles.gui) % incorrect - gui doesn't exist


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% % hObject    handle to figure1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: delete(hObject) closes the figure
global acq_quit;
acq_quit = 1;
delete(hObject);


% --- Executes on button press in StartStopButton.
function StartStopButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartStopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(handles.StartStopButton, 'UserData') == false) % Idle
    set(handles.StartStopButton, 'UserData', true)
    set(handles.StartStopButton, 'String', 'Stop')
    mainfn(hObject, eventdata, handles);
else % Running
    set(handles.StartStopButton, 'UserData', false)
    set(handles.StartStopButton, 'String', 'Start')
end

    


% --- Executes on button press in med_filt_checkbox.
function med_filt_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to med_filt_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of med_filt_checkbox


% --- Executes on button press in lpf_checkbox.
function lpf_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to lpf_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of lpf_checkbox


% --- Executes on slider movement.
function lpf_wp_slider_Callback(hObject, eventdata, handles)
% hObject    handle to lpf_wp_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function lpf_wp_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lpf_wp_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function med_filt_size_Callback(hObject, eventdata, handles)
% hObject    handle to med_filt_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of med_filt_size as text
%        str2double(get(hObject,'String')) returns contents of med_filt_size as a double


% --- Executes during object creation, after setting all properties.
function med_filt_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to med_filt_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function thres_slider_Callback(hObject, eventdata, handles)
% hObject    handle to thres_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function thres_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thres_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
