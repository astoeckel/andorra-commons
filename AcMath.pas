{
* THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
* CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT
* LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT,
* MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
*
* This program is licensed under the Common Public License (CPL) Version 1.0
* You should have recieved a copy of the license with this file.
* If not, see http://www.opensource.org/licenses/cpl1.0.txt for more informations.
* You also should have recieved a copy of this license with this file.
* 
* Inspite of the incompatibility between the Common Public License (CPL) and the GNU General Public License (GPL) you're allowed to use this program 
* under the GPL. 
* If not, see http://www.gnu.org/licenses/gpl.txt for more informations.
*
* Project: Andorra Commons
* Author:  Andreas Stoeckel
* File: AcBuffer.pas
* Comment: Contains various classes that are usefull for buffering data. A simple
*   buffered filestream class that speeds up byte access on file streams is also
*   included.
}

{Parts of this unit were taken from the "VectorGeometry.pas" originaly by Dipl.
 Ing. Mike Lischke (public@lischke-online.de) from the GLScene project 
 (http://glscene.sf.net/). This code is published under the MPL.
 See http://glscene.cvs.sourceforge.net/viewvc/*checkout*/glscene/Source/Base/VectorGeometry.pas
 to get the original source code.
 If you define the "DO_NOT_USE_3DNOW" compiler switch in the andorra_conf.inc or
 your project settings, all code that was taken from this unit will be
 deactivated.}      

{Contains optimized mathematical functions for matrix and vector calculations.}
unit AcMath;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  AcTypes;

{$I andorra.inc}
{$I commons_conf.inc}

var
  {Multiplies two matrixes and returns the new matrix}
  AcMatrix_Multiply: function(const amat1,amat2:TAcMatrix):TAcMatrix;
  {Mutiplies a matrix with a vector and returns the result vector.}
  AcMatrix_Multiply_Vector: function(const amat: TAcMatrix; const avec: TAcVector4): TAcVector4;
  {Transposes and returns the given matrix}
  AcMatrix_Transpose: function(const mat: TAcMatrix): TAcMatrix;
  {Returns a translation matrix.}
  AcMatrix_Translate: function(const tx,ty,tz:single):TAcMatrix;
  {Returns a scale matrix.}
  AcMatrix_Scale: function(const sx,sy,sz:single):TAcMatrix;
  {Returns a matrix for rotation around the X-Axis}
  AcMatrix_RotationX: function(const angle:single):TAcMatrix;
  {Returns a matrix for rotation around the Y-Axis}
  AcMatrix_RotationY: function(const angle:single):TAcMatrix;
  {Returns a matrix for rotation around the Z-Axis}
  AcMatrix_RotationZ: function(const angle:single):TAcMatrix;
  {Returns a matrix for rotation around the X, Y and Z-Axis}
  AcMatrix_Rotation: function(const ax, ay, az: single):TAcMatrix;


function AcMatrix_Proj_Perspective(const fovy, aspect, zNear, zFar: double): TAcMatrix;
function AcMatrix_Proj_Ortho(const left, right, bottom, top, zNear, zFar: double): TAcMatrix;
function AcMatrix_View_LookAt(const Pos, Dir, Up: TAcVector3): TAcMatrix;

function AcVector_Length(const AVec: TAcVector3): Double;
function AcVector_Normalize(const AVec: TAcVector3): TAcVector3;
function AcVector_Cross(const AVec1, AVec2: TAcVector3): TAcVector3;
function AcVector_Dot(const AVec1, AVec2: TAcVector3): double;
function AcVector_Sub(const AVec1, AVec2: TAcVector3): TAcVector3;
function AcVector_Add(const AVec1, AVec2: TAcVector3): TAcVector3;
function AcVector_MultFloat(const AVec1: TAcVector3; const AFloat: single): TAcVector3;
function AcVector_FromQuat(const AQuat: TAcVector4): TAcVector3;

function AcQuaternion_MultVector(const AQuat: TAcVector4; const AVec: TAcVector3): TAcVector3;
function AcQuaternion_Length(const AQuat: TAcVector4): Single;
function AcQuaternion_Normalize(const AQuat: TAcVector4): TAcVector4;
function AcQuaternion_Mult(const AQuat1, AQuat2: TAcVector4): TAcVector4;
function AcQuaternion_Conjugate(const AQuat: TAcVector4): TAcVector4;

implementation

function AcQuaternion_Conjugate(const AQuat: TAcVector4): TAcVector4;
begin
  result.x :=  AQuat.x;
  result.y := -AQuat.y;
  result.z := -AQuat.z;
  result.w := -AQuat.w;
end;

function AcQuaternion_Length(const AQuat: TAcVector4): Single;
begin
  result :=
    Sqrt(Sqr(AQuat.x) + Sqr(AQuat.y) + Sqr(AQuat.z) + Sqr(AQuat.w));
end;

function AcQuaternion_Normalize(const AQuat: TAcVector4): TAcVector4;
var
  l: Single;
begin
  l := AcQuaternion_Length(AQuat);
  result.x := AQuat.x / l;
  result.y := AQuat.y / l;
  result.z := AQuat.z / l;
  result.w := AQuat.w / l;
end;

function AcVector_FromQuat(const AQuat: TAcVector4): TAcVector3;
begin
  result.x := AQuat.y;
  result.y := AQuat.z;
  result.z := AQuat.w;
end;

function AcQuaternion_Mult(const AQuat1, AQuat2: TAcVector4): TAcVector4;
var
  a, b, c: TAcVector3;
begin
  a := AcVector_FromQuat(AQuat1);
  b := AcVector_FromQuat(AQuat2);

  c := AcVector_Add(
    AcVector_Add(
      AcVector_MultFloat(a, AQuat1.x),
      AcVector_MultFloat(b, AQuat1.x)),
    AcVector_Cross(a, b)
  );

  result.x := AQuat1.x * AQuat2.x -
    AcVector_Dot(a, b);
  result.y := c.x;
  result.z := c.y;
  result.w := c.z;
end;

function AcQuaternion_MultVector(const AQuat: TAcVector4; const AVec: TAcVector3): TAcVector3;
Var
  a00, a01, a02, a03, a11, a12, a13, a22, a23, a33 : Single;
Begin
  a00 := AQuat.x * AQuat.x;
  a01 := AQuat.x * AQuat.y;
  a02 := AQuat.x * AQuat.z;
  a03 := AQuat.x * AQuat.w;
  a11 := AQuat.y * AQuat.y;
  a12 := AQuat.y * AQuat.z;
  a13 := AQuat.y * AQuat.w;
  a22 := AQuat.z * AQuat.z;
  a23 := AQuat.z * AQuat.w;
  a33 := AQuat.w * AQuat.w;

  Result.x := AVec.x * (a00 + a11 - a22 - a33) +
    2 * (a12 * AVec.y + a13 * AVec.z + a02 * AVec.z - a03 * AVec.y);

  Result.y := AVec.y * (a00 - a11 + a22 - a33) +
    2 * (a12 * AVec.x + a23 * AVec.z + a03 * AVec.x - a01 * AVec.z);

  Result.z := AVec.z * (a00 - a11 - a22 + a33) +
    2 * (a13 * AVec.x + a23 * AVec.y - a02 * AVec.x + a01 * AVec.y);
end;

function AcVector_MultFloat(const AVec1: TAcVector3; const AFloat: single): TAcVector3;
begin
  result.x := AVec1.x * AFloat;
  result.y := AVec1.y * AFloat;
  result.z := AVec1.z * AFloat;
end;

function AcVector_Sub(const AVec1, AVec2: TAcVector3): TAcVector3;
begin
  result.x := AVec1.x - AVec2.x;
  result.y := AVec1.y - AVec2.y;
  result.z := AVec1.z - AVec2.z;
end;

function AcVector_Add(const AVec1, AVec2: TAcVector3): TAcVector3;
begin
  result.x := AVec1.x + AVec2.x;
  result.y := AVec1.y + AVec2.y;
  result.z := AVec1.z + AVec2.z;
end;

function AcVector_Length(const AVec: TAcVector3): Double;
begin
  result := sqrt(sqr(AVec.x) + sqr(AVec.y) + sqr(AVec.z));  
end;

function AcVector_Normalize(const AVec: TAcVector3): TAcVector3;
var
  l: Double;
begin
  l := AcVector_Length(AVec);

  result.x := AVec.x / l;
  result.y := AVec.y / l;
  result.z := AVec.z / l;
end;

function AcVector_Cross(const AVec1, AVec2: TAcVector3): TAcVector3;
begin
  result.x := (AVec1.y * AVec2.z - AVec1.z * AVec2.y);
  result.y := (AVec1.z * AVec2.x - AVec1.x * AVec2.z);
  result.z := (AVec1.x * AVec2.y - AVec1.y * AVec2.x);
end;

function AcVector_Dot(const AVec1, AVec2: TAcVector3): double;
begin
  result := AVec1.x * AVec2.x + AVec1.y * AVec2.y + AVec1.z * AVec2.z;
end; 

function AcMatrix_Proj_Perspective(const fovy, aspect, zNear, zFar: double): TAcMatrix;
var
  cotangent, deltaZ: double;
begin
  result := AcMatrix_Identity;

  deltaZ := zNear - zFar;
  cotangent := cos(fovy * 0.5) / sin(fovy * 0.5);

  result[0][0] :=  cotangent / aspect;
  result[1][1] :=  cotangent;
  result[2][2] :=  zFar / deltaZ;
  result[2][3] := -1.0;
  result[3][2] :=  zNear * zFar / deltaZ;
  result[3][3] :=  0.0;
end;

function AcMatrix_Proj_Ortho(const left, right, bottom, top, zNear, zFar: double): TAcMatrix;
var
  rml, bmt, nmz: double;
begin
  rml := 1 / (right - left);
  bmt := 1 / (bottom - top);
  nmz := 1 / (zNear - zFar);
  
  result := AcMatrix_Identity;
  result[0][0] :=   2 * rml;
  result[1][1] :=   2 * bmt;
  result[2][2] :=   nmz;
  result[3][0] := -(right + left) * rml;
  result[3][1] := -(bottom + top) * bmt;
  result[3][2] :=   zNear * nmz;
end;

function AcMatrix_View_LookAt(const Pos, Dir, Up: TAcVector3): TAcMatrix;
var
  xax, yax, zax: TAcVector3;
begin
  result := AcMatrix_Identity;

  zax := AcVector_Normalize(AcVector_Sub(Pos, Dir));
  xax := AcVector_Normalize(AcVector_Cross(Up, zax));
  yax := AcVector_Cross(zax, xax);

  result[0][0] := xax.x;
  result[0][1] := yax.x;
  result[0][2] := zax.x;

  result[1][0] := xax.y;
  result[1][1] := yax.y;
  result[1][2] := zax.y;

  result[2][0] := xax.z;
  result[2][1] := yax.z;
  result[2][2] := zax.z;

  result[3][0] := -AcVector_Dot(xax, Pos);
  result[3][1] := -AcVector_Dot(yax, Pos);
  result[3][2] := -AcVector_Dot(zax, Pos);
end;

{$IFDEF FPC}
  {$IFDEF CPU386}
    {$ASMMODE intel}
  {$ELSE}
    {$DEFINE DO_NOT_USE_ASM}
  {$ENDIF}
{$ENDIF}

{$IFDEF DO_NOT_USE_ASM}
  {$DEFINE DO_NOT_USE_3DNOW}
{$ENDIF}

{$IFDEF DO_NOT_USE_ASM}
procedure SinCos(const Alpha: Extended; var Sin, Cos: Extended);{$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
begin
  Sin := System.Sin(Alpha);
  Cos := System.Cos(Alpha);
end;
{$ELSE}
procedure SinCos(const Alpha: Extended; var Sin, Cos: Extended);
begin
  asm
    FLD     Alpha
    FSINCOS
    FSTP    tbyte ptr [edx]
    FSTP    tbyte ptr [eax]
    FWAIT
  end;
end;
{$ENDIF}

function _PASCAL_AcMatrix_Multiply(const amat1, amat2:TAcMatrix):TAcMatrix;
var
  x,y:integer;
begin
  for x := 0 to 3 do
  begin
    for y := 0 to 3 do
    begin
      result[x,y] := 
        amat2[0,y] * amat1[x,0] + 
        amat2[1,y] * amat1[x,1] + 
        amat2[2,y] * amat1[x,2] +
        amat2[3,y] * amat1[x,3];
    end;
  end;
end;

function _PASCAL_AcMatrix_Multiply_Vector(const amat: TAcMatrix; const avec: TAcVector4): TAcVector4;
begin
  with result do
  begin
    X := amat[0, 0] * avec.x + amat[1, 0] * avec.y + amat[2, 0] * avec.z + amat[3, 0] * avec.w;
    Y := amat[0, 1] * avec.x + amat[1, 1] * avec.y + amat[2, 1] * avec.z + amat[3, 1] * avec.w;
    Z := amat[0, 2] * avec.x + amat[1, 2] * avec.y + amat[2, 2] * avec.z + amat[3, 2] * avec.w;
    W := amat[0, 3] * avec.x + amat[1, 3] * avec.y + amat[2, 3] * avec.z + amat[3, 3] * avec.w;
  end;
end;

function _PASCAL_AcMatrix_Transpose(const mat: TAcMatrix): TAcMatrix;
var
  i,j : integer;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      result[i, j] := mat[j, i];
end;

function _PASCAL_AcMatrix_Translate(const tx,ty,tz:single):TAcMatrix;
begin
  result := AcMatrix_Identity;
  result[3,0] := tx;
  result[3,1] := ty;
  result[3,2] := tz;
end;

function _PASCAL_AcMatrix_Scale(const sx,sy,sz:single):TAcMatrix;
begin
  result := AcMatrix_Clear;
  result[0,0] := sx;
  result[1,1] := sy;
  result[2,2] := sz;
  result[3,3] := 1;
end;

function _PASCAL_AcMatrix_RotationX(const angle:single):TAcMatrix;
var
  asin, acos: Extended;
begin
  asin := 0; acos := 0;
  SinCos(angle, asin, acos);

  result := AcMatrix_Clear;
  result[0,0] := 1;
  result[1,1] := acos;
  result[1,2] := asin;
  result[2,1] := -asin;
  result[2,2] := acos;
  result[3,3] := 1;
end;

function _PASCAL_AcMatrix_RotationY(const angle:single):TAcMatrix;
var
  asin, acos: Extended;
begin
  SinCos(angle, asin, acos);

  result := AcMatrix_Clear;
  result[0,0] := acos;
  result[0,2] := -asin;
  result[1,1] := 1;
  result[2,0] := asin;
  result[2,2] := acos;
  result[3,3] := 1;
end;

function _PASCAL_AcMatrix_RotationZ(const angle:single):TAcMatrix;
var
  asin, acos: Extended;
begin
  SinCos(angle, asin, acos);
  
  result := AcMatrix_Clear;
  result[0,0] := acos;
  result[0,1] := asin;
  result[1,0] := -asin;
  result[1,1] := acos;
  result[2,2] := 1;
  result[3,3] := 1;
end;

function _PASCAL_AcMatrix_Rotation(const ax, ay, az:single):TAcMatrix;
var
  AMat1, AMat2: TAcMatrix;
begin
  //Calculate the X and the Y rotation matrix
  AMat1 := _PASCAL_AcMatrix_RotationX(ax);
  AMat2 := _PASCAL_AcMatrix_RotationY(ay); 
  AMat1 := AcMatrix_Multiply(AMat1, AMat2);

  //Calculate the Z rotation matrix and multiply it with the XY rotation matrix
  AMat2 := _PASCAL_AcMatrix_RotationZ(az);
  AMat1 := AcMatrix_Multiply(AMat1, AMat2);

  //Return the calculated XYZ Matrix
  result := AMat1;
end;

procedure UsePascal;
begin
  AcMatrix_Multiply := _PASCAL_AcMatrix_Multiply;
  AcMatrix_Multiply_Vector := _PASCAL_AcMatrix_Multiply_Vector;
  AcMatrix_Transpose := _PASCAL_AcMatrix_Transpose;
  AcMatrix_Translate := _PASCAL_AcMatrix_Translate;
  AcMatrix_Scale := _PASCAL_AcMatrix_Scale;
  AcMatrix_RotationX := _PASCAL_AcMatrix_RotationX;
  AcMatrix_RotationY := _PASCAL_AcMatrix_RotationY;
  AcMatrix_RotationZ := _PASCAL_AcMatrix_RotationZ;
  AcMatrix_Rotation := _PASCAL_AcMatrix_Rotation;
end;

{$IFNDEF DO_NOT_USE_3DNOW}

{The procedures listed here are taken from the VectorGeometry.pas from the
 GLScene project. For more details see above.}

{$MESSAGE HINT 'Andorra Commons may use the AMD 3DNow optimization. This code is not tested!'}
{$MESSAGE HINT 'If you encounter any problem, activate the DO_NOT_USE_3DNOW compiler switch in andorra_conf.inc and report this problem to the Andorra 2D developers. Thank you.'}
{$MESSAGE HINT 'If you are using an AMD processor and everything works fine, it would be great if you could report this.'}

function _3DNOW_AcMatrix_Multiply(const amat1, amat2:TAcMatrix):TAcMatrix;
begin
  asm
    xchg eax, ecx
    db $0F,$6F,$01           /// movq        mm0,[ecx]
    db $0F,$6F,$49,$08       /// movq        mm1,[ecx+8]
    db $0F,$6F,$22           /// movq        mm4,[edx]
    db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
    db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
    db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
    db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
    db $0F,$62,$C0           /// punpckldq   mm0,mm0
    db $0F,$62,$C9           /// punpckldq   mm1,mm1
    db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
    db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
    db $0F,$0F,$42,$08,$B4   /// pfmul       mm0, [edx+8]
    db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
    db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
    db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
    db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
    db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
    db $0F,$0F,$EC,$9E       /// pfAdd       mm5,mm4
    db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
    db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
    db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
    db $0F,$0F,$F5,$9E       /// pfAdd       mm6,mm5
    db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
    db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
    db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
    db $0F,$6F,$41,$10       /// movq        mm0,[ecx+16]
    db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2
    db $0F,$6F,$49,$18       /// movq        mm1,[ecx+24]
    db $0F,$7F,$38           /// movq        [eax],mm7
    db $0F,$6F,$22           /// movq        mm4,[edx]
    db $0F,$7F,$58,$08       /// movq        [eax+8],mm3

    db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
    db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
    db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
    db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
    db $0F,$62,$C0           /// punpckldq   mm0,mm0
    db $0F,$62,$C9           /// punpckldq   mm1,mm1
    db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
    db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
    db $0F,$0F,$42,$08,$B4   /// pfmul       mm0,[edx+8]
    db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
    db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
    db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
    db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
    db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
    db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
    db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
    db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
    db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
    db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
    db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
    db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
    db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
    db $0F,$6F,$41,$20       /// movq        mm0,[ecx+32]
    db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2
    db $0F,$6F,$49,$28       /// movq        mm1,[ecx+40]
    db $0F,$7F,$78,$10       /// movq        [eax+16],mm7
    db $0F,$6F,$22           /// movq        mm4,[edx]
    db $0F,$7F,$58,$18       /// movq        [eax+24],mm3

    db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
    db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
    db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
    db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
    db $0F,$62,$C0           /// punpckldq   mm0,mm0
    db $0F,$62,$C9           /// punpckldq   mm1,mm1
    db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
    db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
    db $0F,$0F,$42,$08,$B4   /// pfmul       mm0,[edx+8]
    db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
    db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
    db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
    db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
    db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
    db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
    db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
    db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
    db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
    db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
    db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
    db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
    db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
    db $0F,$6F,$41,$30       /// movq        mm0,[ecx+48]
    db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2
    db $0F,$6F,$49,$38       /// movq        mm1,[ecx+56]
    db $0F,$7F,$78,$20       /// movq        [eax+32],mm7
    db $0F,$6F,$22           /// movq        mm4,[edx]
    db $0F,$7F,$58,$28       /// movq        [eax+40],mm3

    db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
    db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
    db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
    db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
    db $0F,$62,$C0           /// punpckldq   mm0,mm0
    db $0F,$62,$C9           /// punpckldq   mm1,mm1
    db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
    db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
    db $0F,$0F,$42,$08,$B4   /// pfmul       mm0,[edx+8]
    db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
    db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
    db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
    db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
    db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
    db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
    db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
    db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
    db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
    db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
    db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
    db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
    db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
    db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2
    db $0F,$7F,$78,$30       /// movq        [eax+48],mm7
    db $0F,$7F,$58,$38       /// movq        [eax+56],mm3
    db $0F,$0E               /// femms
  end;
end;

function _3DNOW_AcMatrix_Multiply_Vector(const amat: TAcMatrix; const avec: TAcVector4): TAcVector4;
begin
  asm
    db $0F,$6F,$00           /// movq        mm0,[eax]
    db $0F,$6F,$48,$08       /// movq        mm1,[eax+8]
    db $0F,$6F,$22           /// movq        mm4,[edx]
    db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
    db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
    db $0F,$62,$C0           /// punpckldq   mm0,mm0
    db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
    db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
    db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
    db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
    db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
    db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
    db $0F,$62,$C9           /// punpckldq   mm1,mm1
    db $0F,$0F,$42,$08,$B4   /// pfmul       mm0,[edx+8]
    db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
    db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
    db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
    db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
    db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
    db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
    db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
    db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
    db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
    db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
    db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
    db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2

    db $0F,$7F,$39           /// movq        [ecx],mm7
    db $0F,$7F,$59,$08       /// movq        [ecx+8],mm3
    db $0F,$0E               /// femms
  end
end;

function Supports3DNow: boolean;
var
  vSIMD: integer;
begin
  vSIMD := 0;
  try
    // detect 3DNow! capable CPU (adapted from AMD's "3DNow! Porting Guide")
    asm
      pusha
      mov  eax, $80000000
      db $0F,$A2               /// cpuid
      cmp  eax, $80000000
      jbe @@No3DNow
      mov  eax, $80000001
      db $0F,$A2               /// cpuid
      test edx, $80000000
      jz @@No3DNow
      mov vSIMD, 1
     @@No3DNow:
      popa
    end;
  except
    // trap for old/exotics CPUs
    vSIMD := 0;
  end;
  
  result := vSIMD = 1;
end;

procedure Use3DNow;
begin
  UsePascal;
  AcMatrix_Multiply := _3DNOW_AcMatrix_Multiply;
  AcMatrix_Multiply_Vector := _3DNOW_AcMatrix_Multiply_Vector;
end;
 
{$ENDIF}

initialization
  {$IFDEF DO_NOT_USE_3DNOW}
    //If 3DNOW optimizations are deactivated, connect the functions in the 
    //interface part of the unit with the functions written in standard 
    //pascal
    UsePascal;
  {$ELSE}
    //Check whether the optimizations that are needed by the optimized functions
    //are available on this processor
    if Supports3DNow then
      Use3DNow
    else
      UsePascal;
  {$ENDIF}
end.
