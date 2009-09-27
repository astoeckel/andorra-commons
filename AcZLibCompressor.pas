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

File: AcZLibCompressor.pas
Author: Andreas Stöckel
}

{Contains a ZLib compressor. Multiple ZLib/Deflate implementations may be used
 using compiler switches.}
unit AcZLibCompressor;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

{$DEFINE USE_MZLIB}

uses
  SysUtils, Classes,
  {$IFDEF USE_MZLIB}
  MZLib,
  {$ELSE}
  AcZLib,
  {$ENDIF}
  AcCompressorClasses;

type    
  {TAcCompressor is an "abstract" class, which defines an stream compressor.}
  TAcZLibCompressor = class(TAcCompressor)
    public
      {The decompress function decompresses the given input stream and outputs
       the decompressed data on the output stream. The decompressing progress may
       be reported by the "OnProgress" callback function.
       @param(AIn defines the input stream from which the compressed data is
         read)
       @param(AOut defines the output stream to wich the decompressed data should
         be written.)}
      function Decompress(const AIn, AOut: TStream;
        AReadSize: Cardinal = 0): boolean;override;
      {The compress function compresses the given input stream and outputs
       the compressed data on the output stream. The compressing progress may
       be reported by the "OnProgress" callback function.
       @param(AIn defines the input stream from which the uncompressed data is
         read)
       @param(AOut defines the output stream to wich the compressed data should
         be written.)}
      function Compress(const AIn, AOut: TStream;
        AReadSize: Cardinal = 0): boolean;override;
  end;


implementation

{ TAcZLibCompressor }

const
  chunk_size = 16384;

function TAcZLibCompressor.Compress(const AIn, AOut: TStream;
  AReadSize: Cardinal): boolean;
begin
  result := false; 
end;

function TAcZLibCompressor.Decompress(const AIn, AOut: TStream;
  AReadSize: Cardinal): boolean;
var
  {$IFDEF USE_MZLIB}
  strm: TZState;
  {$ELSE}
  strm: TZStream;
  {$ENDIF}
  src, tar: PByte;
  ret: integer;
  readsize, read, bufsize, wrote, cnt: Cardinal;
  abort: boolean;
begin
  //Initialize all local variables
  src := nil; tar := nil;
  FillChar(strm, SizeOf(strm), 0);
  read := 0; wrote := 0;
  result := false;

  if InflateInit(strm) <> Z_OK then
    exit;

  try
    //Reserve buffer memory
    GetMem(tar, chunk_size);
    GetMem(src, chunk_size);
    
    //Set the number of bytes which have to be read
    if AReadSize <= 0 then
      readsize := AIn.Size
    else
      readsize := AReadSize;

    repeat
      //Calculate how many bytes have to be read
      if readsize - read > chunk_size then
        bufsize := chunk_size
      else
        bufsize := readsize - read;
        
      //Read data
      cnt := AIn.Read(src^, bufsize);
      read := read + cnt;

      {$IFDEF USE_MZLIB}
      strm.AvailableInput := cnt;
      strm.NextInput := src;
      {$ELSE}
      strm.avail_in := cnt;
      strm.next_in := src;
      {$ENDIF}

      repeat
        {$IFDEF USE_MZLIB}
        //Set the write target
        strm.AvailableOutput := chunk_size;
        strm.NextOutput := tar;
        {$ELSE}
        //Set the write target
        strm.avail_out := chunk_size;
        strm.next_out := tar;
        {$ENDIF}

        //Try to inflate the data
        ret := Inflate(strm, Z_NO_FLUSH);
        abort := (ret <> Z_OK) and (ret <> Z_STREAM_END);
        if not abort then
        begin
          {$IFDEF USE_MZLIB}
          //Read the deflated data to the stream
          AOut.Write(tar^, chunk_size - strm.AvailableOutput);

          //Increment the "wrote" variable
          wrote := wrote + (chunk_size - strm.AvailableOutput);
          {$ELSE}
          //Read the deflated data to the stream
          AOut.Write(tar^, chunk_size - strm.avail_out);

          //Increment the "wrote" variable
          wrote := wrote + Cardinal(chunk_size - strm.avail_out);
          {$ENDIF}

          //Call the callback function
          if Assigned(FProgress) then
            FProgress(readsize, read, wrote);
        end;

      {$IFDEF USE_MZLIB}
      until (strm.AvailableOutput > 0) or (abort);
      {$ELSE}
      until (strm.avail_out > 0) or (abort);
      {$ENDIF}
    until (ret = Z_STREAM_END) or (abort);
  finally
    if src <> nil then FreeMem(src);
    if tar <> nil then FreeMem(tar);

    InflateEnd(strm);
  end;

  //Everything worked!
  result := not abort;
end;

end.
