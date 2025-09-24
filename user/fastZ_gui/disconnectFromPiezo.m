function disconnectFromPiezo
% Disconnect from piezo controller and destroy object

global Controller

if ~isempty(Controller)
    display('Disconnecting from E709 controller')
    Controller.CloseConnection;
    Controller.Destroy;
    Controller = [];
end