unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Menus, ActnList, StdActns, ComCtrls, ExtCtrls, StdCtrls,

  AcDataStore;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    Bevel1: TBevel;
    edtAddr: TEdit;
    FileNew: TAction;
    EditExport: TAction;
    EditDelete: TAction;
    EditAdd: TAction;
    FileExit: TAction;
    FileSaveAs: TAction;
    FileSave: TAction;
    FileOpen: TAction;
    ActionList1: TActionList;
    ImageList1: TImageList;
    lblValueCaption: TLabel;
    lblValue: TLabel;
    lblNameCaption: TLabel;
    lblPathCaption: TLabel;
    lblSizeCaption: TLabel;
    lblClassCaption: TLabel;
    lblNoInfo: TLabel;
    lblName: TLabel;
    lblAddInfo: TLabel;
    Label2: TLabel;
    lblPath: TLabel;
    lblSize: TLabel;
    lblClass: TLabel;
    ListView1: TListView;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    dlgFileOpen: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    statbar: TStatusBar;
    ToolBar1: TToolBar;
    trvStructure: TTreeView;
    procedure FileExitExecute(Sender: TObject);
    procedure FileNewExecute(Sender: TObject);
    procedure FileOpenExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure trvStructureChange(Sender: TObject; Node: TTreeNode);
  private
    { private declarations }
  public
    worknode: TAcStoreNode;
    firsttime: boolean;
    filename: string;
    procedure BuildTreeView;
    procedure UpdateStatusBar;
    procedure ShowElementInfo(ANode: TAcStoreNode);
    procedure Open(AFileName: string);
    procedure New;
  end; 

var
  frmMain: TfrmMain;

implementation

{ TfrmMain }

function FileSizeToStr(const ASize: Int64): string;
const
  Units: Array[0..8] of string = ('Byte', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB');
var
  Index: Integer;
begin
  if ASize > 0 then
  begin
    Index := Trunc(ln(ASize) / ln(2) / 10);
    if Index > 0 then
      result := Format('%.2f %s', [ASize / (1 shl (Index * 10)), Units[Index]])
    else
      result := IntToStr(ASize) + ' Byte';
  end else
    result := '0 Byte';
end;

procedure TfrmMain.FileExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.FileNewExecute(Sender: TObject);
begin
  New;
end;

procedure TfrmMain.FileOpenExecute(Sender: TObject);
begin
  if dlgFileOpen.Execute then
    Open(dlgFileOpen.FileName);
end;

procedure TfrmMain.FormActivate(Sender: TObject);
begin
  if not firsttime then
    ShowElementInfo(nil);
   firsttime := true;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  worknode := TAcStoreNode.Create(nil);

  BuildTreeView;
  UpdateStatusBar;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  worknode.Free;
end;

procedure TfrmMain.FormResize(Sender: TObject);
var
  i, w: integer;
begin
  //Resize the status bar areas
  w := 0;
  for i := 1 to statbar.Panels.Count - 1 do
    w := w + statbar.Panels[i].Width;
  statbar.Panels[0].Width := statbar.ClientWidth - w - 10;
end;

procedure TfrmMain.trvStructureChange(Sender: TObject; Node: TTreeNode);
begin
  if trvStructure.Selected <> nil then
    ShowElementInfo(TAcStoreNode(trvStructure.Selected.Data))
  else
    ShowElementInfo(nil);
end;

procedure TfrmMain.BuildTreeView;

  procedure BuildRec(node: TAcStoreNode; items: TTreeNodes; parent: TTreeNode);
  var
    i: integer;
    item: TTreeNode;
  begin
    item := items.AddChild(parent, node.Name);
    item.Data := node;
    if node.Nodes.Count = 0 then
    begin
      item.ImageIndex := 1;
      item.SelectedIndex := 1;

      if (node is TAcIntegerNode) or (node is TAcFloatNode) then
      begin
        item.ImageIndex := 4;
        item.SelectedIndex := 4;
      end else
      if node is TAcStringNode then
      begin
        item.ImageIndex := 3;
        item.SelectedIndex := 3;
      end else
      if node is TAcBoolNode then
      begin
        item.ImageIndex := 5;
        item.SelectedIndex := 5;
      end;

    end else
    begin
      item.ImageIndex := 0;
      item.SelectedIndex := 0;
      for i := 0 to node.Nodes.Count - 1 do
        BuildRec(node.Nodes[i], items, item);
    end;
  end;

begin
  trvStructure.Items.Clear;
  trvStructure.Items.BeginUpdate;
  BuildRec(worknode, trvStructure.Items, nil);
  trvStructure.Items.EndUpdate;
end;

procedure TfrmMain.UpdateStatusBar;
begin
  if filename <> '' then
    statbar.Panels[0].Text := filename
  else
    statbar.Panels[0].Text := 'No file opened';

  statbar.Panels[1].Text := 'Needed Memory: ' + FileSizeToStr(worknode.Size);
end;

procedure TfrmMain.ShowElementInfo(ANode: TAcStoreNode);
begin
  lblName.Visible := ANode <> nil;
  lblNameCaption.Visible := ANode <> nil;
  lblPath.Visible := ANode <> nil;
  lblPathCaption.Visible := ANode <> nil;
  lblSize.Visible := ANode <> nil;
  lblSizeCaption.Visible := ANode <> nil;
  lblClass.Visible := ANode <> nil;
  lblClassCaption.Visible := ANode <> nil;
  lblValue.Visible := ANode <> nil;
  lblValueCaption.Visible := ANode <> nil;

  lblNoInfo.Visible := ANode = nil;

  if ANode <> nil then
  begin
    lblName.Caption := ANode.Name;
    lblPath.Caption := ANode.Path;
    lblClass.Caption := ANode.ClassName;
    lblSize.Caption := FileSizeToStr(ANode.Size);
    if (ANode is TAcIntegerNode) then
      lblValue.Caption := IntToStr(TAcIntegerNode(ANode).Value)
    else if (ANode is TAcFloatNode) then
      lblValue.Caption := FloatToStr(TAcFloatNode(ANode).Value)
    else if (ANode is TAcStringNode) then
      lblValue.Caption := TAcStringNode(ANode).Value
    else if (ANode is TAcBoolNode) then
    begin
      case TAcBoolNode(ANode).Value of
        true: lblValue.Caption := 'true';
        false: lblValue.Caption := 'false';
      end;
    end else
      lblValue.Caption := 'Unkown Value';
  end;
end;

procedure TfrmMain.Open(AFileName: string);
begin
  filename := AFileName;

  worknode.LoadFromFile(AFileName);

  BuildTreeView;
  UpdateStatusBar;
end;

procedure TfrmMain.New;
begin
  filename := '';

  worknode.Clear(true);

  BuildTreeView;
  UpdateStatusBar;
end;

initialization
  {$I main.lrs}

end.

