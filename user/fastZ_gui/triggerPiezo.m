function triggerPiezo(varargin)

% function triggerPiezo(verbose)
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


global piezoTriggerObj

if isempty(piezoTriggerObj)
    makeTriggers
end

% Trigger should be configured for "Rising Edge"
outputSingleScan(piezoTriggerObj,0)
pause(0.001)
outputSingleScan(piezoTriggerObj,1)

if verbose
    display('Piezo triggered. Scan Image will be triggered by hardware')
end