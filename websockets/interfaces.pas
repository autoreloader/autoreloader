{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Stan Korotky <stasson@orc.ru>
Description:  Interfaces declaration for websockets messages and connections
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

unit Interfaces;

interface

uses
  Classes, Framing;
  
type

  IWebSocketMessage = class
    {
     * Retreive an array of frames of which this message is composed
     *
     * @return WebSocketFrame[]
    }
    function getFrames: TWebSocketFrameEnumerator; virtual; abstract;

    {
     * Set the body of the message
     * This should recompile the array of frames
     * @param AnsiString data
    }
    procedure setData(data: AnsiString); virtual; abstract;

    {
     * Retreive the body of the message
     * @return AnsiString
    }
    function getData: AnsiString; virtual; abstract;

    {
     * Check if we have received the last frame of the message
     *
     * @return boolean
    }
    function isFinalised: boolean; virtual; abstract;

    procedure takeFrame(pframe: TWebSocketFrame); virtual; abstract;
  end;


  IWebSocketConnection = class
    function sendHandshakeResponse: Boolean; virtual; abstract;

    function readFrame(data: AnsiString): TWebSocketFrame; virtual; abstract;
    function sendFrame(tframe: TWebSocketFrame): Boolean; virtual; abstract;
    function sendMessage(msg: IWebSocketMessage): Boolean; virtual; abstract;
    procedure sendString(msg: AnsiString); virtual; abstract;

    function getHeaders: TStringList; virtual; abstract;
    function getUriRequested: AnsiString; virtual; abstract;
    function getCookies: TStringList; virtual; abstract;

    procedure disconnect; virtual; abstract;
  end;

implementation
  
end.
