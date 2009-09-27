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



implementation

end.
