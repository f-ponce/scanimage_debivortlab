function triggerScanImage(varargin)

% function triggerScanImage(verbose)
%
% INPUT
% verbose(optional) - do report trigger
%
% Modified byt F.Ponce(2025), based on Kyle Honegger, July 2015


if nargin < 1
    verbose = 0;
else
    verbose = varargin{1};
end


global scimTriggerObj

if isempty(scimTriggerObj)
    makeTriggers
end

% Trigger should be configured for "Rising Edge"
outputSingleScan(scimTriggerObj,1)
pause(0.001)
outputSingleScan(scimTriggerObj,0)

if verbose
    display('ScanImage triggered')
end