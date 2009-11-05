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

File: AcStream.pas
Author: Andreas Stöckel
}

{This unit contains classes and functions which are usefull when working with
 streams and files.}
unit AcStream;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}


interface

uses
  SysUtils, Classes,

  AcMessages;

type
  {Exception raised when a stream I/O operation failed.}
  EAcStreamIO = class(Exception);

  {TAcSandboxedStreamAdapter provides read access on a specified part of another stream.
   "Read" or "Seek" actions which are out of the specified bounds will show the same
   results as if the stream only had the specified size.
   Classes using TAcSandboxedStreamAdapter will see no difference to other descendants of
   TStream.
   Write access is on a TAcSandboxedStreamAdapter is not possible and will result
   in an exception being raised.
   TAcSandboxedStreamAdapter should not be used in environments where high security
   is needed as it has not been checked for any vunerabilities.}
  TAcSandboxedStreamAdapter = class(TStream)
    private
      FSourceStream: TStream;
      FOffset: int64;
      FSize: int64;
      function CurPos: int64;
    public
      {Creates a new instance of TAcSandboxedStreamAdapter. TAcSandboxedStreamAdapter
       does not check the data given to this function on correctness!
       @param(ASrc specifies the stream which shall be adapted.)
       @param(AOffs specifies the offset in the source stream, from which
        on data can be read.)
       @param(ASize specifies the size of the bounds, from which data
        can be read.)}
      constructor Create(ASrc: TStream; AOffs, ASize: int64);

      {Reads data from the adapted stream.}
      function Read(var Buffer; Count: Longint): Longint; override;
      {Raises an EAcStreamIO exception, as writing is not supported by TAcSandboxed
       stream adapter}
      function Write(const Buffer; Count: Longint): Longint; override;

      {Seeks to the given offset from the origin. All positions are recalculated
       to fit the bounds.}
      function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

implementation

{ TAcStreamAdapter }

constructor TAcSandboxedStreamAdapter.Create(ASrc: TStream; AOffs, ASize: int64);
begin
  inherited Create;

  FSourceStream := ASrc;
  FOffset := AOffs;
  FSize := ASize;
end;

function TAcSandboxedStreamAdapter.CurPos: int64;
begin
  result := FSourceStream.Position - FOffset;
end;

function TAcSandboxedStreamAdapter.Read(var Buffer; Count: Integer): Longint;
begin
  //Check bounds
  if Count + CurPos > FSize then
  begin
    Count := FSize - CurPos;
    if Count < 0 then
      Count := 0;
  end else if Count < 0 then
    Count := 0;

  //Call the read method of the adapted stream
  result := FSourceStream.Read(Buffer, Count);
end;

function TAcSandboxedStreamAdapter.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
var
  pos: int64;
begin
  case Origin of
  
    soBeginning:
    begin
      //Check bounds
      if (Offset > FSize) then
        //When offset exceeds the emulated size, seek to the end of the stream
        pos := FOffset + FSize
      else if Offset < 0 then
        //Offset shall not be smaller than zero
        pos := 0
      else
        //Offset does not break out of the given bounds, seek to the specified
        //position
        pos := FOffset + Offset;

      FSourceStream.Seek(pos, soBeginning);
    end;
    
    soCurrent:
    begin
      //Check bounds
      if Offset + CurPos > FSize then
        pos := FSize - CurPos
      else if Offset + CurPos < 0 then
        pos := -CurPos
      else
        pos := Offset;

      FSourceStream.Seek(pos, soCurrent);
    end;
    
    soEnd:
    begin
      //Check bounds
      if -Offset > FSize then
        pos := FOffset
      else if Offset > 0 then
        pos := FOffset + FSize
      else
        pos := FOffset + FSize + Offset;

      FSourceStream.Seek(pos, soBeginning);
    end;
  end;

  result := CurPos;
end;

function TAcSandboxedStreamAdapter.Write(const Buffer; Count: Integer): Longint;
begin
{$IFDEF FPC}result := 0;{$ENDIF}
  raise EAcStreamIO.Create(MsgIOErrWrite);
end;

end.
