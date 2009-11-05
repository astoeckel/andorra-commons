unit AcTypes;

interface

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

type
  {$IFDEF DELPHI5_DOWN}
  PByte = ^Byte;
  PCardinal = ^Cardinal;
  PWord = ^Word;
  PLongWord = ^LongWord;
  {$ENDIF}

  PAcVector1 = ^TAcVector1;
  TAcVector1 = packed record
    x: single;
  end;

  TAcVector2 = packed record
    case Integer of
      0: (x, y: single);
      1: (vec1: TAcVector1);
  end;
  PAcVector2 = ^TAcVector2;

  TAcVector3 = packed record
    case Integer of
      0: (x, y, z: single);
      1: (vec2: TAcVector2);
  end;
  PAcVector3 = ^TAcVector3;

  TAcVector4 = packed record
    case Integer of
      0: (x, y, z, w: single);
      1: (vec3: TAcVector3);
  end;
  PAcVector4 = ^TAcVector4;

function AcVector1(AX:single): TAcVector1;overload;
{Returns a vector with two components.}
function AcVector2(AX,AY:single):TAcVector2;overload;
{Returns a vector with two components.}
function AcVector2(AVec: TAcVector1; AY:single):TAcVector2;overload;
{Returns a vector with three components.}
function AcVector3(AX,AY,AZ:single):TAcVector3;overload;
{Returns a vector with three components.}
function AcVector3(AVec: TAcVector2; AZ: single): TAcVector3;overload;
{Returns a vector with four components.}
function AcVector4(AX, AY, AZ, AW:single):TAcVector4;overload;
{Returns a vector with four components.}
function AcVector4(AVec: TAcVector3; AW: single): TAcVector4;overload;

function AcVectorLength(AVec: TAcVector1): Single; overload;
function AcVectorLength(AVec: TAcVector2): Single; overload;
function AcVectorLength(AVec: TAcVector3): Single; overload;
function AcVectorLength(AVec: TAcVector4): Single; overload;

function AcVectorNormalize(AVec: TAcVector1): TAcVector1;overload;
function AcVectorNormalize(AVec: TAcVector2): TAcVector2;overload;
function AcVectorNormalize(AVec: TAcVector3): TAcVector3;overload;
function AcVectorNormalize(AVec: TAcVector4): TAcVector4;overload;

function AcVectorDot(AVec1, AVec2: TAcVector1): Single;overload;
function AcVectorDot(AVec1, AVec2: TAcVector2): Single;overload;
function AcVectorDot(AVec1, AVec2: TAcVector3): Single;overload;
function AcVectorDot(AVec1, AVec2: TAcVector4): Single;overload;

function AcVectorAdd(AVec1, AVec2: TAcVector1): TAcVector1;overload;
function AcVectorAdd(AVec1, AVec2: TAcVector2): TAcVector2;overload;
function AcVectorAdd(AVec1, AVec2: TAcVector3): TAcVector3;overload;
function AcVectorAdd(AVec1, AVec2: TAcVector4): TAcVector4;overload;

function AcVectorSub(AVec1, AVec2: TAcVector1): TAcVector1;overload;
function AcVectorSub(AVec1, AVec2: TAcVector2): TAcVector2;overload;
function AcVectorSub(AVec1, AVec2: TAcVector3): TAcVector3;overload;
function AcVectorSub(AVec1, AVec2: TAcVector4): TAcVector4;overload;

function AcVectorMul(AVec: TAcVector1; r: Single): TAcVector1;overload;
function AcVectorMul(AVec: TAcVector2; r: Single): TAcVector2;overload;
function AcVectorMul(AVec: TAcVector3; r: Single): TAcVector3;overload;
function AcVectorMul(AVec: TAcVector4; r: Single): TAcVector4;overload;

function AcVectorCross(AVec1, AVec2: TAcVector3): TAcVector3;overload;

implementation

function AcVectorLength(AVec: TAcVector1): Single; overload;
begin
  result := AVec.x;
end;

function AcVectorLength(AVec: TAcVector2): Single; overload;
begin
  result := Sqrt(Sqr(AVec.x) + Sqr(AVec.y));
end;

function AcVectorLength(AVec: TAcVector3): Single; overload;
begin
  result := Sqrt(Sqr(AVec.x) + Sqr(AVec.y) + Sqr(AVec.z));
end;

function AcVectorLength(AVec: TAcVector4): Single; overload;
begin
  result := Sqrt(Sqr(AVec.x) + Sqr(AVec.y) + Sqr(AVec.z) + Sqr(AVec.w));
end;

function AcVectorNormalize(AVec: TAcVector1): TAcVector1;overload;
begin
  result.x := 1;
end;

function AcVectorNormalize(AVec: TAcVector2): TAcVector2;overload;
var
  l: Single;
begin
  l := 1 / AcVectorLength(AVec);
  with result do
  begin
    x := AVec.x * l;
    y := AVec.y * l;
  end;
end;

function AcVectorNormalize(AVec: TAcVector3): TAcVector3;overload;
var
  l: Single;
begin
  l := 1 / AcVectorLength(AVec);
  with result do
  begin
    x := AVec.x * l;
    y := AVec.y * l;
    z := AVec.z * l;
  end;
end;

function AcVectorNormalize(AVec: TAcVector4): TAcVector4;overload;
var
  l: Single;
begin
  l := 1 / AcVectorLength(AVec);
  with result do
  begin
    x := AVec.x * l;
    y := AVec.y * l;
    z := AVec.z * l;
    w := AVec.w * l;
  end;
end;

function AcVectorDot(AVec1, AVec2: TAcVector1): Single;overload;
begin
  result := AVec1.x * AVec2.x;
end;

function AcVectorDot(AVec1, AVec2: TAcVector2): Single;overload;
begin
  result := AVec1.x * AVec2.x + AVec1.y * AVec2.y;
end;

function AcVectorDot(AVec1, AVec2: TAcVector3): Single;overload;
begin
  result := AVec1.x * AVec2.x + AVec1.y * AVec2.y + AVec1.z * AVec2.z;
end;

function AcVectorDot(AVec1, AVec2: TAcVector4): Single;overload;
begin
  result := AVec1.x * AVec2.x + AVec1.y * AVec2.y + AVec1.z * AVec2.z + AVec1.w * AVec2.w;
end;

function AcVectorCross(AVec1, AVec2: TAcVector3): TAcVector3;overload;
begin
  with result do
  begin
    x := AVec1.y * AVec2.z - AVec1.z * AVec2.y;
    y := AVec1.z * AVec2.x - AVec1.x * AVec2.z;
    z := AVec1.x * AVec2.y - AVec1.y * AVec2.x;
  end;
end;

function AcVectorAdd(AVec1, AVec2: TAcVector1): TAcVector1;overload;
begin
  with result do
    x := AVec1.x + AVec2.x;
end;

function AcVectorAdd(AVec1, AVec2: TAcVector2): TAcVector2;overload;
begin
  with result do
  begin
    x := AVec1.x + AVec2.x;
    y := AVec1.y + AVec2.y;
  end;
end;

function AcVectorAdd(AVec1, AVec2: TAcVector3): TAcVector3;overload;
begin
  with result do
  begin
    x := AVec1.x + AVec2.x;
    y := AVec1.y + AVec2.y;
    z := AVec1.z + AVec2.z;
  end;
end;

function AcVectorAdd(AVec1, AVec2: TAcVector4): TAcVector4;overload;
begin
  with result do
  begin
    x := AVec1.x + AVec2.x;
    y := AVec1.y + AVec2.y;
    z := AVec1.z + AVec2.z;
    w := AVec1.w + AVec2.w;
  end;
end;

function AcVectorSub(AVec1, AVec2: TAcVector1): TAcVector1;overload;
begin
  with result do
    x := AVec1.x - AVec2.x;
end;

function AcVectorSub(AVec1, AVec2: TAcVector2): TAcVector2;overload;
begin
  with result do
  begin
    x := AVec1.x - AVec2.x;
    y := AVec1.y - AVec2.y;
  end;
end;

function AcVectorSub(AVec1, AVec2: TAcVector3): TAcVector3;overload;
begin
  with result do
  begin
    x := AVec1.x - AVec2.x;
    y := AVec1.y - AVec2.y;
    z := AVec1.z - AVec2.z;
  end;
end;

function AcVectorSub(AVec1, AVec2: TAcVector4): TAcVector4;overload;
begin
  with result do
  begin
    x := AVec1.x - AVec2.x;
    y := AVec1.y - AVec2.y;
    z := AVec1.z - AVec2.z;
    w := AVec1.w - AVec2.w;
  end;
end;

function AcVectorMul(AVec: TAcVector1; r: Single): TAcVector1;overload;
begin
  with result do
    result.x := result.x * r;
end;

function AcVectorMul(AVec: TAcVector2; r: Single): TAcVector2;overload;
begin
  with result do
  begin
    result.x := result.x * r;
    result.y := result.y * r;
  end;
end;

function AcVectorMul(AVec: TAcVector3; r: Single): TAcVector3;overload;
begin
  with result do
  begin
    result.x := result.x * r;
    result.y := result.y * r;
    result.z := result.z * r;
  end;
end;

function AcVectorMul(AVec: TAcVector4; r: Single): TAcVector4;overload;
begin
  with result do
  begin
    result.x := result.x * r;
    result.y := result.y * r;
    result.z := result.z * r;
    result.w := result.w * r;
  end;
end;

function AcVector3(AX,AY,AZ:single):TAcVector3;
begin
  with result do
  begin
    x := ax;
    y := ay;
    z := az;
  end;
end;

function AcVector3(AVec: TAcVector2; AZ: single): TAcVector3;
begin
  with result do
  begin
    vec2 := AVec;
    z := AZ;
  end;
end;

function AcVector4(AX, AY, AZ, AW:single):TAcVector4;
begin
  with result do
  begin
    x := AX;
    y := AY;
    z := AZ;
    w := AW;
  end;
end;

function AcVector4(AVec: TAcVector3; AW: single): TAcVector4;
begin
  with result do
  begin
    vec3 := AVec;
    w := AW;
  end;
end;

function AcVector2(AX, AY: single): TAcVector2;
begin
  with result do
  begin
    x := ax;
    y := ay;
  end;
end;

function AcVector2(AVec: TAcVector1; AY: single): TAcVector2;
begin
  with result do
  begin
    vec1 := AVec;
    y := ay;
  end;
end;

function AcVector1(AX:single): TAcVector1;
begin
  result.x := AX;
end;


end.
