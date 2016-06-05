{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Stan Korotky <stasson@orc.ru>
Description:  Auxiliary functions for websockets
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
23 Nov 2012   Bug fix in cookie_parse

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

unit Functions;

interface

uses
  Classes, SysUtils, OverbyteIcsWSocket, OverbyteIcsUrl, OverbyteIcsSha1, OverbyteIcsMimeUtils, OverbyteIcsMd5;

const
  buffsize = 1024;

type

  THixieKey = class
	public
    number: Integer;
	  key: AnsiString;

    constructor Create(number: Integer; key: AnsiString);
	end;

  TWebSocketProtocolVersions =
    (HIXIE_76 = 0, HYBI_8 = 8, HYBI_9 = 8, HYBI_10 = 8, HYBI_11 = 8, HYBI_12 = 8, LATEST = 8);

  TWebSocketFunctions = class
    class function cookie_parse(line: AnsiString): TStringList;
    class function parseHeaders(header: AnsiString): TStringList;
    class function calcHybiResponse(challenge: AnsiString): AnsiString;
    class function calcHixieResponse(key1, key2, l8b: AnsiString): AnsiString;
    class function randHybiKey: AnsiString;
    class procedure say(msg: String = '');
    class function genKey3: AnsiString;
    class function randHixieKey: THixieKey;
  public
  end;

function PackN64(num: Int64): AnsiString;
function PackN32(num: Cardinal): AnsiString;
function PackN16(num: Word): AnsiString;
function UnPackN32(x: AnsiString): Cardinal;
function UnPackN16(x: AnsiString): Word;

procedure HixieTest;

implementation

uses
  WebSocketSrv1; // this depndency is used for debug output only,
                 // it can be inverted or completely eliminated

type
  THixieResponse = packed record
    key1     : Integer;
    key2     : Integer;
    suffix   : array[0..7] of Byte;
  end;

constructor THixieKey.Create(number: Integer; key: AnsiString);
begin
  self.number := number;
  self.key := key;
end;

{
	 * Parse a HTTP HEADER 'Cookie:' value into a key-value pair array
	 *
	 * @param AnsiString $line Value of the COOKIE header
	 * @return array Key-value pair array
}
class function TWebSocketFunctions.cookie_parse(line: AnsiString): TStringList;
var
  cookies: TStringList;
  csplit: TStringList;
  cinfo: TStringList;
  i: Integer;
  key, val: AnsiString;
begin
  cookies := TStringList.Create;
  csplit := TStringList.Create;
  csplit.Delimiter := ';';

  cinfo := TStringList.Create;
  cinfo.Delimiter := '=';

  csplit.DelimitedText := String(line);

  for i := 0 to csplit.Count - 1 do
  begin
    cinfo.DelimitedText := csplit.Strings[i];

    key := AnsiString(Trim(cinfo.Strings[0]));
    val := AnsiString(UrlDecode(cinfo.Strings[1])); // can be empty

    cookies.Add(String(key + '=' + val));

  end;

  cinfo.Free;
  csplit.Free;

  Result := cookies;
end;

{
	 * Parse HTTP request into an array
	 *
	 * @param AnsiString header HTTP request as a AnsiString
	 * @return array Headers as a key-value pair array
}
class function TWebSocketFunctions.parseHeaders(header: AnsiString): TStringList;
var
  HeaderList: TStringList;
  retVal: TStringList;
  i, k, p: Integer;
  name, value: String;
begin
  retVal := TStringList.Create;
  HeaderList := TStringList.Create;
  HeaderList.Delimiter := #10;
  HeaderList.Text := String(header);
  // unfold header lines, removing internal linebreaks
  k := 0;
  for i := 0 to HeaderList.Count - 1 do
  begin
    if Length(HeaderList.Strings[i]) = 0 then continue;
    if (HeaderList.Strings[i][1] = AnsiChar(9)) or (HeaderList.Strings[i][1] = AnsiChar(32)) then
    begin
      HeaderList.Strings[k] := HeaderList.Strings[k] + Trim(HeaderList.Strings[i]);
      HeaderList.Strings[i] := '';
    end
    else
    begin
      HeaderList.Strings[i] := Trim(HeaderList.Strings[i]);
      k := i; // store index of starting line
    end;
  end;

  for i := 0 to HeaderList.Count - 1 do
  begin
    if Length(HeaderList.Strings[i]) > 0 then
    begin
      if Copy(HeaderList.Strings[i], 1, 3) = 'GET' then
      begin
        p := Pos(' HTTP/', HeaderList.Strings[i]);
        name := 'GET';
        value := Copy(HeaderList.Strings[i], 5, p - 5);
      end
      else
      begin
        p := Pos(':', HeaderList.Strings[i]);
        name := Trim(Copy(HeaderList.Strings[i], 1, p - 1));
        value := Trim(Copy(HeaderList.Strings[i], p + 1, MaxInt));
      end;
      retVal.Add(name + '=' + value);
    end;
  end;

  HeaderList.Free;

	Result := retVal;
end;

class function TWebSocketFunctions.calcHybiResponse(challenge: AnsiString): AnsiString;
begin
  Result := Base64Encode(SHA1ofStr(challenge + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'));
end;

procedure HixieTest;
begin
  TWebSocketFunctions.say(String(TWebSocketFunctions.calcHixieResponse('3e6b263  4 17 80', '17  9 G`ZD9   2 2b 7X 3 /r90', 'WjN}|M(6')));
end;

function GetMD5Raw(Buffer: Pointer; BufSize: Integer): AnsiString;
var
    I          : Integer;
    MD5Digest  : TMD5Digest;
    MD5Context : TMD5Context;
begin
    for I := 0 to 15 do
        Byte(MD5Digest[I]) := I + 1;
    MD5Init(MD5Context);
    MD5UpdateBuffer(MD5Context, Buffer, BufSize);
    MD5Final(MD5Digest, MD5Context);
    //Result := MD5Digest;
    SetString(Result, PAnsiChar(@MD5Digest[0]), 16);
end;

function PackN64(num: Int64): AnsiString;
begin
  Result :=
    AnsiChar((num and $ff00000000000000) shr 56)
  + AnsiChar((num and $ff000000000000) shr 48)
  + AnsiChar((num and $ff0000000000) shr 40)
  + AnsiChar((num and $ff00000000) shr 32)
  + AnsiChar((num and $ff000000) shr 24)
  + AnsiChar((num and $ff0000) shr 16)
  + AnsiChar((num and $ff00) shr 8)
  + AnsiChar(num and $ff);
end;

function PackN32(num: Cardinal): AnsiString;
begin
  Result :=
    AnsiChar((num and $ff000000) shr 24)
  + AnsiChar((num and $ff0000) shr 16)
  + AnsiChar((num and $ff00) shr 8)
  + AnsiChar(num and $ff);
end;

function UnPackN32(x: AnsiString): Cardinal;
begin
  Result :=
    (Ord(x[1]) shl 24)
  + (Ord(x[2]) shl 16)
  + (Ord(x[3]) shl 8)
  + Ord(x[4]);
end;

function PackN16(num: Word): AnsiString;
begin
  Result := AnsiChar((num and $ff00) shr 8) + AnsiChar(num and $ff);
end;

function UnPackN16(x: AnsiString): Word;
begin
  Result := (Ord(x[1]) shl 8) + Ord(x[2]);
end;

{
	 * Calculate the #76 draft key based on the 2 challenges from the client and the last 8 bytes of the request
	 *
	 * @param AnsiString key1 Sec-WebSocket-Key1
	 * @param AnsiString key2 Sec-Websocket-Key2
	 * @param AnsiString l8b Last 8 bytes of the client's opening handshake
}
class function TWebSocketFunctions.calcHixieResponse(key1, key2, l8b: AnsiString): AnsiString;
var
  numbers1, numbers2: AnsiString;
  num1, num2: Int64;
  spaces1, spaces2: Integer;
  i: Integer;
  complex: THixieResponse;
begin
  spaces1 := 0;
  spaces2 := 0;

  for i := 1 to Length(key1) do
  begin
    if (key1[i] >= '0') and (key1[i] <= '9') then numbers1 := numbers1 + key1[i];
    if key1[i] = ' ' then Inc(spaces1);
  end;

  for i := 1 to Length(key2) do
  begin
    if (key2[i] >= '0') and (key2[i] <= '9') then numbers2 := numbers2 + key2[i];
    if key2[i] = ' ' then Inc(spaces2);
  end;

  if (spaces1 = 0) or (spaces2 = 0) then
    raise Exception.Create('WebSocketInvalidKeyException:Space');

  num1 := StrToInt64(String(numbers1));
  num2 := StrToInt64(String(numbers2));

  if (num1 mod spaces1 <> 0) or (num2 mod spaces2 <> 0) then
    raise Exception.Create('WebSocketInvalidKeyException:Mod');

  num1 := num1 div spaces1;
  num2 := num2 div spaces2;

  complex.key1 := swap(num1 shr 16) or (longint(swap(num1 and $ffff)) shl 16);
  complex.key2 := swap(num2 shr 16) or (longint(swap(num2 and $ffff)) shl 16);
  Move(l8b[1], complex.suffix, 8 * SizeOf(AnsiChar));

  result := GetMD5Raw(@complex, 16);

end;

class function TWebSocketFunctions.randHybiKey: AnsiString;
begin
	Result := Base64Encode(
			AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
			+ AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
			+ AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
			+ AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
		);
end;

class procedure TWebSocketFunctions.say(msg: String = '');
begin
  WebSocketForm.Display(msg);
end;

class function TWebSocketFunctions.genKey3: AnsiString;
begin
	Result := AnsiString('') + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256))
	             + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256)) + AnsiChar(random(256));
end;

class function TWebSocketFunctions.randHixieKey: THixieKey;
var
  spaces_n: Integer;
  max_n: Integer;
  number_n: Integer;
  product_n: Int64;
  key_n, key_n1, key_n2: AnsiString;
  range: Integer;
  i: Integer;
  c: AnsiChar;
  len: Integer;
  p: Integer;
begin
  spaces_n := random(12) + 1;

  max_n := MaxInt div spaces_n;
  number_n := random(max_n + 1);
  product_n := number_n * spaces_n;
  key_n := AnsiString(IntToStr(product_n));
  range := random(12) + 1;
  for i := 0 to range - 1 do
  begin
    if (random(2) > 0 ) then
			c := AnsiChar(random($2f + 1) + $21)
		else
			c := AnsiChar(random($7e + 1) + $3a);
    len := Length(key_n);
    p := random(len + 1);
    key_n1 := Copy(key_n, 1, p);
    key_n2 := Copy(key_n, p + 1, MaxInt);
    key_n := key_n1 + c + key_n2;
  end;

  for i := 0 to spaces_n - 1 do
  begin
    len := Length(key_n);
    p := random(len) + 1;
    key_n1 := Copy(key_n, 1, p);
    key_n2 := Copy(key_n, p + 1, MaxInt);
    key_n := key_n1 + ' ' + key_n2;
  end;

  Result := THixieKey.Create(number_n, key_n);

end;

end.
