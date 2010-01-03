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

File: AcRegUtils.pas
Author: Andreas Stöckel
}

{Contains a function which dumps the instances of a class to a stringlist.}
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
