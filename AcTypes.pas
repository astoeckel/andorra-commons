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

File: AcTypes.pas
Author: Andreas Stöckel
}

{Contains basic type definitions.}
unit AcTypes;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

{$I andorra.inc}
{$I commons_conf.inc}

type
  {$IFDEF DELPHI5_DOWN}
  PByte = ^Byte;
  PCardinal = ^Cardinal;
  PWord = ^Word;
  PLongWord = ^LongWord;
  {$ENDIF}

  //Type definitions for types with the same size
  {$IFDEF FPC}
  //8-Bit signed integer
  AcInt8 = ShortInt;
  //16-Bit signed integer
  AcInt16 = SmallInt;
  //32-Bit signed integer
  AcInt32 = Integer;
  //64-Bit signed integer
  AcInt64 = Int64;
  //8-Bit unsigned integer
  AcUInt8 = Byte;
  //16-Bit unsigned integer
  AcUInt16 = Word;
  //32-Bit unsigned integer
  AcUInt32 = Longword;
  //32-Bit float single precision
  AcFloat = Single;
  //64-Bit float double precision
  AcDouble = Double;
  //Signed integer which has the same size as a pointer
  AcPtrInt = ptrint;
  //8-Bit Boolean value
  AcBool = ByteBool;
  {$ELSE}
  //8-Bit signed integer
  AcInt8 = ShortInt;
  //16-Bit signed integer
  AcInt16 = SmallInt;
  //32-Bit signed integer
  AcInt32 = LongInt;
  //64-Bit signed integer
  AcInt64 = Int64;
  //8-Bit unsigned integer
  AcUInt8 = Byte;
  //16-Bit unsigned integer
  AcUInt16 = Word;
  //32-Bit unsigned integer
  AcUInt32 = Longword;
  //32-Bit float single precision
  AcFloat = Single;
  //64-Bit float double precision
  AcDouble = Double;
  //Signed integer which has the same size as a pointer
  AcPtrInt = Integer;
  //8-Bit Boolean value
  AcBool = ByteBool;
  {$ENDIF}

  AcInt24 = array[0..2] of Byte;
  PAcInt24 = ^AcInt24;

  PAcInt8 = ^AcInt8;
  PAcInt16 = ^AcInt16;
  PAcInt32 = ^AcInt32;
  PAcInt64 = ^AcInt64;
  PAcUInt8 = ^AcUInt8;
  PAcUInt16 = ^AcUInt16;
  PAcUInt32 = ^AcUInt32;
  
  PAcFloat = ^AcFloat;
  PAcDouble = ^AcDouble;
  PAcBool = ^AcBool;

  TAcEndian = (
    acBigEndian,
    acLittleEndian
  );

  PAcVector1 = ^TAcVector1;
  TAcVector1 = packed record
    case Integer of
      0: (x: single);
      1: (elems: array[0..0] of Single);
  end;

  TAcVector2 = packed record
    case Integer of
      0: (x, y: single);
      1: (vec1: TAcVector1);
      2: (elems: array[0..1] of Single);
  end;
  PAcVector2 = ^TAcVector2;

  TAcVector3 = packed record
    case Integer of
      0: (x, y, z: single);
      1: (vec2: TAcVector2);
      2: (elems: array[0..2] of Single);
  end;
  PAcVector3 = ^TAcVector3;

  TAcVector4 = packed record
    case Integer of
      0: (x, y, z, w: single);
      1: (vec3: TAcVector3);
      2: (elems: array[0..3] of Single);
  end;
  PAcVector4 = ^TAcVector4;

  {A standard 4x4 matrix.}
  TAcMatrix = array[0..3] of array[0..3] of single;
  PAcMatrix = ^TAcMatrix;

  TAcPlane = record
    case Integer of
      0: (a, b, c, d: Single);
      1: (elems: array[0..3] of Single);
      2: (normal: TAcVector3);
  end;
  PAcPlane = ^TAcPlane;

  TAcFrustrum = array[0..5] of TAcPlane;
  PAcFrustrum = ^TAcFrustrum;

  TAcAABB = record
    min: TAcVector3;
    max: TAcVector3;
  end;
  PAcAABB = ^TAcAABB;

  TAcTriangle = record
    case Integer of
      0: (e1, e2, e3: TAcVector3);
      1: (elems: array[0..2] of TAcVector3);
  end;
  PAcTriangle = ^TAcTriangle;

  TAcRay = record
    origin: TAcVector3;
    dir0: TAcVector3;
  end;
  PAcRay = ^TAcRay;

  TAcNotifyEvent = procedure(Sender: TObject) of object;

function AcVector1(AX:single): TAcVector1;{$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}overload;
{Returns a vector with two components.}
function AcVector2(AX,AY:single):TAcVector2;{$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}overload;
{Returns a vector with two components.}
function AcVector2(AVec: TAcVector1; AY:single):TAcVector2;{$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}overload;
{Returns a vector with three components.}
function AcVector3(AX,AY,AZ:single):TAcVector3;{$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}overload;
{Returns a vector with three components.}
function AcVector3(AVec: TAcVector2; AZ: single): TAcVector3;{$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}overload;
{Returns a vector with four components.}
function AcVector4(AX, AY, AZ, AW:single):TAcVector4;{$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}overload;
{Returns a vector with four components.}
function AcVector4(AVec: TAcVector3; AW: single): TAcVector4;{$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}overload;

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

function AcTriangle(const AVec1, AVec2, AVec3: TAcVector3): TAcTriangle;overload;
function AcTriangle(const ax1, ay1, az1, ax2, ay2, az2, ax3, ay3,
  az3: Single): TAcTriangle;overload;

function AcRay(const AOrigin, ADirection: TAcVector3): TAcRay;
function AcRayPnts(const AFrom, ATo: TAcVector3): TAcRay;

//! Add compiler switches for freepascal
const
  AcMachineEndian: TAcEndian = acLittleEndian;
  
procedure AcConvertEndian(ASrc, ADest: Pointer; const ASize: Integer;
  const ASrcEndian: TAcEndian; const ADestEndian: TAcEndian = acLittleEndian);

const
  {A matrix which only contains zero values}
  AcMatrix_Clear    : TAcMatrix = ((0,0,0,0),(0,0,0,0),(0,0,0,0),(0,0,0,0));
  {A identity matrix.}
  AcMatrix_Identity : TAcMatrix = ((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));

implementation

procedure AcConvertEndian(ASrc, ADest: Pointer; const ASize: Integer;
  const ASrcEndian: TAcEndian; const ADestEndian: TAcEndian = acLittleEndian);
var
  i: integer;
begin
  if ASrcEndian = ADestEndian then
  begin
    //If source and destination endian are equal, no conversion has to be done,
    //the bytes are just copied from source to destination
    for i := 0 to ASize - 1 do
    begin
      PByte(ADest)^ := PByte(ASrc)^;
      inc(PByte(ASrc));
      inc(PByte(ADest));
    end;
  end else
  begin
    //If source and destination endian are unequal, the bytes are copied from
    //source to destination in reverse order.
    inc(PByte(ADest), ASize - 1);
    for i := 0 to ASize - 1 do
    begin
      PByte(ADest)^ := PByte(ASrc)^;
      inc(PByte(ASrc));
      dec(PByte(ADest));
    end;
  end;  
end;

function AcTriangle(const AVec1, AVec2, AVec3: TAcVector3): TAcTriangle;overload;
begin
  with result do
  begin
    e1 := AVec1;
    e2 := AVec2;
    e3 := AVec3;
  end;
end;

function AcTriangle(const ax1, ay1, az1, ax2, ay2, az2, ax3, ay3,
  az3: Single): TAcTriangle;overload;
begin
  with result do
  begin
    e1 := AcVector3(ax1, ay1, az1);
    e2 := AcVector3(ax2, ay2, az2);
    e3 := AcVector3(ax3, ay3, az3);
  end;
end;

function AcRay(const AOrigin, ADirection: TAcVector3): TAcRay;
begin
  with result do
  begin
    origin := AOrigin;
    dir0 := ADirection;
  end;
end;

function AcRayPnts(const AFrom, ATo: TAcVector3): TAcRay;
begin
  result.origin := AFrom;
  result.dir0 := AcVectorNormalize(AcVectorSub(ATo, AFrom)); 
end;

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
    result.x := AVec.x * r;
end;

function AcVectorMul(AVec: TAcVector2; r: Single): TAcVector2;overload;
begin
  with result do
  begin
    result.x := AVec.x * r;
    result.y := AVec.y * r;
  end;
end;

function AcVectorMul(AVec: TAcVector3; r: Single): TAcVector3;overload;
begin
  with result do
  begin
    result.x := AVec.x * r;
    result.y := AVec.y * r;
    result.z := AVec.z * r;
  end;
end;

function AcVectorMul(AVec: TAcVector4; r: Single): TAcVector4;overload;
begin
  with result do
  begin
    result.x := AVec.x * r;
    result.y := AVec.y * r;
    result.z := AVec.z * r;
    result.w := AVec.w * r;
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
