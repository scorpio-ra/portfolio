unit FTPAddFiles;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmFTPUploadAdd = class(TForm)
    GBFiles: TGroupBox;
    LBFiles: TListBox;
    bbAdd: TBitBtn;
    BBDel: TBitBtn;
    BBClear: TBitBtn;
    GBEquipment: TGroupBox;
    LBEQSelect: TListBox;
    LBEQAll: TListBox;
    bbEQAdd: TBitBtn;
    bbEQAddAll: TBitBtn;
    bbEQDel: TBitBtn;
    bbEQDelAll: TBitBtn;
    bbOk: TBitBtn;
    bbCancel: TBitBtn;
    OpenDialog1: TOpenDialog;
    procedure bbAddClick(Sender: TObject);
    procedure BBDelClick(Sender: TObject);
    procedure BBClearClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bbEQAddClick(Sender: TObject);
    procedure bbEQAddAllClick(Sender: TObject);
    procedure bbEQDelClick(Sender: TObject);
    procedure bbEQDelAllClick(Sender: TObject);
    procedure bbCancelClick(Sender: TObject);
    procedure bbOkClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmFTPUploadAdd: TfrmFTPUploadAdd;

implementation

uses main, DM, FTPUpload;

{$R *.dfm}

procedure TfrmFTPUploadAdd.bbAddClick(Sender: TObject);
begin
     if OpenDialog1.Execute then begin
        while OpenDialog1.Files.Count>0 do begin
            LBFiles.Items.Add(OpenDialog1.Files[0]);
            OpenDialog1.Files.Delete(0);
        end;
     end;
end;

procedure TfrmFTPUploadAdd.bbCancelClick(Sender: TObject);
begin
     frmFTPUploadAdd.ModalResult:=mrCancel;
     frmFTPUploadAdd.Close;
end;

procedure TfrmFTPUploadAdd.BBClearClick(Sender: TObject);
begin
     LBFiles.Items.Clear;
end;

procedure TfrmFTPUploadAdd.BBDelClick(Sender: TObject);
var a:integer;
begin
     if LBFiles.ItemIndex>-1 then begin
        a:=LBFiles.ItemIndex;
        LBFiles.DeleteSelected;
        if a<LBFiles.Items.Count then LBFiles.ItemIndex:=a else LBFiles.ItemIndex:=LBFiles.Items.Count-1;
     end;
end;

procedure TfrmFTPUploadAdd.bbEQAddAllClick(Sender: TObject);
begin
     while LBEQAll.Items.Count>0 do begin
        LBEQAll.ItemIndex:=0;
        bbEQAddClick(self);
     end;
end;

procedure TfrmFTPUploadAdd.bbEQAddClick(Sender: TObject);
var idx:integer;
begin
     if LBEQAll.Count=0 then exit;
     if LBEQAll.ItemIndex<0 then LBEQAll.ItemIndex:=0;
     if LBEQAll.ItemIndex>-1 then begin
        idx:=LBEQAll.ItemIndex;
        LBEQSelect.Items.AddObject(LBEQAll.Items[idx],LBEQAll.Items.Objects[LBEQAll.ItemIndex]);
        // Необходимо сначала отвязать от списка объект, иначе он может быть уничтожен
        LBEQAll.Items.Objects[LBEQAll.ItemIndex]:=nil;
        LBEQAll.Items.Delete(LBEQAll.ItemIndex);
        if idx<LBEQAll.Count then LBEQAll.ItemIndex:=idx else LBEQAll.ItemIndex:=LBEQAll.Count-1;
     end;
end;

procedure TfrmFTPUploadAdd.bbEQDelAllClick(Sender: TObject);
begin
     while LBEQSelect.Items.Count>0 do begin
        LBEQSelect.ItemIndex:=0;
        bbEQDelClick(self);
     end;
end;

procedure TfrmFTPUploadAdd.bbEQDelClick(Sender: TObject);
var idx:integer;
begin
     if LBEQSelect.Count=0 then exit;
     if LBEQSelect.ItemIndex<0 then LBEQSelect.ItemIndex:=0;
     if LBEQSelect.ItemIndex>-1 then begin
        idx:=LBEQSelect.ItemIndex;
        LBEQAll.Items.AddObject(LBEQSelect.Items[LBEQSelect.ItemIndex],LBEQSelect.Items.Objects[LBEQSelect.ItemIndex]);
        // Необходимо сначала отвязать от списка объект, иначе он может быть уничтожен
        LBEQSelect.Items.Objects[LBEQSelect.ItemHeight]:=nil;
        LBEQSelect.Items.Delete(LBEQSelect.ItemIndex);
        if idx<LBEQSelect.Count then LBEQSelect.ItemIndex:=idx else LBEQSelect.ItemIndex:=LBEQSelect.Count-1;
     end;
end;

procedure TfrmFTPUploadAdd.bbOkClick(Sender: TObject);
var
  I: Integer;
  idx: Integer;
  ip:string;
begin
     if LBFiles.Items.Count<1 then begin
        Application.MessageBox('Не выбраны файлы для загрузки','Сообщение');
        exit;
     end;
     if LBEQSelect.Items.Count<1 then begin
        Application.MessageBox('Не выбрано оборудование для загрузки файлов','Сообщение');
        exit;
     end;
     // Добавляем выбранные файлы к списку файлов для загрузки
     for I := 0 to LBEQSelect.Items.Count - 1 do begin
         try
            TMobileEQModular(LBEQSelect.Items.Objects[i]).Locked.Enter;
            ip:=TMobileEQModular(LBEQSelect.items.Objects[i]).IPAddress;
            TMobileEQModular(LBEQSelect.Items.Objects[i]).Locked.Leave;
         except
            //Application.MessageBox(PWideChar(LBEQSelect.Items.Objects[i].ClassName),'');
            TMobileEQModular(LBEQSelect.Items.Objects[i]).Locked.Leave;
            exit;
         end;
         ftpList.AddEquipment(LBEQSelect.Items[i],ip,LBFiles.Items);
     end;
     frmFTPTasks.SGFTPEquipment.RowCount:=ftpList.Count;
     frmFTPUploadAdd.ModalResult:=mrOk;
     //frmFTPUploadAdd.Close;
end;

procedure TfrmFTPUploadAdd.FormClose(Sender: TObject; var Action: TCloseAction);
var i: integer;
begin
     for i := 0 to LBEQAll.Items.Count - 1 do LBEQAll.Items.Objects[i]:=nil;
     LBEQAll.Clear;
     for i := 0 to LBEQSelect.Items.Count - 1 do LBEQSelect.Items.Objects[i]:=nil;
     LBEQSelect.Clear;
     LBFiles.Clear;
     Action:=caHide;
end;

procedure TfrmFTPUploadAdd.FormShow(Sender: TObject);
var i:integer;
begin
     for i := 0 to EQAllList.Count -1 do begin
         if (TEquipment(EQALLList.Items[i]^).ClassType =TTruck) or (TEquipment(EQALLList.Items[i]^).ClassType=TExcav) then begin
           LBEQAll.Items.AddObject(TEquipment(EQALLList.Items[i]^).name,TEquipment(EQALLList.Items[i]^));
         end;
     end;
end;

end.
