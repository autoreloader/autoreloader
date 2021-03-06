object WebSocketForm: TWebSocketForm
  Left = 327
  Top = 392
  BorderStyle = bsDialog
  Caption = 'AutoReloader'
  ClientHeight = 409
  ClientWidth = 530
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 272
    Top = 16
    Width = 87
    Height = 13
    Caption = 'Match Extensions:'
  end
  object Label1: TLabel
    Left = 8
    Top = 16
    Width = 53
    Height = 13
    Caption = 'Directories:'
  end
  object DisplayMemo: TMemo
    Left = 0
    Top = 215
    Width = 530
    Height = 194
    Align = alBottom
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'DisplayMemo')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object addBtn: TButton
    Left = 70
    Top = 14
    Width = 89
    Height = 17
    Caption = 'Add..'
    TabOrder = 1
    OnClick = addBtnClick
  end
  object patterns: TMemo
    Left = 272
    Top = 40
    Width = 249
    Height = 169
    TabOrder = 2
  end
  object dirs: TListBox
    Left = 8
    Top = 40
    Width = 249
    Height = 169
    ItemHeight = 13
    TabOrder = 3
    OnClick = dirsClick
  end
  object removeBtn: TButton
    Left = 170
    Top = 14
    Width = 89
    Height = 17
    Caption = 'Remove'
    Enabled = False
    TabOrder = 4
    OnClick = removeBtnClick
  end
  object WSocketServer1: TWSocketServer
    LineEnd = #13#10
    Proto = 'tcp'
    LocalAddr = '127.0.0.1'
    LocalAddr6 = '::'
    LocalPort = '0'
    SocksLevel = '5'
    ComponentOptions = []
    ReqVerLow = 1
    ReqVerHigh = 1
    OnBgException = WSocketServer1BgException
    Banner = 'Welcome to TcpSrv'
    OnClientDisconnect = WSocketServer1ClientDisconnect
    OnClientConnect = WSocketServer1ClientConnect
    MultiListenSockets = <>
    Left = 16
    Top = 256
  end
  object CoolTrayIcon1: TCoolTrayIcon
    CycleInterval = 0
    Icon.Data = {
      0000010001001010000000002000680400001600000028000000100000002000
      000001002000000000004004000000000000000000000000000000000000FFFF
      FF01B19E8DFFFFFFFF01FFFFFF01FFFFFF01A7927F21AA948171AD988481B09B
      8881B39F8B71B7A28F31FFFFFF01FFFFFF01FFFFFF01FFFFFF01FFFFFF01FFFF
      FF01B19E8DFF9D87749FA08B7821A38D7ABFB9A998FFCBBDAEFFCEC1B2FFCFC1
      B2FFCDBEAEFFC3B2A0FFBCA895BFBCA79431FFFFFF01FFFFFF01FFFFFF01FFFF
      FF01B19E8DFFBBAC9DFFA99684FFD3C8BBFFDBD1C5FFDAD1C4FFDAD0C3FFD9CF
      C1FFD9CEC0FFD8CCBEFFD6C9BAFFC2AF9DFFBCA79461FFFFFF01FFFFFF01FFFF
      FF01B19E8DFFC8BCAFFFCEC4B7FFD5CBBFFFD7CDC0FFBDAD9DFFB5A391FFB8A5
      93FFC1B1A0FFD4C7B9FFD8CCBEFFD8CBBCFFC1AF9CFFBAA59131FFFFFF01FFFF
      FF01B19E8DFFC2B5A7FFC8BCAFFFCBC0B3FFA6917EEFA5907C41FFFFFF01FFFF
      FF01AE998631B39F8CBFCABBABFFD8CCBEFFD6C9BAFFBAA692CFFFFFFF01FFFF
      FF01B19E8DFFBCAEA0FFC2B5A7FFC8BCAFFFBDAE9EFFA38D7A9FFFFFFF01FFFF
      FF01FFFFFF01FFFFFF01B09B87BFD4C7B9FFD8CCBEFFC4B3A1FFB49F8B31FFFF
      FF01B19E8DFFB19E8DFFB19E8DFFB19E8DFFB19E8DFFB19E8DFFB19E8DFFFFFF
      FF01FFFFFF01FFFFFF01AE998521BEAD9BFFD9CEC0FFCEC0B1FFB19C88815CAA
      DE6150B0E2BF4AB2E4BF4FA4D88FFFFFFF01FFFFFF01FFFFFF01FFFFFF01FFFF
      FF01FFFFFF01FFFFFF01FFFFFF01B19E8BDFD9CFC1FFD6CABCFFAD9784AF5CAA
      DE8141BFEEFF38CAF8FF48AFE1EFFFFFFF01FFFFFF01FFFFFF01FFFFFF01FFFF
      FF01FFFFFF01FFFFFF01FFFFFF01B19E8DFFB19E8DFFB19E8DFFB19E8DFF5DAA
      DE7143BCECFF38CAF7FF45B6E6FF4DA4D741FFFFFF01FFFFFF01FFFFFF013D9D
      D09F3DA1D3FF3EABDDFF40ACDEFF44ADDFFF47AEE0FF4FA8DBFFFFFFFF015DAA
      DE214EB4E5FF38C8F5FF3AC9F7FF4CA7DACF4CA3D711FFFFFF01FFFFFF01FFFF
      FF01429FD29F3DC0EFFF39D3FFFF39D2FEFF39D0FDFF4DB0E2FFFFFFFF01FFFF
      FF015CAADEBF3EC0EFFF38CAF7FF3CC5F3FF4CA7DADF4CA3D7614BA3D61149A2
      D51149A2D56146A8DAFF3ACEFBFF39D0FDFF39CFFBFF4EB1E3FFFFFFFF01FFFF
      FF015DAADE2155AFE2EF3AC5F3FF38CAF7FF3ACAF7FF42BCEBFF46B1E2FF46B1
      E2FF41BCECFF3ACDFAFF39CFFCFF39CEFBFF38CCF9FF50B1E3FFFFFFFF01FFFF
      FF01FFFFFF015DAADE3155AFE2EF3EC1F0FF38CAF7FF38CBF8FF38CDFAFF38CE
      FAFF39CEFAFF38CDFAFF3FC4F2FF52ACDFFF44BDECFF53B1E3FFFFFFFF01FFFF
      FF01FFFFFF01FFFFFF015DAADE115CAADE9F52B1E3FF47BAEBFF40C1F0FF40C2
      F0FF46BCECFF4FB0E3FF57A8DC9F58A8DC115CAADE9F5BACDFFFFFFFFF01FFFF
      FF01FFFFFF01FFFFFF01FFFFFF01FFFFFF015CAADE115BA9DD415AA9DD815AA9
      DD8159A8DC4159A9DC11FFFFFF01FFFFFF01FFFFFF015DAADE9FFFFFFF010000
      FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000
      FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF}
    IconVisible = True
    IconIndex = 0
    PopupMenu = PopupMenu1
    MinimizeToTray = True
    OnClick = CoolTrayIcon1Click
    Left = 48
    Top = 256
  end
  object changeTimer: TTimer
    Enabled = False
    OnTimer = changeTimerTimer
    Left = 80
    Top = 256
  end
  object PopupMenu1: TPopupMenu
    Left = 112
    Top = 256
    object Exit1: TMenuItem
      Caption = 'Show'
      OnClick = Exit1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Exit2: TMenuItem
      Caption = 'Exit'
      OnClick = Exit2Click
    end
  end
  object MultiInstance1: TMultiInstance
    AppId = 2
    Left = 160
    Top = 256
  end
end
