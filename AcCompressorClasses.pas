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

File: AcCompressorClasses.pas
Author: Andreas Stöckel
}

{Contains the class and type definitions for working with compressors.}
unit AcCompressorClasses;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, Classes;

type
  {Callback function used by TAcCompressor and its descendant classes. It allows
   compressors to report their current compressing/decompressing progress.
   @param(AInSize defines how many bytes are in the input stream.)
   @param(AInRead defines how many bytes have been read from the input stream.
   @param(AOutWrote defines how many bytes have been written to the output stream.)}
  TAcCompressorProgressProc =
    procedure(AInSize, AInRead, AOutWrote: integer) of object;
  
  {TAcCompressor is an "abstract" class, which defines an stream compressor.}
  TAcCompressor = class
    protected
      FProgress: TAcCompressorProgressProc;
    public
      {The decompress function decompresses the given input stream and outputs
       the decompressed data on the output stream. The decompressing progress may
       be reported by the "OnProgress" callback function.
       @param(AIn defines the input stream from which the compressed data is
         read)
       @param(AOut defines the output stream to wich the decompressed data should
         be written.)}
      function Decompress(const AIn, AOut: TStream;
        AReadSize: Cardinal = 0): boolean;virtual;
      {The compress function compresses the given input stream and outputs
       the compressed data on the output stream. The compressing progress may
       be reported by the "OnProgress" callback function.
       @param(AIn defines the input stream from which the uncompressed data is
         read)
       @param(AOut defines the output stream to wich the compressed data should
         be written.)}
      function Compress(const AIn, AOut: TStream;
        AReadSize: Cardinal = 0): boolean;virtual;

      {The on progress callback may be used to obtain information about the current
       encoding/decoding progress. Whether the callback function is active depends
       on the implementation of the descendant TAcCompressor class. Do not rely
       on the data given by the OnProgress function.}
      property OnProgress: TAcCompressorProgressProc read FProgress write
        FProgress;
  end;

implementation

{ TAcCompressor }

function TAcCompressor.Compress(const AIn, AOut: TStream;
  AReadSize: Cardinal): boolean;
begin
  //The default implementation doesn't support compressing data
  result := false;
end;

function TAcCompressor.Decompress(const AIn, AOut: TStream;
  AReadSize: Cardinal): boolean;
begin
  //The default implementation doesn't support decompressing data
  result := false;
end;

end.
