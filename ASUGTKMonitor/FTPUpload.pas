unit FTPUpload;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Grids, xmldom, XMLIntf, msxmldom, XMLDoc, MyUtils,
  FTPAddFiles, xercesxmldom, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdExplicitTLSClientServerBase, IdFTP, syncobjs;

type
    TFTPEquipment = class
      equipmentname:string;
      IPAddress:string;
      Files:TStrings;
    private
      FCurrentConnected:boolean;
    public
      constructor Create;
      destructor destroy;
      property CurrentConnected:boolean read FCurrentConnected write FCurrentConnected; // ФТП подключен к этому самосвалу
    end;

type TFTPList=class(TStringList)
        Locked:TCriticalSection;
      private
        function GetEquipment(index:integer):TFTPEquipment;
      public
        constructor Create;
        destructor Destroy;
        property Equipment[index:integer]: TFTPEquipment read GetEquipment;
        procedure AddEquipment(eqname:string;IPAddress:string;Files:TStrings);
        procedure DeleteEquipment(index:integer);
end;

// Поток загрузки файлов на PTX
type TFTPUploadThread=class(TThread)
     private
        messageToProgram:string;
     protected
        procedure RedrawList;
        procedure RedrawTable;
        procedure WriteMessage;
        procedure Execute; override;
     public
        LogFile:string;
        saveToLog:boolean;
        constructor Create(Suspended:boolean);
end;

type
  TfrmFTPTasks = class(TForm)
    SGFTPEquipment: TStringGrid;
    PTool: TPanel;
    bbAdd: TBitBtn;
    bbDelete: TBitBtn;
    bbClearAll: TBitBtn;
    XMLFIles: TXMLDocument;
    FTPConnect: TIdFTP;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bbAddClick(Sender: TObject);
    procedure bbDeleteClick(Sender: TObject);
    procedure bbClearAllClick(Sender: TObject);
    procedure SGFTPEquipmentDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
  private
    { Private declarations }
    FXMLName:string;
  public
    { Public declarations }
    property XMLName:string read FXMLName write Fxmlname;
    function SaveListToXML(filename:string):boolean;
    function LoadListFromXML(filename:string):boolean;
    procedure Redraw;
  end;

var
  frmFTPTasks: TfrmFTPTasks;
  ftpList:TFTPList;
  ftpThread:TFTPUploadThread;

implementation

uses main;
{$R *.dfm}

{ TFTPList }

procedure TfrmFTPTasks.bbAddClick(Sender: TObject);
begin
     frmFTPUploadAdd.ShowModal;
     if frmFTPUploadAdd.ModalResult=mrOk then begin
         frmFTPTasks.SaveListToXML(frmFTPTasks.XMLName);
         frmFTPTasks.ReDraw;
         if not Assigned(ftpThread) then ftpThread:=TFTPUploadThread.Create(false)
            else if ftpThread.Suspended then ftpThread.Resume;
     end;
end;

procedure TfrmFTPTasks.bbClearAllClick(Sender: TObject);
begin
     ftpList.Locked.Enter;
     ftpList.Clear;
     DeleteFile(frmFTPTasks.XMLName);
     ftpList.Locked.Leave;
     Redraw;
end;

procedure TfrmFTPTasks.bbDeleteClick(Sender: TObject);
var
  idx: Integer;
begin
     idx:=SGFTPEquipment.Row;
     if idx>-1 then begin
        ftpList.Locked.Enter;
        ftpList.DeleteEquipment(idx);
        SaveListToXML(frmFTPTasks.XMLName);
        ftpList.Locked.Leave;
        frmFTPTasks.Redraw;
     end;
end;

procedure TfrmFTPTasks.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     Action:=caHide;
end;

{ TFTPList }

procedure TFTPList.AddEquipment(eqname, IPAddress: string; Files: TStrings);
var FTPEQ:TFTPEquipment;
    i:integer;
    eqidx:integer;
begin
     if not IsIPAddress(IPAddress) then exit;
     if Files.Count<1 then exit;
     eqidx:=self.IndexOf(eqname);
     self.Locked.Enter;
     if eqidx>-1 then begin
        TFTPEquipment(self.Objects[eqidx]).Files.AddStrings(Files);
     end
     else begin
        FTPEQ:=TFTPEquipment.Create;
        FTPEQ.equipmentname:=eqname;
        FTPEQ.IPAddress:=IPAddress;
        FTPEQ.Files.AddStrings(Files);
        self.AddObject(eqname,FTPEQ);
     end;
     self.Locked.Leave;
end;

constructor TFTPList.Create;
begin
     inherited;
     Locked:=TCriticalSection.Create;
end;

procedure TFTPList.DeleteEquipment(index: integer);
begin
     self.Delete(index);
end;

destructor TFTPList.Destroy;
begin
     FreeAndNil(Locked);
end;

{ TFTPEquipment }

constructor TFTPEquipment.Create;
begin
     Files:=TStringList.Create;
     CurrentConnected:=false;
end;

destructor TFTPEquipment.destroy;
begin
     FreeAndNil(Files);
end;

function TFTPList.GetEquipment(index: integer): TFTPEquipment;
begin
     try
        result:=TFTPEquipment(Objects[index]);
     except
        result:=nil;
     end;
end;

procedure TfrmFTPTasks.FormCreate(Sender: TObject);
begin
     ftpList:=TFTPList.Create;
     self.XMLName:=ExtractFilePath(Application.ExeName)+'UploadList.xml';
     self.LoadListFromXML(self.XMLName);
     self.Redraw;
     if not Assigned(ftpThread) then ftpThread:=TFTPUploadThread.Create(true);
     ftpThread.saveToLog:=true;
     if ftpList.Count>0 then ftpThread.Resume;
end;

procedure TfrmFTPTasks.FormDestroy(Sender: TObject);
begin
     FreeAndNil(ftpList);
end;

procedure TfrmFTPTasks.FormShow(Sender: TObject);
begin
     frmFTPTasks.Redraw;
end;

function TfrmFTPTasks.LoadListFromXML(filename: string): boolean;
var
  I: Integer;
  eqname: string;
  lst:TStrings;
  j: Integer;
  ip: string;
  docnode:IXMLNode;
begin
     if not FileExists(filename) then exit;
     XMLFIles.Active:=true;
     if not XMLFIles.IsEmptyDoc then XMLFIles.ChildNodes.Clear;
     XMLFIles.LoadFromFile(filename);
     lst:=TStringList.Create;
     try
        docnode:=XMLFIles.ChildNodes['UploadList'];
     except
        FreeAndNil(lst);
        exit;
     end;
     for I := 0 to docnode.ChildNodes.Count - 1 do begin
         if docnode.ChildNodes[i].NodeName='equipment' then begin
            eqname:=String(docnode.ChildNodes[i].Attributes['name']);
            ip:=string(docnode.ChildNodes[i].Attributes['ip']);
            if (eqname<>'') and (IsIPAddress(ip)) then begin
               lst.Clear;
               for j := 0 to docnode.ChildNodes[i].ChildNodes.Count - 1 do begin
                  if docnode.ChildNodes[i].ChildNodes[j].NodeName='file' then lst.Add(String(docnode.ChildNodes[i].ChildNodes[j].NodeValue));
               end;
               // Создаем оборудование с параметрами
               if lst.Count>0 then ftpList.AddEquipment(eqname,ip,lst);
            end;
         end;
     end;
     FreeAndNil(lst);
end;

procedure TfrmFTPTasks.Redraw;
var
  I: Integer;
  j: Integer;
  str:string;
begin
     ftpList.Locked.Enter;
     SGFTPEquipment.RowCount:=ftpList.Count;
     SGFTPEquipment.ColWidths[0]:=round(SGFTPEquipment.Width*0.2);
     SGFTPEquipment.ColWidths[1]:=SGFTPEquipment.Width-SGFTPEquipment.ColWidths[0];
     SGFTPEquipment.Cols[0].Clear;
     SGFTPEquipment.Cols[1].Clear;
     for I := 0 to ftpList.Count-1 do begin
       SGFTPEquipment.Cells[0,i]:=ftpList[i];
       str:='';
       if ftpList.Equipment[i].Files.Count>0 then SGFTPEquipment.RowHeights[i]:=SGFTPEquipment.Font.Height*-1*ftpList.Equipment[i].Files.Count+10;
     end;
     ftpList.Locked.Leave;
     SGFTPEquipment.Repaint;
end;

function TfrmFTPTasks.SaveListToXML(filename: string): boolean;
var
  I: Integer;
  j: Integer;
  docnode:IXMLNode;
  eqnode:IXMLNode;
  filenode:IXMLNode;
begin
     if ftpList.Count=0 then begin
        if FileExists(filename) then DeleteFile(filename);
        exit;
     end;
     XMLFIles.XML.Clear;
     XMLFIles.Active:=true;
     XMLFIles.Version:='1.0';
     //if not XMLFIles.IsEmptyDoc then XMLFIles.ChildNodes.Clear;
     // Необходимо создать корневой элемент
     docnode:=XMLFIles.AddChild('UploadList');
     ftpList.Locked.Enter;
     for I := 0 to ftpList.Count-1 do begin
         if TFTPEquipment(ftpList.Objects[i]).Files.Count >0 then begin
            eqnode:=docnode.AddChild('equipment');
            eqnode.Attributes['name']:=ftpList[i];
            eqnode.Attributes['ip']:=ftpList.Equipment[i].IPAddress;
            for j := 0 to ftpList.Equipment[i].Files.Count - 1 do begin
                filenode:=eqnode.AddChild('file');
                filenode.NodeValue:=ftpList.Equipment[i].Files[j];
            end;
         end;
     end;
     ftpList.Locked.Leave;
     // Дописываем в начало файла информацию об xml
     //XMLFIles.XML.Insert(0,'<?xml version="1.0"?>');
     //XMLFIles.Active:=true;
     XMLFIles.SaveToFile(filename);
     XMLFIles.Active:=false;
end;

procedure TfrmFTPTasks.SGFTPEquipmentDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  i: Integer;
  y1: integer;
  x1: integer;
begin
      TStringGrid(sender).Canvas.Brush.Color:=clWhite;
      TStringGrid(sender).Canvas.FillRect(Rect);
      ftpList.Locked.Enter;
      if ARow<=(ftpList.Count-1) then begin
         if (ACol=0) then begin
            with TStringGrid(Sender).Canvas do begin
                if (ftpList.Equipment[ARow].CurrentConnected) then Font.Color:=clGreen else font.Color:=clBlack;
                TextOut(Rect.Left+10,Rect.Top+3,ftpList.Equipment[ARow].equipmentname);
                Font.Color:=clBlack;
            end;
         end;
         if (ACol=1) then begin
            with TStringGrid(Sender).Canvas do begin
                //Brush.Color:=clWhite;
                FillRect(Rect);
                x1:=Rect.Left+10;
                y1:=Rect.Top;
                Pen.Color:=clBlack;
                if ftpList.Equipment[ARow].CurrentConnected then Font.Color:=clGreen else Font.Color:=clBlack;
                try
                if ARow<ftpList.Count then begin
                    for i := 0 to ftpList.Equipment[ARow].Files.Count - 1 do begin
                        TextOut(x1,y1+3,ftpList.Equipment[ARow].Files[i]);
                        y1:=y1+(Font.Height*-1);
                    end;
                end;
                except

                end;
                font.Color:=clBlack;
            end;
         end;
      end;
      ftpList.Locked.Leave;
end;

{ TFTPUploadThread }

constructor TFTPUploadThread.Create(Suspended: boolean);
begin
     inherited Create(suspended);
     saveToLog:=false;
     LogFile:='';
end;

procedure TFTPUploadThread.Execute;
var
  i,j: Integer;
  shortfilename:string;
  filename:string;
  str1:string;
  needNext, nn1:boolean;
  currentEQ:TFTPEquipment;
begin
   if saveToLog and (LogFile='') then LogFile:=ExtractFilePath(Application.ExeName)+'FTP.log';
   currentEQ:=TFTPEquipment.Create;
   FreeOnTerminate:=false;
   i:=0;
   if saveToLog then SaveLogToFile(LogFile,'Задача запущена');
   while not Terminated do begin
       ftpList.Locked.Enter;
       while (not Terminated) and (ftpList.Count>0) do begin
             if i>(ftpList.Count-1) then begin
                i:=0;
                ftpList.Locked.Leave;
                sleep(10000);
                ftpList.Locked.Enter;
                //if saveToLog then SaveLogToFile(Logfile,'Начали проверять заново');
                // Если за время паузы удалили все файлы из задания, то прервать загрузку
                if ftpList.Count=0 then break;
             end;
             try
                currentEQ.equipmentname:=ftpList.Equipment[i].equipmentname;
                currentEQ.IPAddress:=ftpList.Equipment[i].IPAddress;
                currentEQ.Files.Clear;
                currentEQ.Files.AddStrings(ftpList.Equipment[i].Files);
                ftpList.Equipment[i].CurrentConnected:=true;
                ftpList.Locked.Leave;
                synchronize(RedrawTable);
                ftpList.Locked.Enter;
             except
                break;
             end;
             frmFTPTasks.FTPConnect.Host:=currentEQ.IPAddress;
             frmFTPTasks.FTPConnect.Username:='admin';
             frmFTPTasks.FTPConnect.Password:='***';
             frmFTPTasks.FTPConnect.Passive:=true;
             try
                needNext:=false;
                //if saveToLog then SaveLogToFile(Logfile,'Попытка подключения к '+currentEQ.equipmentname);
                ftpList.Locked.Leave;
                frmFTPTasks.FTPConnect.Connect;
                ftpList.Locked.Enter;
             except
                // нет связи. Ждем и подключаемся к следующему устройству
                //if saveToLog then SaveLogToFile(Logfile,'Нет связи с '+currentEQ.equipmentname);
                sleep(1000);
                ftpList.Locked.Enter;
                //if saveToLog then SaveLogToFile(Logfile,'Будем проверять следующий');
                needNext:=true;
             end;
             if NeedNext then begin
                try
                   ftpList.Equipment[i].CurrentConnected:=false;
                except
                   break;
                end;
                inc(i);
                Continue;
             end;
             // Если подключились к устройству, то загружаем на него файлы
             if frmFTPTasks.FTPConnect.Connected then begin
                //if saveToLog then SaveToFile(LogFile,'Подключение к '+CurrentEQ.equipmentname+' установлено');
                j:=0;
                while j <= currentEQ.Files.Count -1 do begin
                    filename:=CurrentEQ.Files[j];
                    shortfilename:=ExtractFileName(filename);
                    try
                      nn1:=false;
                      ftpList.Locked.Leave;
                      //if saveToLog then SaveLogToFile(Logfile,'Загрузка файла '+CurrentEQ.Files[j]);
                      frmFTPTasks.FTPConnect.Put(filename);
                      //if saveToLog then SaveLogToFile(Logfile,'Загрузка файла завершена');
                      messagetoProgram:=CurrentEQ.equipmentname+'. Загружен файл '+CurrentEQ.Files[j];
                      if saveToLog then SaveLogToFile(Logfile,messageToProgram);
                      Synchronize(WriteMessage);
                      ftpList.Locked.Enter;
                    except
                      // Если не удалась загрузка, то пробуем загрузить следующий файл
                      ftpList.Locked.Enter;
                      if saveToLog then SaveLogToFile(Logfile,'Ошибка загрузки файла');
                      nn1:=true;
                    end;
                    if nn1 then begin
                      inc(j);
                      continue;
                    end;
                    // Если не было ошибок при загрузке, то удаляем файл из списка и перерисовываем
                    if (i<ftpList.Count) and (currentEQ.equipmentname=ftpList.Equipment[i].equipmentname) and (currentEQ.Files.Count=ftpList.Equipment[i].Files.Count) then ftpList.Equipment[i].Files.Delete(j);
                    currentEQ.Files.Delete(j);
                    ftpList.Locked.Leave;
                    Synchronize(RedrawList);
                    ftpList.Locked.Enter;
                    //inc(j);
                end;
                if saveToLog then SaveLogToFile(Logfile,'Закрытие подключения к '+CurrentEQ.equipmentname);
                frmFTPTasks.FTPConnect.Quit;
             end;
             // Если в списке для загрузки больше нет файлов, то удаляем едиинцу
             if (i<ftpList.Count) and (currentEQ.equipmentname=ftpList.Equipment[i].equipmentname) then begin
                    ftpList.Equipment[i].CurrentConnected:=false;
                    if ftpList.Equipment[i].Files.Count=0 then begin
                       ftpList.DeleteEquipment(i);
                       if saveToLog then SaveLogToFile(Logfile,'Все файлы загружены. '+currentEQ.equipmentname+' удален из списка загрузки');
                       ftpList.Locked.Leave;
                       synchronize(RedrawList);
                       ftpList.Locked.Enter;
                    end else inc(i);
             end;
             ftpList.Locked.Leave;
             sleep(1000);
             ftpList.Locked.Enter;
       end;
       ftpList.Locked.Leave;
       sleep(1000);
   end;
   FreeAndNil(currentEQ);
end;

procedure TFTPUploadThread.RedrawList;
begin
     frmFTPTasks.SaveListToXML(frmFTPTasks.XMLName);
     frmFTPTasks.Redraw;
end;

procedure TFTPUploadThread.RedrawTable;
begin
     frmFTPTasks.Redraw;
end;

procedure TFTPUploadThread.WriteMessage;
begin
     frmMain.MMessages.Lines.Add(messageToProgram);
end;

end.
