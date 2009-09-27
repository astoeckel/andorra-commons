unit AcRegUtils;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, Classes,
  AcPersistent;

procedure AcEnumRegClasses(AClass: TAcPersistentClass; AStrs: TStrings);

implementation

procedure RegSrvProc(ASender: Pointer; AEntry: PAcRegisteredClassEntry);
begin
  TStrings(ASender).Add(AEntry^.Name);
end;

procedure AcEnumRegClasses(AClass: TAcPersistentClass; AStrs: TStrings);
begin
  AcRegSrv.EnumClasses(AClass, RegSrvProc, AStrs);
end;


end.
