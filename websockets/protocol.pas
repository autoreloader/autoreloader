{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Stan Korotky <stasson@orc.ru>
Description:  Websocket connection implementation (HIXIE and HYBIE protocols)
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

unit Protocol;

interface

uses
  Classes, Interfaces, Socket, Functions, Framing;

type

  TWebSocketConnectionFactory = class
  public
    class function fromSocketData(socket: TWebSocketSocket; data: AnsiString): IWebSocketConnection;
  end;

  // default base implementation
  TWebSocketConnection = class (IWebSocketConnection)
    public
      constructor Create(socket: TWebSocketSocket; headers: TStringList);
      destructor Destroy; override;
      procedure setHeaders(headers: TStringList);

      // interface
      function sendHandshakeResponse: Boolean; override;

      function readFrame(data: AnsiString): TWebSocketFrame; override;
      function sendFrame(tframe: TWebSocketFrame): Boolean; override;
      function sendMessage(msg: IWebSocketMessage): Boolean; override;
      procedure sendString(msg: AnsiString); override;

      function getHeaders: TStringList; override;
      function getUriRequested: AnsiString; override;
      function getCookies: TStringList; override;

      procedure disconnect; override;

    protected
      _headers: TStringList;
      _socket: TWebSocketSocket;
      _cookies: TStringList;
      _parameters: TStringList;

      procedure getQueryParts;
  end;

  TWebSocketConnectionHybie = class (TWebSocketConnection)
    public
      constructor Create(socket: TWebSocketSocket; headers: TStringList);

      // interface
      function sendHandshakeResponse: Boolean; override;

      function readFrame(data: AnsiString): TWebSocketFrame; override;
      procedure sendString(msg: AnsiString); override;

      procedure disconnect; override;

    protected
      procedure processMessageFrame(tframe: TWebSocketFrameHybie);
      procedure processControlFrame(tframe: TWebSocketFrameHybie);

    private
      _openMessage: IWebSocketMessage;
      _lastFrame: TWebSocketFrameHybie;
  end;

  TWebSocketConnectionHixie = class (TWebSocketConnection)
    public
      constructor Create(socket: TWebSocketSocket; headers: TStringList; clientHandshake: AnsiString);

      // interface
      function sendHandshakeResponse: Boolean; override;

      function readFrame(data: AnsiString): TWebSocketFrame; override;
      procedure sendString(msg: AnsiString); override;

      procedure disconnect; override;

    private
      _clientHandshake: AnsiString;
  end;


implementation

uses
  OverbyteIcsUrl, Message;

class function TWebSocketConnectionFactory.fromSocketData(socket: TWebSocketSocket; data: AnsiString): IWebSocketConnection;
var
  headers: TStringList;
  s: IWebSocketConnection;
begin
  s := nil;
  headers := TWebSocketFunctions.parseHeaders(data);
  if headers.Values['Sec-Websocket-Key1'] <> '' then
  begin
    s := TWebSocketConnectionHixie.Create(socket, headers, data);
    s.sendHandshakeResponse;
  end
  else
  if (Pos(AnsiString('<policy-file-request/>'), data) = 1) then
  begin
    // TODO: $s = new WebSocketConnectionFlash($socket, $data);
  end
  else
  if headers.Values['Sec-Websocket-Key'] <> '' then
  begin
    s := TWebSocketConnectionHybie.Create(socket, headers);
    s.sendHandshakeResponse;
  end;
  Result := s;
end;

constructor TWebSocketConnection.Create(socket: TWebSocketSocket; headers: TStringList);
begin
  _headers := TStringList.Create;
  _headers.Sorted := true;
  _cookies := TStringList.Create;
  _parameters := TStringList.Create;

  setHeaders(headers);
  _socket := socket;
end;

destructor TWebSocketConnection.Destroy;
begin
  _headers.Free;
  _cookies.Free;
  _parameters.Free;
end;

procedure TWebSocketConnection.setHeaders(headers: TStringList);
var
  cookieIndex, i: Integer;
begin
  _headers.Assign(headers);
  cookieIndex := _headers.IndexOfName('Cookie');
  if cookieIndex <> -1 then
  begin
    for i := cookieIndex to _headers.Count - 1 do
    begin
      if _headers.Names[i] <> 'Cookie' then Break;
      _cookies.AddStrings(TWebSocketFunctions.cookie_parse(AnsiString(_headers.ValueFromIndex[i])));
    end;
  end;

  getQueryParts;
end;

function TWebSocketConnection.sendHandshakeResponse: Boolean;
begin
  Result := false;
end;

function TWebSocketConnection.readFrame(data: AnsiString): TWebSocketFrame;
begin
  Result := nil;
end;

procedure TWebSocketConnection.sendString(msg: AnsiString);
begin
end;

procedure TWebSocketConnection.disconnect;
begin
end;

function TWebSocketConnection.getHeaders: TStringList;
begin
  Result := _headers;
end;

procedure TWebSocketConnection.getQueryParts;
var
  url, q, kv: AnsiString;
  p, i: Integer;
  kvpairs: TStringList;
  Proto, User, Pass, Host, Port, Path : String;
begin
  url := getUriRequested;
  p := Pos(AnsiString('?'), url);

  if p > 0 then
  begin
    q := Copy(url, p + 1, MaxInt);

    kvpairs := TStringList.Create;
    kvpairs.Delimiter := '&';
    kvpairs.Text := String(q);

    for i := 0 to kvpairs.Count - 1 do
    begin
      kv := AnsiString(kvpairs.Strings[i]);
      p := Pos(AnsiString('='), kv);
      _parameters.Add(UrlDecode(Copy(kv, 1, p - 1)) + '=' + UrlDecode(Copy(kv, p + 1, MaxInt)));
    end;

    kvpairs.Free;
  end
  else
    q := url;

  ParseURL(String(url), Proto, User, Pass, Host, Port, Path);
  if Proto <> '' then _headers.Add('PROTO=' + Proto);
  if User <> '' then _headers.Add('USER=' + User);
  if Pass <> '' then _headers.Add('PASSWORD=' + Pass);
  if Host <> '' then _headers.Add('HOST=' + Host);
  if Port <> '' then _headers.Add('PORT=' + Port);
  if Path <> '' then _headers.Add('PATH=' + Path);

end;

function TWebSocketConnection.sendFrame(tframe: TWebSocketFrame): Boolean;
begin
  _socket.write(tframe.encode);
  Result := true;
end;

function TWebSocketConnection.sendMessage(msg: IWebSocketMessage): Boolean;
var
  e: TWebSocketFrameEnumerator;
  i: Integer;
begin
  e := msg.getFrames;
  for i := 0 to e.Count - 1 do
  begin
    if not sendFrame(e.Frame[i]) then
    begin
      Result := false;
      Exit;
    end;
  end;

  Result := true;
end;

function TWebSocketConnection.getCookies: TStringList;
begin
  Result := _cookies;
end;

function TWebSocketConnection.getUriRequested: AnsiString;
begin
	Result := AnsiString(_headers.Values['GET']);
end;


constructor TWebSocketConnectionHybie.Create(socket: TWebSocketSocket; headers: TStringList);
begin
  inherited Create(socket, headers);
  _openMessage := nil;
  _lastFrame := nil;
end;

// INTERFACE

function TWebSocketConnectionHybie.sendHandshakeResponse: Boolean;
var
  challenge: AnsiString;
  response: AnsiString;
begin
  // Check for handshake values
  if _headers.Values['Sec-Websocket-Key'] <> '' then
    challenge := AnsiString(_headers.Values['Sec-Websocket-Key']);
  if challenge = '' then
  begin
    Result := false;
    exit;
  end;

  // Build HTTP response
  response := 'HTTP/1.1 101 WebSocket Protocol Handshake' + #13#10 + 'Upgrade: WebSocket' + #13#10 + 'Connection: Upgrade' + #13#10;

  // Build HYBI response
  response := response + 'Sec-WebSocket-Accept: ' + TWebSocketFunctions.calcHybiResponse(challenge) + #13#10#13#10;

  _socket.write(response);

  TWebSocketFunctions.say('HYBI Response SENT!');
  Result := true;
end;

function TWebSocketConnectionHybie.readFrame(data: AnsiString): TWebSocketFrame;
var
  frame: TWebSocketFrameHybie;
begin
  frame := nil;
  while (Length(data) > 0) do
  begin
    frame := TWebSocketFrameHybie(TWebSocketFrameHybie.decode(data, TWebSocketFrame(_lastFrame)));
    if (frame.isReady) then
    begin
      if (isControlFrame(frame.getType)) then
      begin
        processControlFrame(frame);
        // control frames are not used further
        frame.Free;
        frame := nil;
      end
      else
        processMessageFrame(frame);
        // now the message is responsible for new frame

      _lastFrame := nil;
    end
    else
    begin
      _lastFrame := frame;
    end;

    //frames[] = frame;
  end;

  Result := TWebSocketFrame(frame);
end;


{
 * Process a Message Frame
 *
 * Appends or creates a new message and attaches it to the user sending it.
 *
 * When the last frame of a message is received, the message is sent for processing to the
 * abstract WebSocket::onMessage() method.
 *
 * @param WebSocketFrame tframe
}
procedure TWebSocketConnectionHybie.processMessageFrame(tframe: TWebSocketFrameHybie);
begin
  if (_openMessage <> nil) and (not _openMessage.isFinalised) then
  begin
    _openMessage.takeFrame(TWebSocketFrame(tframe));
  end
  else
  begin
    _openMessage := TWebSocketMessageHybie.fromFrame(tframe);
  end;

  if (_openMessage <> nil) and (_openMessage.isFinalised) then
  begin
    _socket.onMessage(_openMessage);
    TWebSocketMessageHybie(_openMessage).Free;
    _openMessage := nil;
  end;
end;

{
 * Handle incoming control frames
 *
 * Sends Pong on Ping and closes the connection after a Close request.
 *
 * @param WebSocketFrame $frame
}
procedure TWebSocketConnectionHybie.processControlFrame(tframe: TWebSocketFrameHybie);
var
  r: TWebSocketFrameHybie;
begin
  case tframe.getType of
    CloseFrame :
      begin
      r := TWebSocketFrameHybie.Create(CloseFrame);
      sendFrame(TWebSocketFrame(r));
      r.Free;
      _socket.disconnect;
      end;
    PingFrame :
      begin
      r := TWebSocketFrameHybie.Create(PongFrame);
      sendFrame(TWebSocketFrame(r));
      r.Free;
      end;
  end;
end;

procedure TWebSocketConnectionHybie.sendString(msg: AnsiString);
var
  m: TWebSocketMessageHybie;
begin
  m := TWebSocketMessageHybie.Create(msg);
  sendMessage(m);
  m.Free;
end;

procedure TWebSocketConnectionHybie.disconnect;
var
  f: TWebSocketFrameHybie;
begin
  f := TWebSocketFrameHybie.Create(CloseFrame);
  sendFrame(TWebSocketFrame(f));
  f.Free;
  _socket.disconnect;
end;

constructor TWebSocketConnectionHixie.Create(socket: TWebSocketSocket; headers: TStringList; clientHandshake: AnsiString);
begin
  inherited Create(socket, headers);
  _clientHandshake := clientHandshake;
end;

function TWebSocketConnectionHixie.sendHandshakeResponse: Boolean;
var
  l8b, key1, key2, origin, host, location, response: AnsiString;
begin
  // Last 8 bytes of the client's handshake are used for key calculation later
  l8b := Copy(_clientHandshake, Length(_clientHandshake) - 7, 8);

  // Check for 2-key based handshake (Hixie protocol draft)
  key1 := AnsiString(_headers.Values['Sec-Websocket-Key1']);
  key2 := AnsiString(_headers.Values['Sec-Websocket-Key2']);

  // Origin checking (TODO)
  origin := AnsiString(_headers.Values['Origin']);
  host := AnsiString(_headers.Values['Host']);
  location := AnsiString(_headers.Values['GET']);

  // Build HTTP response
  response := 'HTTP/1.1 101 WebSocket Protocol Handshake' + #13#10 + 'Upgrade: WebSocket' + #13#10 + 'Connection: Upgrade' + #13#10;

  // Build HIXIE response
  response := response + 'Sec-WebSocket-Origin: ' + origin + #13#10 + 'Sec-WebSocket-Location: ws://' + host + location + #13#10;
  response := response + #13#10 + TWebSocketFunctions.calcHixieResponse(key1, key2, l8b);

  _socket.write(response);
  TWebSocketFunctions.say('HIXIE Response SENT!');

  Result := true;
end;

function TWebSocketConnectionHixie.readFrame(data: AnsiString): TWebSocketFrame;
var
  f: TWebSocketFrame;
  m: IWebSocketMessage;
begin
  f := TWebSocketFrame76.decode(data);
  if Assigned(f) then
  begin
    m := TWebSocketMessageHixie.fromFrame(f);
    _socket.onMessage(m);
    TWebSocketMessageHixie(m).Free;
  end
  else
    _socket.disconnect;

	Result := f;
end;

procedure TWebSocketConnectionHixie.sendString(msg: AnsiString);
var
  m: IWebSocketMessage;
begin
  m := TWebSocketMessageHixie.Create(msg);

  sendMessage(m);
end;

procedure TWebSocketConnectionHixie.disconnect;
begin
  _socket.disconnect;
end;

end.


