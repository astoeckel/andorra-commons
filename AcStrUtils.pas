unit AcStrUtils;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils;
  
type
  {A simple array of strings used in the explode function.
   @seealso(Explode)}
  TAdStringArray = array of string;
  
{Seperates a string with the given seperator char and puts all string parts in the AResult array.}
procedure Explode(AString:string; AChar:Char; var AResult:TAdStringArray);

//Code taken from "Synapse", synautil.pas
function ParseURL(URL: string; var Prot, User, Pass, Host, Port, Path,
  Para: string): string;
function SeparateLeft(const Value, Delimiter: string): string;
function SeparateRight(const Value, Delimiter: string): string;

implementation

function SeparateLeft(const Value, Delimiter: string): string;
var
  x: Integer;
begin
  x := Pos(Delimiter, Value);
  if x < 1 then
    Result := Value
  else
    Result := Copy(Value, 1, x - 1);
end;

function SeparateRight(const Value, Delimiter: string): string;
var
  x: Integer;
begin
  x := Pos(Delimiter, Value);
  if x > 0 then
    x := x + Length(Delimiter) - 1;
  Result := Copy(Value, x + 1, Length(Value) - x);
end;

function ParseURL(URL: string; var Prot, User, Pass, Host, Port, Path,
  Para: string): string;
var
  x, y: Integer;
  sURL: string;
  s: string;
  s1, s2: string;
begin
  Prot := '';
  User := '';
  Pass := '';
  Port := '80';
  Para := '';

  x := Pos('://', URL);
  if x > 0 then
  begin
    Prot := SeparateLeft(URL, '://');
    sURL := SeparateRight(URL, '://');
  end
  else
    sURL := URL;
  if UpperCase(Prot) = 'HTTPS' then
    Port := '443';
  if UpperCase(Prot) = 'FTP' then
    Port := '21';
  x := Pos('@', sURL);
  y := Pos('/', sURL);
  if (x > 0) and ((x < y) or (y < 1))then
  begin
    s := SeparateLeft(sURL, '@');
    sURL := SeparateRight(sURL, '@');
    x := Pos(':', s);
    if x > 0 then
    begin
      User := SeparateLeft(s, ':');
      Pass := SeparateRight(s, ':');
    end
    else
      User := s;
  end;
  x := Pos('/', sURL);
  if x > 0 then
  begin
    s1 := SeparateLeft(sURL, '/');
    s2 := SeparateRight(sURL, '/');
  end
  else
  begin
    s1 := sURL;
    s2 := '';
  end;
  if Pos('[', s1) = 1 then
  begin
    Host := Separateleft(s1, ']');
    Delete(Host, 1, 1);
    s1 := SeparateRight(s1, ']');
    if Pos(':', s1) = 1 then
      Port := SeparateRight(s1, ':');
  end
  else
  begin
    x := Pos(':', s1);
    if x > 0 then
    begin
      Host := SeparateLeft(s1, ':');
      Port := SeparateRight(s1, ':');
    end
    else
      Host := s1;
  end;
  Result := '/' + s2;
  x := Pos('?', s2);
  if x > 0 then
  begin
    Path := '/' + SeparateLeft(s2, '?');
    Para := SeparateRight(s2, '?');
  end
  else
    Path := '/' + s2;
  if Host = '' then
    Host := 'localhost';
end;

procedure Explode(AString:string; AChar:Char; var AResult:TAdStringArray);
var
  s:string;
  p:integer;
begin
  SetLength(AResult,0);

  while length(AString) > 0 do
  begin
    //Search the next place where "AChar" apears in "AString"
    p := Pos(AChar,AString);

    if p = 0 then
    begin
      //If not found copy the whole string
      s := copy(AString,1,length(AString));
      AString := '';
    end
    else
    begin
      s := copy(AString,1,p-1);
      AString := copy(AString,p+1,length(AString)-p+1);
    end;

    //Add item
    if s <> '' then
    begin
      SetLength(AResult,Length(AResult)+1);
      AResult[high(AResult)] := s;
    end;
  end;
end;

end.

