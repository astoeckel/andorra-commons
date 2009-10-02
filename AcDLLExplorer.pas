unit AcDLLExplorer;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, Classes,
  AcPersistent, AcSysUtils;

type
  {$IFDEF CPU64}
  THandle = int64;
  {$ENDIF}

  TAcPluginDLL = class
    private
      FSourceID: integer;
      FHandle: THandle;
      FDLLInit: TAcDLLInitProc;
      FDLLFinalize: TAcDLLFinalizeProc;
      FDLLExport: TAcDLLExportClassesProc;
      FDLLMemMgt: TAcDLLMemoryManagerProc;
      FClassEntries: TList;
      FFileName: string;
      FRegisterd: boolean;
      FMemMgt: boolean;
      FOldMemMgr: TAcMemoryManagerBuf;
      FOldMemMgrSize: Byte;
      function GetLoaded: boolean;
      procedure ClearClassEntries;
    public
      constructor Create;
      destructor Destroy;override;
      
      function LoadPlugin(AName: string): boolean;
      function RegisterPluginClasses(AClassType: TAcPersistentClass): integer;
      function HasClass(AClass: TAcPersistentClass): boolean;
      procedure UnregisterPluginClasses;
      procedure UnloadPlugin;

      property SourceID: integer read FSourceID;
      property DLLHandle: THandle read FHandle;
      property Loaded: boolean read GetLoaded;
      property ClassEntries: TList read FClassEntries;
      property FileName: string read FFileName;
  end;
  
  TAcDLLExplorer = class
    public
      procedure GetPlugins(Plugins: TStrings; const Dir: string;
        const Extension: string='');overload;
      procedure GetPluginsEx(Plugins: TStrings; const Dir: string;
        BaseClass: TAcPersistentClass; const Extension: string='');overload;
  end;

  TAcPluginDLLList = class(TList)
    private
      function GetItem(AIndex: integer): TAcPluginDLL;
    protected
      procedure Notify(ptr: Pointer; action: TListNotification);override;
    public
      property Items[AIndex: integer]: TAcPluginDLL read GetItem; default;
  end;

  TAcPluginManager = class
    private
      FPlugins: TAcPluginDLLList;
    public
      constructor Create;
      destructor Destroy;override;
      
      procedure LoadPlugins(AList: TStrings; AClass: TAcPersistentClass);
      function LoadPlugin(AName: string; AClass: TAcPersistentClass): TAcPluginDLL;
      procedure AutoLoad;overload;
      procedure AutoLoad(BaseClass: TAcPersistentClass);overload;
      procedure AutoLoad(const Dir: string; const Extension: string = '');overload;
      procedure AutoLoad(const Dir: string; BaseClass: TAcPersistentClass;
        const Extension: string = '');overload;

      property Plugins: TAcPluginDLLList read FPlugins;
  end;

implementation

const
  {$IFDEF WIN32}
    ext = '.dll';
  {$ELSE}
    ext = '.so';
  {$ENDIF}

{ TAcPluginDLL }

constructor TAcPluginDLL.Create;
begin
  inherited;

  FHandle := 0;
  FSourceID := -1;
  FClassEntries := TList.Create;
  FRegisterd := false;
end;

destructor TAcPluginDLL.Destroy;
begin
  UnloadPlugin;

  FreeAndNil(FClassEntries);
  
  inherited;
end;

procedure TAcPluginDLL.ClearClassEntries;
var
  i: Integer;
begin
  for i := 0 to FClassEntries.Count - 1 do
    Dispose(FClassEntries[i]);
end;


function TAcPluginDLL.GetLoaded: boolean;
begin
  result := (FHandle <> 0);
end;

function TAcPluginDLL.HasClass(AClass: TAcPersistentClass): boolean;
var
  i: integer;
  entry: PAcRegisteredClassEntry;
begin
  result := false;
  
  for i := 0 to FClassEntries.Count - 1 do
  begin
    entry := PAcRegisteredClassEntry(FClassEntries[i]);
    if AcIsClass(AClass.ClassName, entry^.IdentStr) then
    begin
      result := true;
      exit;
    end;   
  end;
end;

procedure TAcPluginDLL_ListProc(ASender: Pointer; AEntry: PAcRegisteredClassEntry); 
var
  entry: PAcRegisteredClassEntry;
begin
  with TAcPluginDLL(ASender) do
  begin
    //Copy the class entry
    New(entry);
    entry^ := AEntry^;

    //Set the source id of the entry to FSourceID
    entry^.SourceID := FSourceID;

    //Add the entry to the classes list
    FClassEntries.Add(entry);
  end;
end;


function TAcPluginDLL.LoadPlugin(AName: string): boolean;
var
  memmgr: TAcMemoryManager;
begin
  result := false;

  //Unload the plugin if one had been loaded
  UnloadPlugin;

  FFileName := AName;

  FHandle := AcLoadLibrary(AName);

  if Loaded then
  begin
    @FDLLInit := AcGetProcAddress(FHandle, 'AcDLLInit');
    @FDLLFinalize := AcGetProcAddress(FHandle, 'AcDLLFinalize');
    @FDLLExport := AcGetProcAddress(FHandle, 'AcDLLExportClasses');
    @FDLLMemMgt := AcGetProcAddress(FHandle, 'AcDLLMemMgt');

    if Assigned(FDLLInit) and Assigned(FDLLFinalize) and Assigned(FDLLExport) then
    begin
      result := true;

      //Write all classes exported by the plugin to the classes list
      AcRegSrv.IncSourceCount;
      FSourceID := AcRegSrv.SourceCount;

      //Init...
      FDLLInit;

      //...assign the memory manager...
      if Assigned(FDLLMemMgt) then
      begin
        GetMemoryManager(memmgr);

        Move(memmgr, FOldMemMgr[0], SizeOf(memmgr));
        FOldMemMgrSize := SizeOf(memmgr);
        
        FDLLMemMgt(@FOldMemMgr, FOldMemMgrSize); //The old memory manager will be stored in the var-parameter

        FMemMgt := true;        
      end;      

      //...export registered functions
      FDLLExport(TAcPluginDLL_ListProc, self, AcProgVer);
    end
    else
      UnloadPlugin;
  end;
end;

function TAcPluginDLL.RegisterPluginClasses(
  AClassType: TAcPersistentClass): integer;
var
  i: integer;
  entry: PAcRegisteredClassEntry;
begin
  result := 0;
  if Loaded then
  begin
    FRegisterd := true;
    
    AcRegSrv.BeginUpdate;
    try
      for i := 0 to FClassEntries.Count - 1 do
      begin
        entry := PAcRegisteredClassEntry(FClassEntries[i]);
        if (AcRegSrv.GetEntry(entry^.Name) = nil) and
           (AcIsClass(AClassType.ClassName, entry^.IdentStr)) then
        begin
          AcRegSrv.RegisterClass(entry^);
          inc(result);
        end;
      end;
    finally
      AcRegSrv.EndUpdate;
    end;
  end;
end;

procedure TAcPluginDLL.UnregisterPluginClasses;
begin
  if (FSourceID > 0) and (FRegisterd) then
    AcRegSrv.UnregisterSource(FSourceID);

  FSourceID := -1;
  FRegisterd := false;
end;

procedure TAcPluginDLL.UnloadPlugin;
begin
  ClearClassEntries;

  FFileName := '';
  
  if Loaded then
  begin
    UnregisterPluginClasses;

    //Restore the old dll memory manager
    if FMemMgt then
      FDLLMemMgt(@FOldMemMgr, FOldMemMgrSize);
    FMemMgt := false;
    FillChar(FOldMemMgr, SizeOf(FOldMemMgr), 0);
    FOldMemMgrSize := 0;

    //Finalize the DLL
    if Assigned(FDLLFinalize) then
      FDLLFinalize;

    AcFreeLibrary(FHandle);
    FHandle := 0;
    FSourceID := -1;
    FRegisterd := false;

    FDLLInit := nil;
    FDLLFinalize := nil;
    FDLLExport := nil;
  end;
end;

{ TAcDLLExplorer }

procedure TAcDLLExplorer.GetPlugins(Plugins: TStrings; const Dir, Extension: string);
begin
  GetPluginsEx(Plugins, Dir, TAcPersistent, Extension);
end;

procedure TAcDLLExplorer.GetPluginsEx(Plugins: TStrings; const Dir: string;
  BaseClass: TAcPersistentClass; const Extension: string);
var
  searchrec:TSearchRec;
  exten: string;
  plg: TAcPluginDLL;
  res: Integer;
begin
  //Set the default extenstion, if the string was empty
  if Extension = '' then
    exten := ext
  else
    exten := Extension;
    
  res := FindFirst(dir+'*'+exten, faAnyFile, searchrec);
  while (res = 0) do
  begin
    plg := TAcPluginDLL.Create;
    try
      plg.LoadPlugin(searchrec.Name);
      if (plg.Loaded) and (plg.HasClass(BaseClass)) then
        Plugins.Add(searchrec.Name);
    finally
      plg.Free;
    end;
    res := FindNext(searchrec);
  end;
  FindClose(searchrec);
end;

{ TAcPluginDLLList }

function TAcPluginDLLList.GetItem(AIndex: integer): TAcPluginDLL;
begin
  result := inherited Items[AIndex];
end;

procedure TAcPluginDLLList.Notify(ptr: Pointer; action: TListNotification);
begin
  if action = lnDeleted then
    TAcPluginDLL(ptr).Free;
end;

{ TAcPluginManager }

procedure TAcPluginManager.AutoLoad;
begin
  //Search for plugins in the root directory
  AutoLoad(ExtractFilePath(ParamStr(0)));
end;

procedure TAcPluginManager.AutoLoad(BaseClass: TAcPersistentClass);
begin
  AutoLoad(ExtractFilePath(ParamStr(0)), BaseClass, '');
end;

procedure TAcPluginManager.AutoLoad(const Dir, Extension: string);
begin
  AutoLoad(Dir, TAcPersistent, Extension);
end;

procedure TAcPluginManager.AutoLoad(const Dir: string;
  BaseClass: TAcPersistentClass; const Extension: string);
var
  expl: TAcDLLExplorer;
  strs: TStringList;
begin
  strs := TStringList.Create;
  expl := TAcDLLExplorer.Create;
  try
    //Search for plugins in the specified directory
    expl.GetPluginsEx(strs, Dir, BaseClass, Extension);

    //Load all plugins which have been found
    LoadPlugins(strs, BaseClass);
  finally
    expl.Free;
    strs.Free;
  end;
end;

constructor TAcPluginManager.Create;
begin
  inherited Create;

  FPlugins := TAcPluginDLLList.Create;
end;

destructor TAcPluginManager.Destroy;
begin
  FPlugins.Free;
  inherited;
end;

function TAcPluginManager.LoadPlugin(AName: string; AClass: TAcPersistentClass): TAcPluginDLL;
begin
  //Create the plugin dll object
  result := TAcPluginDLL.Create;
  try
    //Load the plugin from the given filename
    result.LoadPlugin(AName);

    //Check whether the plugin is loaded
    if result.Loaded then
    begin
      result.RegisterPluginClasses(AClass);
      FPlugins.Add(result)
    end
    else
      FreeAndNil(result);

  except
    //Free the plugin if any exception occured
    FreeAndNil(result);
    raise;
  end;
end;

procedure TAcPluginManager.LoadPlugins(AList: TStrings; AClass: TAcPersistentClass);
var
  i: Integer;
begin
  //Loads a list of plugins
  for i := 0 to AList.Count - 1 do
    LoadPlugin(AList[i], AClass);
end;

end.
