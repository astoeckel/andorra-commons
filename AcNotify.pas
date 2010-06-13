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

File: AcNotify.pas
Author: Andreas Stöckel
}

{AcNotify contains classes and functions which can be used to send inter-thread
 notifications. This concept is somewhat simmilar to the TThread.QueueMethod method,
 but AcNotify is able to provide this functionality for NonVCL and console applications.}
unit AcNotify;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, Classes,
  AcMessages, AcSyncObjs;

{$I commons_conf.inc}

type
  {Exception which is thrown if an error inside the AcNotify Unit occurs.}
  EAcNotifyException = class(Exception);

  {Callback method used within the Andorra Commons notification system. ASender
   represents the object which made the queue call, AUserData can be any data
   provided the calling object.
   @seealso(TAcNotifyProcessor.AddNotification)}
  TAcNotifyMethod = procedure(ASender: TObject; AUserData: Pointer) of object;

  {The TAcNotification record is internally used to store the notification data.}
  TAcNotification = record
    user_data: Pointer;//< The pointer supplied via the "AUserData" parameter of TAcNotifyMethod
    method: TAcNotifyMethod;//< The method which should be called when the notification is triggered 
    sender: TObject;//< The sender object which is supplied via the "ASender" parameter of TAcNotifyMethod
  end;
  {A pointer on TAcNotification}
  PAcNotification = ^TAcNotification;

  {The base class for each actual notify processor implementation. The notify processor
   cares about adding notifications to the internal queue and calling the notifications
   in a thread safe manner with minimum delay. All notifications will allways be
   called synchronously in order. You should always use the public
   functions supplied in this unit instead of instanciating a TAcNotifyProcessor
   yourself.
   @seealso(AcNotifyQueue)
   @seealso(AcNotifyRemoveObject)}
  TAcNotifyProcessor = class
    private
      FQueue: TList;
      FProcessNotification: PAcNotification;
      FQueueMutex: TAcMutex;
      FProcessMutex: TAcMutex;
      FCallingMutex: TAcMutex;
      function ReferenceToObject(ANotification: PAcNotification; AObj: Pointer): Boolean;
    protected
      {Returns true if a notification is on the queue. Thread safe.}
      function HasObject: Boolean;
      {Processes the oldest entry in the notification queue. Thread safe.}
      procedure ProcessQueue;
    public
      {Creates an instance of TAcNotifyProcessor.}
      constructor Create;
      {Destroys this instance of TAcNotifyProcessor. All remaining notifications
       are freed and will not get called.}
      destructor Destroy;override;

      {Adds a new notification to the TAcNotifyProcessor.}
      procedure AddNotification(const ANotification: TAcNotification);
      {Removes all notifications which reference to the supplied object. A notification
      references to an object if either the notification or the target object of the
      method (TMethod(method).Data) is equal to the supplied object.}
      procedure RemoveObject(AObj: TObject);
  end;

  {Callback function used internally with TAcNotifyProcessorThread.}
  TAcNotifyProcessorThreadCallback = function: Boolean of object;

  {Used internally within TAcThreadedNotifyProcessor.}
  TAcNotifyProcessorThread = class(TThread)
    private
      FCallback: TAcNotifyProcessorThreadCallback;
    protected
      procedure Execute;override;
    public
      constructor Create(ACallback: TAcNotifyProcessorThreadCallback);
  end;

  {This abstract class represents an notify processor which calls the notifications
   from an extra thread and or uses and extra thread to run asynchronously from
   the main thread.}
  TAcThreadedNotifyProcessor = class(TAcNotifyProcessor)
    private
      FThread: TAcNotifyProcessorThread;
      function ThreadCallback: Boolean;virtual;abstract;
    public
      {Creates an instance of TAcThreadedNotifyProcessor and starts the thread.}
      constructor Create;
      {Destroys the instance of TAcThreadedNotifyProcessor and terminates the
      thread running in the background.}
      destructor Destroy;override;
  end;

  {Implements the TAcThreadedNotifyProcessor class and uses TThread.Synchronize internally
   to synchronize the notifications with the main thread. This class is automatically
   used whenever you're using the VCL in your project.}
  TAcVCLNotifyProcessor = class(TAcThreadedNotifyProcessor)
    protected
      function ThreadCallback: Boolean;override;
  end;

  {Implements the TAcThreadedNotifyProcessor class and calls all notifications from
  an extra thread.}
  TAcNonVCLNotifyProcessor = class(TAcThreadedNotifyProcessor)
    protected
      function ThreadCallback: Boolean;override;
  end;

  {Implements the TAcNotifyProcessor class and allows you to do the synchronization
  with your main thread directly. You can use this class by calling the "AcNotifyManualInit()"
  function before using any object which uses the AcNotify framework. Using the
  "AcNotifyManualProcessQueue()" function, you can call all notifications available.
  @seealso(AcNotifyManualInit)
  @seealso(AcNotifyManualProcessQueue)}
  TAcManualNotifyProcessor = class(TAcNotifyProcessor)
    public
      {Processes the last object which is on the queue. Returns "false" if no object
      is available on the queue, otherwise "true".}
      function Process: Boolean;
  end;

{Adds an event to the notification queue. If the notification system has not yet
been initialized using either "AcNotifyManualSetProcessor" or "AcNotifyManualInit",
the notification system will be initialized using a default processor (either
TAcVCLNotifyProcessor or TAcNonVCLProcessor, depending on whether you're using the
VCL or not).
@param(ASender specifies the object which should be passed to the notification handler. @Nil is allowed.)
@param(AMethod specifies notification handling method.)
@param(AUserData can be used to send some user defined data to the notification hander. Defaults to nil.)
@seealso(TAcNotifyProcessor)}
procedure AcNotifyQueue(ASender: TObject; AMethod: TAcNotifyMethod; AUserData: Pointer = nil);
{Removes all notifications from the queue which have an reference to the specified object
either in the "sender" or in the notification handler (TMethod.Data).}
procedure AcNotifyRemoveObject(AObject: TObject);

{Allows you to set an own instance of a notification processor. This method has to
be called before any other notification system procedure has been used.
@seealso(TAcNotifyProcessor)}
procedure AcNotifyManualSetProcessor(ANotifyProcessor: TAcNotifyProcessor);
{If you've initialized the notification queue system using the AcNotifyManualInit
function, you must use this function to synchronize the notifications with the
thread calling AcNotifyManualProcessQueue.
@seealso(AcNotifyManualInit)}
procedure AcNotifyManualProcessQueue;
{Initializes the notification system with TAcManualNotifyProcessor, allowing you
to use the AcNotifyManualProcessQueue function.
@seealso(AcNotifyManualProcessQueue)}
procedure AcNotifyManualInit;

implementation

{ TAcNotifyProcessor }

constructor TAcNotifyProcessor.Create;
begin
  inherited;

  FQueue := TList.Create;
  FQueueMutex := TAcMutex.Create;
  FProcessMutex := TAcMutex.Create;
  FCallingMutex := TAcMutex.Create;
end;

destructor TAcNotifyProcessor.Destroy;
var
  i: integer;
begin 
  FreeAndNil(FCallingMutex);
  FreeAndNil(FProcessMutex);
  FreeAndNil(FQueueMutex);

  //Free all remaining queue objects
  for i := 0 to FQueue.Count - 1 do
    Dispose(PAcNotification(FQueue[i]));
  FQueue.Clear;

  FreeAndNil(FQueue);
  inherited;
end;

function TAcNotifyProcessor.HasObject: Boolean;
begin
  FQueueMutex.Acquire;
  try
    result := FQueue.Count > 0;
  finally
    FQueueMutex.Release;
  end;
end;

procedure TAcNotifyProcessor.AddNotification(
  const ANotification: TAcNotification);
var
  pnotify: PAcNotification;
begin
  FQueueMutex.Acquire;
  try
    //Create a copy of the supplied parameter and add it to the list
    New(pnotify);
    pnotify^ := ANotification;
    
    FQueue.Add(pnotify);
  finally
    FQueueMutex.Release;
  end;
end;

procedure TAcNotifyProcessor.ProcessQueue;
var
  ntfc: TAcNotification;
  hasntfc: Boolean;
  valid: boolean;
begin
  FillChar(ntfc, SizeOf(ntfc), 0);
  hasntfc := false;

  //FProcessMutex protects access on the FProcessNotification structure
  FProcessMutex.Acquire;
  try
    New(FProcessNotification);

    //Create a copy of the last element in the queue
    FQueueMutex.Acquire;
    try
      if FQueue.Count > 0 then
      begin
        FProcessNotification^ := PAcNotification(FQueue[0])^;
        ntfc := PAcNotification(FQueue[0])^;
        Dispose(PAcNotification(FQueue[0]));
        FQueue.Delete(0);
        hasntfc := true;
      end
      else
      begin
        //If there isn't a element on the queue, delete the memory reserved again
        Dispose(FProcessNotification);
        FProcessNotification := nil;
      end;
    finally //FQueue Mutex
      FQueueMutex.Release;
    end;
  finally //FProcessMutex
    FProcessMutex.Release;
  end;

  FCallingMutex.Acquire;
  try
    FProcessMutex.Acquire;
    try
      valid := FProcessNotification <> nil;
    finally
      FProcessMutex.Release;
    end;

    //Call the method specified in the notification record
    if valid and hasntfc then
      ntfc.method(ntfc.sender, ntfc.user_data);
  finally
    FCallingMutex.Release;
  end;

  FProcessMutex.Acquire;
  try
    if FProcessNotification <> nil then
      Dispose(FProcessNotification);
    FProcessNotification := nil;
  finally
    FProcessMutex.Release;
  end;
end;

function TAcNotifyProcessor.ReferenceToObject(ANotification: PAcNotification;
  AObj: Pointer): Boolean;
begin
  result := (ANotification <> nil) and
    ((ANotification^.sender = AObj) or (TMethod(ANotification^.method).Data = AObj));
end;

procedure TAcNotifyProcessor.RemoveObject(AObj: TObject);
var
  i: integer;
  hasref: Boolean;
begin
  //Check whether there currently is access to the object - if yes, wait until the access is done
  FProcessMutex.Acquire;
  try
    hasref := ReferenceToObject(FProcessNotification, AObj);

    if hasref and (FProcessNotification <> nil) then
    begin
      Dispose(FProcessNotification);
      FProcessNotification := nil;
    end;

    //Delete all notifications referencing to the object specified from the queue
    FQueueMutex.Acquire;
    try
      for i := FQueue.Count - 1 downto 0 do
      begin
        if ReferenceToObject(PAcNotification(FQueue[i]), AObj) then
        begin
          Dispose(PAcNotification(FQueue[i]));
          FQueue.Delete(i);
        end;
      end;
    finally
      FQueueMutex.Release;
    end;
  finally
    FProcessMutex.Release;
  end;

  if hasref then
  begin
    //Wait for the calling mutex
    FCallingMutex.Acquire;
    try
      //
    finally
      FCallingMutex.Release;
    end;
  end;
end;

{ TAcNotifyProcessorThread }

constructor TAcNotifyProcessorThread.Create(
  ACallback: TAcNotifyProcessorThreadCallback);
begin
  inherited Create(false);

  FCallback := ACallback;
end;

procedure TAcNotifyProcessorThread.Execute;
begin
  //Simply loop and call the specified callback
  while not Terminated do
  begin
    try
      if not FCallback then
        Sleep(1);
    except
      //
    end;
  end;
end;

{ TAcThreadedNotifyProcessor }

constructor TAcThreadedNotifyProcessor.Create;
begin
  inherited;

  FThread := TAcNotifyProcessorThread.Create(ThreadCallback);
end;

destructor TAcThreadedNotifyProcessor.Destroy;
begin
  //Wait for the termination of the notify processor thread and finally free it
  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNil(FThread);

  inherited;
end;

{ TAcNonVCLNotifyProcessor }

function TAcNonVCLNotifyProcessor.ThreadCallback: Boolean;
begin
  //Simpy process the notify queue in the context of the notify processor thread
  result := false;
  if HasObject then
  begin
    ProcessQueue;
    result := true;
  end;
end;

{ TAcVCLNotifyProcessor }

function TAcVCLNotifyProcessor.ThreadCallback: Boolean;
begin
  //Call the TThread.Synchronize method in order to have the notification in sync with the VCL/LCL application
  result := false;
  if HasObject then
  begin
    TThread.Synchronize(nil, ProcessQueue);
    result := true;
  end;
end;

{ TAcManualNotifyProcessor }

function TAcManualNotifyProcessor.Process: Boolean;
begin
  result := false;
  if HasObject then
  begin
    ProcessQueue;
    result := true;
  end;
end;

{ Functions }

var
  ac_notify_processor: TAcNotifyProcessor;
  ac_init: Boolean;

function AcVCLActive: Boolean;
begin
  result := Assigned(WakeMainThread);
end;

procedure AcNotifyInit;
begin
  if (ac_notify_processor = nil) and not ac_init then
  begin
    //Check whether the VCL/LCL is initialized
    if AcVCLActive then
      ac_notify_processor := TAcVCLNotifyProcessor.Create
    else
      ac_notify_processor := TAcNonVCLNotifyProcessor.Create;
  end;

  ac_init := true;
end;

procedure AcNotifyQueue(ASender: TObject; AMethod: TAcNotifyMethod; AUserData: Pointer = nil);
var
  notification: TAcNotification;
begin
  //Make sure the notification system is initialized
  AcNotifyInit;

  //Set all notification record properties  
  notification.sender := ASender;
  notification.method := AMethod;
  notification.user_data := AUserData;

  //Add the notification
  ac_notify_processor.AddNotification(notification);
end;

procedure AcNotifyRemoveObject(AObject: TObject);
begin
  if ac_notify_processor <> nil then
    ac_notify_processor.RemoveObject(AObject);
end;

procedure AcNotifyManualProcessQueue;
begin
  if (ac_notify_processor <> nil) and (ac_notify_processor is TAcManualNotifyProcessor) then
  begin
    while TAcManualNotifyProcessor(ac_notify_processor).Process do;
  end;
end;

procedure AcNotifyManualSetProcessor(ANotifyProcessor: TAcNotifyProcessor);
begin
  if (ac_notify_processor = nil) and (ac_init = false) then
    ac_notify_processor := ANotifyProcessor
  else
    raise EAcNotifyException.Create(MsgNotifyErrAlreadyInitialized);

  ac_init := true;
end;

procedure AcNotifyManualInit;
begin
  if (ac_notify_processor = nil) and (ac_init = false) then
    ac_notify_processor := TAcManualNotifyProcessor.Create
  else
    raise EAcNotifyException.Create(MsgNotifyErrAlreadyInitialized);

  ac_init := true;
end;

initialization

finalization
  if ac_notify_processor <> nil then
    FreeAndNil(ac_notify_processor);

end.
