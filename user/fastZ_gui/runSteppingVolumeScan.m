function runSteppingVolumeScan(hObject,data)

global Controller state

% Get ScanImage model handle 
if evalin('base','exist(''hSI'',''var'')')
    hSI = evalin('base','hSI');
else
    error('ScanImage model ''hSI'' not found in base workspace.');
end

% handles to update GUI display
h = data.Position_indicator_plot;
d = get(h,'Children');

stepping = get(hObject,'Value');

% get the logical axis name that was stored at connect time
axisName = getappdata(0,'E709_axisName');

starting_pos = round(Controller.qPOS(axisName));

if stepping
    
    abortStack = 0;
    
    % make sure that # slices is set
    if isempty(get(data.Volume_number_steps_edit,'String'))
        set(hObject,'Value',~stepping)
        error('Number of steps must be defined!')
    end
    
    % calculate step series params
    top_position    = str2double(get(data.Set_top_edit,'String'));
    bottom_position = str2double(get(data.Set_bottom_edit,'String'));
    n_steps         = str2double(get(data.Volume_number_steps_edit,'String'));
    
    step_series = linspace(top_position,bottom_position,n_steps+1);
    
    % frames per slice from hSI instead of gh.mainControls
    n_frames = hSI.hStackManager.framesPerSlice;
    display(sprintf('Acquiring %d frames per slice...',n_frames))
    
    % frame rate: prefer legacy 'state' if present, else use hSI
    if isfield(state,'acq') && isfield(state.acq,'frameRate') && ~isempty(state.acq.frameRate)
        frameRate = state.acq.frameRate;
    else
        frameRate = hSI.hRoiManager.scanFrameRate;
    end
    
    time_buffer = 0.5; % extra time to allow ScanImage per slice
    slice_time  = n_frames*(1/frameRate) + time_buffer;
    
    % validate against hSI stack size (closest equivalent) -- AUTO-SET VOLUMES
    desiredVolumes = n_steps + 1;
    try
        if hSI.hStackManager.numVolumes ~= desiredVolumes
            hSI.hStackManager.numVolumes = desiredVolumes;   % auto-fix instead of erroring
        end
    catch ME
        set(hObject,'Value',~stepping)
        error('Total repeats in ScanImage must be set to %d (could not set automatically: %s)', ...
              desiredVolumes, ME.message);
    end
    
    % lock out piezo GUI
    toggleGUIaccess(data,'off')
    
    % step to each slice position, wait for OnTarget, trigger SI
    for i = 1:length(step_series)
        
        % poll before each step to see whether scan has been aborted
        if ~get(hObject,'Value')
            abortStack = 1;
            break
        end
        
        position = step_series(i);
        
        Controller.MOV(axisName, position);
        
        set(data.Current_position_edit,'String',position)
        line_position = 130 + 0.38*position;
        set(d(1),'YData',[line_position line_position])
        
        % Wait until piezo is on target
        while ~piezoOnTarget
            pause(0.05)
        end
        
        triggerScanImage(1)
        
        % pause for frame_period + buffer
        pause(slice_time)
    end
    
    if ~abortStack
        display('Stack acquired successfully')
        set(hObject,'Value',~stepping)
    end
    
else
    display('Stack aborted')
end

% return to start position
Controller.MOV(axisName, starting_pos);

% update GUI position info
set(data.Current_position_edit,'String',starting_pos)
line_position = 130 + 0.38*starting_pos;
set(d(1),'YData',[line_position line_position])

% re-enable GUI controls
toggleGUIaccess(data,'on')


function toggleGUIaccess(data,toggleState)

set(data.Go_home,'Enable',toggleState)
set(data.Current_position_edit,'Enable',toggleState)
set(data.Step_up,'Enable',toggleState)
set(data.Step_down,'Enable',toggleState)
set(data.Step_size_edit,'Enable',toggleState)
set(data.Move_top,'Enable',toggleState)
set(data.Move_middle,'Enable',toggleState)
set(data.Move_bottom,'Enable',toggleState)
set(data.Set_top,'Enable',toggleState)
set(data.Set_bottom,'Enable',toggleState)
set(data.Set_home,'Enable',toggleState)
set(data.Set_top_edit,'Enable',toggleState)
set(data.Set_bottom_edit,'Enable',toggleState)
set(data.Set_home_edit,'Enable',toggleState)
set(data.Volume_number_steps_edit,'Enable',toggleState)
set(data.Volume_step_size_edit,'Enable',toggleState)
set(data.Volume_step_button,'Enable',toggleState)
set(data.Volume_sawtooth_button,'Enable',toggleState)

if strcmp(toggleState,'off')
    set(data.Volume_Start_stepping_button,'String','Abort Z-stack')
else
    set(data.Volume_Start_stepping_button,'String','Start Z-stack')
end
