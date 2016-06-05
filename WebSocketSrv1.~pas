unit WebSocketSrv1;

{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  OverbyteIcsIniFiles, StdCtrls, ExtCtrls, DirectoryMonitor,
  OverbyteIcsWSocket, OverbyteIcsWSocketS, OverbyteIcsWndControl,
  Socket, interfaces, inifiles, FileCtrl, Dialogs, CoolTrayIcon, Menus;

type

  TWebSocketForm = class(TForm)
    DisplayMemo: TMemo;
    WSocketServer1: TWSocketServer;
    Label2: TLabel;
    Label1: TLabel;
    addBtn: TButton;
    patterns: TMemo;
    dirs: TListBox;
    CoolTrayIcon1: TCoolTrayIcon;
    removeBtn: TButton;
    changeTimer: TTimer;
    PopupMenu1: TPopupMenu;
    Exit1: TMenuItem;
    N1: TMenuItem;
    Exit2: TMenuItem;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure WSocketServer1ClientConnect(Sender: TObject;
      Client: TWSocketClient; Error: Word);
    procedure WSocketServer1ClientDisconnect(Sender: TObject;
      Client: TWSocketClient; Error: Word);
    procedure WSocketServer1BgException(Sender: TObject; E: Exception;
      var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure addBtnClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure dirsClick(Sender: TObject);
    procedure removeBtnClick(Sender: TObject);
    procedure changeTimerTimer(Sender: TObject);
    procedure Exit2Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure CoolTrayIcon1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  private
    theCon: IWebSocketConnection;

    FDirMons: array[0..10] of TDirectoryMonitor;
    FDirMonCount: Integer;

    procedure DirChange(Sender: TObject; Action: TDirectoryAction; FileName: string);
    procedure Add(Dir: string);

    procedure ClientBgException(Sender: TObject; E: Exception; var CanClose: Boolean);
    procedure WebSocketConnected(Sender: TObject; con: IWebSocketConnection);
    procedure WebSocketMessage(Sender: TObject; Msg: string);
  public
    procedure Display(Msg: string);
  end;

var
  WebSocketForm: TWebSocketForm;

implementation

{$R *.DFM}

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

procedure TWebSocketForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := Params.ExStyle and not WS_EX_APPWINDOW;
  Params.WndParent := Application.Handle;
end;

procedure TWebSocketForm.FormCreate(Sender: TObject);
var
  i: integer;
  s: string;
  ini: tinifile;
begin
  FDirMonCount := 0;

  ini := tinifile.create('config.ini');
  try
    s := ini.ReadString('main', 'patterns', 'css,js,php,html');
    patterns.Lines.CommaText := s;

    s := ini.ReadString('main', 'folders', '');
    dirs.Items.CommaText := s;

    if (dirs.Items.Count > 0) then
      for i := 0 to dirs.Items.Count - 1 do
        add(dirs.Items[i]);
  finally
    ini.free;
  end;

  WSocketServer1.OnBgException := WSocketServer1BgException;
  WSocketServer1.OnClientConnect := WSocketServer1ClientConnect;
  WSocketServer1.OnClientDisconnect := WSocketServer1ClientDisconnect;

  DisplayMemo.Clear;
  WSocketServer1.Proto := 'tcp'; { Use TCP protocol  }
  WSocketServer1.Port := '2907';
  WSocketServer1.Addr := '0.0.0.0'; { Use any interface }
  WSocketServer1.ClientClass := TTcpSrvClient; { Use our component }
  WSocketServer1.Banner := '';
  WSocketServer1.Listen; { Start litening    }

  Display(' Waiting for clients at port 2907...');
  Display('');
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

procedure TWebSocketForm.FormShow(Sender: TObject);
begin
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

procedure TWebSocketForm.Display(Msg: string);
begin
  DisplayMemo.Lines.Add(Msg);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ This handler is called when a new socket client is available,             }
{ at this moment it's not yet known if this is a proper websocket client.   }

procedure TWebSocketForm.WSocketServer1ClientConnect(
  Sender: TObject;
  Client: TWSocketClient;
  Error: Word);
begin
  with Client as TTcpSrvClient do begin
    Display('Client connected.' +
      ' Remote: ' + PeerAddr + '/' + PeerPort +
      ' Local: ' + GetXAddr + '/' + GetXPort);
    Display('There is now ' +
      IntToStr(TWSocketServer(Sender).ClientCount) +
      ' clients connected.');
    LineMode := false;
    OnBgException := ClientBgException;
    OnWebSocketMessage := WebSocketMessage;
    OnWebSocketConnected := WebSocketConnected;
    ConnectTime := Now;
  end;

  TWebSocketSocket.Create(TTcpSrvClient(Client));
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ This handler is called after ClientConnect if the new client has passed   }
{ websockets handshake successfully; it's the place to check and to store   }
{ websockets-specific stuff, such as path (selector)                        }

procedure TWebSocketForm.WebSocketConnected(Sender: TObject; con: IWebSocketConnection);
begin
  if Assigned(con) then
  begin
    theCon := con;
    con.sendString('Welcome to "echo" websockets service');
  end
  else
    (Sender as TWebSocketSocket).disconnect;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ When something arrived via a websocket, this handler is called with       }
{ the websocket as Sender, and raw data as Msg                              }

procedure TWebSocketForm.WebSocketMessage(Sender: TObject; Msg: string);
var
  L: Integer;
begin
  L := Length(Msg);
  if L > 80 then
  begin
    Display('Websocket message(' + IntToStr(L) + ' bytes)[suppressed]');
  end
  else
  begin
    Display('Websocket message(' + IntToStr(L) + ' bytes):' + UTF8Decode(Msg));
  end;
  (Sender as TWebSocketSocket).getConnection.sendString(AnsiString(Msg + ' ' + DateTimeToStr(Now)));
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

procedure TWebSocketForm.WSocketServer1ClientDisconnect(
  Sender: TObject;
  Client: TWSocketClient;
  Error: Word);
begin
  with Client as TTcpSrvClient do begin
    Display('Client disconnecting: ' + PeerAddr + '   ' +
      'Duration: ' + FormatDateTime('hh:nn:ss',
      Now - ConnectTime));
    Display('There is now ' +
      IntToStr(TWSocketServer(Sender).ClientCount - 1) +
      ' clients connected.');
  end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ This event handler is called when listening (server) socket experienced   }
{ a background exception. Should normally never occurs.                     }

procedure TWebSocketForm.WSocketServer1BgException(
  Sender: TObject;
  E: Exception;
  var CanClose: Boolean);
begin
  Display('Server exception occured: ' + E.ClassName + ': ' + E.Message);
  CanClose := FALSE; { Hoping that server will still work ! }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ This event handler is called when a client socket experience a background }
{ exception. It is likely to occurs when client aborted connection and data }
{ has not been sent yet.                                                    }

procedure TWebSocketForm.ClientBgException(
  Sender: TObject;
  E: Exception;
  var CanClose: Boolean);
begin
  Display('Client exception occured: ' + E.ClassName + ': ' + E.Message);
  CanClose := TRUE; { Goodbye client ! }
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

procedure TWebSocketForm.Button1Click(Sender: TObject);
begin
  theCon.sendString('hello');
end;

procedure TWebSocketForm.addBtnClick(Sender: TObject);
var
  s: string;
begin
  SelectDirectory('Select a directory', '', s);

  if ((s <> '') and (dirs.Items.count < high(FDirMons))) then
  begin
    dirs.Items.add(s);
    add(s);
  end;
end;

procedure TWebSocketForm.DirChange(Sender: TObject; Action: TDirectoryAction; FileName: string);
const
  ActionDesc: array[TDirectoryAction] of string =
  (
    'This can be a change in the time stamp or attributes.',
    'FILE_ACTION_ADDED. The file %s was added to the directory.',
    'FILE_ACTION_REMOVED. The file %s was removed from the directory.',
    'FILE_ACTION_MODIFIED. The file %s was modified.',
    'FILE_ACTION_RENAMED_OLD_NAME. The file %s was renamed, and this is the old name.',
    'FILE_ACTION_RENAMED_NEW_NAME The file %s was renamed and this is the new name.'
    );
var
  ext: string;
  i: integer;
begin
  Display(Format(ActionDesc[Action], [FileName]));

  ext := StringReplace(trim(ExtractFileExt(filename)), '.', '', [rfReplaceAll]);

  for i := 0 to patterns.Lines.Count - 1 do
    if (LowerCase(ext) = trim(LowerCase(patterns.Lines[i]))) then
      changeTimer.enabled := true;
end;

procedure TWebSocketForm.Add(Dir: string);
var
  FDirMon: TDirectoryMonitor;
begin
  FDirMon := TDirectoryMonitor.Create;
  FDirMon.OnDirectoryChange := DirChange;
  FDirMon.Options := [awChangeFileName, awChangeSize, awChangeLastWrite];
  FDirMon.DirectoryToWatch := Dir;
  FDirMon.Start;

  FDirMons[FDirMonCount] := FDirMon;
  Inc(FDirMonCount);
end;

procedure TWebSocketForm.FormDestroy(Sender: TObject);
var
  i: integer;
  ini: tinifile;
begin
  ini := tinifile.create('config.ini');

  try
    ini.WriteString('main', 'patterns', patterns.Lines.CommaText);
    ini.WriteString('main', 'folders', dirs.Items.CommaText);
  finally
  end;

  if (FDirMonCount > 0) then
    for i := 0 to FDirMonCount - 1 do
    begin
      FDirMons[i].Stop;
      FDirMons[i].Free;
    end;

  WSocketServer1.Close;
end;

procedure TWebSocketForm.dirsClick(Sender: TObject);
begin
  removeBtn.Enabled := dirs.Selected[dirs.ItemIndex];
end;

procedure TWebSocketForm.removeBtnClick(Sender: TObject);
var
  i: integer;
  s: string;
begin
  s := dirs.Items[dirs.itemindex];

  if (FDirMonCount > 0) then
  begin
    for i := 0 to FDirMonCount - 1 do
    begin
      if (FDirMons[i].DirectoryToWatch = s) then
        FDirMons[i].Stop;
    end;
  end;

  dirs.Items.Delete(dirs.itemindex);
end;

procedure TWebSocketForm.changeTimerTimer(Sender: TObject);
begin
  changetimer.Enabled := false;

  if (assigned(theCon)) then
  begin
    theCon.sendString('change');
    Display('Send: change');
  end;

end;

procedure TWebSocketForm.Exit2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TWebSocketForm.Exit1Click(Sender: TObject);
begin
  Show;
end;

procedure TWebSocketForm.CoolTrayIcon1Click(Sender: TObject);
begin
  application.Restore;
  show;
end;

procedure TWebSocketForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  application.Minimize;
  canclose := false;
end;

end.

