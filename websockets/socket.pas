{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Stan Korotky <stasson@orc.ru>
Description:  ICS socket operations for websocket messaging (data exchange)
              (ported from phpws project)
Creation:     05 Mar 2012
Version:      0.01
Legal issues: Portions Copyright (C) 2011, 2012 Chris Tanaskoski,
              http://code.google.com/p/phpws/

              This software is provided 'as-is', without any express or
              implied warranty.  In no event will the author be held liable
              for any  damages arising from the use of this software.

              Permission is granted to anyone to use this software for any
              purpose, including commercial applications, and to alter it
              and redistribute it freely, subject to the following
              restrictions:

              1. The origin of this software must not be misrepresented,
                 you must not claim that you wrote the original software.
                 If you use this software in a product, an acknowledgment
                 in the product documentation would be appreciated but is
                 not required.

              2. Altered source versions must be plainly marked as such, and
                 must not be misrepresented as being the original software.

              3. This notice may not be removed or altered from any source
                 distribution.
History:
05 Mar 2012   V0.01 Initial release

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

Unit Socket;

interface

uses
  Interfaces, OverbyteIcsWSocket, OverbyteIcsWSocketS;

type

  TWebSocketSocket = class;

  TWebSocketMessage = procedure(Sender: TObject; Msg: String) of object;
  TWebSessionConnected = procedure(Sender: TObject; con: IWebSocketConnection) of object;

  { TTcpSrvClient is the class which will be instanciated by server component }
  { for each new client. N simultaneous clients means N TTcpSrvClient will be }
  { instanciated. Each being used to handle only a single client.             }
  { We can add any data that has to be private for each client, such as       }
  { receive buffer or any other data needed for processing.                   }
  TTcpSrvClient = class(TWSocketClient)
    protected
      FOnWebSocketMessage : TWebSocketMessage;
      FOnWebSocketConnected : TWebSessionConnected;
    public
      RcvdLine    : String;
      ConnectTime : TDateTime;
      property OnWebSocketMessage : TWebSocketMessage read  FOnWebSocketMessage
                                                      write FOnWebSocketMessage;
      property OnWebSocketConnected : TWebSessionConnected read  FOnWebSocketConnected
                                                      write FOnWebSocketConnected;
  end;

  TWebSocketSocket = class
    public
      constructor Create(socket: TTcpSrvClient);
      destructor Destroy; override;
      function getResource: TTcpSrvClient;

      // procedure setConnection(con: IWebSocketConnection);
      // to be used by implementors of clients, server creates connections internally

      function getConnection: IWebSocketConnection;
      procedure establishConnection(data: AnsiString);

      procedure onMessage(m: IWebSocketMessage);

      procedure onData(data: AnsiString); // read from client
      procedure write(data: AnsiString);  // write to client
      procedure disconnect;

      function getLastChanged: TDateTime;

    protected
      procedure handleSessionClosed(Sender: TObject; ErrCode: Word);
      procedure handleDataAvailable(Sender: TObject; ErrCode: Word);

    private
      _socket: TTcpSrvClient;
      _con: IWebSocketConnection;
      _lastChanged: TDateTime;

  end;

implementation

uses
  SysUtils, Protocol, Functions;

constructor TWebSocketSocket.Create(socket: TTcpSrvClient);
begin
  _socket := socket;
  _socket.OnDataAvailable := handleDataAvailable;
  _socket.OnSessionClosed := handleSessionClosed;
end;

destructor TWebSocketSocket.Destroy;
begin
end;

procedure TWebSocketSocket.handleDataAvailable(Sender: TObject; ErrCode: Word);
begin
  with Sender as TTcpSrvClient do begin
    RcvdLine := ReceiveStr;
    //Display('Received from ' + GetPeerAddr + ': ''' + RcvdLine + '''');
    onData(AnsiString(RcvdLine));
  end;
end;

procedure TWebSocketSocket.handleSessionClosed(Sender: TObject; ErrCode: Word);
begin
  self.Free;
end;

function TWebSocketSocket.getResource: TTcpSrvClient;
begin
  Result := _socket;
end;

function TWebSocketSocket.getConnection: IWebSocketConnection;
begin
  Result := _con;
end;

procedure TWebSocketSocket.establishConnection(data: AnsiString);
begin
  _con := TWebSocketConnectionFactory.fromSocketData(self, data);

  if assigned(_con) and assigned(_socket.OnWebSocketConnected) then
    _socket.OnWebSocketConnected(self, _con);
end;

procedure TWebSocketSocket.onMessage(m: IWebSocketMessage);
begin
  if assigned(_con) and assigned(_socket.OnWebSocketMessage) then
    _socket.OnWebSocketMessage(self, String(m.getData));
end;

procedure TWebSocketSocket.onData(data: AnsiString); // read from client
begin
  try
    _lastChanged := Now;

    if assigned(_con) then
      _con.readFrame(data)
    else
      establishConnection(data);
  except
    on E: Exception do
    begin
      TWebSocketFunctions.say(E.Message);
    end;
  end;
end;

procedure TWebSocketSocket.write(data: AnsiString);
begin
  if Assigned(_socket) then
  begin
    _socket.SendStr(data);
  end;
end;

function TWebSocketSocket.getLastChanged: TDateTime;
begin
  Result := _lastChanged;
end;

procedure TWebSocketSocket.disconnect;
begin
  _socket.CloseDelayed;
end;

end.
