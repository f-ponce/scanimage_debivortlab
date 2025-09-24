function varargout = fastZ_gui(varargin)
% FASTZ_GUI MATLAB code for fastZ_gui.fig
%      FASTZ_GUI, by itself, creates a new FASTZ_GUI or raises the existing
%      singleton*.
%
%      H = FASTZ_GUI returns the handle to a new FASTZ_GUI or the handle to
%      the existing singleton*.
%
%      FASTZ_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FASTZ_GUI.M with the given input arguments.
%
%      FASTZ_GUI('Property','Value',...) creates a new FASTZ_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before fastZ_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to fastZ_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help fastZ_gui

% Last Modified by GUIDE v2.5 10-Mar-2016 16:13:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fastZ_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @fastZ_gui_OutputFcn, ...
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


% --- Executes just before fastZ_gui is made visible.
function fastZ_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to fastZ_gui (see VARARGIN)

% Choose default command line output for fastZ_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes fastZ_gui wait for user response (see UIRESUME)
% uiwait(handles.FAST_Z_CONTROLS);


% Initialize controller in current state
global Controller

% Check whether controller is already connected
isconnected = ~isempty(Controller) && isprop(Controller,'IsConnected') && Controller.IsConnected;

% 
% if isconnected
%     Controller.WGO(1,0) % Disarm, just in case
%     
%     set(handles.Enable_checkbox,'Value',1);
%     
%     starting_position = round(Controller.qPOS);
%     
%     lineIdx = 1;
%     updatePosition(handles,starting_position,lineIdx);
% end


% --- Outputs from this function are returned to the command line.
function varargout = fastZ_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes during object creation, after setting all properties.
function Position_indicator_plot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Position_indicator_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Load background image
im = imread(fullfile(fileparts(mfilename('fullpath')),'Position_idicator.jpg'));
imagesc(im)
hold on
axis off

% Draw sample area
patch([0 0 165 165], [130 282 282 130],'b','FaceAlpha',0.2,'EdgeColor','none')

% Draw position planes
% Y range: [130, 282] so remap actual position to 150 + 0.25*actual_position
% X range: [37.5, 127.5]

% We'll hardcode these for now with default values
top_limit = 130 + 0.38*170;
bottom_limit = 130 + 0.38*230;
current_position = 130 + 0.38*200;

line([37.5 127.5], [top_limit top_limit], 'Color', 'm', 'LineWidth', 2)
line([37.5 127.5], [bottom_limit bottom_limit], 'Color', 'b', 'LineWidth', 2)
line([37.5 127.5], [current_position current_position], 'Color', 'g', 'LineWidth', 2)

% ---------------------------------------------------------------------



function Step_size_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Step_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Step_size_edit as text
%        str2double(get(hObject,'String')) returns contents of Step_size_edit as a double


% --- Executes during object creation, after setting all properties.
function Step_size_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Step_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Step_up.
function Step_up_Callback(hObject, eventdata, handles)
% hObject    handle to Step_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

lineIdx = 1;

data = guidata(hObject);
current_position = str2double(get(data.Current_position_edit,'String'));
new_position = current_position - str2double(get(data.Step_size_edit,'String'));
updatePosition(data,new_position,lineIdx)


% --- Executes on button press in Step_down.
function Step_down_Callback(hObject, eventdata, handles)
% hObject    handle to Step_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

lineIdx = 1;

data = guidata(hObject);
current_position = str2double(get(data.Current_position_edit,'String'));
new_position = current_position + str2double(get(data.Step_size_edit,'String'));
updatePosition(data,new_position,lineIdx)


function Volume_period_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Volume_period_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Volume_period_edit as text
%        str2double(get(hObject,'String')) returns contents of Volume_period_edit as a double


% --- Executes during object creation, after setting all properties.
function Volume_period_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Volume_period_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Go_home.
function Go_home_Callback(hObject, eventdata, handles)
% hObject    handle to Go_home (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

lineIdx = 1;

data = guidata(hObject);
home_position = str2double(get(data.Set_home_edit,'String'));
updatePosition(data,home_position,lineIdx)


% --- Executes on button press in Set_bottom.
function Set_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to Set_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

lineIdx = 2;

data = guidata(hObject);
position = str2double(get(data.Current_position_edit,'String'));
h = data.Set_bottom_edit;
set(h,'String',position)

% Update Z-stack step settings, if appropriate
updateStepParams(data)

% Update position indicator line
updatePositionLine(data,position,lineIdx)

% --- Executes on button press in Set_home.
function Set_home_Callback(hObject, eventdata, handles)
% hObject    handle to Set_home (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);
position = str2double(get(data.Current_position_edit,'String'));
h = data.Set_home_edit;
set(h,'String',position)


% --- Executes on button press in Set_top.
function Set_top_Callback(hObject, eventdata, handles)
% hObject    handle to Set_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

lineIdx = 3;

data = guidata(hObject);
position = str2double(get(data.Current_position_edit,'String'));
h = data.Set_top_edit;
set(h,'String',position)

% Update Z-stack step settings, if appropriate
updateStepParams(data)

% Update position indicator line
updatePositionLine(data,position,lineIdx)


function Current_position_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Current_position_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Current_position_edit as text
%        str2double(get(hObject,'String')) returns contents of Current_position_edit as a double

lineIdx = 1;

data = guidata(hObject);
position = str2double(get(hObject,'String'));
updatePosition(data,position,lineIdx)


% --- Executes during object creation, after setting all properties.
function Current_position_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Current_position_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function Write_button_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Write_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% --- Executes on button press in Write_button.
function Write_button_Callback(hObject, eventdata, handles)
% hObject    handle to Write_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global Controller
data = guidata(hObject);

% if get(data.Volume_step_button,'Value')
%     % For stepping mode...
%     setupSteppingVolumeScan(hObject,data);
%
% else

% For fast sawtooth mode...
wave_cycles = str2double(get(data.Volumes_per_scan_edit,'String'));
piezo_home = str2double(get(data.Set_home_edit,'String'));
piezo_lower = str2double(get(data.Set_bottom_edit,'String'));
piezo_upper = str2double(get(data.Set_top_edit,'String'));
piezo_period = str2double(get(data.Volume_period_edit,'String'));
wave_amplitude = abs(piezo_lower-piezo_upper);
piezo_offset = min([piezo_lower piezo_upper]);

trigPt = getTrigger(wave_amplitude,piezo_period/1000);

wavetable_idx = 1; % Static, for now...

Controller.WSL(1,1)
Controller.WTR(1,10,0)
Controller.WGC(1,wave_cycles)
Controller.WOS(1,piezo_offset) %Will handle inverted axis

% Configure piezo output triggers
Controller.CTO(1,3,4)
Controller.TWC()
Controller.TWS(1,trigPt,1)

% Check whether the piezo will outrun ScanImage
try
    
    global gh
    frame_rate = str2double(get(gh.configurationControls.etFrameRate,'String'));
    n_frames = str2double(get(gh.mainControls.framesTotal,'String'));
    
    
    % amount of time left in cycle after trigger is sent to SI
    period_remaining = (piezo_period - trigPt)/1e3; % time (sec) left in piezo period after trigger is sent to SI
    stack_period = (1/frame_rate)*n_frames; % time (sec) to acquire all requested frames in one volume
    storage_latency = stack_period*0.15; %time (sec) to write data to SSD (scaling factor is empirical)
    
    if (piezo_period/1e3 - stack_period) < storage_latency
        fprintf('\nIncrease your frame rate or take fewer frames!  ScanImage will not trigger reliably at this rate.\n\n')
    elseif stack_period > period_remaining
        fprintf('\nIncrease your frame rate or take fewer frames!  You will be acquiring Z-flyback.\n\n')
    end
    
end

% Write waveform to Wavetable - only linear ramp function currently
wave_table_data = get(hObject,'UserData');

% The idea here is to avoid unnecessary writing to the E709 nonvolatile memory
if isempty(wave_table_data)
    Controller.WAV_LIN(wavetable_idx,0,piezo_period,0,0,wave_amplitude,0,piezo_period)
else
    if (wave_table_data.wave_amplitude ~= wave_amplitude) || (wave_table_data.piezo_period ~= piezo_period)
        Controller.WAV_LIN(wavetable_idx,0,piezo_period,0,0,wave_amplitude,0,piezo_period)
    end
end

% Update our wave_table_data structure
wave_table_data.wave_amplitude = wave_amplitude;
wave_table_data.piezo_period = piezo_period;

set(hObject,'UserData',wave_table_data)

% Finally, allow arming if everything above completed successfully
set(data.Arm_button,'Enable','on')

% end


% --- Executes during object creation, after setting all properties.
function Enable_checkbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Enable_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% --- Executes on button press in Enable_checkbox.
function Enable_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to Enable_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check whether controller is already connected
global Controller
isconnected = ~isempty(Controller);

% Should we enable or disable controller?
enabled = get(hObject,'Value');

data = guidata(hObject);

if enabled && ~isconnected
    connectToPiezo
    
    Controller.WGO(1,0) % Disarm, just in case

    % Set default scan params
    piezo_upper = 170;
    Controller.WTR(1,10,0)
    Controller.WGC(1,10)
    Controller.WSL(1,1)
    Controller.WOS(1,piezo_upper)
    
    % Configure wave generator to trigger on 100th point (at 10 msec) by default
    Controller.CTO(1,3,4)
    Controller.TWC()
    Controller.TWS(1,100,1)
    
    % >>> axis fix here <<<
    starting_position = round(Controller.qPOS(getappdata(0,'E709_axisName')));
    
    lineIdx = 1;
    updatePosition(data,starting_position,lineIdx);
    
elseif ~enabled && isconnected
    disconnectFromPiezo
end


function Volumes_per_scan_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Volumes_per_scan_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Volumes_per_scan_edit as text
%        str2double(get(hObject,'String')) returns contents of Volumes_per_scan_edit as a double


% --- Executes during object creation, after setting all properties.
function Volumes_per_scan_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Volumes_per_scan_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Set_top_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Set_top_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Set_top_edit as text
%        str2double(get(hObject,'String')) returns contents of Set_top_edit as a double

lineIdx = 3;

% Update position indicator line
data = guidata(hObject);
position = str2double(get(hObject,'String'));

if ~(position >=0 && position <=400)
    if position > 400
        position = 400;
    elseif position < 0
        position = 0;
    else
        error('You must input a real value between 0 and 400.')
    end
    set(hObject,'String',position);
end

% Update Z-stack step settings, if appropriate
updateStepParams(data)

updatePositionLine(data,position,lineIdx)


% --- Executes during object creation, after setting all properties.
function Set_top_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Set_top_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Set_home_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Set_home_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Set_home_edit as text
%        str2double(get(hObject,'String')) returns contents of Set_home_edit as a double


position = str2double(get(hObject,'String'));

if ~(position >=0 && position <=400)
    if position > 400
        position = 400;
    elseif position < 0
        position = 0;
    else
        error('You must input a real value between 0 and 400.')
    end
    set(hObject,'String',position);
end


% --- Executes during object creation, after setting all properties.
function Set_home_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Set_home_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Set_bottom_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Set_bottom_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Set_bottom_edit as text
%        str2double(get(hObject,'String')) returns contents of Set_bottom_edit as a double

lineIdx = 2;

% Update position indicator line
data = guidata(hObject);
position = str2double(get(hObject,'String'));

if ~(position >=0 && position <=400)
    if position > 400
        position = 400;
    elseif position < 0
        position = 0;
    else
        error('You must input a real value between 0 and 400.')
    end
    set(hObject,'String',position);
end

% Update Z-stack step settings, if appropriate
updateStepParams(data)

updatePositionLine(data,position,lineIdx)


% --- Executes during object creation, after setting all properties.
function Set_bottom_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Set_bottom_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Move_top.
function Move_top_Callback(hObject, eventdata, handles)
% hObject    handle to Move_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

lineIdx = 1;

data = guidata(hObject);
position = str2double(get(data.Set_top_edit,'String'));
updatePosition(data,position,lineIdx)


% --- Executes on button press in Move_bottom.
function Move_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to Move_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

lineIdx = 1;

data = guidata(hObject);
position = str2double(get(data.Set_bottom_edit,'String'));
updatePosition(data,position,lineIdx)


% --- Executes on button press in Move_middle.
function Move_middle_Callback(hObject, eventdata, handles)
% hObject    handle to Move_middle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

lineIdx = 1;

data = guidata(hObject);
top_position = str2double(get(data.Set_top_edit,'String'));
bottom_position = str2double(get(data.Set_bottom_edit,'String'));
middle_position = (top_position + bottom_position)/2;
updatePosition(data,middle_position,lineIdx)


% --- Executes during object creation, after setting all properties.
function Arm_button_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Arm_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

%create global piezoTrigger object
global pzt piezoIsScanning piezoDoneScanning piezoRearm

%kill any existing piezoTrigger object
% if isa(pzt,'piezoTrigger')
%     pzt.delete
%     clear global pzt
% end

if ~isempty(pzt)
    pzt.delete
    clear global pzt
end


pzt = piezoTrigger;
pzt.GuiIsActive = get(get(hObject,'Parent'),'Parent'); %handle to GUI

piezoIsScanning = addlistener(pzt,'Triggered',@pzt.lockoutPiezo);
piezoDoneScanning = addlistener(pzt,'DoneScanning',@pzt.disarmPiezo);
piezoRearm = addlistener(pzt,'Disarmed',@pzt.rearmPiezo);


% --- Executes on button press in Arm_button.
function Arm_button_Callback(hObject, eventdata, handles)
% hObject    handle to Arm_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);

% If armed, then run:
if get(hObject,'Value')
    
    % Check to see if cameraPreview is on
    global vid
    if isa(vid,'videoinput')
        cameraPreviewOff    % If running, kill preview to save resources
    end
	
    
    % Make sure a wavetable has been linked
    global Controller
    
    if ~Controller.qWSL(1)
        Controller.WSL(1,1);
    end
    
    % Step up 10um from baseline before scan start (needed for accurate triggering of ScanImage)
    initial = Controller.qWOS(1)+10;
    % >>> axis fix here <<<
    Controller.MOV(getappdata(0,'E709_axisName'), initial)
    
    % Arm piezo for external trigger
    Controller.WGO(1,2)
    
    % Set scan lockout time in piezoTrigger object
    % n_vol = str2double(get(data.Volumes_per_scan_edit,'String'));
    % per_vol = str2double(get(data.Volume_period_edit,'String'));
    
    global pzt
    pzt.WaitTime = double(Controller.qWGC(1))*(Controller.qWAV(1,1)*double(Controller.qWTR(1)))/1e4;
    
%     global state loopRearm
%     % Set up listener to retrigger SI loop mode
%     if isempty(loopRearm)
%         loopRearm = addlistener(state.hSI,'loopEnded',@restartLoop);
%     end
    
    % Disable movement once armed
    set(data.Go_home,'Enable','off')
    set(data.Current_position_edit,'Enable','off')
    set(data.Step_up,'Enable','off')
    set(data.Step_down,'Enable','off')
    set(data.Move_top,'Enable','off')
    set(data.Move_middle,'Enable','off')
    set(data.Move_bottom,'Enable','off')
    set(data.Write_button,'Enable','off')
    
    % Hold in armed state until the piezo scanning is finished
    
else
    disarmPiezo(data) % Disarm after another button press
    
end


% --- Executes during object creation, after setting all properties.
function Volume_number_steps_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Volume_number_steps_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Volume_number_steps_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Volume_number_steps_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Volume_number_steps_edit as text
%        str2double(get(hObject,'String')) returns contents of Volume_number_steps_edit as a double

data = guidata(hObject);

% Update step size
n_steps = round(str2double(get(hObject,'String')));

set(hObject,'String',n_steps); % Update display in case input gets rounded

scan_range =  abs(str2double(get(data.Set_top_edit,'String')) - ...
                  str2double(get(data.Set_bottom_edit,'String')));
              
step_size_um = scan_range/n_steps;

set(data.Volume_step_size_edit,'String',step_size_um);


function Volume_step_size_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Volume_step_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Volume_step_size_edit as text
%        str2double(get(hObject,'String')) returns contents of Volume_step_size_edit as a double

data = guidata(hObject);

% Update step size
step_size_um = str2double(get(hObject,'String'));

scan_range =  abs(str2double(get(data.Set_top_edit,'String')) - ...
                  str2double(get(data.Set_bottom_edit,'String')));
              
% Check input validity
if step_size_um < 0.05
    step_size_um = 0.05;
    set(hObject,'String',step_size_um)
elseif step_size_um > scan_range
    step_size_um = scan_range;
    set(hObject,'String',step_size_um)
end

n_steps = scan_range/step_size_um;

% Handle case where requested step size does not divide even into scan range
if mod(n_steps,1)
    n_steps = round(n_steps);
    step_size_um = scan_range/n_steps;
    set(hObject,'String',step_size_um)
end

set(data.Volume_number_steps_edit,'String',n_steps);


% --- Executes during object creation, after setting all properties.
function Volume_step_size_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Volume_step_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes when selected object is changed in Volume_scan_button_panel.
function Volume_scan_button_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in Volume_scan_button_panel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);

volume_mode = get(eventdata.NewValue,'String');

toggleVolumeMode(volume_mode,data);


% --- Executes on button press in Volume_Start_stepping_button.
function Volume_Start_stepping_button_Callback(hObject, eventdata, handles)
% hObject    handle to Volume_Start_stepping_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);

runSteppingVolumeScan(hObject,data)

%---------------------------------------------------


function updatePosition(data,position,lineIdx)
% This function:
%       1. Moves the piezo to a new position
%       2. Updates current_position_edit value
%       3. Updates position indicator line
%
% Called when current_position changes:
%       1. Current_position_edit is updated
%       2. Go_home is pressed
%       3. Step_up or Step_down are pressed
%       4. Move_top / Move_middle / Move_bottom are pressed

% Check position for acceptable values
if ~(position <= 400 && position >= 0)
    
    display('Position out of range!! Acceptable range is 0um to 400um.')
    
    if position > 400
        position = 400;
    elseif position < 0
        position = 0;
    else
        error('You must input a real value between 0 and 400.')
    end
    
end

if get(data.Enable_checkbox, 'Value')
    % Move piezo
    global Controller
    
    position = single(position);
    
    % >>> axis fix here <<<
    axisName = getappdata(0,'E709_axisName');
    
    % Need to set the precision on this thing
    if position ~= Controller.qPOS(axisName)
        display(sprintf('Moving piezo to: %dum',position))
        Controller.MOV(axisName,position);
    end
end

% Update Current_position_edit value
h = data.Current_position_edit;
set(h,'String',position)

% Update position indicator line
updatePositionLine(data,position,lineIdx)



function updatePositionLine(data,position,lineIdx)
h = data.Position_indicator_plot;
d = get(h,'Children');
position = 130 + 0.38*position;
set(d(lineIdx),'YData',[position position])



function trigPt = getTrigger(amp,period)
% This calculates the optimal point in the waveform generator to trigger
% the start of the linear portion of the ramp

persistent predictOptimalTrigger

if isempty(predictOptimalTrigger)
    load(fullfile(fileparts(mfilename('fullpath')), 'piezoTriggerModel_Current.mat'));
end

trigPt = ceil(predictOptimalTrigger(amp,period)) + 1;



function toggleVolumeMode(volume_mode,data)

if strcmp(volume_mode,'Step')

    % hide sawtooth options
	set(data.Volumes_per_scan_edit,'Visible','off') 
    set(data.Volume_period_edit,'Visible','off')
    set(data.text_Volumes_per_scan,'Visible','off')
    set(data.text_Scan_period_msec,'Visible','off')
	set(data.Write_button,'Visible','off')
    set(data.Arm_button,'Visible','off')
    set(data.text_Arm,'Visible','off')
    
    % show step options
    set(data.Volume_step_size_edit,'Visible','on') 
    set(data.Volume_number_steps_edit,'Visible','on')
    set(data.text_volume_number_steps,'Visible','on')
    set(data.text_volume_step_size,'Visible','on')
    set(data.text_volume_um,'Visible','on')
    set(data.Volume_Start_stepping_button,'Visible','on')
    
else
    
    % hide step options
	set(data.Volume_step_size_edit,'Visible','off') 
    set(data.Volume_number_steps_edit,'Visible','off')
    set(data.text_volume_number_steps,'Visible','off')
    set(data.text_volume_step_size,'Visible','off')
    set(data.text_volume_um,'Visible','off')
    set(data.Volume_Start_stepping_button,'Visible','off')
    
    % show sawtooth options
	set(data.Volumes_per_scan_edit,'Visible','on') 
    set(data.Volume_period_edit,'Visible','on')
    set(data.text_Volumes_per_scan,'Visible','on')
    set(data.text_Scan_period_msec,'Visible','on')
    set(data.Write_button,'Visible','on')
    set(data.Arm_button,'Visible','on')
    set(data.text_Arm,'Visible','on')
end



function updateStepParams(data)

if get(data.Volume_step_button,'Value') && ~isempty(get(data.Volume_number_steps_edit,'String'))
    
    n_steps = str2double(get(data.Volume_number_steps_edit,'String'));
    
    scan_range =  abs(str2double(get(data.Set_top_edit,'String')) - ...
                      str2double(get(data.Set_bottom_edit,'String')));
    
    step_size_um = scan_range/n_steps;
    
    set(data.Volume_step_size_edit,'String',step_size_um);
end



function disarmPiezo(data)
% This is called if user disarms by unchecking the Arm_button box

% Reset Arm_button (if not already done)
set(data.Arm_button,'Value',0)

% Make sure piezo is reset
global Controller
Controller.WGO(1,0)

% Re-enable movement
set(data.Go_home,'Enable','on')
set(data.Current_position_edit,'Enable','on')
set(data.Step_up,'Enable','on')
set(data.Step_down,'Enable','on')
set(data.Move_top,'Enable','on')
set(data.Move_middle,'Enable','on')
set(data.Move_bottom,'Enable','on')
set(data.Write_button,'Enable','on')

% Return to starting position
starting_pos = str2double(get(data.Current_position_edit,'String'));
Controller.MOV(getappdata(0,'E709_axisName'),starting_pos);
