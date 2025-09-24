% Connect to E-709 over USB (GUI version uses same flow as your working script)

% Instantiate controller class
global Controller

disp('Connecting to E709 controller...')

% Add driver path (adjust if needed)
addpath(genpath('C:\Users\debivort lab\Documents\MATLAB\PI_drivers'));

% If a stale handle exists, try to close it (ignore errors)
try
    if ~isempty(Controller) && isprop(Controller,'IsConnected') && Controller.IsConnected
        Controller.CloseConnection(); % some wrappers use CloseConnection/Disconnect
    end
catch
end
Controller = [];  % clear stale reference

% 0) Controller
Controller = PI_GCS_Controller();

% 1) Enumerate devices (no filter; matches your working code)
devs = Controller.EnumerateUSB('');
if ischar(devs)
    devlist = regexp(devs, '\r?\n', 'split'); devlist = devlist(~cellfun(@isempty, devlist));
elseif isstring(devs)
    devlist = cellstr(devs);
elseif iscell(devs)
    devlist = devs;
else
    error('Unexpected type from EnumerateUSB: %s', class(devs));
end
assert(~isempty(devlist), 'No PI USB controllers found.');

% 2) Pick E-709
idx   = find(contains(devlist,'E-709','IgnoreCase',true), 1, 'first');
assert(~isempty(idx), 'No "E-709" device found. Devices:\n%s', strjoin(devlist, newline));
entry = strtrim(devlist{idx});
tok   = regexp(entry, 'S/?N\s*([A-Za-z0-9\-]+)', 'tokens', 'once');
assert(~isempty(tok), sprintf('Could not parse serial from entry: "%s"', entry));
serial = tok{1};

% 3) Connect using SERIAL ONLY (matches your working script)
Dev = Controller.ConnectUSB(serial);
assert(Dev.IsConnected, 'ConnectUSB succeeded but IsConnected==false');
fprintf('Connected: %s\n', Dev.qIDN());

% 4) Make the GUI use this same connected handle, and store axis name
Controller = Dev;  % <-- GLOBAL, live handle for GUI callbacks

axesStr       = Dev.qSAI();
availableAxes = regexp(axesStr, '[\w-]+', 'match');
assert(~isempty(availableAxes), 'Controller reported no logical axes.');
axisName      = availableAxes{1};               % e.g. '1'
setappdata(0, 'E709_axisName', axisName);

% 5) Initialize & enable servo on that logical axis
Controller = Controller.InitializeController();
Controller.SVO(axisName, 1);

disp('E709 controller connected.')


% % Move axis to position
% position = 20;
% Controller.MOV(axisname, position);
%
% % Start a waveform scan
% Controller.WGC(1,1)
% Controller.WGC(1,5)
% Controller.WGO(1,1)
