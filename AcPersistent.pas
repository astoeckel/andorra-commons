{*******************************************************}
{                                                       }
{       Andorra Commons General Purpose Library         }
{       Copyright (c) Andreas St�ckel, 2009             }
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
Andreas St�ckel. All Rights Reserved.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License license (the �GPL License�), in which case the provisions of
GPL License are applicable instead of those above. If you wish to allow use
of your version of this file only under the terms of the GPL License and not
to allow others to use your version of this file under the MPL, indicate your
decision by deleting the provisions above and replace them with the notice and
other provisions required by the GPL License. If you do not delete the
provisions above, a recipient may use your version of this file under either the
MPL or the GPL License.

File: AcPersistent.pas
Author: Andreas St�ckel
}

{AcPersistent.pas allows you to register classes and to share them between
 units, dynamic linked libraries and applications.}
unit AcPersistent;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  AcContainers;

type

{$M+}
  {A replacement for TPersistentClass.}
  TAcPersistentClass = class of TAcPersistent;

  {A replacement for TPersistent from classes.}
  TAcPersistent = class
    public
      {Returns an identifier for this persistent class.}
      class function IdentStr: ShortString;
      {Returns true if the class is the given class or a child class.}
      class function IsClass(AName: ShortString): boolean;overload;
      {Returns true if the class is the given class or a child class.}
      class function IsClass(AClass: TAcPersistentClass): boolean;overload;
  end;
{$M-}

  {TAcRegisteredClassEntry represents an registered class.}
  TAcRegisteredClassEntry = record
    {The name of the class.}
    Name: ShortString;
    {The identifier of the class.}
    IdentStr: ShortString;
    {Source identifier. If the class is importet from an external library,
     SourceID represents this library.}
    SourceID: integer;
    {Pointer to a function which creates and returns the class described in this
     record.}
    ClassConstructor: Pointer;
  end;
  {Pointer on TAcRegisteredClassEntry.}
  PAcRegisteredClassEntry = ^TAcRegisteredClassEntry;

  {Function used to enumerate registered classes. AEntry contains all information
   about the registered class entry.}
  TAcEnumClassProc = procedure(ASender: Pointer; AEntry: PAcRegisteredClassEntry);

  {TAcRegistrationServer copes with registering }
  TAcRegistrationServer = class
    private
      FClasses: TAcLinkedList;
      FNotifyEvents: TAcLinkedList;
      FUpdating: boolean;
      FSourceCount: integer;
      procedure Notify;
    public
      constructor Create;
      destructor Destroy;override;

      procedure BeginUpdate;
      procedure EndUpdate;

      procedure RegisterClass(AClass: TAcPersistentClass; AClassConstructor: Pointer);overload;
      procedure RegisterClass(const AEntry: TAcRegisteredClassEntry);overload;

      procedure UnregisterClass(AName: ShortString);
      procedure UnregisterSource(ASourceID: integer);

      function GetConstructor(const AName: ShortString): Pointer;
      function GetEntry(const AName: ShortString): PAcRegisteredClassEntry;overload;

      procedure EnumClasses(const AClassName: ShortString;
        ACallback: TAcEnumClassProc; ASender: Pointer = nil);overload;
      procedure EnumClasses(AClass: TAcPersistentClass;
        ACallback: TAcEnumClassProc; ASender: Pointer = nil);overload;

      procedure RegisterNotifyEvent(ACode: Pointer);
      procedure UnregisterNotifyEvent(ACode: Pointer);

      procedure IncSourceCount;

      procedure DbgDump;

      property SourceCount: integer read FSourceCount;
  end;

  {$IFDEF FPC}
  TAcMemoryManager = TMemoryManager;
  {$ELSE}
  TAcMemoryManager = TMemoryManagerEx;
  {$ENDIF}

  TAcRegSrvVerStr = string[20];

  TAcRegSrvNotifyEvent = procedure;

  TAcDLLExportClassesProc = function(ACallback: TAcEnumClassProc;
    ASender: Pointer; AVer: TAcRegSrvVerStr): integer;
  TAcDLLInitProc = procedure;
  TAcDLLFinalizeProc = procedure;
  TAcDLLMemoryManagerProc = procedure(var AManager: TAcMemoryManager);

const
  acceOk = 0;
  acceErr_Ver = 1;

var
  AcRegSrv: TAcRegistrationServer = nil;
{$IFDEF FPC}
  AcProgVer: TAcRegSrvVerStr = 'ACREGSRV LAZ 1.0';
{$ELSE}
  AcProgVer: TAcRegSrvVerStr = 'ACREGSRV DEL 1.0';
{$ENDIF}

function AcDLLExportClasses(ACallback: TAcEnumClassProc; ASender: Pointer; AVer: TAcRegSrvVerStr): integer;
procedure AcDLLRegisterProc(ASender: Pointer; AEntry: PAcRegisteredClassEntry);
procedure AcDLLInit;
procedure AcDLLFinalize;
procedure AcDLLMemMgt(var AManager: TAcMemoryManager);
function AcIsClass(AClass: ShortString; AIdentStr: ShortString): boolean;


implementation

procedure AcDLLRegisterProc(ASender: Pointer; AEntry: PAcRegisteredClassEntry); 
var
  entry: TAcRegisteredClassEntry;
begin
  if AcRegSrv.GetEntry(AEntry^.Name) = nil then
  begin
    entry := AEntry^;
    entry.SourceID := AcRegSrv.SourceCount;
    AcRegSrv.RegisterClass(entry);
  end;
end;

function AcDLLExportClasses(ACallback: TAcEnumClassProc; ASender: Pointer; AVer: TAcRegSrvVerStr): integer; 
begin
  result := acceErr_Ver;
  if AVer = AcProgVer then
  begin
    AcRegSrv.EnumClasses(TAcPersistentClass.ClassName, ACallback, ASender);
    result := acceOk;
  end;
end;

{ TAdPersistent }

class function TAcPersistent.IdentStr: ShortString;
var
  cls: TClass;
begin
  result := ClassName;
  cls := self.ClassParent;
  repeat
    result := cls.ClassName + '.' + result;
    cls := cls.ClassParent;
  until (cls = TObject) or (cls = nil);
end;

//Checks whether AStr1 contains AStr2
function ContainsStr(AStr1, AStr2: string): boolean;
var
  s: string;
  i, l, st: integer;
begin
  result := false;
  if Length(AStr1) < Length(AStr2) then
    exit;

  if AStr1 = AStr2 then
  begin
    result := true;
    exit;
  end;

  l := 0;
  st := 1;

  SetLength(s, Length(AStr2));
  for i := 1 to Length(AStr1) do
  begin
    //Search for the first '.'
    if (AStr1[i] = '.') then
    begin
      if l = Length(AStr2) then
      begin
        Move(AStr1[st], s[1], l);
        if s = AStr2 then
        begin
          result := true;
          exit;
        end;
      end;
      st := i + 1;
      l := -1;
    end;
    l := l + 1;
  end;
end;

function AcIsClass(AClass: ShortString; AIdentStr: ShortString): boolean;
begin
  result := ContainsStr(AIdentStr, AClass);
end;

class function TAcPersistent.IsClass(AName: ShortString): boolean;
begin
  result := ContainsStr(IdentStr, AName);
end;

class function TAcPersistent.IsClass(AClass: TAcPersistentClass): boolean;
begin
  result := IsClass(AClass.ClassName);
end;

{ TAdRegistrationServer }

constructor TAcRegistrationServer.Create;
begin
  inherited;

  FClasses := TAcLinkedList.Create;
  FNotifyEvents := TAcLinkedList.Create;
end;

destructor TAcRegistrationServer.Destroy;
begin
  //Free the memory reserved for the classes list
  FClasses.StartIteration;
  while not FClasses.ReachedEnd do
    Dispose(PAcRegisteredClassEntry(FClasses.GetCurrent));

  FClasses.Free;
  FNotifyEvents.Free;

  inherited;
end;

procedure TAcRegistrationServer.EnumClasses(const AClassName: ShortString;
  ACallback: TAcEnumClassProc; ASender: Pointer);
var
  entry: PAcRegisteredClassEntry;
begin
  FClasses.StartIteration;
  while not FClasses.ReachedEnd do
  begin
    entry := PAcRegisteredClassEntry(FClasses.GetCurrent);
    if ContainsStr(entry^.IdentStr, AClassName) then
      ACallback(ASender, entry);
  end;
end;

procedure TAcRegistrationServer.EnumClasses(AClass: TAcPersistentClass;
  ACallback: TAcEnumClassProc; ASender: Pointer);
begin
  EnumClasses(AClass.ClassName, ACallback, ASender);
end;

function TAcRegistrationServer.GetConstructor(const AName: ShortString): Pointer;
var
  entry: PAcRegisteredClassEntry;
begin
  result := nil;
  entry := GetEntry(AName);
  if entry <> nil then
    result := entry^.ClassConstructor;
end;

function TAcRegistrationServer.GetEntry(
  const AName: ShortString): PAcRegisteredClassEntry;
var
  entry: PAcRegisteredClassEntry;
begin
  result := nil;

  FClasses.StartIteration;
  while not FClasses.ReachedEnd do
  begin
    entry := FClasses.GetCurrent;
    if entry^.Name = AName then
    begin
      result := entry;
      break;
    end;
  end;
end;

procedure TAcRegistrationServer.IncSourceCount;
begin
  FSourceCount := FSourceCount + 1;
end;

procedure TAcRegistrationServer.RegisterClass(const AEntry: TAcRegisteredClassEntry);
var
  entry: PAcRegisteredClassEntry;
begin
  //Create a new entry for the registered classes list
  New(entry);

  //Copy the parameter data to our new entry
  entry^ := AEntry;

  //Add the class to the registered classes list
  FClasses.Add(entry);
end;

procedure TAcRegistrationServer.RegisterClass(AClass: TAcPersistentClass;
  AClassConstructor: Pointer);
var
  entry: PAcRegisteredClassEntry;
begin
  //Create a new entry for the registered classes list
  New(entry);

  //Set the data for the entry
  entry^.Name := AClass.ClassName;
  entry^.IdentStr := AClass.IdentStr;
  entry^.ClassConstructor := AClassConstructor;
  entry^.SourceID := 0;

  //Add the class to the registered classes list
  FClasses.Add(entry);

  //Call all registered notify events
  Notify;
end;

procedure TAcRegistrationServer.UnregisterClass(AName: ShortString);
var
  entry: PAcRegisteredClassEntry;
begin
  entry := GetEntry(AName);
  if entry <> nil then
    FClasses.Remove(entry);

  //Call all registered notify events
  Notify;
end;

procedure TAcRegistrationServer.RegisterNotifyEvent(ACode: Pointer);
begin
  FNotifyEvents.Add(ACode);
end;

procedure TAcRegistrationServer.UnregisterNotifyEvent(ACode: Pointer);
begin
  FNotifyEvents.Remove(ACode);
end;

procedure TAcRegistrationServer.UnregisterSource(ASourceID: integer);
var
  entry: PAcRegisteredClassEntry;
begin
  FClasses.StartIteration;
  while not FClasses.ReachedEnd do
  begin
    entry := FClasses.GetCurrent;
    if entry^.SourceID = ASourceID then
    begin
      FClasses.Remove(entry);
      Dispose(entry);
    end;
  end;

  //Call all registered notify events
  Notify;
end;

procedure TAcRegistrationServer.BeginUpdate;
begin
  FUpdating := true;
end;

procedure TAcRegistrationServer.EndUpdate;
begin
  FUpdating := false;
  Notify;
end;

procedure TAcRegistrationServer.Notify;
begin
  if not FUpdating then
  begin
    FNotifyEvents.StartIteration;
    while not FNotifyEvents.ReachedEnd do
      TAcRegSrvNotifyEvent((FNotifyEvents.GetCurrent));
  end;    
end;

function IntToHex(AVal: Integer): string;
var
  rem: Integer;
begin
  result := '';
  while AVal > 0 do
  begin
    rem := AVal mod 16;
    if rem in [10..15] then    
      result := Chr(Ord('A') + (rem - 10)) + result
    else
      result := Chr(Ord('0') + rem) + result;
    AVal := AVal div 16
  end;
end;

procedure TAcRegistrationServer.DbgDump;
var
  itm: PAcRegisteredClassEntry;
begin
  WriteLn('AcRegSrv DbgDump');
  WriteLn('----------------');
  WriteLn;
  WriteLn('Name':30, ' | ', 'IdentStr':50, ' | ', 'SrcID':5, ' | ', '@Create':10);
  WriteLn('':30, ' | ', '':50, ' | ', '':5, ' | ', '':10);
  FClasses.StartIteration;
  while not FClasses.ReachedEnd do
  begin
    itm := FClasses.GetCurrent;
    WriteLn(itm.Name:30, ' | ', itm.IdentStr:50, ' | ', itm.SourceID:5, ' | ', '$'+IntToHex(Integer(itm.ClassConstructor)):10);
  end;

  WriteLn;

  WriteLn('Classes registered: ', #9, FClasses.Count);
  WriteLn('Current source id: ', #9, SourceCount);

  WriteLn;
end;

var
  dll_instance_count: integer = 0;

procedure AcDLLInit;
begin
  dll_instance_count := dll_instance_count + 1;

  if AcRegSrv = nil then
    AcRegSrv := TAcRegistrationServer.Create;
end;

procedure AcDLLFinalize;
begin
  if dll_instance_count > 0 then
    dll_instance_count := dll_instance_count - 1; 

  if (AcRegSrv <> nil) and (dll_instance_count = 0) then
  begin
    AcRegSrv.Free;
    AcRegSrv := nil;
  end;
end;

procedure AcDLLMemMgt(var AManager: TAcMemoryManager);
var
  tmp: TAcMemoryManager;
begin
  //Store the old memory manager
  GetMemoryManager(tmp);

  //Store the new memory manager and set it
  SetMemoryManager(AManager);

  //Return the old memory manager
  AManager := tmp;
end;

initialization
  AcDLLInit;

finalization
  AcDLLFinalize;


end.