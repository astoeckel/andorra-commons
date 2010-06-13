unit AcSyncObjs;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

{$INCLUDE andorra.inc}

//Determine whether the mutex object is available
{$DEFINE HAS_MUTEX}
{$IFDEF FPC}
  {$UNDEF HAS_MUTEX}
{$ENDIF}
{$IFDEF DELPHI_5_DOWN}
  {$UNDEF HAS_MUTEX}
{$ENDIF}
{$IFDEF VER140}
  {$UNDEF HAS_MUTEX}
{$ENDIF}
{$IFDEF VER150}
  {$UNDEF HAS_MUTEX}
{$ENDIF}

uses
  SysUtils, SyncObjs;

type
  TAcCriticalSection = TCriticalSection;
  {$IFNDEF HAS_MUTEX}
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
  TAcMutex = class(TMutex);
  {$ENDIF}

  { TAcLock }

  TAcLock = class(TAcMutex)
    public
      procedure Enter;
      procedure Leave;
  end;

implementation

{$IFNDEF HAS_MUTEX}

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
  b: Boolean;
begin
  FIntCritSect.Enter;
  try
    h := AcGetCurrentThreadId;
    b := h <> FHandle;
  finally
    FIntCritSect.Leave;
  end;

  if b then
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
  begin
    FIntCritSect.Enter;
    try
      FEnterCount := FEnterCount + 1;
    finally
      FIntCritSect.Leave;;
    end;
  end;
end;

procedure TAcMutex.Release;
var
  b: Boolean;
begin
  FIntCritSect.Enter;
  try
    b := FEnterCount = 0;
  finally
    FIntCritSect.Leave;
  end;

  if b then
  begin
    FCritSect.Leave;
    FIntCritSect.Enter;
    try
      FHandle := 0;
    finally
      FIntCritSect.Leave;
    end;
  end else
  begin
    FIntCritSect.Enter;
    try
      FEnterCount := FEnterCount - 1;
    finally
      FIntCritSect.Leave;
    end;
  end;
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
