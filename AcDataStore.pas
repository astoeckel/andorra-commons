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

File: AcDataStore.pas
Author: Andreas Stöckel
}

{This unit contains an unified data store mechanism, which allows you to store
 data in a XML like way in binary files. Andorra Commons Data Store features
 memory management, support for huge files and linking capabilities.}
unit AcDataStore;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, Classes,

  AcPersistent, AcMessages, AcStream;

type
  EAcStoreNode = class(Exception);
  EAcStoreNodeLoad = class(EAcStoreNode);

  {TAcStoreNode is the base class every Andorra Common Store file is based on.
   TAcStoreNode contains the base functions for name- (unique name, path), file-
   and chilren management. TAcStoreNode allows to add new child nodes via the
   add functions. Some of these functions are able to add a fixed type child
   to the node.
   TAcStoreNodes manage their children inside a store node list. Every TAcStoreNode
   is able to contain an unlimited amount of child nodes.
   @seealso(TAcStoreNodeList)}
  TAcStoreNode = class;

  {TAcStoreNodeClass is the class descriptor for TAcStoreNode and descendent classes.}
  TAcStoreNodeClass = class of TAcStoreNode;

  {TAcStoreNodeList manges a set of TAcStoreNodes. Every TAcStoreNode instance
   contains an own TAcStoreNodeList to store their children.}
  TAcStoreNodeList = class(TList)
    private
      FAutoFree: boolean;
      function GetItem(AIndex: integer): TAcStoreNode;
      procedure SetItem(AIndex: integer; AItem: TAcStoreNode);
      function GetItemNamed(AName: string): TAcStoreNode;
    protected
      procedure Notify(ptr: Pointer; action: TListNotification); override;
    public
      {Creates a new instance of TAcStoreNodeList.}
      constructor Create;

      {Returns the index of an element with the given unique name. If such an element
       is not found, IndexOfName returns -1.}
      function IndexOfName(AName: string): integer;

      {The "ClearStreamRef" procedure calls the "ClearStreamRef" procedure of all
       elements in the list.
       @seealso(TAcStoreNode.ClearStreamRef)}
      procedure ClearStreamRef;

      {The "FinishLoading" procedure calls the "FinishLoading" procedure of all
       elements in the list.
       @seealso(TAcStoreNode.FinishLoading)}
      procedure FinishLoading;

      {Provides read/write access on all elements in the list based on their
       index.}
      property Items[Index: integer]: TAcStoreNode read GetItem write SetItem; default;
      
      {Provides read access on elements in the list based on their unique name.
       If a element with this unique name is not found, ItemNamed returns @nil.
       @seealso(IndexOfName)
       @seealso(Items)}
      property ItemNamed[AName: string]: TAcStoreNode read GetItemNamed;

      {AutoFree describes the behaviour of TAcStoreNodeList, when an element is
       removed from the list or the list is freed. If AutoFree is "true", these elements
       will be automatically freed. The default value for AutoFree is "true".}
      property AutoFree: boolean read FAutoFree write FAutoFree;
  end;

  {TAcStoreMemState describes where the data a TAdStoreNode contains is currently
   located. TAcStoreMemState is internally used.}
  TAcStoreMemState = (
    acsmComplete, //< The data had been read from the stream or had been set manually.
    acsmInStream, //< The data had not yet been read from the stream, but the element knows where to find its data when it has to access it.
    acsmEmpty //< The element does not contain any data.
  );

  {TAcStoreNode is the base class every Andorra Common Store file is based on.
   TAcStoreNode contains the base functions for name- (unique name, path), file-
   and chilren management. TAcStoreNode allows to add new child nodes via the
   add functions. Some of these functions are able to add a fixed type child
   to the node.
   TAcStoreNodes manage their children inside a store node list. Every TAcStoreNode
   is able to contain an unlimited amount of child nodes.
   @seealso(TAcStoreNodeList)}
  TAcStoreNode = class(TAcPersistent)
    private
      FParent: TAcStoreNode;
      FName: AnsiString;
      FUniqueName: AnsiString;
      FNodes: TAcStoreNodeList;
      FInNameSearch: boolean;
      FRequired: boolean;

      FSize: int64;

      FInFS: TFileStream;

      FStreamSource: TStream;
      FStreamOffs: int64;
      FStreamSize: int64;
      FMemState: TAcStoreMemState;

      FChanged: boolean;

      function GetName: AnsiString;
      function GetUniqueName: AnsiString;
      procedure SetName(AName: AnsiString);
      function GetPath: AnsiString;
      function GetSize: Int64;
      function GetLoadSize: Int64;
      function MakeNameUnique(AName: AnsiString): AnsiString;
    protected
      class function MemPersistent: boolean;virtual;

      procedure BeforeLoad;virtual;
      procedure AfterLoad;virtual;
      procedure BeforeSave;virtual;
      procedure AfterSave;virtual;
      
      procedure WriteData(AStream: TStream);virtual;
      procedure ReadData;virtual;
      function DataSize: int64;virtual;
      function LoadSize: int64;virtual;
      procedure DoFlushMem;virtual;

      property MemState: TAcStoreMemState read FMemState write FMemState;
      property StreamSource: TStream read FStreamSource;
      property StreamOffs: int64 read FStreamOffs;
      property StreamSize: int64 read FStreamSize;
    public
      constructor Create(AParent: TAcStoreNode);virtual;
      destructor Destroy;override;    

      procedure SaveToStream(AStream: TStream);
      procedure LoadFromStream(AStream: TStream);

      procedure LoadFromFile(AFile: string);
      procedure SaveToFile(AFile: string);
      procedure FinishLoading;

      procedure Clear(AFreeChildren: boolean = false);virtual;
      procedure ClearStreamRef;

      //Functions for adding nodes
      function Add: TAcStoreNode;overload;
      function Add(AName: string): TAcStoreNode;overload;
      function Add(AName: string; AClass: TAcStoreNodeClass): TAcStoreNode;overload;

      //Functions for adding values directly
      procedure Add(AName: string; AValue: int64);overload;
      procedure Add(AName: string; AValue: Extended);overload;
      procedure Add(AName: string; AValue: string);overload;
      procedure Add(AName: string; AValue: boolean);overload;

      //Functions for reading values directrly
      function IntValue(AName: string; ADefault: int64 = 0): int64;
      function FloatValue(AName: string; ADefault: Extended = 0): Extended;
      function BoolValue(AName: string; ADefault: boolean): Boolean;
      function StringValue(AName: string; ADefault: AnsiString = ''): AnsiString;

      procedure FlushMem(ARecurse: boolean = true);    

      property Name: AnsiString read GetName write SetName;
      property UniqueName: AnsiString read GetUniqueName;
      property Path: AnsiString read GetPath;
      property Nodes: TAcStoreNodeList read FNodes;
      property Required: boolean read FRequired write FRequired;
      property Size: int64 read GetSize;
      property MemSize: int64 read GetLoadSize;
      property Changed: boolean read FChanged write FChanged;
  end;

  TAcIntegerNode = class(TAcStoreNode)
    private
      FValue: int64;
      function GetValue: int64;
      procedure SetValue(AVal: int64);
    protected
      class function MemPersistent: boolean;override;
      function DataSize: int64;override;
      procedure WriteData(AStream: TStream);override;
      procedure ReadData;override;
    published
      property Value: int64 read GetValue write SetValue;
  end;

  TAcFloatNode = class(TAcStoreNode)
    private
      FValue: Extended;
      function GetValue: Extended;
      procedure SetValue(AVal: Extended);
    protected
      class function MemPersistent: boolean;override;
      function DataSize: int64;override;
      procedure WriteData(AStream: TStream);override;
      procedure ReadData;override;
    published
      property Value: Extended read GetValue write SetValue;
  end;

  TAcStringNode = class(TAcStoreNode)
    private
      FValue: AnsiString;
      function GetValue: AnsiString;
      procedure SetValue(AVal: AnsiString);
    protected
      procedure DoFlushMem;override;
      function LoadSize: int64;override;
      procedure WriteData(AStream: TStream);override;
      procedure ReadData;override;
    published
      property Value: AnsiString read GetValue write SetValue;
  end;

  TAcBoolNode = class(TAcStoreNode)
    private
      FValue: Boolean;
      function GetValue: Boolean;
      procedure SetValue(AVal: Boolean);
    protected
      class function MemPersistent: boolean;override;
      function DataSize: int64;override;
      procedure WriteData(AStream: TStream);override;
      procedure ReadData;override;
    published
      property Value: Boolean read GetValue write SetValue;
  end;

  TAcStreamOpenMode = (
    acsoRead,
    acsoWrite
  );

  TAcStreamNode = class(TAcStoreNode)
    private
      FMem: TMemoryStream;
      FAdapt: TAcSandboxedStreamAdapter;
      FStream: TStream;
    protected
      procedure DoFlushMem;override;
      function LoadSize: int64;override;
      procedure WriteData(AStream: TStream);override;
      procedure ReadData;override;
    public
      destructor Destroy;override;
      procedure Open(AOpenMode: TAcStreamOpenMode);
      procedure Close;
    published
      property Stream: TStream read FStream;
  end;

  TAcLinkNode = class(TAcStoreNode)
    private
      FFile: AnsiString;
      FTmpList: TAcStoreNodeList;
      procedure LoadFile;
      procedure SetFile(AValue: AnsiString);
    protected
      procedure DoFlushMem;override;
      function LoadSize: int64;override;
      procedure WriteData(AStream: TStream);override;
      procedure ReadData;override;

      procedure AfterLoad;override;
      procedure BeforeSave;override;
      procedure AfterSave;override;
    public
      destructor Destroy;override;
    published
      property Filename: AnsiString read FFile write SetFile;
  end;

  TAcStoreNodeConstructor = function(AParent: TAcStoreNode): TAcStoreNode;

const
  AcStoreNodeChunk: Cardinal = $4B43444E;

{In order to save disk space, AcStoreAddAlias allows you to replace the long class
 name of a registered TAcStoreNode class by a short alias, which will be stored
 instead of the long name.}
procedure AcStoreAddAlias(AClass: TAcStoreNodeClass; AAlias: AnsiString);

implementation

var
  AcStoreAliasList: TStringList;

//Functions needed for registering

function CreateAcStoreNode(AParent: TAcStoreNode): TAcStoreNode;
begin
  result := TAcStoreNode.Create(AParent);
end;

function CreateAcIntegerNode(AParent: TAcStoreNode): TAcStoreNode;
begin
  result := TAcIntegerNode.Create(AParent);
end;

function CreateAcFloatNode(AParent: TAcStoreNode): TAcStoreNode;
begin
  result := TAcFloatNode.Create(AParent);
end;

function CreateAcStringNode(AParent: TAcStoreNode): TAcStoreNode;
begin
  result := TAcStringNode.Create(AParent);
end;

function CreateAcBoolNode(AParent: TAcStoreNode): TAcStoreNode;
begin
  result := TAcBoolNode.Create(AParent);
end;

function CreateAcStreamNode(AParent: TAcStoreNode): TAcStoreNode;
begin
  result := TAcStreamNode.Create(AParent);
end;

function CreateAcLinkNode(AParent: TAcLinkNode): TAcStoreNode;
begin
  result := TAcLinkNode.Create(AParent);
end;

procedure AcStoreAddAlias(AClass: TAcStoreNodeClass; AAlias: AnsiString);
begin
  AcStoreAliasList.Add(AClass.ClassName + '=' + AAlias);
end;

function GetAlias(AClass: TAcStoreNodeClass): AnsiString;
begin
  result := AcStoreAliasList.Values[AClass.ClassName];
end;

function GetClassFromAlias(AAlias: AnsiString): AnsiString;
var
  i: integer;
begin
  result := '';
  for i := 0 to AcStoreAliasList.Count - 1 do
  begin
    if AcStoreAliasList.ValueFromIndex[i] = AAlias then
    begin
      result := AcStoreAliasList.Names[i];
      break;
    end;
  end;
end;


{ TAcStoreNodeList }

constructor TAcStoreNodeList.Create;
begin
  inherited;

  FAutoFree := true;
end;

procedure TAcStoreNodeList.ClearStreamRef;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].ClearStreamRef;
end;

procedure TAcStoreNodeList.FinishLoading;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].FinishLoading;
end;   

function TAcStoreNodeList.IndexOfName(AName: string): integer;
var
  i: integer;
begin
  result := -1;

  for i := 0 to Count - 1 do
    if (Items[i].UniqueName = AName) then
    begin
      result := i;
      break;
    end;    
end;

function TAcStoreNodeList.GetItem(AIndex: integer): TAcStoreNode;
begin
  result := inherited Items[AIndex];
end;

function TAcStoreNodeList.GetItemNamed(AName: string): TAcStoreNode;
var
  ind: integer;
begin
  result := nil;
  ind := IndexOfName(AName);
  if ind > -1 then
    result := Items[ind];
end;

procedure TAcStoreNodeList.SetItem(AIndex: integer; AItem: TAcStoreNode);
begin
  inherited Items[AIndex] := AItem;
end;

procedure TAcStoreNodeList.Notify(ptr: Pointer; action: TListNotification);
begin
  if FAutoFree and (action = lnDeleted) then
    TAcStoreNode(ptr).Free;
end;

{ TAcStoreNode }

function TAcStoreNode.Add: TAcStoreNode;
begin
  result := TAcStoreNode.Create(self);
  Nodes.Add(result);
end;

function TAcStoreNode.Add(AName: string): TAcStoreNode;
begin
  result := TAcStoreNode.Create(self);
  result.Name := AName;
  Nodes.Add(result);
end;

function TAcStoreNode.Add(AName: string;
  AClass: TAcStoreNodeClass): TAcStoreNode;
begin
  result := AClass.Create(self);
  result.Name := AName;
  Nodes.Add(result);
end;

procedure TAcStoreNode.Add(AName: string; AValue: int64);
begin
  TAcIntegerNode(Add(AName, TAcIntegerNode)).Value := AValue;
end;

procedure TAcStoreNode.Add(AName: string; AValue: Extended);
begin
  TAcFloatNode(Add(AName, TAcFloatNode)).Value := AValue;
end;

procedure TAcStoreNode.Add(AName, AValue: string);
begin
  TAcStringNode(Add(AName, TAcStringNode)).Value := AValue;        
end;

procedure TAcStoreNode.Add(AName: string; AValue: boolean);
begin
  TAcBoolNode(Add(AName, TAcBoolNode)).Value := AValue;
end;


function TAcStoreNode.IntValue(AName: string; ADefault: int64): int64;
var
  ind: integer;
begin
  //Search for an item with the given name
  ind := Nodes.IndexOfName(AName);

  //If an item has been found, check whether it is an integer node
  if (ind > -1) and (Nodes[ind] is TAcIntegerNode) then
    result := TAcIntegerNode(Nodes[ind]).Value
  else
    result := ADefault;
end;

function TAcStoreNode.FloatValue(AName: string; ADefault: Extended): Extended;
var
  ind: integer;
begin
  //Search for an item with the given name
  ind := Nodes.IndexOfName(AName);

  //If an item has been found, check whether it is an float node
  if (ind > -1) and (Nodes[ind] is TAcFloatNode) then
    result := TAcFloatNode(Nodes[ind]).Value
  else
    result := ADefault;
end; 

procedure TAcStoreNode.FlushMem(ARecurse: boolean);
var
  i: Integer;
begin
  if not Changed then
  begin
    DoFlushMem;
    MemState := acsmInStream;
  end;

  if ARecurse then
    for i := 0 to Nodes.Count - 1 do
      Nodes[i].FlushMem(true);
end;

function TAcStoreNode.StringValue(AName: string; ADefault: AnsiString): AnsiString;
var
  ind: integer;
begin
  //Search for an item with the given name
  ind := Nodes.IndexOfName(AName);

  //If an item has been found, check whether it is an string node
  if (ind > -1) and (Nodes[ind] is TAcStringNode) then
    result := TAcStringNode(Nodes[ind]).Value
  else
    result := ADefault;
end;

function TAcStoreNode.BoolValue(AName: string; ADefault: boolean): Boolean;
var
  ind: integer;
begin
  //Search for an item with the given name
  ind := Nodes.IndexOfName(AName);

  //If an item has been found, check whether it is an boolean node
  if (ind > -1) and (Nodes[ind] is TAcBoolNode) then
    result := TAcBoolNode(Nodes[ind]).Value
  else
    result := ADefault;
end;


procedure TAcStoreNode.Clear(AFreeChildren: boolean = false);
begin
  //If the "AFreeChildren" parameter is true, delete all children elements
  if AFreeChildren then
    Nodes.Clear;

  FMemState := acsmEmpty;

  ClearStreamRef;
end;

procedure TAcStoreNode.ClearStreamRef;
begin
  FStreamSource := nil;
  FStreamOffs := -1;
  FStreamSize := -1;

  FMemState := acsmEmpty;

  FNodes.ClearStreamRef;
end;

constructor TAcStoreNode.Create(AParent: TAcStoreNode);
begin
  inherited Create;

  FParent := AParent;
  FNodes := TAcStoreNodeList.Create;
  FRequired := false;


  Clear;
end;

destructor TAcStoreNode.Destroy;
begin
  Clear(true);
  
  FNodes.Free;

  //Free the file streams if they were created
  if Assigned(FInFS) then
    FreeAndNil(FInFS);

  inherited;
end;

procedure TAcStoreNode.FinishLoading;
begin
  if FMemState = acsmInStream then
    ReadData;

  Nodes.FinishLoading;

  //If the data has been loaded from this instance, then delete the in file stream.
  if Assigned(FInFS) then
    FreeAndNil(FInFS);
end;

function TAcStoreNode.GetLoadSize: Int64;
var
  i: integer;
begin
  result := LoadSize;
  
  for i := 0 to nodes.Count - 1 do
    result := result + nodes[i].MemSize;
end;

function TAcStoreNode.GetName: AnsiString;
var
  id: integer;
begin
  //No name has been specified for this element, create an unique one
  if (FName = '') and not FInNameSearch then
  begin
    if FParent = nil then
      FName := 'root'
    else begin
      id := FParent.Nodes.IndexOf(self);
      FName := MakeNameUnique('item_' + IntToStr(id));      
    end;
  end;

  result := FName;
end;

function TAcStoreNode.GetPath: AnsiString;
begin
  if FParent = nil then
    result := UniqueName
  else
    result := FParent.Path + '\' + UniqueName;
end;

function TAcStoreNode.GetSize: Int64;
var
  i: integer;
begin
  if (StreamSource <> nil) and (MemState = acsmInStream) then
    result := StreamSize
  else
    result := DataSize;

  for i := 0 to nodes.Count - 1 do
    result := result + nodes[i].Size;
end;

function TAcStoreNode.GetUniqueName: AnsiString;
begin
  result := FUniqueName;
end;

function TAcStoreNode.MakeNameUnique(AName: AnsiString): AnsiString;
var
  i: integer;
  tmp: string;
begin
  result := '';
  FInNameSearch := true;  
  
  if (FParent = nil) or (AName = FName) then
    result := AName
  else begin
    tmp := AName;
    i := 1;
    repeat
      if FParent.Nodes.IndexOfName(tmp) <> -1 then
        tmp := AName + '_' + IntToStr(i)
      else begin
        result := tmp;
        break;
      end;
      i := i + 1;
    until false;
  end;
  
  FInNameSearch := false;
end;

class function TAcStoreNode.MemPersistent: boolean;
begin
  result := false;
end;

procedure TAcStoreNode.LoadFromFile(AFile: string);
begin
  if Assigned(FInFS) then
    FreeAndNil(FInFS);
  
  FInFS := TFileStream.Create(AFile, fmOpenRead or fmShareDenyWrite);
  LoadFromStream(FInFS);
end;

procedure TAcStoreNode.SaveToFile(AFile: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AFile, fmCreate);
  try
    SaveToStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TAcStoreNode.LoadFromStream(AStream: TStream);
var
  id, cls: AnsiString;
  chk: Cardinal;
  len8: Byte;
  len16: Word;
  len64: int64;
  bool8: boolean;
  count, i: Integer;
  offs: int64;
  constr: Pointer;
  node: TAcStoreNode;
  pos: int64;
begin
  BeforeLoad;
  
  //Clear this node and all its children
  Clear(true);

  //Delete the InFS if we aren't currently loading from it
  if (AStream <> FInFS) and Assigned(FInFS) then
    FreeAndNil(FInFS);

  //Read the node chunk
  AStream.Read(chk, 4);
  if chk <> AcStoreNodeChunk then
    raise EAcStoreNodeLoad.Create(MsgInvalidStoreNodeChunk);    

  //Read the name
  AStream.Read(len16, 2);
  SetLength(id, len16);
  AStream.Read(id[1], len16);
  FUniqueName := MakeNameUnique(id);
  FName := id;

  //Read the node data size
  AStream.Read(FStreamSize, 8);   
  FStreamSource := AStream;
  FStreamOffs := AStream.Position;
  FMemState := acsmInStream;

  //Skip the node data
  AStream.Seek(FStreamSize, soFromCurrent);

  //Read the children count
  AStream.Read(count, 4);
  for i := 0 to count - 1 do
  begin
    //Read wether the following node is required
    AStream.Read(bool8, 1);

    //Read the class id
    AStream.Read(len8, 1);
    SetLength(id, len8);
    AStream.Read(id[1], len8);

    //Read the node size
    AStream.Read(len64, 8);

    //Calculate the end of this node
    offs := AStream.Position + len64;

    //Check wether this id is an alias
    cls := GetClassFromAlias(id);
    if cls <> '' then
      id := cls;
      
    constr := AcRegSrv.GetConstructor(id);
    if (constr = nil) and not Required then
      constr := @CreateAcStoreNode;
    
    if constr <> nil then
    begin
      node := TAcStoreNodeConstructor(constr)(self);
      node.Required := bool8;
      node.LoadFromStream(AStream);

      Nodes.Add(node);
    end else
      raise EAcStoreNodeLoad.Create(MsgInvalidStoreNodeClass);

    //Compare the position we have calculated above to our current position
    if AStream.Position <> offs then
      raise EAcStoreNodeLoad.Create(MsgInvalidFileOffset);
  end;

  //Call the after load routine. As it may change the file offset, simply temporarily
  //store it.
  pos := AStream.Position;
  try
    AfterLoad;
  finally
    AStream.Position := pos;
  end;
end;

function TAcStoreNode.LoadSize: int64;
begin
  if (MemState = acsmComplete) or (MemPersistent) then
    result := size
  else
    result := 0;  
end;

type
  TAcSaveStrProc = procedure(AStream: TStream) of object;

procedure WriteWithSize64(ATar: TStream; AProc: TAcSaveStrProc);
var
  len, offs1, offs2: int64;
begin
  //Get the current stream position
  offs1 := ATar.Position;

  //Write "zero" as the current size
  len := 0;
  ATar.Write(len, 8);

  //Write the data
  AProc(ATar);

  //Get the current position
  offs2 := ATar.Position;

  //Seek back
  ATar.Position := offs1;

  //Write the real size
  len := offs2 - offs1 - 8;
  ATar.Write(len, 8);

  //Seek to the end of the stream
  ATar.Position := offs2;
end;

procedure TAcStoreNode.SaveToStream(AStream: TStream);
var
  id: AnsiString;
  len8: Byte;
  len16: Word;
  bool8: boolean;
  count, i: Integer;
begin
  BeforeSave;
  
  //Write the node chunk
  AStream.Write(AcStoreNodeChunk, 4);

  //Write the node name to the stream
  id := Name;
  len16 := Length(id);
  AStream.Write(len16, 2);
  AStream.Write(id[1], len16);

  //Write the node data
  WriteWithSize64(AStream, WriteData);

  //Write the node's children count
  count := FNodes.Count;
  AStream.Write(count, 4);
  for i := 0 to count - 1 do
  begin
    //Write whether the node is necessary
    bool8 := Nodes[i].Required;
    AStream.Write(bool8, 1);

    //Write the node classid
    id := GetAlias(TAcStoreNodeClass(Nodes[i].ClassType));
    if id = '' then
      id := Nodes[i].ClassName;
      
    len8 := Length(id);
    AStream.Write(len8, 1);
    AStream.Write(id[1], len8);

    //Write the node
    WriteWithSize64(AStream, Nodes[i].SaveToStream);
  end;

  AfterSave;
end;

procedure TAcStoreNode.SetName(AName: AnsiString);
begin
  FUniqueName := MakeNameUnique(AName);
  FName := AName;
end;

procedure TAcStoreNode.ReadData;
begin
  FMemState := acsmComplete;
  FSize := FStreamSize;
  FChanged := false;
end;

function TAcStoreNode.DataSize: int64;
begin
  //If the data is in the stream, the size of the node is equal to the size
  //of the data in the stream
  if MemState = acsmInStream then
    result := StreamSize
  else
    //If the data is completely in the memory, the size of the node is equal
    //the the loaded size
    result := LoadSize;
end;

procedure TAcStoreNode.WriteData(AStream: TStream);
begin
  if FMemState = acsmInStream then
    ReadData;
  FChanged := false;
end;

procedure TAcStoreNode.DoFlushMem;
begin
  //
end;

procedure TAcStoreNode.AfterLoad;
begin
  //
end;

procedure TAcStoreNode.AfterSave;
begin
  //
end;

procedure TAcStoreNode.BeforeLoad;
begin
  //
end;

procedure TAcStoreNode.BeforeSave;
begin
  //
end;


{ TAcIntegerNode }

function TAcIntegerNode.DataSize: int64;
begin
  result := SizeOf(FValue);
end;

function TAcIntegerNode.GetValue: int64;
begin
  if MemState = acsmInStream then
    ReadData;

  result := FValue;
end;

class function TAcIntegerNode.MemPersistent: boolean;
begin
  result := true;
end;

procedure TAcIntegerNode.SetValue(AVal: int64);
begin
  FValue := AVal;
  MemState := acsmComplete;
  Changed := true;
end;

procedure TAcIntegerNode.ReadData;
begin
  StreamSource.Position := StreamOffs;
  StreamSource.Read(FValue, SizeOf(FValue));

  inherited;
end;

procedure TAcIntegerNode.WriteData(AStream: TStream);
begin
  inherited;

  AStream.Write(FValue, SizeOf(FValue));
end;

{ TAcFloatNode }

function TAcFloatNode.DataSize: int64;
begin
  result := SizeOf(FValue);
end;

function TAcFloatNode.GetValue: Extended;
begin
  if MemState = acsmInStream then
    ReadData;

  result := FValue;
end;

class function TAcFloatNode.MemPersistent: boolean;
begin
  result := true;
end;

procedure TAcFloatNode.SetValue(AVal: Extended);
begin
  FValue := AVal;
  MemState := acsmComplete;
  Changed := true;
end;

procedure TAcFloatNode.ReadData;
begin
  StreamSource.Position := StreamOffs;
  StreamSource.Read(FValue, SizeOf(FValue));

  inherited;
end;

procedure TAcFloatNode.WriteData(AStream: TStream);
begin
  inherited;

  AStream.Write(FValue, SizeOf(FValue));
end;

{ TAcStringNode }

procedure TAcStringNode.DoFlushMem;
begin
  SetLength(FValue, 0);
end;

function TAcStringNode.GetValue: AnsiString;
begin
  if MemState = acsmInStream then
    ReadData;

  result := FValue;
end;

function TAcStringNode.LoadSize: int64;
begin
  result := Length(FValue) + 4;
end;

procedure TAcStringNode.ReadData;
var
  len: Integer;
begin
  StreamSource.Position := StreamOffs;
  StreamSource.Read(len, 4);
  SetLength(FValue, len);
  StreamSource.Read(FValue[1], len);

  inherited;
end;

procedure TAcStringNode.SetValue(AVal: AnsiString);
begin
  FValue := AVal;
  MemState := acsmComplete;
  Changed := true;
end;

procedure TAcStringNode.WriteData(AStream: TStream);
var
  len: Integer;
begin
  inherited;

  len := Length(FValue);
  AStream.Write(len, 4);
  AStream.Write(FValue[1], len);
end;

{ TAcBoolNode }

function TAcBoolNode.DataSize: int64;
begin
  result := SizeOf(FValue);
end;

function TAcBoolNode.GetValue: Boolean;
begin
  if MemState = acsmInStream then
    ReadData;

  result := FValue;
end;

class function TAcBoolNode.MemPersistent: boolean;
begin
  result := true;
end;

procedure TAcBoolNode.ReadData;
begin
  StreamSource.Position := StreamOffs;
  StreamSource.Read(FValue, SizeOf(FValue));
  inherited;
end;

procedure TAcBoolNode.SetValue(AVal: Boolean);
begin
  FValue := AVal;
  MemState := acsmComplete;
  Changed := true;
end;

procedure TAcBoolNode.WriteData(AStream: TStream);
begin
  inherited;
  AStream.Write(FValue, SizeOf(FValue));
end;

{ TAcStreamNode }

destructor TAcStreamNode.Destroy;
begin
  if FMem <> nil then
    FreeAndNil(FMem);

  if FMem <> nil then
    FreeAndNil(FMem);


  inherited;
end;

procedure TAcStreamNode.DoFlushMem;
begin
  FStream := nil;

  if FAdapt <> nil then  
    FreeAndNil(FAdapt);

  if FMem <> nil then  
    FreeAndNil(FMem);
end;

function TAcStreamNode.LoadSize: int64;
begin
  result := 0;
  if FMem <> nil then
    result := FMem.Size;
end;

procedure TAcStreamNode.Open(AOpenMode: TAcStreamOpenMode);
begin
  if (AOpenMode = acsoRead) then
  begin
    if MemState = acsmInStream then
    begin
      //The node content has not been read to memory now. We're using TAcStreamAdapter
      //to provide "sandbox access" on the source stream
      FAdapt := TAcSandboxedStreamAdapter.Create(FStreamSource, FStreamOffs,
        FStreamSize);
      FStream := FAdapt;
    end else
    begin
      //The stream has been read to memory. Simply assign FMem to FStream
      FStream := FMem;
    end;
  end
  else if (AOpenMode = acsoWrite) then
  begin
    //Write access can only be performed in memory. Flush all other references now.
    FlushMem;

    //Create an memorystream and assign FMem to FStream
    FMem := TMemoryStream.Create;
    FStream := FMem;

    //As all data is now in the memory, set MemState to acsmComplete
    MemState := acsmComplete;

    Changed := true;
  end;  
end;

procedure TAcStreamNode.Close;
begin
  if (FMem <> nil) and (not Changed) then
  begin
    FreeAndNil(FMem);
    FStream := nil;
  end;

  if (FAdapt <> nil) then
  begin
    FreeAndNil(FAdapt);
    FStream := nil;
  end;
end;

procedure TAcStreamNode.ReadData;
begin
  DoFlushMem;

  StreamSource.Position := StreamOffs;
  FMem := TMemoryStream.Create;
  FMem.CopyFrom(StreamSource, StreamSize);
  FStream := FMem;

  inherited;
end;

procedure TAcStreamNode.WriteData(AStream: TStream);
begin
  inherited;
  if FMem <> nil then  
    FMem.SaveToStream(AStream);
end;

{ TAcLinkNode }

destructor TAcLinkNode.Destroy;
begin
  if FTmpList <> nil then
    FreeAndNil(FTmpList);

  inherited;
end;

procedure TAcLinkNode.AfterLoad;
begin
  ReadData;
  LoadFile;
end;

procedure TAcLinkNode.AfterSave;
var
  i: integer;
begin
  if FTmpList <> nil then
  begin
    for i := FTmpList.Count - 1 downto 0 do
    begin
      FNodes.Add(FTmpList[i]);
      FTmpList.Delete(i);
    end;
    FreeAndNil(FTmpList);
  end;

  FNodes.AutoFree := true;
end;

procedure TAcLinkNode.BeforeSave;
var
  i: integer;
begin
  if FTmpList <> nil then
    FreeAndNil(FTmpList);

  FTmpList := TAcStoreNodeList.Create;
  FTmpList.AutoFree := false;
  FNodes.AutoFree := false;

  for i := FNodes.Count - 1 downto 0 do
  begin
    FTmpList.Add(FNodes[i]);
    FNodes.Delete(i);
  end;
end;

procedure TAcLinkNode.LoadFile;
var
  sr: TSearchRec;
  node: TAcStoreNode;
begin
  //Clear all child nodes
  Nodes.Clear;
  
  if FFile <> '' then
  begin
    if FindFirst(FFile, faAnyFile and (not faDirectory), sr) = 0 then
    begin
      repeat
        node := TAcStoreNode.Create(self);
        try
          node.LoadFromFile(ExtractFilePath(FFile) + sr.Name);
          node.Name := ExtractFileName(sr.Name);
          FNodes.Add(node);
        except
          node.Free;
        end;
      until FindNext(sr) <> 0;
    end;

    FindClose(sr);
  end;
end;

procedure TAcLinkNode.SetFile(AValue: AnsiString);
begin
  if AValue <> FFile then
  begin
    FFile := AValue;
    FChanged := true;
    FMemState := acsmComplete;

    FNodes.Clear;

    LoadFile;
  end;
end;

procedure TAcLinkNode.DoFlushMem;
begin
  //There is nothing to flush
end;

function TAcLinkNode.LoadSize: int64;
begin
  result := Length(FFile) + 4;
end;

procedure TAcLinkNode.ReadData;
var
  len: Integer;
begin
  StreamSource.Position := StreamOffs;
  StreamSource.Read(len, 4);
  SetLength(FFile, len);
  StreamSource.Read(FFile[1], len);

  inherited;
end;

procedure TAcLinkNode.WriteData(AStream: TStream);
var
  len: Integer;
begin
  inherited;

  len := Length(FFile);
  AStream.Write(len, 4);
  AStream.Write(FFile[1], len);
end;

initialization
  AcRegSrv.RegisterClass(TAcStoreNode, @CreateAcStoreNode);
  AcRegSrv.RegisterClass(TAcIntegerNode, @CreateAcIntegerNode);
  AcRegSrv.RegisterClass(TAcFloatNode, @CreateAcFloatNode);
  AcRegSrv.RegisterClass(TAcStringNode, @CreateAcStringNode);
  AcRegSrv.RegisterClass(TAcBoolNode, @CreateAcBoolNode);
  AcRegSrv.RegisterClass(TAcStreamNode, @CreateAcStreamNode);
  AcRegSrv.RegisterClass(TAcLinkNode, @CreateAcLinkNode);


  AcStoreAliasList := TStringList.Create;

  AcStoreAddAlias(TAcStoreNode, '/');
  AcStoreAddAlias(TAcIntegerNode, 'i');
  AcStoreAddAlias(TAcFloatNode, 'f');
  AcStoreAddAlias(TAcStringNode, 's');
  AcStoreAddAlias(TAcBoolNode, 'b');
  AcStoreAddAlias(TAcStreamNode, 'x');
  AcStoreAddAlias(TAcLinkNode, 'l'); 

finalization
  AcStoreAliasList.Free;

end.
