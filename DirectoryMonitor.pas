Unit DirectoryMonitor;

Interface

Uses
  SysUtils,
  Classes,
  Windows,
  Messages;

Const
  MAX_BUFFER = 65536;
  CM_DIRECTORY_EVENT = WM_USER + 4242;

  FILE_LIST_DIRECTORY = 0;

Type
  TFileNotifyInformation = Record
    NextEntryOffset: DWORD;
    Action: DWORD;
    FileNameLength: DWORD;
    FileName: Array[0..MAX_PATH] Of WCHAR;
  End;
  PFileNotifyInformation = ^TFileNotifyInformation;

  TActionToWatch = (
    awChangeFileName,
    awChangeDirName,
    awChangeAttributes,
    awChangeSize,
    awChangeLastWrite,
    awChangeLastAccess,
    awChangeCreation,
    awChangeSecurity
    );

  TActionsToWatch = Set Of TActionToWatch;

  TDirectoryAction = (daUnknown, daFileAdded, daFileRemoved, daFileModified, daFileRenamedOldName, daFileRenamedNewName);

  TDirectoryChangeEvent = Procedure(Sender: TObject; Action: TDirectoryAction; FileName: String) Of Object;



  TDirectoryMonitorWorkerThread = Class(TThread)
  Private
    FWatchSubFolders: Boolean;
    FPathToWatch: String;
    FActionsToWatch: TActionsToWatch;
    FNotifyMask: DWORD;
    FDirHandle: THandle;
    FChangeHandle: THandle;
    FShutdownHandle: THandle;

    FBuffer: Pointer;
    FBufferLength: Cardinal;
    FOnDirectoryChange: TDirectoryChangeEvent;


    FNotifyFileName: String;
    FNotifyAction: TDirectoryAction;

    Procedure DoOnDirectoryChange;
    Function GetNotifyMask: DWORD;
    Function GetNotifyAction(SystemAction: DWORD): TDirectoryAction;
  Public
    Property OnDirectoryChange: TDirectoryChangeEvent Read FOnDirectoryChange Write FOnDirectoryChange;

    Constructor Create(Const PathToWatch: String; ActionsToWatch: TActionsToWatch; WatchSubFolders: Boolean);
    Destructor Destroy; Override;

    Procedure Execute; Override;
    Procedure ShutDown;
  End;

{$M+}
  TDirectoryMonitor = Class
  Private
    FDirectoryToWatch: String;
    FWorkerThread: TDirectoryMonitorWorkerThread;
    FOnDirectoryChange: TDirectoryChangeEvent;
    FOptions: TActionsToWatch;
    FWatchSubFolders: Boolean;
    FRunning: Boolean;

    Procedure SetDirToWatch(Const Value: String);
    Procedure DoOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: String);
  Public
    Property WorkerThread: TDirectoryMonitorWorkerThread Read FWorkerThread;
    Property DirectoryToWatch: String Read FDirectoryToWatch Write SetDirToWatch;
  Published
    Property OnDirectoryChange: TDirectoryChangeEvent Read FOnDirectoryChange Write FOnDirectoryChange;
    Property Options: TActionsToWatch Read FOptions Write FOptions;
    Property WatchSubFolders: Boolean Read FWatchSubFolders Write FWatchSubFolders Default True;

    Procedure Start;
    Procedure Stop;

    Constructor Create;
    Destructor Destroy; Override;
  End;
{$M-}


Implementation

Constructor TDirectoryMonitorWorkerThread.Create(Const PathToWatch: String;
  ActionsToWatch: TActionsToWatch;
  WatchSubFolders: Boolean);
Begin
  Inherited Create(True);
  FreeOnTerminate := false;

  FWatchSubFolders := WatchSubFolders;
  FPathToWatch := PathToWatch;
  FActionsToWatch := ActionsToWatch;
  FNotifyMask := GetNotifyMask;

  FChangeHandle := CreateEvent(Nil, FALSE, FALSE, Nil);
  FDirHandle := CreateFile(PChar(FPathToWatch),
    FILE_LIST_DIRECTORY Or GENERIC_READ,
    FILE_SHARE_READ Or FILE_SHARE_WRITE Or FILE_SHARE_DELETE,
    Nil,
    OPEN_EXISTING,
    FILE_FLAG_BACKUP_SEMANTICS Or FILE_FLAG_OVERLAPPED,
    0);

  FShutdownHandle := CreateEvent(Nil, FALSE, FALSE, Nil);

  GetMem(FBuffer, MAX_BUFFER);
  FBufferLength := MAX_BUFFER;
End;

Destructor TDirectoryMonitorWorkerThread.Destroy;
Begin
  If FDirHandle <> INVALID_HANDLE_VALUE Then
    CloseHandle(FDirHandle);

  If FChangeHandle <> 0 Then
    CloseHandle(FChangeHandle);

  If FShutdownHandle <> 0 Then
    CloseHandle(FShutdownHandle);

  FreeMem(FBuffer, MAX_BUFFER);
  Inherited Destroy;
End;

Procedure TDirectoryMonitorWorkerThread.DoOnDirectoryChange;
Begin
  If Assigned(FOnDirectoryChange) Then
  Try
    Try
      If (FNotifyAction <> daUnknown)
        And (Trim(FNotifyFileName) <> EmptyStr) Then
      Try
        FOnDirectoryChange(Self, FNotifyAction, FNotifyFileName);
      Except
      End;
    Finally
      FNotifyAction := daUnknown;
      FNotifyFileName := EmptyStr;
    End;
  Except
  End;
End;

Function TDirectoryMonitorWorkerThread.GetNotifyAction(SystemAction: DWORD): TDirectoryAction;
Begin
  Case SystemAction Of
    FILE_ACTION_ADDED: Result := daFileAdded;
    FILE_ACTION_REMOVED: Result := daFileRemoved;
    FILE_ACTION_MODIFIED: Result := daFileModified;
    FILE_ACTION_RENAMED_OLD_NAME: Result := daFileRenamedOldName;
    FILE_ACTION_RENAMED_NEW_NAME: Result := daFileRenamedNewName;
  Else
    Result := daUnknown;
  End;
End;

Procedure TDirectoryMonitorWorkerThread.Execute;
Var
  bytesRead: DWORD;
  FNI: PFileNotifyInformation;
  nextOffset: DWORD;
  buffer: Array[0..MAX_BUFFER - 1] Of byte;
  overlap: TOverlapped;
  events: Array[0..1] Of THandle;
  waitResult: DWORD;
Begin
  If FDirHandle <> INVALID_HANDLE_VALUE Then
  Begin
    FillChar(overlap, SizeOf(TOverlapped), 0);
    overlap.hEvent := fChangeHandle;

    events[0] := fChangeHandle;
    events[1] := fShutdownHandle;

    While Not Terminated Do
    Begin
      FillChar(buffer, SizeOf(buffer), 0);
      If ReadDirectoryChangesW(
        FDirHandle,
        @buffer[0],
        MAX_BUFFER,
        True,
        GetNotifyMask,
        @bytesRead,
        @overlap,
        Nil) Then
      Begin
        waitResult := WaitForMultipleObjects(2, @events[0], FALSE, INFINITE);
        If waitResult = WAIT_OBJECT_0 Then
        Begin
          FNI := @buffer[0];
          Repeat
            nextOffset := FNI.NextEntryOffset;
            FNotifyFileName := WideCharLenToString(@FNI.FileName, FNI.FileNameLength);
            SetLength(FNotifyFileName, StrLen(PChar(FNotifyFileName)));
            FNotifyAction := GetNotifyAction(FNI.Action);
            Synchronize(DoOnDirectoryChange);

            PByte(FNI) := PByte(DWORD(FNI) + nextOffset);
          Until (nextOffset = 0) Or Terminated;
        End;
      End;
    End;
  End;
End;

Function TDirectoryMonitorWorkerThread.GetNotifyMask: DWORD;
Begin
  Result := 0;
  If awChangeFileName In FActionsToWatch Then
    Result := Result Or FILE_NOTIFY_CHANGE_FILE_NAME;
  If awChangeDirName In FActionsToWatch Then
    Result := Result Or FILE_NOTIFY_CHANGE_DIR_NAME;
  If awChangeSize In FActionsToWatch Then
    Result := Result Or FILE_NOTIFY_CHANGE_SIZE;
  If awChangeAttributes In FActionsToWatch Then
    Result := Result Or FILE_NOTIFY_CHANGE_ATTRIBUTES;
  If awChangeLastWrite In FActionsToWatch Then
    Result := Result Or FILE_NOTIFY_CHANGE_LAST_WRITE;
  If awChangeSecurity In FActionsToWatch Then
    Result := Result Or FILE_NOTIFY_CHANGE_SECURITY;
  If awChangeLastAccess In FActionsToWatch Then
    Result := Result Or FILE_NOTIFY_CHANGE_LAST_ACCESS;
  If awChangeCreation In FActionsToWatch Then
    Result := Result Or FILE_NOTIFY_CHANGE_CREATION;
End;

Procedure TDirectoryMonitorWorkerThread.ShutDown;
Begin
  Terminate;
  If FShutdownHandle <> 0 Then
    SetEvent(FShutdownHandle);
End;

Constructor TDirectoryMonitor.Create;
Begin
  Inherited Create;
  FDirectoryToWatch := EmptyStr;
  FWatchSubFolders := True;
  FWorkerThread := Nil;
  FRunning := false;
  FOptions := [
    awChangeFileName,
    awChangeDirName,
    awChangeAttributes,
    awChangeSize,
    awChangeLastWrite,
    awChangeLastAccess,
    awChangeCreation,
    awChangeSecurity
    ];
End;

Destructor TDirectoryMonitor.Destroy;
Begin
  Stop;
  Inherited Destroy;
End;

Procedure TDirectoryMonitor.DoOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: String);
Begin
  If Assigned(FOnDirectoryChange) Then
  Try
    FOnDirectoryChange(Self, Action, FileName);
  Except
  End;
End;

Procedure TDirectoryMonitor.SetDirToWatch(Const Value: String);
Var
  wasRunning: Boolean;
Begin
  wasRunning := FRunning And (FWorkerThread <> Nil) And Assigned(FWorkerThread);

  If wasRunning Then
    Stop;

  FDirectoryToWatch := Trim(Value);

  If wasRunning Then
    Start;
End;

Procedure TDirectoryMonitor.Start;
Begin
  If Not FRunning And ((FWorkerThread = Nil) Or Not Assigned(FWorkerThread)) Then
  Begin
    If (FOptions <> [])
      And (FDirectoryToWatch <> EmptyStr)
      And DirectoryExists(FDirectoryToWatch) Then
    Begin
      FWorkerThread := TDirectoryMonitorWorkerThread.Create(FDirectoryToWatch, FOptions, FWatchSubFolders);
      FWorkerThread.OnDirectoryChange := DoOnDirectoryChange;
      FWorkerThread.Resume;
      FRunning := true;
    End;

  End;
End;

Procedure TDirectoryMonitor.Stop;
Begin
  If FRunning And (FWorkerThread <> Nil) And Assigned(FWorkerThread) Then
  Begin
    FWorkerThread.OnDirectoryChange := Nil;
    FWorkerThread.ShutDown;
    Try
      Try
        FWorkerThread.WaitFor
      Finally
        Try
          FreeAndNil(FWorkerThread);
        Except
        End;
        FRunning := false;
        FWorkerThread := Nil;
      End;
    Except
    End;
  End;
End;

End.

