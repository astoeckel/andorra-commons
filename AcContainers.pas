{This unit contains some container classes for the every day use in andorra 2d.}
unit AcContainers;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface
   
type
  {Pointer on TAcLinkedListItem}
  PAcLinkedListItem = ^TAcLinkedListItem;
  
  {A list item used in TAcLinked list.}
  TAcLinkedListItem = record
    next:PAcLinkedListItem;{<Pointer to the next element}
    data:Pointer;{<Pointer to the stored object.}
  end;

  {Pointer on a TAcLinkedList.}
  PAcLinkedList = ^TAcLinkedList;
  {A linked list class.}
  TAcLinkedList = class
    private
      FStart,FLast:PAcLinkedListItem;
      FCount:Integer;

      FIterItem:PAcLinkedListItem;

      function GetItem(AIndex:integer):Pointer;
      procedure SetItem(AIndex:integer;AValue:Pointer);
    protected

    public
      {Don't now what this is for...}
      Tag:integer;
      {Returns the count of elements in the list}
      property Count:Integer read FCount;
      {Direct access the the items. Don't use in  time-critical cases.}
      property Items[Index:integer]:Pointer read GetItem write SetItem; default;

      {Creates an instance of TAcLinkedList.}
      constructor Create;
      {Destroys the instance of TAcLinkedList}
      destructor Destroy;override;

      {Adds an item to the list and returns its position.}
      function Add(AItem:Pointer):Integer;
      {Inserts a item on a specific place in the list.}
      procedure Insert(AIndex:integer;AItem:Pointer);
      {Removes an item from the list.}
      function Remove(AItem:Pointer):boolean;
      {Delets an item with a specific index from the list.}
      function Delete(AIndex:integer):boolean;
      {Returns the index of a specific item.}
      function IndexOf(AItem:Pointer):integer;
      {Pointer to the first item.} 
      function First:Pointer;
      {Pointer to the last item.}
      function Last:Pointer;

      {Deletes all entries in the linked list.}
      procedure Clear;

      {Resets the iterator.}
      procedure StartIteration;
      {Returns true, if the iterator reached the end of the list.}
      function ReachedEnd:boolean;
      {Returns the current item of the iterator and steps to the next item.}
      function GetCurrent:Pointer;
  end;

  {An abstract class for the use in TAcMap. Represents a key in the hashmap.}
  TAcMapKey = class
    public
      {Returns the hash of the object.}
      function Hash:integer;virtual;abstract;
      {Returns, whether this key is equal to another one.}
      function Equal(AItem:TAcMapKey):boolean;virtual;abstract;
  end;

  {Pointer on TAcMapPair.}
  PAcMapPair = ^TAcMapPair;
  
  {Represents a key and a value stored in the hash map.}
  TAcMapPair = record
    Key:TAcMapKey;{The key of the value}
    Value:TObject;{The value}
  end;

  {A simple bucket hash map class.}
  TAcMap = class
    private
      FCapacity: integer;
      FData: Pointer;
      FMemSize: Cardinal;
      procedure Rehash(ACapacity: integer);
    protected      
      FCount: integer;
      procedure FreeMemory(AFreeItems: boolean = false);
      property Data:Pointer read FData write FData;
    public
      {Creates a new instance of TAcMap. ACapacity specifies the size of the data array the elements are stored in.}
      constructor Create(ACapacity: integer=128);
      {Destroys the instance of TAcMap}
      destructor Destroy;override;

      {Inserts a key connected to a value in the hash map.}
      function Insert(AKey:TAcMapKey; AValue:TObject):Boolean;
      {Returns the stored object or nil, if the object is not found. AKey specifies the key you search with.}
      function GetValue(AKey:TAcMapKey):TObject;
      {Removes the object connected to the key from the hash map}
      function Remove(AKey:TAcMapKey):Boolean;

      {Returns the count of elements in the list}
      property Count: integer read FCount;
      {Returns the capacity of the data array.}
      property Capacity: integer read FCapacity;
  end;

const
  UpperRehashBound = 1;
  LowerRehashBound = 0.25;
  RehashFactor = 2;


implementation

{ TAcLinkedList }

constructor TAcLinkedList.Create;
begin
  inherited Create;

  //Initialize Varibales
  FCount := 0;
  FStart := nil;
  FLast := nil;
end;

destructor TAcLinkedList.Destroy;
begin
  //Free all elements
  Clear;
  
  inherited Destroy;
end;

function TAcLinkedList.Add(AItem: Pointer): Integer;
var
  PItem:PAcLinkedListItem;
begin
  //Create a new element
  New(PItem);
  PItem^.data := AItem;
  
  //The new element hasn't got a next element
  PItem^.next := nil;

  //The next element of the last element is the new item
  if FLast <> nil then
  begin
    FLast^.next := PItem;
  end;

  //The new item now is the last element
  FLast := PItem;

  if FCount = 0 then
  begin
    //Because there is no other element, this new element is the first element
	  FStart := PItem;
  end;

  //Return the index of the new element
  result := FCount;
  FCount := FCount + 1;
end;

function TAcLinkedList.Delete(AIndex: Integer): boolean;
var
  i:integer;
  PItem:PAcLinkedListItem;
  PNext,PPrev:PAcLinkedListItem;
begin
  result := false;
  if (AIndex >= FCount) or (AIndex < 0) then exit;

  PItem := FStart;
  PPrev := nil;
  for i := 0 to AIndex-1 do
  begin
    PPrev := PItem;
    PItem := PItem^.next;
  end;

  if PItem <> nil then
  begin
    PNext := PItem^.next;

    Dispose(PItem);
    result := true;

    if AIndex = 0 then
    begin
      FStart := PNext;
    end
    else
    begin
      PPrev^.next := PNext;
    end;
    
    if AIndex = FCount - 1 then
    begin
      FLast := PPrev;
    end;

    FCount := FCount - 1;
  end;
end;

function TAcLinkedList.IndexOf(AItem: Pointer): integer;
var
  i:integer;
  PItem:PAcLinkedListItem;
begin
  PItem := FStart;
  i := 0;
  while (PItem <> nil) and (PItem^.data <> AItem) do
  begin
    PItem := PItem^.next;
    i := i + 1;
  end;

  if PItem = nil then
    result := -1
  else
    result := i;
end;

procedure TAcLinkedList.Insert(AIndex: integer; AItem: Pointer);
var
  i:integer;
  PItem,PAcd,PPrev:PAcLinkedListItem;
begin

  if AIndex < 0 then
  begin
    AIndex := 0;
  end;
  
  if AIndex >= Count then
  begin
    Add(AItem);
    exit;
  end;

  PItem := FStart;
  PPrev := nil;
  for i := 0 to AIndex-1 do
  begin
    PPrev := PItem;
    PItem := PItem^.next;
  end;

  New(PAcd);
  PAcd^.data := AItem;
  PAcd^.next := PItem;

  if PPrev = nil then
  begin
    FStart := PAcd;
  end
  else
  begin
    PPrev^.next := PAcd;
  end;

  FCount := FCount + 1;
end;

function TAcLinkedList.Remove(AItem: Pointer): boolean;
begin
  result := Delete(IndexOf(AItem));
end;

function TAcLinkedList.GetItem(AIndex: integer): Pointer;
var
  i:integer;
  PItem:PAcLinkedListItem;
begin
  if (AIndex >= Count) or (AIndex < 0) then
  begin
    result := nil;
  end
  else
  begin
    PItem := FStart;

    for i := 0 to AIndex-1 do
    begin
      PItem := PItem^.next;
    end;

    result := PItem^.data;
  end;
end;

procedure TAcLinkedList.SetItem(AIndex: integer; AValue: Pointer);
var
  i:integer;
  PItem:PAcLinkedListItem;
begin
  if (AIndex < Count) and (AIndex > 0) then
  begin
    PItem := FStart;

    for i := 0 to AIndex-1 do
    begin
      PItem := PItem^.next;
    end;

    PItem^.data := AValue;
  end;
end;

procedure TAcLinkedList.StartIteration;
begin
  FIterItem := FStart;
end;

function TAcLinkedList.GetCurrent: Pointer;
begin
  result := FIterItem^.data;
  FIterItem := FIterItem^.next;
end;

function TAcLinkedList.ReachedEnd: boolean;
begin
  result := FIterItem = nil;
end;

function TAcLinkedList.First: Pointer;
begin
  result := nil;
  if FStart <> nil then
    result := FStart^.data;
end;

function TAcLinkedList.Last: Pointer;
begin
  result := nil;
  if FLast <> nil then
    result := FLast^.data;
end;

procedure TAcLinkedList.Clear;
var
  p1, p2: PAcLinkedListItem;
begin
  //Get the first element
  p1 := FStart;

  //Iterate trough the list
  while p1 <> nil do
  begin
    //Save the element next to the current element
    p2 := p1^.next;
    //Free the current element
    Dispose(p1);
    //Go on iterating through the list using the next element
    p1 := p2;
  end;

  //Set everything to the initial settings
  FStart := nil;
  FLast := nil;
  FIterItem := nil;
  FCount := 0;
end;

{ TAcMap }

constructor TAcMap.Create(ACapacity: integer);
begin
  inherited Create;

  FData := nil;
  Rehash(ACapacity);
  FCount := 0;
end;

destructor TAcMap.Destroy;
begin
  FreeMemory(true);
  inherited;
end;

procedure TAcMap.FreeMemory(AFreeItems: boolean);
var
  i: integer;
  PList: PAcLinkedList;
  PItem: PAcMapPair;
begin
  if FData <> nil then
  begin
    PList := FData;
    for i := 0 to FCapacity-1 do
    begin
      if AFreeItems then
      begin
        PList^.StartIteration;
        while not PList^.ReachedEnd do
        begin
          PItem := PList^.GetCurrent;
          Dispose(PItem);
        end;
      end;

      PList^.Free;
      inc(PList);
    end;
    FreeMem(FData,FMemSize);
    FData := nil;
  end;
end;

function TAcMap.GetValue(AKey: TAcMapKey): TObject;
var
  PItem:PAcMapPair;
  Pos:integer;
  PList:PAcLinkedList;
begin
  result := nil;

  //Search List Element
  Pos := (Abs(AKey.Hash) mod FCapacity);
  PList := FData;
  inc(PList,Pos);

  with PList^ do
  begin
    StartIteration;
    while not ReachedEnd do
    begin
      PItem := PAcMapPair(GetCurrent);
      if PItem^.Key.Equal(AKey) then
      begin
        result := PItem^.Value;
        exit;
      end;
    end;
  end;
end;

function TAcMap.Insert(AKey: TAcMapKey; AValue: TObject): Boolean;
var
  PItem:PAcMapPair;
  Pos:integer;
  PList:PAcLinkedList;  
begin
  result := false;

  //Search List Element
  Pos := (Abs(AKey.Hash) mod FCapacity);
  PList := FData;
  inc(PList,Pos);

  //Check wether key already exists - replace value if necessary
  PList^.StartIteration;
  while not PList^.ReachedEnd do
  begin
    PItem := PAcMapPair(PList^.GetCurrent);
    if PItem^.Key.Equal(AKey) then
    begin
      PItem^.Value := AValue;
      exit;
    end;
  end;

  //Key not found, insert item
  New(PItem);
  PItem^.Key := AKey;
  PItem^.Value := AValue;
  PList^.Add(PItem);    

  FCount := FCount + 1;
  if FCount >= FCapacity * UpperRehashBound then
    Rehash(round(FCapacity * RehashFactor));
end;

procedure TAcMap.Rehash(ACapacity: integer);
var
  PTmp:Pointer;
  PList1,PList2:PAcLinkedList;
  Pos:integer;
  i:integer;
  PCurItem:PAcMapPair;
begin
  //Reserve new memory
  FMemSize := SizeOf(PAcLinkedList)*ACapacity;

  {$IFDEF FPC}PTmp := nil;{$ENDIF}

  GetMem(PTmp, FMemSize);

  //Create lists
  PList2 := PTmp;
  for i := 0 to ACapacity - 1 do
  begin
    PList2^ := TAcLinkedList.Create;
    PList2^.Tag := i;
    inc(PList2);
  end;

  //Copy elements into new array
  PList1 := FData;
  for i := 0 to FCapacity - 1 do
  begin
    PList1^.StartIteration;
    while not PList1^.ReachedEnd do
    begin
      PCurItem := PList1^.GetCurrent;

      //Insert element
      PList2 := PTmp;
      Pos := (Abs(PCurItem^.Key.Hash) mod ACapacity);
      Inc(PList2, Pos);

      PList2^.Add(PCurItem);
    end;
    Inc(PList1);
  end;

  //Free Memory and lists
  FreeMemory;

  //Set new values
  FData := PTmp;
  FCapacity := ACapacity;
end;

function TAcMap.Remove(AKey: TAcMapKey): Boolean;
var
  PItem:PAcMapPair;
  Pos:integer;
  PList:PAcLinkedList;  
begin
  result := false;

  //Search List Element
  Pos := (Abs(AKey.Hash) mod FCapacity);
  PList := FData;
  inc(PList,Pos);

  PList^.StartIteration;
  while not PList^.ReachedEnd do
  begin
    PItem := PAcMapPair(PList^.GetCurrent);
    if PItem^.Key.Equal(AKey) then
    begin
      PList^.Remove(PItem);      
      Dispose(PItem);
      result := true;
      FCount := FCount - 1;

      if FCount < FCapacity * LowerRehashBound  then
        Rehash(round(FCapacity / RehashFactor));
        
      exit;
    end;
  end;
end;

end.
