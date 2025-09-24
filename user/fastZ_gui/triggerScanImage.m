function triggerScanImage(~)
% Arm ScanImage once; let external hardware TTLs (from the piezo -> NI) drive acquisition.

% Get ScanImage model
if evalin('base','exist(''hSI'',''var'')')
    hSI = evalin('base','hSI');
else
    error('ScanImage model ''hSI'' not found in base workspace.');
end

% Persist arming so we don't re-start while already acquiring
persistent armedOnce
if isempty(armedOnce); armedOnce = false; end

% Only arm if idle; afterwards, hardware TTLs advance acquisition
if ~armedOnce
    if strcmpi(hSI.acqState,'idle')
        % Use startLoop if your SI config is "external trigger per frame/volume"
        hSI.startLoop();
    end
    armedOnce = true;
end
end
