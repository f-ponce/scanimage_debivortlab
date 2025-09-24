classdef piezoTrigger < handle
    % Class def for piezoTrigger handle
    
    properties
        WaitTime = false
        GuiIsActive = false
    end
    
    events
        Triggered
        DoneScanning
        Disarmed
    end
    
    methods
        ...
            function fire(varargin) %obj
            triggerPiezo
            notify(varargin{1},'Triggered'); % Broadcast notice of event
            end
            
            
            function lockoutPiezo(obj,src,evnt)
                global Controller
                
                if Controller.qWGO(1)
                    t = timer;
                    t.StartDelay = obj.WaitTime + 0.5*logical(obj.WaitTime);
                    t.StartFcn = @(myTimerObj, thisEvent)display('Scanning');
                    t.TimerFcn = @(myTimerObj, thisEvent)display('Scanning complete');
                    t.StopFcn = @(myTimerObj, thisEvent)notify(obj,'DoneScanning');
                    %t.StopFcn = @(myTimerObj, thisEvent)delete(t);
                    start(t)
                else
                    display('Piezo has not been armed - aborting Z-scan')
                end
            end
            
            function disarmPiezo(obj,src,evnt)
                
                % Reset piezo
                global Controller
                Controller.WGO(1,0)
                
                if obj.GuiIsActive
                    
                    data = guidata(obj.GuiIsActive);
                    
                    % Reset Arm_button (if not already done)
                    set(data.Arm_button,'Value',0)
                    
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
                    axisName = getappdata(0,'E709_axisName');   % <-- use stored axis name
                    Controller.MOV(axisName, starting_pos);
                end
                
                notify(obj,'Disarmed'); % Broadcast notice of event
                
            end
            
            
            function rearmPiezo(obj,src,evnt)
                
                global Controller
                
                % Step up 10um from baseline before scan start (needed for accurate triggering of ScanImage)
                initial = Controller.qWOS(1)+10;
                axisName = getappdata(0,'E709_axisName');       % <-- use stored axis name
                Controller.MOV(axisName, initial)
                
                % Rearm piezo
                Controller.WGO(1,2)
                
                data = guidata(obj.GuiIsActive);
                
                if obj.GuiIsActive
                    % Disable movement once armed
                    set(data.Go_home,'Enable','off')
                    set(data.Current_position_edit,'Enable','off')
                    set(data.Step_up,'Enable','off')
                    set(data.Step_down,'Enable','off')
                    set(data.Move_top,'Enable','off')
                    set(data.Move_middle,'Enable','off')
                    set(data.Move_bottom,'Enable','off')
                    set(data.Write_button,'Enable','off')
                    set(data.Arm_button,'Value',1)
                end
                
            end
    end
end
