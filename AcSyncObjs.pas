unit AcSyncObjs;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, SyncObjs;

type
  TAcCriticalSection = TCriticalSection;
  {$IFDEF FPC}
  TAcMutex = class(TSynchroObject)
    private
      FCritSect: TCriticalSection;
      FIntCritSect: TCriticalSection;
      FEnterCount: Cardinal;
      FHandle: Cardinal;
    public
      constructor Create;
      destructor Destroy;override;

      procedure Acquire;override;
      procedure Release;override;
  end;
  {$ELSE}
  TAcMutex = TMutex;
  {$ENDIF}

  { TAcLock }

  TAcLock = class(TAcMutex)
    public
      procedure Enter;
      procedure Leave;
  end;

implementation

{$IFDEF FPC}

uses
  AcSysUtils;

constructor TAcMutex.Create;
begin
  inherited;
  FCritSect := TCriticalSection.Create;
  FIntCritSect := TCriticalSection.Create;
  
  FEnterCount := 0;
  FHandle := 0;
end;

destructor TAcMutex.Destroy;
begin
  FCritSect.Free;
  FIntCritSect.Free;
  inherited;
end;

procedure TAcMutex.Acquire;
var
  h: Cardinal;
begin
  FIntCritSect.Enter;
  try
    h := AcGetCurrentThreadId;
  finally
    FIntCritSect.Leave;
  end;

  if h <> FHandle then
  begin
    FCritSect.Enter;

    FIntCritSect.Enter;
    try
      FHandle := h;
      FEnterCount := 0;
    finally
      FIntCritSect.Leave;
    end;
  end
  else
    FEnterCount := FEnterCount + 1;

end;

procedure TAcMutex.Release;
begin
  if (FEnterCount = 0) then
  begin
    FCritSect.Leave;
    FIntCritSect.Enter;
    try
      FHandle := 0;
    finally
      FIntCritSect.Leave;
    end;
  end else
    FEnterCount := FEnterCount - 1;
end;
{$ENDIF}


{ TAcLock }

procedure TAcLock.Enter;
begin
  if Self <> nil then
    Acquire;
end;

procedure TAcLock.Leave;
begin
  if Self <> nil then
    Release;
end;

end.
