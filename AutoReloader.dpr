program AutoReloader;

uses
  Windows,
  Forms,
  WebSocketSrv1 in 'WebSocketSrv1.pas' {WebSocketForm},
  socket in 'websockets\socket.pas',
  framing in 'websockets\framing.pas',
  functions in 'websockets\functions.pas',
  interfaces in 'websockets\interfaces.pas',
  message in 'websockets\message.pas',
  protocol in 'websockets\protocol.pas';

{$R *.RES}

begin
  Application.CreateForm(TWebSocketForm, WebSocketForm);
  Application.Run;
end.

