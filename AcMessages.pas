{*******************************************************}
{                                                       }
{       Andorra Commons General Purpose Library         }
{       Copyright (c) Andreas Stöckel, 2010             }
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

File: AcMessages.pas
Author: Andreas Stöckel
}

{Contains messages used in various Andorra Commons units.}
unit AcMessages;//@exclude

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

resourcestring

  {Messages for the Andorra Common Store Classes}

  MsgInvalidStoreNodeChunk = 'Error while loading the file. The Andorra Common Store ' +
   'file chunk could not be found. Probably the file is corrupted or of a newer version ' +
   'of the Andorra Common Store file format. But most probably you have tried to open ' +
   'a file of an invalid/unsupported file format.';

  MsgInvalidStoreNodeClass = 'Error while loading the file. Andorra Common Store ' +
   'found an unsupported class reference in the file you tried to load. Make sure that ' +
   'the Andorra Common Store file belongs to this application. Probably some plugins needed' +
   'to load this file are not available.';

  MsgInvalidFileOffset = 'Error while loading the file. The file you tried to load ' +
   'contained a wrong data offset and may be corrupted.';

   {Messages for the Andorra Commons Stream utitlities}

   MsgIOErrRead = 'Read access not possible as the stream is opened for write ' +
    'access only.';
   MsgIOErrWrite = 'Write access not possible as the stream is opened for read ' +
    'access only.';

   {Messages for the Andorra Commons Notify classes}

   MsgNotifyErrAlreadyInitialized = 'The notify system is already initialized.';



implementation

end.
