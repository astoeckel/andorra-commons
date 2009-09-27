{*******************************************************}
{                                                       }
{       Andorra Commons General Purpose Library         }
{       Copyright (c) Andreas Stöckel, 2009             }
{       Andorra Commons is an "Andorra Suite" Project   }
{                                                       }
{*******************************************************}

{The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"); you may not use this file except in compliance with the
License. You may obtain a copy of the License at http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Initial Developer of the Original Code is
Andreas Stöckel. All Rights Reserved.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License license (the “GPL License”), in which case the provisions of
GPL License are applicable instead of those above. If you wish to allow use
of your version of this file only under the terms of the GPL License and not
to allow others to use your version of this file under the MPL, indicate your
decision by deleting the provisions above and replace them with the notice and
other provisions required by the GPL License. If you do not delete the
provisions above, a recipient may use your version of this file under either the
MPL or the GPL License.

File: AcSysUtils.pas
Author: Andreas Stöckel
}

{Contains system dependend functions like AcGetTickCount and AcGetCurrentThread.}
unit AcSysUtils;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

{$IFNDEF WIN32}
uses
  SysUtils, LclIntf, libc, cThreads, dynlibs;
{$ELSE}
uses
  Windows;
{$ENDIF}

type
  {Funtion pointer used to dynamically asign the function pointer of AcGetTickCount.
  @seealso(AcGetTickCount)
  }
  TAcGetTickCountProc = function: Double;

{$IFDEF CPU64}
  //Handle definition for 64-Bit CPUs
  TAcHandle = Int64;
{$ELSE}
  //Handle definition for non 64-Bit CPUs
  TAcHandle = Cardinal;
{$ENDIF}

{Returns the ID of the thread which is currently active. Warning: The returned
 ID may differ from the ID returned by TThread.ThreadID}
function AcGetCurrentThreadID: Cardinal;
{Returns a temporary directory in which the application has write rights.}
function AcGetTempDir: string;
{Sleeps ATime milliseconds.}
procedure AcSleep(ATime: Cardinal);

{Loads an shared object (DLL, SO). In difference to "LoadLibrary" AcLoadLibrary
 cares about storing the FPU control word and suppressing error messages produced
 by the PE loader (SetErrorMode(SEM_FAILCRITICALERRORS)).
@returns{If the function fails, zero is returned}
function AcLoadLibrary(AModule: string): TAcHandle;
{Returns the pointer to the given procedure exported by the loaded library or nil.}
function AcGetProcAddress(AHandle: TAcHandle; AProcName: string): Pointer;
{Frees an loaded library.}
function AcFreeLibrary(AHandle: TAcHandle): Boolean;


var
  AcGetTickCount: TAcGetTickCountProc;

implementation

{$IFDEF WIN32}
var
  perfcfreq: int64;

const
  affinmask: LongWord = 1;

function WIN32_HW_TICKCOUNT: Double;
var
  hndl: Cardinal;
  cnt: int64;
  mask: LongWord;
begin
  hndl := GetCurrentThread;
  mask := High(LongWord);
  try
    mask := SetThreadAffinityMask(hndl, affinmask);
    QueryPerformanceFrequency(perfcfreq);
    QueryPerformanceCounter(cnt);
    result := cnt / perfcfreq * 1000;
  finally
    SetThreadAffinityMask(hndl, mask)
  end;
end;

function WIN32_SW_TICKCOUNT: Double;
begin
  result := GetTickCount;
end;

function AcGetCurrentThreadID: Cardinal;
begin
  result := GetCurrentThreadID;
end;

{$ELSE}

function LAZ_SW_TICKCOUNT: Double;
begin
  result := GetTickCount;
end;

function AcGetCurrentThreadID: Cardinal;
begin
  result := GetCurrentThreadID;
end;

{$ENDIF}

{$IFDEF WIN32}
function AcGetTempDir: string;
var
  buf: array[0..511] of AnsiChar;
  l: Cardinal;
begin
  result := '';

  l := GetTempPathA(512, @buf[0]);
  if l > 0 then
  begin
    SetLength(result, l);
    Move(buf[0], result[1], l);
  end;
end;
{$ELSE}
function AcGetTempDir: string;
begin
  result := '/tmp/';
end;
{$ENDIF}

procedure AcSleep(ATime:Cardinal);
begin
  Sleep(ATime);
end;

function AcLoadLibrary(AModule: string): TAcHandle;
var
  fpu_word: Word;
begin
  //Store the fpu control word as some dlls might corrupt it when they are not
  //loaded properly
  fpu_word := get8087cw;

  {$IFDEF WIN32}
  //On Windows prevent the PE-Loader from showing up any exceptions
  SetErrorMode(SEM_FAILCRITICALERRORS);
  {$ENDIF}

  try
    result := LoadLibrary(PChar(AModule));
  finally
    {$IFDEF WIN32}
    //Reset the error mode to default
    SetErrorMode(0);
    {$ENDIF}
    //Reset the FPU word
    set8087cw(fpu_word);
  end;
end;

function AcGetProcAddress(AHandle: TAcHandle; AProcName: string): Pointer;
begin
  result := GetProcAddress(AHandle, PChar(AProcName));
end;

function AcFreeLibrary(AHandle: TAcHandle): Boolean;
begin
  result := FreeLibrary(AHandle);
end;

initialization
  {$IFDEF WIN32}
  if QueryPerformanceFrequency(perfcfreq) then
    AcGetTickCount := WIN32_HW_TICKCOUNT
  else
    AcGetTickCount := WIN32_SW_TICKCOUNT;
  {$ELSE}
    AcGetTickCount := LAZ_SW_TICKCOUNT;
  {$ENDIF}

end.
