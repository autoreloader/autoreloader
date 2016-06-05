{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Stan Korotky <stasson@orc.ru>
Description:  Websocket message implementation
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

unit Message;

interface

uses
  SysUtils, Interfaces, Framing;

type

  TWebSocketMessageHybie = class (IWebSocketMessage)
    public
      constructor Create(data: AnsiString);
      destructor Destroy; override;
      procedure createFrames;
      {
       * Create a message from it's first frame
       * @param IWebSocketFrame $frame
      }
      class function fromFrame(tframe: TWebSocketFrame): IWebSocketMessage;

      // interface
      function getFrames: TWebSocketFrameEnumerator; override;
      procedure setData(data: AnsiString); override;
      function getData: AnsiString; override;
      function isFinalised: boolean; override;
      procedure takeFrame(tframe: TWebSocketFrame); override;
    protected
      _frames: TWebSocketFrameEnumerator;
      _data: AnsiString;
  end;

  TWebSocketMessageHixie = class (IWebSocketMessage)
    public
      constructor Create(data: AnsiString);
      destructor Destroy; override;
      class function fromFrame(tframe: TWebSocketFrame): IWebSocketMessage;

      // interface
      function getFrames: TWebSocketFrameEnumerator; override;
      procedure setData(data: AnsiString); override;
      function getData: AnsiString; override;
      function isFinalised: Boolean; override;
      procedure takeFrame(tframe: TWebSocketFrame); override;
    protected
      _frame: TWebSocketFrame;
      _data: AnsiString;
  end;


implementation

// HYBIE

constructor TWebSocketMessageHybie.Create(data: AnsiString);
begin
  _frames := TWebSocketFrameEnumerator.Create;
  _data := '';
  if data <> '' then
    setData(data);
end;

destructor TWebSocketMessageHybie.Destroy;
var
  i: Integer;
begin
  for i := 0 to _frames.Count - 1 do
    _frames.Frame[i].Free;

  _frames.Free;
end;

procedure TWebSocketMessageHybie.createFrames;
var
  t: TWebSocketFrame;
begin
  t := TWebSocketFrameHybie.Create(TextFrame, _data);
  _frames.Add(t);
end;

{
 * Create a message from it's first frame
 * @param IWebSocketFrame $frame
}
class function TWebSocketMessageHybie.fromFrame(tframe: TWebSocketFrame): IWebSocketMessage;
var
  m: IWebSocketMessage;
begin
  m := TWebSocketMessageHybie.Create('');

  m.takeFrame(TWebSocketFrame(tframe));
  Result := m;
end;

function TWebSocketMessageHybie.getFrames: TWebSocketFrameEnumerator;
begin
  Result := _frames;
end;

procedure TWebSocketMessageHybie.setData(data: AnsiString);
begin
  _data := data;
  createFrames;
end;

function TWebSocketMessageHybie.getData: AnsiString;
var
  i: Integer;
begin
  if not isFinalised then
    raise Exception.Create('WebSocketMessageNotFinalised');

  _data := '';

  for i := 0 to _frames.Count - 1 do
    _data := _data + _frames.Frame[i].getData;

  Result := _data;
end;

function TWebSocketMessageHybie.isFinalised: boolean;
var
  f: TWebSocketFrameHybie;
begin
  if _frames.Count = 0 then
  begin
    result := false;
    exit;
  end;

  f := TWebSocketFrameHybie(_frames.Frame[_frames.Count - 1]);
  Result := f.isFinal;
end;

procedure TWebSocketMessageHybie.takeFrame(tframe: TWebSocketFrame);
begin
  _frames.Add(tframe);
end;

// HIXIE

constructor TWebSocketMessageHixie.Create(data: AnsiString);
begin
  if data <> '' then
    setData(data);
end;

destructor TWebSocketMessageHixie.Destroy;
begin
  if Assigned(_frame) then _frame.Free;
end;

class function TWebSocketMessageHixie.fromFrame(tframe: TWebSocketFrame): IWebSocketMessage;
begin
  Result := TWebSocketMessageHixie.Create('');
  Result.takeFrame(tframe);
end;

function TWebSocketMessageHixie.getFrames: TWebSocketFrameEnumerator;
var
  e: TWebSocketFrameEnumerator;
begin
  e := TWebSocketFrameEnumerator.Create;
  e.Add(_frame);
  Result := e;
end;

procedure TWebSocketMessageHixie.setData(data: AnsiString);
var
  tframe: TWebSocketFrame76;
begin
  _data := data;
  tframe := TWebSocketFrame76.create(TextFrame, data);
  _frame := TWebSocketFrame(tframe);
end;

function TWebSocketMessageHixie.getData: AnsiString;
begin
  Result := _frame.getData;
end;

function TWebSocketMessageHixie.isFinalised: boolean;
begin
  Result := true;
end;

procedure TWebSocketMessageHixie.takeFrame(tframe: TWebSocketFrame);
begin
  _frame := tframe;
end;


end.
