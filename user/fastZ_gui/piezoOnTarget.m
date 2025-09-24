function onTarget = piezoOnTarget
% Return true when the E-709 reports "on target" for the configured axis.

global Controller

% Get the logical axis name saved at connect time
axisName = getappdata(0,'E709_axisName');
if isempty(axisName)
    error('E709 axis name not set. Did connectToPiezo run?');
end
axisName = char(axisName);  % ensure char, not string or numeric

% Query On-Target; support both "by axis" and "all axes" return styles
try
    val = Controller.qONT(axisName);   % preferred: pass axis as char
catch
    val = Controller.qONT();           % some drivers return a struct
end

% Normalize to a scalar logical
if isstruct(val)
    if isfield(val, axisName)
        val = val.(axisName);
    else
        error('qONT did not return field for axis "%s".', axisName);
    end
end
if isnumeric(val)
    val = val(1);  % in case an array was returned
end

onTarget = logical(val);
