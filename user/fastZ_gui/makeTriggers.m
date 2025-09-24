% function makeTriggers
% 
% global scimTriggerObj piezoTriggerObj
% 
% warning off
% 
% if isempty(scimTriggerObj) || isempty(piezoTriggerObj)
% 
%     scimTriggerObj = daq('ni');
%     piezoTriggerObj = daq('ni');
% 
%     try
%         addDigitalChannel(scimTriggerObj,'Dev2','Port0/Line0','OutputOnly'); %ScanImage trigger
%         addDigitalChannel(piezoTriggerObj,'Dev2','Port0/Line1','OutputOnly'); %Piezo trigger
%     catch
%         error('Cannot add triggers to USB-6001')
%     end
% 
% end
% 
% warning on