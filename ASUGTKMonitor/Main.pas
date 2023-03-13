unit Main;

interface

uses
  Windows, Messages, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Grids,
  MyTimer, DB, ADODB, Menus, ActnList, MonitoringEditor, ImgList,
  settings, FileVersion, DM, Math, MyUtils, TasksUnit, ShellAPI, ActiveX,
  Updater, UpdMessenger,   Buttons, ThreadBeep, About, cryptlib, ViewData,
  ResourceChecker, TeCanvas, Generics.collections,  InterfacesEdit, FTPUpload,
  FTPAddFiles, Changelog, xmldom, XMLIntf, msxmldom, XMLDoc, PlannedWorks,
  waitForm, ScorpioSSH, rxPlacemnt, RxMenus, LogsViewer, JCLDebug, AppEvnts,
  sysUtils;

  type TProc = procedure(sender:TObject);

  procedure SuspendMonitoringByHour(intfc:CInterface);

  type
  TfrmMain = class(TForm)
    RxTrayIcon1: TTrayIcon;
    StatusBar1: TStatusBar;
    ActionList1: TActionList;
    ADisableMonitoring: TAction;
    AShowReason: TAction;
    AEnableMonitoring: TAction;
    ImageList1: TImageList;
    bDoWorkold: TButton;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    AMainSettings: TAction;
    PCMain: TPageControl;
    tsEquipment: TTabSheet;
    tsServer: TTabSheet;
    SGEquipment: TStringGrid;
    SGServer: TStringGrid;
    tsMessages: TTabSheet;
    MMessages: TMemo;
    bClearMessages_old: TButton;
    tsTasks: TTabSheet;
    SGTasks: TStringGrid;
    AConnectVNC: TAction;
    APingPTX: TAction;
    AConnectTelnet: TAction;
    AxrebootPTX: TAction;
    AConnectVNCAndTelnet: TAction;
    AConnectBullet: TAction;
    APingPTXBullet: TAction;
    tsExcavs: TTabSheet;
    SGExcavs: TStringGrid;
    NSettings: TMenuItem;
    NVolumeAll: TMenuItem;
    BBDisableSound: TBitBtn;
    statusbarEquipment: TStatusBar;
    statusbarExcavs: TStatusBar;
    Panel1: TPanel;
    Shape1: TShape;
    Label3: TLabel;
    Shape2: TShape;
    Label4: TLabel;
    Shape3: TShape;
    Label5: TLabel;
    Shape4: TShape;
    Label7: TLabel;
    Shape5: TShape;
    Label8: TLabel;
    Shape6: TShape;
    Label9: TLabel;
    statusbarServers: TStatusBar;
    NHelp: TMenuItem;
    NCheckUpdate: TMenuItem;
    NAbout: TMenuItem;
    tsNetworking: TTabSheet;
    SGNetwork: TStringGrid;
    statusbarNetwork: TStatusBar;
    PMEquipment: TPopupMenu;
    ASuspendMonitoringByHour: TAction;
    ASuspendAllMonitoringByHour: TAction;
    APing: TAction;
    ASuspendDamageMonitoringByHour: TAction;
    AVEIData: TAction;
    PHint: TPanel;
    TimerHint: TTimer;
    PBDStatus: TPanel;
    shMysql: TShape;
    shD6: TShape;
    Label1: TLabel;
    ImageList2: TImageList;
    bDoWork: TBitBtn;
    ACheckEquipment: TAction;
    sbDisableCheck: TSpeedButton;
    PMDisable1h: TPopupMenu;
    AWaitPowerOn: TAction;
    ANoWaitPowerOn: TAction;
    AWaitNotWork: TAction;
    ANoWaitNotWork: TAction;
    NReWriteInterfaces: TMenuItem;
    ALCommands: TActionList;
    AReWriteInterfaces: TAction;
    NEquipmentSettings: TMenuItem;
    NEditInterfaces: TMenuItem;
    NEnableGood: TMenuItem;
    NUtility: TMenuItem;
    NUploadFiles: TMenuItem;
    ASuspendMonitoringBy2Hours: TAction;
    NChangeLog: TMenuItem;
    Images: TImageList;
    AWaitPowerOff: TAction;
    ANoWaitPowerOff: TAction;
    AWaitGBM: TAction;
    ANowaitGBM: TAction;
    PMessagesTools: TPanel;
    bClearMessages: TBitBtn;
    LHint: TLabel;
    AShowModularStatus: TAction;
    Splitter1: TSplitter;
    NPlannedWorks: TMenuItem;
    tsDrills: TTabSheet;
    SGDrills: TStringGrid;
    statusBarDrills: TStatusBar;
    LTime: TLabel;
    TmTime: TTimer;
    NShowClock: TMenuItem;
    FormStorage1: TFormStorage;
    shKobus: TShape;
    PMTasks: TRxPopupMenu;
    NTaskStart: TMenuItem;
    TaskImages: TImageList;
    NTaskStop: TMenuItem;
    ActionsTasks: TActionList;
    ATaskStart: TAction;
    ATaskStop: TAction;
    ATaskLog: TAction;
    NTaskLog: TMenuItem;
    tsSZMs: TTabSheet;
    SGSZMs: TStringGrid;
    statusBarSZMs: TStatusBar;
    ApplicationEvents1: TApplicationEvents;
    procedure FormCreate(Sender: TObject);
    procedure RxTrayIcon1DblClick(Sender: TObject);
    procedure Hide_appl(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SGEquipmentDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure SGEquipmentContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure ADisableMonitoringExecute(Sender: TObject);
    procedure AShowReasonExecute(Sender: TObject);
    procedure bDoWorkClick(Sender: TObject);
    procedure AMainSettingsExecute(Sender: TObject);
    procedure SGServerDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure bClearMessages_oldClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SGTasksDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure AConnectVNCExecute(Sender: TObject);
    procedure APingPTXExecute(Sender: TObject);
    procedure AConnectTelnetExecute(Sender: TObject);
    procedure AxrebootPTXExecute(Sender: TObject);
    procedure AConnectVNCAndTelnetExecute(Sender: TObject);
    procedure AWifiEnableMonExecute(Sender: TObject);
    procedure AWiFiDisableMonExecute(Sender: TObject);
    procedure AWifiStatusMonExecute(Sender: TObject);
    procedure APressEnableMonExecute(Sender: TObject);
    procedure APressDisableMonExecute(Sender: TObject);
    procedure APressStatusMonExecute(Sender: TObject);
    procedure AVeiEnableMonExecute(Sender: TObject);
    procedure AVeiDisableMonExecute(Sender: TObject);
    procedure AVEIStatusMonExecute(Sender: TObject);
    procedure AConnectBulletExecute(Sender: TObject);
    procedure APingPTXBulletExecute(Sender: TObject);
    procedure BBDisableSoundClick(Sender: TObject);
    procedure NVolumeAllClick(Sender: TObject);
    procedure NVolumeAllDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure NAboutClick(Sender: TObject);
    procedure NCheckUpdateClick(Sender: TObject);
    procedure AGPSEnableMonExecute(Sender: TObject);
    procedure AGPSDisableMonExecute(Sender: TObject);
    procedure AGPSSTatusMonExecute(Sender: TObject);
    procedure SGNetworkContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure ANetWiFiEnableMonExecute(Sender: TObject);
    procedure ANetWiFiDisableMonExecute(Sender: TObject);
    procedure ANetWiFiStatusMonExecute(Sender: TObject);
    procedure SGServerContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure AEnableMonitoringExecute(Sender: TObject);
    procedure ASuspendMonitoringByHourExecute(Sender: TObject);
    procedure ASuspendAllMonitoringByHourExecute(Sender: TObject);
    procedure APingExecute(Sender: TObject);
    procedure ASuspendDamageMonitoringByHourExecute(Sender: TObject);
    procedure AVEIDataExecute(Sender: TObject);
    procedure SGEquipmentDblClick(Sender: TObject);
    procedure TimerHintTimer(Sender: TObject);
    procedure TimConnectControlTimer(Sender: TObject);
    procedure ACheckEquipmentExecute(Sender: TObject);
    procedure sbDisableCheckClick(Sender: TObject);
    procedure PMDisableClick(sender:TObject);
    procedure AWaitPowerOnExecute(Sender: TObject);
    procedure ANoWaitPowerOnExecute(Sender: TObject);
    procedure AWaitNotWorkExecute(Sender: TObject);
    procedure ANoWaitNotWorkExecute(Sender: TObject);
    procedure AReWriteInterfacesExecute(Sender: TObject);
    procedure NEditInterfacesClick(Sender: TObject);
    procedure NEnableGoodClick(Sender: TObject);
    procedure ASuspendMonitoringBy2HoursExecute(Sender: TObject);
    procedure NUploadFilesClick(Sender: TObject);
    procedure NChangeLogClick(Sender: TObject);
    procedure AWaitPowerOffExecute(Sender: TObject);
    procedure ANoWaitPowerOffExecute(Sender: TObject);
    procedure AWaitGBMExecute(Sender: TObject);
    procedure ANowaitGBMExecute(Sender: TObject);
    procedure bClearMessagesClick(Sender: TObject);
    procedure AShowModularStatusExecute(Sender: TObject);
    procedure NPlannedWorksClick(Sender: TObject);
    procedure TmTimeTimer(Sender: TObject);
    procedure NShowClockClick(Sender: TObject);
    procedure MMessagesChange(Sender: TObject);
    procedure PMTasksPopup(Sender: TObject);
    procedure SGTasksContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure ATaskStartExecute(Sender: TObject);
    procedure ATaskStopExecute(Sender: TObject);
    procedure ATaskLogExecute(Sender: TObject);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
  private
    { Private declarations }
    function GetInterface(Act:TAction):CInterface;
    function GetCurrentEQTable: TStringGrid;
    procedure SuspendMonitoringBy1Hour(intfc: CInterface);
  public
    { Public declarations }
    IsFirstActivate:boolean;
    HintShowedSec:integer; // Количество секунд, которое отображается подсказка
    disable1hArray: TStringList;   // Ссылки на интерфейсы при отключении на час
    //procedure InitServersold;
    //procedure InitMobileEqold;
    //procedure InitNetworkEQold;
    //procedure InitServers;
   // procedure InitMobileEq;
    //procedure InitNetworkEQ;
    //procedure InitTasks;
    procedure InitEquipment(EquipmentType:TEquipmentType);
    procedure SetGridSizes(tbl:TStringGrid);
    procedure SetTasksGridSizes;
    function EnableInterfaceEquipmentMon(intfc:CInterface):boolean;
    function DisableInterfaceEquipmentMon(intfc:CInterface):boolean;
    function StatusInterfaceEquipmentMon(intfc:CInterface):boolean;
    procedure getEQInformation(var tbl:TStringGrid; var EQIndex:integer; var EQ:TEquipment);
    procedure GenerateSysUtilsMenuItems(PM:TPopupMenu;EQ:TEquipment);
    procedure GenerateInterfacesMenuItems(PM:TPopupMenu; EQ:TEquipment);
    function GetCountEQinCategory:integer;
    procedure AddPMItem(ParentItem:TMenuItem; name,caption:string; basicAction:TBasicAction); overload;
    procedure AddPMItem(ParentItem:TMenuItem; name,caption:string; proc:TNotifyEvent); overload;
    procedure SaveWaitActions;
    procedure LoadWaitActions;
    function GetEquipmentByName(name:string):TEquipment;
  end;

// Опроделение констант цветов для опреленных состояний
const
  color_unknown   = clWhite;    // Статус 0. Цвет неопределенного состояния.
  color_Work      = clGreen;    // Статус 1. Цвет рабочего состояния
  color_NoData    = clRed;      // Статус 2. Цвет отстутствия данных
  color_Disable   = clGray;     // Статус 3. Цвет отключенного мониторинга
  color_NotReady  = clYellow;   // Статус 4. Цвет статуса не готов
  color_Damage    = clPurple;   // Статус 5. Цвет отключенного мониторинга по повреждению
  color_restored  = clSkyBlue;  // Статус 6. Цвет восстановления поступления данных

//procedure Win_Exec_wait(cmd_line:string);
// Массив оборудования
type TServersArray = array [1..10] of TServer;
type TEquipmentArray = array [1..100] of TMobileEQModular;
type TNetworkArray = array [1..20] of TNetworkEQ;
//type TTasksArray = array [1..20] of TTask;
type TDrillsArray = array [1..50] of TDrill;
type TSZMsArray = array [1..20] of TSZM;


var
  frmMain: TfrmMain;
  objSettings:TSettingsOld;
  ServersArray: TServersArray;
  MobileEQArray:TEquipmentArray;
  ExcavsArray:TEquipmentArray;
  //TasksArray:TTasksArray;
  NetworkEQArray:TNetworkArray;
  DrillsArray:TDrillsArray;
  SZMsArray:TSZMsArray;
  EQALLList:TList;
  TableCols, TableRows, cntNoData, cntDisableMonitoring, currentmark:integer;
  settingsFilePath:string;
  waitListFilePath:string;    // Путь к файлу со списком ожидания
  cntTrucks:integer;
  interfacesCount, parameterscount:shortint;
  maxlenInterfaceWidth:integer;
  countServers:integer;
  countEquipment:integer;
  countExcavs:integer;
  countNetworkEQ:integer;
  countDrills:integer;
  countSZMs:integer;
  //countTasks:integer;
  Sound:TThreadBeep;
  FileVersion:TFileInfo;
  ResourceChecker1:TResouceChecker;
  waitActions:boolean;
  countMessages:integer; // Количество сохраненных сообщений из MMessages в файл логов сообщений
  LogMessagesName:string;
  TasksManager : TTasksManagerThread;
implementation

{$R *.dfm}

procedure SuspendMonitoringByHour(intfc: CInterface);
begin
     intfc.MonitoringSuspendByHour;
end;

procedure TfrmMain.RxTrayIcon1DblClick(Sender: TObject);
begin
  try
      RxTrayIcon1.visible := false;
      ShowWindow(Application.Handle,SW_SHOW);
      Application.Restore;
      Application.BringToFront;
      self.Repaint;
  except
      RxTrayIcon1.Visible :=true;
  end;
end;

procedure TfrmMain.SaveWaitActions;
var docnode:IXMLNode;
    eqNode:IXMLNode;
    waitactNode:IXMLNode;
    //waitTypeNode:IXMLNode;
    waitCommentNode:IXMLNode;
    i:integer;
    MEQ:TMobileEquipment;
  j: Integer;
begin
     if not waitActions then begin
        if FileExists(waitListFilePath) then DeleteFile(waitListFilePath);
        exit;
     end;
     dm1.tempXML.Active:=true;
     dm1.tempXML.ChildNodes.Clear;
     dm1.tempXML.Version:='1.0';
     docnode:=dm1.tempXML.AddChild('waitlist');
     for I := 0 to EQALLList.Count -1 do begin
       if (TEquipment(EQALLList[i]^).ClassParent.ClassParent=TMobileEquipment) then begin
          MEQ:=TMobileEquipment(EQALLList[i]^);
          eqnode:=nil;
          for j := 0 to MEQ.waitList.Count-1 do begin
              if TwaitAction(MEQ.waitList[j]^).isWait then begin
                if (eqnode=nil) then begin
                    eqnode:=docnode.AddChild('equipment');
                    eqNode.Attributes['name']:=MEQ.name;
                end;
                waitactNode:=eqnode.AddChild('wait');
                waitactNode.Attributes['type']:=TwaitAction(MEQ.waitList[j]^).ClassName;
                waitactNode.Attributes['isCome']:=TwaitAction(MEQ.waitList[j]^).isCurrCome;
                if (TwaitAction(MEQ.waitList[j]^).comment<>'') then begin
                  waitCommentNode:=waitactNode.AddChild('comment');
                  waitCommentNode.NodeValue:=TwaitAction(MEQ.waitList[j]^).comment;
                end;
              end;
          end;
       end;
     end;
     dm1.tempXML.SaveToFile(waitListFilePath);
     dm1.tempXML.Active:=false;
end;

// Временное отключение мониторинга на неисправном оборудовании
procedure TfrmMain.sbDisableCheckClick(Sender: TObject);
var i,j:integer;
    pnt,pnt1:TPoint;
begin
     BBDisableSound.Click;
     PMDisable1h.Items.Clear;
     disable1hArray.Clear;
     if countServers>0 then begin
        for I := 1 to countServers do begin
          for j := 1 to ServersArray[i].Interfaces.count do begin
            if ServersArray[i].Interfaces[j].status=s_NoData then begin
               AddPMItem(PMDisable1h.Items,'d1h'+inttostr(PMDisable1h.Items.Count),serversArray[i].name+':'+ serversArray[i].Interfaces[j].DisplayName,PMDisableClick);
               disable1hArray.AddObject('',serversArray[i].Interfaces[j]);
            end;
          end;
        end;
     end;
     if countNetworkEQ>0 then begin
        for I := 1 to countNetworkEQ do begin
          for j := 1 to NetworkEQArray[i].Interfaces.count do begin
            if NetworkEQArray[i].Interfaces[j].status=s_NoData then begin
               AddPMItem(PMDisable1h.Items,'d1h'+inttostr(PMDisable1h.Items.Count),NetworkEQArray[i].name+':'+ NetworkEQArray[i].Interfaces[j].DisplayName,PMDisableClick);
               disable1hArray.AddObject('',NetworkEQArray[i].Interfaces[j]);
            end;
          end;
        end;
     end;
     if countEquipment>0 then begin
        for I := 1 to countEquipment do begin
          for j := 1 to MobileEQArray[i].Interfaces.count do begin
            if MobileEQArray[i].Interfaces[j].status=s_NoData then begin
               AddPMItem(PMDisable1h.Items,'d1h'+inttostr(PMDisable1h.Items.Count),MobileEQArray[i].name+':'+ MobileEQArray[i].Interfaces[j].DisplayName,PMDisableClick);
               disable1hArray.AddObject('',MobileEQArray[i].Interfaces[j]);
            end;
          end;
        end;
     end;
     if countExcavs>0 then begin
        for I := 1 to countExcavs do begin
          for j := 1 to ExcavsArray[i].Interfaces.count do begin
            if ExcavsArray[i].Interfaces[j].status=s_NoData then begin
               AddPMItem(PMDisable1h.Items,'d1h'+inttostr(PMDisable1h.Items.count),ExcavsArray[i].name+':'+ ExcavsArray[i].Interfaces[j].DisplayName,PMDisableClick);
               disable1hArray.AddObject('',ExcavsArray[i].Interfaces[j]);
            end;
          end;
        end;
     end;
     if countDrills>0 then begin
        for I := 1 to countDrills do begin
          for j := 1 to DrillsArray[i].Interfaces.count do begin
            if DrillsArray[i].Interfaces[j].status=s_NoData then begin
               AddPMItem(PMDisable1h.Items,'d1h'+inttostr(PMDisable1h.Items.Count),DrillsArray[i].name+':'+ DrillsArray[i].Interfaces[j].DisplayName,PMDisableClick);
               disable1hArray.AddObject('',DrillsArray[i].Interfaces[j]);
            end;
          end;
        end;
     end;
     if countSZMs>0 then begin
        for I := 1 to countSZMs do begin
          for j := 1 to SZMsArray[i].Interfaces.count do begin
            if SZMsArray[i].Interfaces[j].status=s_NoData then begin
               AddPMItem(PMDisable1h.Items,'d1h'+inttostr(PMDisable1h.Items.Count),SZMsArray[i].name+':'+ SZMsArray[i].Interfaces[j].DisplayName,PMDisableClick);
               disable1hArray.AddObject('',SZMsArray[i].Interfaces[j]);
            end;
          end;
        end;
     end;
     if PMDisable1h.Items.Count>0 then begin
        AddPMItem(PMDisable1h.Items,'d1h'+inttostr(PMDisable1h.Items.count),'Все',PMDisableClick);
        GetCursorPos(pnt);
        //pnt:=ClientToScreen(Point(sbDisableCheck.Left,sbDisableCheck.Top+PCMain.Height-(17*PMDisable1h.Items.Count)));
        if PMDisable1h.Items.Count<3 then PMDisable1h.Items[0].Click
          else PMDisable1h.Popup(pnt.X,pnt.y-10-(20*PMDisable1h.Items.Count));
     end else begin
        sbDisableCheck.Enabled:=false;
     end;
end;

procedure TfrmMain.Hide_appl(Sender: TObject);
begin
  RxTrayIcon1.visible := true;
  Application.Minimize;
  ShowWindow(Application.Handle,SW_HIDE);
end;
{
procedure TfrmMain.InitServers;
var conntemp:TADOConnection;
    qryServers, qryInterfaces:TADOQuery;
    servname,intfcname:string;
    servercreated:boolean;
    eqid:integer;
    i:integer;
begin

     countServers:=0;
     CoInitialize(nil);
     Conntemp:=TADOConnection.Create(nil);
     Conntemp.KeepConnection:=false;
     Conntemp.LoginPrompt:=false;
     Conntemp.Provider:='MSDASQL.1';
     conntemp.ConnectionString:=dm1.ConnMySQL.ConnectionString;
     qryServers:=TADOQuery.Create(nil);
     qryServers.Connection:=Conntemp;
     qryInterfaces:=TADOQuery.Create(nil);
     qryInterfaces.Connection:=conntemp;
     qryServers.SQL.Clear;
     qryServers.SQL.Add('select distinct ei.equipment, e.name from equipment_interfaces ei, equipment e where (e.equipment_type=4) and (e.id=ei.equipment)');
     qryServers.Open;
     qryServers.First;
     while not qryServers.Eof do begin
         // Создать сервер
         servercreated:=false;
         servname:=qryServers.FieldByName('name').AsString;
         eqid:=qryServers.FieldByName('equipment').AsInteger;
         if LowerCase(servname)='powerview' then begin
            ServersArray[countServers+1]:=TPowerView.Create;
            servercreated:=true;
         end;
         if LowerCase(servname)='lgkdisp' then begin
            ServersArray[countServers+1]:=TDispatch.Create;
            servercreated:=true;
         end;
         // Если сервер был создан
         if servercreated then begin
           inc(countServers);
           ServersArray[countServers].name:=servname;
           ServersArray[countServers].getIPAddress;
           if qryInterfaces.Active then qryInterfaces.Close;
           qryInterfaces.SQL.Clear;
           qryInterfaces.SQL.Add('select ei.interface, ri.name from equipment_interfaces ei, ref_interfaces ri');
           qryInterfaces.SQL.Add('where (ei.equipment='+inttostr(eqid)+') and (ei.interface=ri.id)');
           qryInterfaces.Open;
           qryInterfaces.First;
           while not qryInterfaces.Eof do begin
               intfcname:=qryInterfaces.FieldByName('name').AsString;
               ServersArray[countServers].Interfaces.Add(ServersArray[countServers].Interfaces.getByName(intfcname),1);
               qryInterfaces.Next;
           end;
           qryInterfaces.Close
         end;
         qryServers.Next;
     end;
     qryServers.Close;
     for I := 1 to countServers do EQALLList.Add(@ServersArray[i]);
     SGServer.Repaint;
     FreeAndNil(qryInterfaces);
     FreeAndNil(qryServers);
     FreeAndNil(conntemp);
end;

procedure TfrmMain.InitServersold;
     var i:integer;
begin
      ServersArray[1]:=TPowerView.Create;
      ServersArray[1].name:='PowerView';
      ServersArray[1].getIPAddress;
      ServersArray[1].Interfaces.Add(TPowerView(ServersArray[1]).LoadDataInterface,1);
      ServersArray[2]:=TDispatch.Create;
      ServersArray[2].name:='lgkdisp';
      ServersArray[2].getIPAddress;
      ServersArray[2].Interfaces.Add(TDispatch(ServersArray[2]).IsRunTransact,1);
      ServersArray[2].Interfaces.Add(TDispatch(ServersArray[2]).IsRunExcept,1);
      ServersArray[2].Interfaces.Add(TDispatch(ServersArray[2]).IsRunGPS,1);
      ServersArray[2].Interfaces.Add(TDispatch(ServersArray[2]).FreeSpace,1);
      countServers:=2;
      for I := 1 to countServers do EQALLList.Add(@ServersArray[i]);
      SGServer.Repaint;
end;
}
type cTask = class of TTask;

{procedure TfrmMain.InitTasks;
var i:integer;
    created:boolean;
    ct1:cTask;
    clname:string;
begin
      countTasks:=0;
      for I := 0 to objSettings.TasksCount - 1 do begin
          created:=false;
          // 2020-04-06 Переделал, чтобы новые задания автоматически запускались
          // и не нужно было каждое сюда вносить
          clname:='TTask'+objSettings.tasks[i].name;
            ct1:=cTask(GetClass(clname));
            if ct1<>nil then begin
                TasksArray[countTasks+1]:=ct1.Create;
                created:=true;
            end else begin
                // 2020-04-09 Проверяем старые задачи по именам,
                // так как старые имена в конфигах могут не совпадать с именами классов
                if objSettings.tasks[i].name='ResetPresspro' then begin
                  TasksArray[countTasks+1]:=TtaskResetPressureGSP.Create;
                  created:=true;
                end;
                if objSettings.tasks[i].name='DrawPitgraph' then begin
                  TasksArray[countTasks+1]:=TTaskGenerateImagePitgraph.Create;
                  created:=true;
                end;
                if objSettings.tasks[i].name='DrawPitASUGTK' then begin
                    TasksArray[countTasks+1]:=TTaskGenerateImagePitgraphASUGTK.Create;
                    created:=true;
                end;
                if objSettings.tasks[i].name='CalcWiFiStatEQ' then begin
                    TasksArray[countTasks+1]:=TTaskCalcStatWiFiByEquipment.Create;
                    created:=true;
                end;
            end;
          if created then begin
             TasksArray[countTasks+1].sleeptime:=objSettings.tasks[i].sleeptimeSec;
             inc(countTasks);
          end;
      end;
end;  }

procedure TfrmMain.LoadWaitActions;
var docnode:IXMLNode;
    eqnode:IXMLNode;
    waitnode:IXMLNode;
  I: Integer;
  eqname: string;
  EQ: TEquipment;
  j: Integer;
  MEQ:TMobileEquipment;
  KEQ:TKobusEquipment;
  ActionName: string;
  k: Integer;
  isCome:boolean;
  j1: Integer;
  comment: string;
  wa: TwaitAction;
begin
     if not FileExists(waitListFilePath) then exit;
     dm1.tempXML.Active:=true;
     if not dm1.tempXML.IsEmptyDoc then dm1.tempXML.ChildNodes.Clear;
     dm1.tempXML.LoadFromFile(waitListFilePath);
     try
        docnode:=dm1.tempXML.ChildNodes['waitlist'];
     except
        exit;
     end;
     for I := 0 to docnode.ChildNodes.Count - 1 do begin
         eqnode:=nil;
         if docnode.ChildNodes[i].NodeName='equipment' then begin
            eqname:=string(docnode.ChildNodes[i].Attributes['name']);
            eqnode:=docnode.ChildNodes[i];
         end;
         EQ:=GetEquipmentByName(eqname);
         if Assigned(EQ) and ((EQ.ClassParent.ClassParent=TMobileEquipment)) then begin
            for j := 0 to eqnode.ChildNodes.Count - 1 do begin
                if eqnode.ChildNodes[j].NodeName='wait' then begin
                    waitnode:=eqnode.ChildNodes[j];
                    if waitnode.HasAttribute('type') then ActionName:=String(waitnode.Attributes['type']) else
                        ActionName:=String(waitnode.NodeValue);
                    if waitnode.HasAttribute('isCome') then isCome:=waitnode.Attributes['isCome'] else isCome:=false;
                    comment:='';
                    if waitnode.HasChildNodes then begin
                      for j1 := 0 to waitnode.ChildNodes.Count - 1 do begin
                        if waitnode.ChildNodes[j1].NodeName='comment' then comment:=String(waitnode.ChildNodes[j1].NodeValue);
                      end;
                    end;
                    if EQ.ClassParent.ClassParent=TMobileEquipment then begin
                        MEQ:=TMobileEquipment(EQ);
                        k:=0;
                        while k<MEQ.waitList.Count do begin
                              if TwaitAction(MEQ.waitList[k]^).ClassName=ActionName then begin
                                 wa:=TWaitAction(MEQ.waitList[k]^);
                                 wa.isWait:=true;
                                 wa.isPrevCome:=False;
                                 wa.isCurrCome:=false;
                                 wa.comment:=comment;
                                 waitActions:=true;
                                 break;
                              end;
                              inc(k);
                        end;
                    end;
                    if EQ.ClassParent=TKobusEquipment then begin
                        KEQ:=TKobusEquipment(EQ);
                        k:=0;
                        while k<KEQ.waitList.Count do begin
                              if TwaitAction(KEQ.waitList[k]^).ClassName=ActionName then begin
                                 wa:=TWaitAction(KEQ.waitList[k]^);
                                 wa.isWait:=true;
                                 wa.isPrevCome:=False;
                                 wa.isCurrCome:=false;
                                 wa.comment:=comment;
                                 waitActions:=true;
                                 break;
                              end;
                              inc(k);
                        end;
                    end;
                end;
            end;
         end;
     end;
     dm1.tempXML.Active:=false;
end;

procedure TfrmMain.MMessagesChange(Sender: TObject);
var
  i: Integer;
  LogMessagesPath: string;
begin
     if LogMessagesName<>'' then begin
         LogMessagesPath:=ExtractFilePath(Application.ExeName)+LogMessagesName;
         MoveBigFile(LogMessagesPath,1024*1024,'.1');
         for i := countMessages to MMessages.Lines.Count-1 do begin
             SaveLogToFile(LogMessagesPath,MMessages.Lines[i]);
         end;
         countMessages:=MMessages.Lines.Count;
     end;
end;

procedure TfrmMain.NAboutClick(Sender: TObject);
var messagename, messageversion, messageAuthor:string;
begin
    if not Assigned(frmAbout) then Application.CreateForm(TfrmAbout, frmAbout);
    frmAbout.ShowModal();
end;

procedure TfrmMain.NChangeLogClick(Sender: TObject);
begin
     frmChangeLog.ShowModal;
end;

procedure TfrmMain.NCheckUpdateClick(Sender: TObject);
begin
     Updater.UpdateThread.NeedCheckUpdate:=true;
     sleep(100);
     StatusBar1.Panels[0].Text:='Проверка обновления запущена';
     sleep(1000);
     StatusBar1.Panels[0].Text:='Проверка обновления выполнена';
end;

procedure TfrmMain.NEditInterfacesClick(Sender: TObject);
begin
     if not Assigned(frmEditInterfaces) then Application.CreateForm(TfrmEditInterfaces, frmEditInterfaces);
     frmEditInterfaces.Show;
end;

procedure TfrmMain.NEnableGoodClick(Sender: TObject);
begin
     if NEnableGood.Checked then objSettings.AutoEnableMonitoring:=false else objSettings.AutoEnableMonitoring:=true;
     NEnableGood.Checked:=not NEnableGood.Checked;
end;

procedure TfrmMain.NPlannedWorksClick(Sender: TObject);
begin
     frmPlannedWorks.Show;
end;

procedure TfrmMain.NShowClockClick(Sender: TObject);
begin
     if NShowClock.Checked then objSettings.ShowClock:=false else objSettings.ShowClock:=true;
     LTime.Visible:=objSettings.ShowClock;
     TmTime.Enabled:=objSettings.ShowClock;
     NShowClock.Checked:=objSettings.ShowClock;
end;

procedure TfrmMain.NUploadFilesClick(Sender: TObject);
begin
    frmFTPTasks.Show;
end;

procedure TfrmMain.NVolumeAllClick(Sender: TObject);
begin
     if NVolumeAll.Checked then objSettings.Sound.Enable:=false else objSettings.Sound.Enable:=true;
     NVolumeAll.Checked:=not NVolumeAll.Checked;
     //BBDisableSound.Visible:=NVolumeAll.Checked
end;

procedure TfrmMain.NVolumeAllDrawItem(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect; Selected: Boolean);
begin
     //if objSettings.Sound.Enable then NVolumeAll.Checked:=true else NVolumeAll.Checked:=false;
end;

procedure TfrmMain.PMDisableClick(sender: TObject);
var idx:integer;
i:integer;
begin
     if sender.ClassName='TMenuItem' then begin
        idx:= TMenuItem(sender).MenuIndex;
        if idx<disable1hArray.Count then begin
           CInterface(disable1hArray.Objects[idx]).MonitoringSuspendByHour;
           CInterface(disable1hArray.Objects[idx]).Check;
           if disable1hArray.Count<2 then sbDisableCheck.Enabled:=false;
           StatusBar1.Panels[0].Text:='Мониторинг интерфейса '+TMenuItem(sender).Caption+' отключен на час';
        end else begin
           for i := 0 to disable1hArray.Count - 1 do begin
              CInterface(disable1hArray.Objects[i]).MonitoringSuspendByHour;
              CInterface(disable1hArray.Objects[i]).Check;
           end;
           sbDisableCheck.Enabled:=false;
           StatusBar1.Panels[0].Text:='Мониторинг всех нерабочих интерфейсов отключен на час';
        end;

     end;
     //PCMain.Repaint;
end;

procedure TfrmMain.PMTasksPopup(Sender: TObject);
var
  taskindex: Integer;
  task: TTask;
begin
     taskindex:=SGTasks.Row-1;
     if taskindex<0 then begin
        NTaskStart.visible:=false;
        NTaskStop.visible:=false;
        NTaskLog.Visible:=false;
      exit;
     end else begin
        NTaskStart.visible:=true;
        NTaskStop.visible:=true;
        NTaskLog.Visible:=true;
     end;
     try
         task:=TasksManager.TasksThreads[taskindex].task;
         if (task.Status=tst_running) or (task.PercentCompleted<100) then begin
            NTaskStart.Enabled:=false;
            NTaskStop.Enabled:=true;
         end else begin
            NTaskStart.Enabled:=true;
            NTaskStop.Enabled:=false;
         end;
     except

     end;
end;

procedure TfrmMain.InitEquipment(EquipmentType: TEquipmentType);
var conntemp:TADOConnection;
    qryEq, qryInterfaces:TADOQuery;
    eqname,intfcname:string;
    iscreated:boolean;
    eqid:integer;
    i:integer;
    cnt:integer;
    category:integer;
    EQ:TEquipment;
  itfcidx: Integer;
  str1:string;
  interfacecreated: Boolean;
  monstat1: Integer;
begin
     case Equipmenttype of
       servers: begin
          category:=4;
          countServers:=0;
       end;
       trucks: begin
          category:=1;
          countEquipment:=0;
       end;
       excavs: begin
          category:=2;
          countExcavs:=0;
       end;
       networking: begin
          category:=3;
          countNetworkEQ:=0;
       end;
       drills: begin
          category:=5;
          countDrills:=0;
       end;
       szms: begin
          category:=6;
          countSZMs:=0;
       end;
     end;
     CoInitialize(nil);
     Conntemp:=TADOConnection.Create(nil);
     Conntemp.KeepConnection:=false;
     Conntemp.LoginPrompt:=false;
     Conntemp.Provider:='MSDASQL.1';
     conntemp.ConnectionString:=dm1.ConnMySQL.ConnectionString;
     qryEQ:=TADOQuery.Create(nil);
     qryEQ.Connection:=Conntemp;
     qryInterfaces:=TADOQuery.Create(nil);
     qryInterfaces.Connection:=conntemp;
     qryEQ.SQL.Clear;
     qryEQ.SQL.Add('select e.id as equipment, e.name, e.ip_address, e.ip_pc from equipment e ');
     qryEQ.SQL.Add('where (e.equipment_type='+inttostr(category)+') and ((e.useInMonitoring=1)');
     if EquipmentType=trucks then qryEq.SQL.Add('or (e.name="A500")');
     qryEq.SQL.Add(')');
     qryEQ.SQL.Add('order by Name');
     qryEQ.Open;
     qryEQ.First;
     while not qryEQ.Eof do begin
         // Создать оборудование
         iscreated:=false;
         eqname:=qryEQ.FieldByName('name').AsString;
         eqid:=qryEQ.FieldByName('equipment').AsInteger;
         if category=1 then begin
            EQ:=TTruck.Create;
            iscreated:=true;
         end;
         if category=2 then begin
            EQ:=TExcav.Create;
            iscreated:=true;
         end;
         if category=3 then begin
            EQ:=TNetworkEQ.Create;
            iscreated:=true;
         end;
         if category=4 then begin
            if LowerCase(eqname)='powerview' then begin
               EQ:=TPowerView.Create;
               iscreated:=true;
            end;
            if LowerCase(eqname)='lgkdisp' then begin
               EQ:=TDispatch.Create;
               iscreated:=true;
            end;
         end;
         if category=5 then begin
            EQ:=TDrill.Create;
            iscreated:=true;
         end;
         if category=6 then begin
            EQ:=TSZM.Create;
            iscreated:=true;
         end;
         // Если был создан
         if iscreated then begin
           EQ.name:=eqname;
           EQ.GetMySQLIndex;
           if EQ.ClassParent.ClassName='TServer' then EQ.IPAddress:=EQ.getIPAddress;
           if EQ.ClassName='TNetworkEQ' then EQ.IPAddress:=qryEQ.FieldByName('ip_address').AsString;
           if EQ.ClassParent.ClassParent=TMobileEquipment then begin
              EQ.IPAddress:=qryEQ.FieldByName('ip_pc').AsString;
              TMobileEquipment(EQ).ModemIP:=qryEQ.FieldByName('ip_address').AsString;
           end;
           if qryInterfaces.Active then qryInterfaces.Close;
           qryInterfaces.SQL.Clear;
           qryInterfaces.SQL.Add('select ei.interface, ri.name from equipment_interfaces ei, ref_interface ri');
           qryInterfaces.SQL.Add('where (ei.equipment='+inttostr(eqid)+') and (ei.interface=ri.id)');
           qryInterfaces.Open;
           qryInterfaces.First;
           while not qryInterfaces.Eof do begin
               intfcname:=qryInterfaces.FieldByName('name').AsString;
               itfcidx:=objSettings.GetInterfaceIndexByName(intfcname);
               if (itfcidx>-1) or (EQ.ClassParent.ClassName='TServer') then begin
                  // [2020-12-28] Пока запускаем мониторинг WiFi в режиме теста без оповещений
                  if (EQ.ClassParent=TKobusEquipment) then monstat1:=2 else monstat1:=1;
                  if EQ.AddInterface(intfcname,monstat1) then begin
                     // Инициализируем параметры интерфейса
                     if itfcidx>-1 then begin
                        for I := 0 to Length(objSettings.interfaces[itfcidx].parameters)-1 do
                             EQ.Interfaces[EQ.Interfaces.count].AddDisplayParameter(objSettings.interfaces[itfcidx].parameters[i]);
                     end;
                  end;
               end;
               qryInterfaces.Next;
           end;
           qryInterfaces.Close;
           case Equipmenttype of
               servers: begin
                  inc(countServers);
                  ServersArray[countServers]:=TServer(EQ);
               end;
               trucks: begin
                  inc(countEquipment);
                  MobileEQArray[countEquipment]:=TMobileEQModular(EQ);
               end;
               excavs: begin
                  inc(countExcavs);
                  ExcavsArray[countExcavs]:=TMobileEQModular(EQ);
               end;
               networking: begin
                  inc(countNetworkEQ);
                  NetworkEQArray[countNetworkEQ]:=TNetworkEQ(EQ);
               end;
               drills: begin
                  inc(countDrills);
                  DrillsArray[countDrills]:=TDrill(EQ);
               end;
               szms: begin
                  inc(countSZMs);
                  SZMsArray[countSZMs]:=TSZM(EQ);
               end;
           end;
         end;
         qryEQ.Next;
     end;
     case EquipmentType of
       servers: SGServer.Repaint;
       trucks: SGEquipment.Repaint;
       excavs: SGExcavs.Repaint;
       networking: SGNetwork.Repaint;
       drills:SGDrills.Repaint;
       szms:SGSZMs.Repaint;
     end;
     qryEQ.Close;
     // Обновляем полный список оборудования
     EQALLList.Clear;
     for i := 1 to countServers do EQALLList.Add(@ServersArray[i]);
     for i := 1 to countEquipment do EQALLList.Add(@MobileEQArray[i]);
     for i := 1 to countExcavs do EQALLList.Add(@ExcavsArray[i]);
     for I := 1 to countNetworkEQ do EQALLList.Add(@NetworkEQArray[i]);
     for I := 1 to countDrills do EQALLList.Add(@DrillsArray[i]);
     for I := 1 to countSZMs do EQALLList.Add(@SZMsArray[i]);

     FreeAndNil(qryInterfaces);
     FreeAndNil(qryEQ);
     FreeAndNil(conntemp);
end;
{
Procedure TfrmMain.InitMobileEq;
var conntemp:TADOConnection;
    qryEQ, qryInterfaces:TADOQuery;
    eqname,intfcname:string;
    iscreated:boolean;
    eqid:integer;
    i:integer;
    itfcidx:integer;
    EQ:TMobileEquipment;
    cat:shortint;
    str:string;
begin
     countEquipment:=0;
     countExcavs:=0;
     CoInitialize(nil);
     Conntemp:=TADOConnection.Create(nil);
     Conntemp.KeepConnection:=false;
     Conntemp.LoginPrompt:=false;
     Conntemp.Provider:='MSDASQL.1';
     conntemp.ConnectionString:=dm1.ConnMySQL.ConnectionString;
     qryEQ:=TADOQuery.Create(nil);
     qryEQ.Connection:=Conntemp;
     qryInterfaces:=TADOQuery.Create(nil);
     qryInterfaces.Connection:=conntemp;
     for cat := 1 to 2 do begin
         if (cat=2) and (not objSettings.ShowExcavs) then break;
         qryEQ.SQL.Clear;
         qryEQ.SQL.Add('select distinct ei.equipment, e.name, e.ip_address from equipment_interfaces ei, equipment e ');
         qryEQ.SQL.Add('where (e.equipment_type='+inttostr(cat)+') and ((e.useInMonitoring=1)or (e.name="A500")) and (e.id=ei.equipment)');
         qryEQ.SQL.Add('order by Name');
         qryEQ.Open;
         qryEQ.First;
         while not qryEQ.Eof do begin
             // Создать оборудование
             iscreated:=false;
             eqname:=qryEQ.FieldByName('name').AsString;
             eqid:=qryEQ.FieldByName('equipment').AsInteger;
             if cat=1 then begin
                EQ:=TTruck.Create;
                iscreated:=true;
             end;
             if cat=2 then begin
                EQ:=TExcav.Create;
                iscreated:=true;
             end;
             // Если был создан
             if iscreated then begin
               EQ.name:=eqname;
               EQ.IPAddress:=qryEQ.FieldByName('ip_address').AsString;
               str:=StringReplace(EQ.IPAddress,'.123.','.122.',[]);
               EQ.ModemIP:=EQ.IPAddress;
               EQ.IPAddress:=str;
               if qryInterfaces.Active then qryInterfaces.Close;
               qryInterfaces.SQL.Clear;
               qryInterfaces.SQL.Add('select ei.interface, ri.name from equipment_interface ei, ref_interfaces ri');
               qryInterfaces.SQL.Add('where (ei.equipment='+inttostr(eqid)+') and (ei.interface=ri.id)');
               qryInterfaces.Open;
               qryInterfaces.First;
               while not qryInterfaces.Eof do begin
                   intfcname:=qryInterfaces.FieldByName('name').AsString;
                   itfcidx:=objSettings.GetInterfaceIndexByName(intfcname);
                   if itfcidx>-1 then
                      EQ.Interfaces.Add(EQ.Interfaces.getByName(intfcname),1);
                   // Инициализируем параметры интерфейса
                   for I := 0 to Length(objSettings.interfaces[itfcidx].parameters)-1 do
                       EQ.Interfaces[EQ.Interfaces.count].AddDisplayParameter(objSettings.interfaces[itfcidx].parameters[i]);
                   qryInterfaces.Next;
               end;
               qryInterfaces.Close;
               // Если категория 1, то записываем в самосвалы, иначе в экскаваторы
               if cat=1 then begin
                  inc(countEquipment);
                  MobileEQArray[countEquipment]:=EQ;
               end;
               if cat=2 then begin
                  inc(countExcavs);
                  ExcavsArray[countExcavs]:=EQ;
               end;
             end;
             qryEQ.Next;
         end;
         qryEQ.Close;
     end;
     for I := 1 to countEquipment do EQALLList.Add(@MobileEQArray[i]);
     for I := 1 to countExcavs do EQALLList.Add(@ExcavsArray[i]);
     SGEquipment.Repaint;
     SGExcavs.Repaint;
     FreeAndNil(qryInterfaces);
     FreeAndNil(qryEQ);
     FreeAndNil(conntemp);

end;

procedure TfrmMain.InitMobileEqold;
var i,j :integer;
    digit3ip:integer;
    str:string;
begin
      // Инициализация списка оборудования и интерфейсов для мониторинга
      CountEquipment:=0;
      dm1.qEquipment.Active:=false;
      dm1.qEquipment.SQL.Clear;
      dm1.qEquipment.SQL.Add('select id, name, ip_address, equipment_type  from equipment');
      dm1.qEquipment.SQL.Add('where ((equipment_type=1) and (useInMonitoring=1))');
      // Для участка АСУГТК показывать еще А500 для работы с ним
      if objSettings.IsAdmin then dm1.qEquipment.SQL.Add(' or (name="A500")');
      dm1.qEquipment.SQL.Add('order by Name');
      if not DM1.qEquipment.Active then DM1.qEquipment.Open;
      while not DM1.qEquipment.Eof do begin
          inc(CountEquipment);
          // Если тип - экскаватор, то создаем объект экскаватор, иначе создаем объект самосвал
          if dm1.qEquipmentEquipment_type.value=2 then MobileEQArray[countEquipment]:=TExcav.Create else
             MobileEQArray[countEquipment]:=TTruck.Create;
          MobileEQArray[CountEquipment].name:=DM1.qEquipmentname.Value;
          str:=StringReplace(DM1.qEquipmentip_address.Value,'.123.','.122.',[]);
          MobileEQArray[countEquipment].IPAddress:=str;
          MobileEQArray[countEquipment].ModemIP:=DM1.qEquipmentip_address.Value;
          // Инициализация интерфейсов оборудования
          for I := 0 to Length(objSettings.interfaces) - 1 do begin
              if MobileEQArray[countEquipment].AddInterface(objSettings.interfaces[i].name,objSettings.interfaces[i].MonitoringStatus) then begin
                // Инициализация параметров интерфейса оборудования
                for j := 0 to Length(objSettings.interfaces[i].parameters) - 1 do
                  MobileEQArray[countEquipment].Interfaces[MobileEQArray[countEquipment].Interfaces.count].AddDisplayParameter(objSettings.interfaces[i].parameters[j]);
              end;
          end;
          EQALLList.Add(@MobileEQArray[countEquipment]);
          DM1.qEquipment.Next;
      end;
      DM1.qEquipment.Close;
      SGEquipment.Repaint;

      // Инициализация списка экскаваторов
      countExcavs:=0;
      if objSettings.ShowExcavs then begin
          if not DM1.qExcavs.Active then DM1.qExcavs.Open;
          while not DM1.qExcavs.Eof do begin
              inc(CountExcavs);
              // Если тип - экскаватор, то создаем объект экскаватор, иначе создаем объект самосвал
              if dm1.qExcavsEquipment_type.value=2 then ExcavsArray[CountExcavs]:=TExcav.Create else
                 ExcavsArray[CountExcavs]:=TTruck.Create;
              ExcavsArray[CountExcavs].name:=DM1.qExcavsname.Value;
              str:=StringReplace(DM1.qExcavsip_address.Value,'.123.','.122.',[]);
              ExcavsArray[CountExcavs].IPAddress:=str;
              ExcavsArray[CountExcavs].ModemIP:=DM1.qExcavsip_address.Value;
              // Инициализация интерфейсов оборудования
              for I := 0 to Length(objSettings.interfaces) - 1 do begin
                  if ExcavsArray[CountExcavs].AddInterface(objSettings.interfaces[i].name,objSettings.interfaces[i].MonitoringStatus) then begin
                    // Инициализация параметров интерфейса оборудования
                    for j := 0 to Length(objSettings.interfaces[i].parameters) - 1 do
                      ExcavsArray[CountExcavs].Interfaces[ExcavsArray[CountExcavs].Interfaces.count].AddDisplayParameter(objSettings.interfaces[i].parameters[j]);
                  end;
              end;
              EQALLList.Add(@ExcavsArray[countExcavs]);
              DM1.qExcavs.Next;
          end;
          DM1.qExcavs.Close;
          SGExcavs.Repaint;
      end;
end;

procedure TfrmMain.InitNetworkEQ;
var conntemp:TADOConnection;
    qryEQ, qryInterfaces:TADOQuery;
    eqname,intfcname:string;
    iscreated:boolean;
    eqid:integer;
    i:integer;
    itfcidx:integer;
    intfccreated:boolean;
begin
     countNetworkEQ:=0;
     CoInitialize(nil);
     Conntemp:=TADOConnection.Create(nil);
     Conntemp.KeepConnection:=false;
     Conntemp.LoginPrompt:=false;
     Conntemp.Provider:='MSDASQL.1';
     conntemp.ConnectionString:=dm1.ConnMySQL.ConnectionString;
     qryEQ:=TADOQuery.Create(nil);
     qryEQ.Connection:=Conntemp;
     qryInterfaces:=TADOQuery.Create(nil);
     qryInterfaces.Connection:=conntemp;
     qryEQ.SQL.Clear;
     qryEQ.SQL.Add('select distinct ei.equipment, e.name, e.ip_address from equipment_interfaces ei, equipment e where (e.equipment_type=3) and (e.id=ei.equipment)');
     qryEQ.Open;
     qryEQ.First;
     while not qryEQ.Eof do begin
         // Создать оборудование
         iscreated:=false;
         eqname:=qryEQ.FieldByName('name').AsString;
         eqid:=qryEQ.FieldByName('equipment').AsInteger;
         NetworkEQArray[countNetworkEQ+1]:=TNetworkEQ.Create;
         iscreated:=true;
         // Если был создан
         if iscreated then begin
           inc(countNetworkEQ);
           NetworkEQArray[countNetworkEQ].name:=eqname;
           NetworkEQArray[countNetworkEQ].IPAddress:=qryEQ.FieldByName('ip_address').AsString;
           if qryInterfaces.Active then qryInterfaces.Close;
           qryInterfaces.SQL.Clear;
           qryInterfaces.SQL.Add('select ei.interface, ri.name from equipment_interfaces ei, ref_interfaces ri');
           qryInterfaces.SQL.Add('where (ei.equipment='+inttostr(eqid)+') and (ei.interface=ri.id)');
           qryInterfaces.Open;
           qryInterfaces.First;
           while not qryInterfaces.Eof do begin
               intfcname:=qryInterfaces.FieldByName('name').AsString;
               itfcidx:=objSettings.GetInterfaceIndexByName(intfcname);
               if itfcidx>-1 then
                  NetworkEQArray[countNetworkEQ].Interfaces.Add(NetworkEQArray[countNetworkEQ].Interfaces.getByName(intfcname),1);
                  intfcCreated:=true;
               // Инициализируем параметры интерфейса
               for I := 0 to Length(objSettings.interfaces[itfcidx].parameters)-1 do
                   NetworkEQArray[CountNetworkEQ].Interfaces[NetworkEQArray[CountNetworkEQ].Interfaces.count].AddDisplayParameter(objSettings.interfaces[itfcidx].parameters[i]);
               qryInterfaces.Next;
           end;
           qryInterfaces.Close
         end;
         qryEQ.Next;
     end;
     qryEQ.Close;
     for I := 1 to countNetworkEQ do EQALLList.Add(@NetworkEQArray[i]);
     SGNetwork.Repaint;
     FreeAndNil(qryInterfaces);
     FreeAndNil(qryEQ);
     FreeAndNil(conntemp);
end;

procedure TfrmMain.InitNetworkEQold;
var i,j:integer;
begin
     TSNetworking.TabVisible:=false;
     TSNetworking.Visible:=false;
     if objSettings.ShowNetwork then begin
        TSNetworking.Visible:=true;
        TSNetworking.TabVisible:=true;
        PCMain.ActivePage:=TSNetworking;
        if not DM1.qNetwork.Active then DM1.qNetwork.Open;
          while not DM1.qNetwork.Eof do begin
              inc(CountNetworkEQ);
              NetworkEQArray[countNetworkEQ]:=TNetworkEQ.Create;
              NetworkEQArray[CountNetworkEQ].name:=DM1.qNetworkname.Value;
              NetworkEQArray[CountNetworkEQ].IPAddress:=DM1.qNetworkip_address.Value;
              // Инициализация интерфейсов оборудования
              for I := 0 to Length(objSettings.interfaces) - 1 do begin
                  if NetworkEQArray[CountNetworkEQ].AddInterface(objSettings.interfaces[i].name,objSettings.interfaces[i].MonitoringStatus) then begin
                    // Инициализация параметров интерфейса оборудования
                    for j := 0 to Length(objSettings.interfaces[i].parameters) - 1 do
                      NetworkEQArray[CountNetworkEQ].Interfaces[NetworkEQArray[CountNetworkEQ].Interfaces.count].AddDisplayParameter(objSettings.interfaces[i].parameters[j]);
                  end;
              end;
              EQALLList.Add(@NetworkEQArray[countNetworkEQ]);
              DM1.qNetwork.Next;
          end;
          DM1.qNetwork.Close;
          SetGridSizes(SGNetwork);
          SGNetwork.Repaint;
     end;
end;
}
procedure TfrmMain.FormActivate(Sender: TObject);
begin
  if IsFirstActivate then Hide_appl(@Self);
  IsFirstActivate:=false;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var i,j,cnt, len1:integer;
    col,row:shortint;
    finfo:TFileInfo;
    icon_name:string;
begin
//  ReportMemoryLeaksOnShutdown:=true;
  FormStorage1.IniFileName:=ExtractFilePath(Application.ExeName)+'FormStorage.ini';
  FormStorage1.Active:=true;
  countMessages:=0;
  LogMessagesName:='Messages.log';
  disable1hArray:=TStringList.Create;
  IsFirstActivate:=true;
  HintShowedSec:=0;
  // Инициализация ssh
  //cryptInit;
  //dm.OSSH:=TSSHobj.Create;
  if GetFileInfo(Application.ExeName,fInfo) then self.Caption:='Мониторинг состояния системы АСУГТК v.'+inttostr(finfo.FileVersion.MajorVersion)+'.'+inttostr(finfo.FileVersion.MinorVersion)+'.'+inttostr(finfo.FileVersion.Release)+' (build '+inttostr(finfo.FileVersion.Build)+')';
  Application.OnMinimize := Hide_appl;
  FileVersion:=finfo;

  // Загрузка настроек из конфигурационного файла
  settingsFilePath:=ExtractFilePath(Application.ExeName)+'settings.ini';
  objSettings:=TSettingsOld.Create;
  objSettings.ReadSettings(settingsFilePath);
  //if objSettings.IsAdmin then NUtility.Visible:=true else NUtility.Visible:=false;
  // Если включена настройка звука
  if objSettings.Sound.Enable then begin
     BBDisableSound.Visible:=true;
     BBDisableSound.Enabled:=false;
     NVolumeAll.Checked:=true
  end else begin
     BBDisableSound.Visible:=true;
     BBDisableSound.Enabled:=false;
     NVolumeAll.Checked:=false;
  end;
  // Если включена настройка включения мониторинга
  if objSettings.AutoEnableMonitoring then NEnableGood.Checked:=true else NEnableGood.Checked:=false;

  frmMain.Width:=objSettings.ClientWidth;
  frmMain.Height:=objSettings.ClientHeight;
  // Подключаем модуль обновления
  if objSettings.UpdateEnabled then begin
     if not Assigned(Updater.UpdateThread) then Updater.UpdateThread:= Updater.TUpdater.Create(true);
     Updater.UpdateThread.LocationUpdate:=objSettings.UpdateFolder;
     Updater.UpdateThread.TempPostfix:=objSettings.UpdatePostfix;
     Updater.UpdateThread.Resume;
     sleep(100);
     if not Assigned(UpdMessenger.UpdaterMessenger) then UpdMessenger.UpdaterMessenger:=UpdMessenger.TUpdaterMessenger.Create(false);
  end;
  if objSettings.CopyExe then MyUtils.CopyEXEVersion(Application.ExeName,'exe');
  // Закончили подключать обновления
  EQALLList:=TList.Create;
  // Инициализация проверки серверов
  if not objSettings.NotCheckServers then begin
     // Инициализация серверов
     InitEquipment(servers);
     SetGridSizes(SGServer);
     tsServer.TabVisible:=true;
     tsServer.Visible:=true;
     PCMain.ActivePage:=tsServer;
  end else begin
     tsServer.TabVisible:=false;
     tsServer.Visible:=false;
  end;
  // Окончание инициализации проверки серверов
  // Инициализация списка сетевого оборудования
  if objSettings.ShowNetwork then begin
      InitEquipment(networking);
      SetGridSizes(SGNetwork);
      tsNetworking.TabVisible:=true;
      tsNetworking.Visible:=true;PCMain.ActivePage:=tsNetworking;
  end else begin
      tsNetworking.TabVisible:=false;
      tsNetworking.Visible:=false;
  end;
  // Окончание инициализации списка сетевого оборудовния
  // Отображение данных об экскаваторах
  if objSettings.ShowExcavs then  begin
     //InitMobileEqold;
     InitEquipment(excavs);
     setGridSizes(SGExcavs);
     tsExcavs.tabVisible:=true;
     tsExcavs.Visible:=true;
     PCMain.ActivePage:=tsExcavs;
  end else begin
     tsExcavs.tabVisible:=false;
     tsExcavs.Visible:=false;
  end;
  // Окончание отображения данных об экскаваторах
  // Отображение данных о самосвалах
  if objSettings.ShowTrucks then begin
     InitEquipment(trucks);
     setGridSizes(SGEquipment);
     TSEquipment.tabVisible:=true;
     TSEquipment.Visible:=true;
     PCMain.ActivePage:=TSEquipment;
  end else begin
     TSEquipment.tabVisible:=false;
     TSEquipment.Visible:=false;
  end;
  // Окончание отображения данных о самосвалах
  // Отображение данных о бурстанках и сзм
  if objSettings.ShowDrills then begin
     InitEquipment(drills);
     setGridSizes(SGDrills);
     tsDrills.tabVisible:=true;
     tsDrills.Visible:=true;
     PCMain.ActivePage:=tsDrills;
     InitEquipment(szms);
     setGridSizes(SGSZMs);
     tsSZMs.tabVisible:=true;
     tsSZMs.Visible:=true;
  end else begin
     tsDrills.tabVisible:=false;
     tsDrills.Visible:=false;
  end;
  // Окончание отображения данных о бурстанках
  frmMain.Resize;
  // Загрузка данных об ожидании состояния техники
  waitListFilePath:=ExtractFilePath(Application.ExeName)+'waitlist.xml';
  LoadWaitActions;
  // Инициализация пищалки
  if not Assigned(Sound) then Sound:=TThreadBeep.Create(true);
  Sound.Duration:=objSettings.Sound.Duration;
  // Если процесс проверки еще не инициализирован, то инициализируем его, иначе перезапускаем
  if EQALLList.Count>0 then begin
      if  not assigned(MyTimer.MyTimerThread) then MyTimer.MyTimerThread := MyTimer.TMyTimerThread.Create(false)
          else bDoWorkClick(sender);
      sleep(100);
      // Запускаем поток контроллера мониторинга для перезагрузки потока мониторинга при его зависании
      if not assigned(MyTimer.ControllerThread) then MyTimer.ControllerThread:=MyTimer.TControllerMonitorThread.Create(false);
  end;

  if objSettings.TasksCount>0 then begin
      tsTasks.TabVisible:=true;
      tsTasks.Visible:=true;
      // Запуск потока для выполнения задач
      if not Assigned(TasksManager) then TasksManager:= TasksUnit.TTasksManagerThread.Create;
      for I := 0 to objSettings.TasksCount-1 do begin
          TasksManager.AddTask(objSettings.tasks[i].name,objSettings.tasks[i].sleeptimeSec);
      end;
      TasksManager.Start;
  end else begin
      tsTasks.TabVisible:=false;
      tsTasks.Visible:=false;
  end;
  PBDStatus.Visible:=true;
  if not Assigned(ResourceChecker1) then ResourceChecker1:=TResouceChecker.Create(false)
      else ResourceChecker1.Resume;
  // Есди пользователь не asugtkadm, то для него загрузить другую иконку трея
  if not objSettings.IsAdmin then begin
      if (not FileExists(ExtractFilePath(Application.ExeName)+'icon_guest.ico')) and FileExists(objSettings.UpdateFolder+'icon_guest.ico')
         then CopyFile(PWideChar(objSettings.UpdateFolder+'icon_guest.ico'),PWideChar(ExtractFilePath(Application.ExeName)+'icon_guest.ico'),False);
      if FileExists(ExtractFilePath(Application.ExeName)+'icon_guest.ico')
         then RxTrayIcon1.Icon.LoadFromFile(ExtractFilePath(Application.ExeName)+'icon_guest.ico');
  end;
  // Инициализация формы загрузки файлов на PTX
  if objSettings.IsAdmin then begin
       frmFTPTasks:=TfrmFTPTasks.Create(frmMain);
       frmFTPUploadAdd:=TfrmFTPUploadAdd.Create(frmMain);
       // Открываем доступ к форме загрузки файлов
       if not NUtility.Visible then NUtility.Visible:=true;
       if not NUploadFiles.Visible then NUploadFiles.Visible:=true;
  end;
  // Отображение часов
  if objSettings.ShowClock then begin
      LTime.Visible:=true;
      TmTime.Enabled:=true;
      NShowClock.Checked:=true;
  end else begin
      LTime.Visible:=false;
      TmTime.Enabled:=false;
      NShowClock.Checked:=false;
  end;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
if Assigned(MyTimer.MyTimerThread) then
  begin
    try
        MyTimer.MyTimerThread.Terminate;
    except
    
    end;
  end;

  if Assigned(Updater.UpdateThread) then Updater.UpdateThread.Terminate;
  if Assigned(UpdMessenger.UpdaterMessenger) then UpdMessenger.UpdaterMessenger.Terminate;
  sleep(200);
  cryptEnd;
end;

procedure TfrmMain.FormResize(Sender: TObject);
var i,j,row,col:integer;
begin
  SGEquipment.ColCount:=(SGEquipment.Width-10) div SGEquipment.DefaultColWidth;
  SGEquipment.RowCount:=Math.Ceil(countEquipment / SGEquipment.ColCount);
  if objSettings.ShowExcavs then begin
      SGExcavs.ColCount:=(SGExcavs.Width-10) div SGExcavs.DefaultColWidth;
      SGExcavs.RowCount:=Math.Ceil(countExcavs / SGExcavs.ColCount);
  end;
  if objSettings.ShowNetwork then begin
      SGNetwork.ColCount:=(SGNetwork.Width-10) div SGNetwork.DefaultColWidth;
      SGNetwork.RowCount:=Math.Ceil(countNetworkEQ / SGNetwork.ColCount);
      if SGNetwork.RowCount=1 then SGNetwork.ColCount:=countNetworkEQ;

  end;
  if objSettings.ShowDrills then begin
      SGDrills.ColCount:=(SGDrills.Width-10) div SGDrills.DefaultColWidth;
      SGDrills.RowCount:=Math.Ceil(countDrills / SGDrills.ColCount);
      if SGDrills.RowCount=1 then SGDrills.ColCount:=countDrills;
      SGSZMs.ColCount:=(SGSZMs.Width-10) div SGSZMs.DefaultColWidth;
      SGSZMs.RowCount:=Math.Ceil(countSZMs / SGSZMs.ColCount);
      if SGSZMs.RowCount=1 then SGSZMs.ColCount:=countSZMs;
  end;
  // Обнуляем значения ячеек
  for i:=0 to SGEquipment.RowCount do
      for j := 0 to SGEquipment.ColCount do SGEquipment.Cells[j,i]:='';
  // Записать названия оборудования в ячейки
  for i:=1 to countEquipment do begin
      row:=((i-1) div SGEquipment.ColCount);
      col:=(i-1) mod SGEquipment.ColCount;
      SGEquipment.Cells[col,row]:=MobileEQArray[i].name;
  end;
  SetTasksGridSizes;
  if (frmMain.Width>100) and (frmMain.Height>100) then begin
     objSettings.SetClientSizes(frmMain.Width,frmMain.Height);
  end;
end;

procedure TfrmMain.GenerateInterfacesMenuItems(PM: TPopupMenu; EQ: TEquipment);
var MIInterfaces, menuitem, parentMItem:TMenuItem;
    i:integer;
    intfcName:string;
    mso:word;
begin
     if EQ.Interfaces.count>0 then begin
         MIInterfaces:=TMenuItem.Create(nil);
         PM.Items.Add(MIInterfaces);
         MIInterfaces.Caption:='Интерфейсы';
         MIInterfaces.Visible:=true;
         for I := 1 to EQ.Interfaces.count do begin
             IntfcName:=EQ.Interfaces[i].name;
             menuItem:=TMenuItem.Create(nil);
             MIInterfaces.Add(menuItem);
             menuItem.Name:='DM_'+EQ.Interfaces[i].name;
             menuItem.Caption:=EQ.Interfaces[i].DisplayName;
             menuItem.Visible:=true;
             parentMItem:=menuItem;
             menuItem:=TMenuItem.Create(nil);
             parentMItem.Add(menuItem);
             menuItem.Caption:='Включение мониторинга';
             menuItem.Action:=AEnableMonitoring;
             menuItem.Enabled:=false;
             menuItem:=TMenuItem.Create(nil);
             parentMItem.Add(menuItem);
             menuItem.Caption:='Выключение мониторинга';
             menuItem.Action:=ADisableMonitoring;
             menuItem.Enabled:=false;
             menuItem:=TMenuItem.Create(nil);
             parentMItem.Add(menuItem);
             menuItem.Caption:='Причина выключения';
             menuItem.Action:=AShowReason;
             menuItem.Enabled:=false;
             menuItem:=TMenuItem.Create(nil);
             parentMItem.Add(menuItem);
             menuItem.Action:=ASuspendMonitoringByHour;
             menuItem.Caption:='Приостановить на час';
             menuItem.Enabled:=false;
             menuItem:=TMenuItem.Create(nil);
             parentMItem.Add(menuItem);
             menuItem.Action:=ASuspendMonitoringBy2Hours;
             menuItem.Caption:='Приостановить на 2 часа';
             menuItem.Enabled:=false;
             mso:=EQ.Interfaces[i].GetMonitoringStatus;
             if EQ.Interfaces[i].MonitoringStatus<>mos_Monitoring then begin
                   parentMItem.Items[0].enabled:=true;
                   parentMItem.Items[1].enabled:=false;
                   parentMItem.Items[2].enabled:=true;
                   parentMItem.Items[3].enabled:=false;
                   parentMItem.Items[4].enabled:=false;
             end else begin
                   parentMItem.Items[0].enabled:=false;
                   parentMItem.Items[1].enabled:=true;
                   parentMItem.Items[2].enabled:=false;
                   parentMItem.Items[3].enabled:=true;
                   parentMItem.Items[4].enabled:=true;
             end;
         end;
         menuItem:=TMenuItem.Create(nil);
         MIInterfaces.Add(menuItem);
         menuItem.Action:=ASuspendAllMonitoringByHour;
         menuItem.Caption:='Приостановить все на час';
         menuItem.Visible:=true;
         menuItem:=TMenuItem.Create(nil);
         MIInterfaces.Add(menuItem);
         menuItem.Action:=ASuspendDamageMonitoringByHour;
         menuItem.Caption:='Приостановить нерабочие на час';
         menuItem.Visible:=true;
     end;
end;

procedure TfrmMain.GenerateSysUtilsMenuItems(PM: TPopupMenu; EQ: TEquipment);
var i:integer;
    PMItem:TMenuItem;
    MEQ:TMobileEquipment;
begin
     AddPMItem(PM.Items,'DM_CheckEquipment','Проверить',ACheckEquipment);
     if ((EQ.ClassName='TTruck') or (EQ.ClassName='TExcav')) and (objSettings.IsAdmin) then begin
        AddPMItem(PM.Items,'DM_ConnectVNC','Подключиться по VNC',AConnectVNC);
        AddPMItem(PM.Items,'DM_ConnectVNCAndTelnet','Подключиться к VNC и Telnet',AConnectVNCAndTelnet);
        AddPMItem(PM.Items,'DM_ConnectTelnet','Подключиться по Telnet',AConnectTelnet);
        AddPMItem(PM.Items,'DM_ConnectBullet','Подключиться к Bullet',AConnectBullet);
        AddPMItem(PM.Items,'DM_PingPTXBullet','Пинговать PTX и Bullet',APingPTXBullet);
        AddPMItem(PM.Items,'DM_PingPTX','Пинговать PTX',APingPTX);
        AddPMItem(PM.Items,'DM_xrebootPTX','Перезагрузить PTX',AxrebootPTX);
     end;
     if (EQ.ClassName='TNetworkEQ') and (objSettings.IsAdmin) then begin
        AddPMItem(PM.Items,'DM_ConnectBullet','Подключиться к Bullet',AConnectBullet);
        AddPMItem(PM.Items,'DM_Ping','Пинговать Bullet',APing);
     end;
     if (EQ.ClassType=TDrill) and (objSettings.IsAdmin) then begin
        AddPMItem(PM.Items,'DM_ConnectBullet','Подключиться к Bullet',AConnectBullet);
     end;

     if (objSettings.User='atu') and (EQ.ClassName='TTruck') then begin
        AddPMItem(PM.Items,'DM_ViewVEIData','Данные по VEI',AVEIData);
     end;
     if EQ.ClassParent.ClassParent=TMobileEquipment then begin
      AddPMItem(PM.Items,'DM_waitActions','Ожидание',nil);
      PMItem:=PM.Items.Find('Ожидание');
      MEQ:=TMobileEquipment(EQ);
      if not MEQ.waitPowerOn.isWait then AddPMItem(PMItem,'DM_waitPowerOn','включения',AWaitPowerOn)
        else AddPMItem(PMItem,'DM_waitPowerOn','Ред. включения',AWaitPowerOn);
      if not MEQ.waitPowerOff.isWait then AddPMItem(PMItem,'DM_waitPowerOff','выключения',AWaitPowerOff)
        else AddPMItem(PMItem,'DM_waitPowerOff','Ред. выключения',AWaitPowerOff);
      if not MEQ.waitNotWork.isWait then AddPMItem(PMItem,'DM_waitNotWork','статуса не "Готов"',AWaitNotWork)
        else AddPMItem(PMItem,'DM_waitNotWork','Ред. статуса не "Готов"',AWaitNotWork);
      if MEQ.ClassParent=TMobileEQModular then begin
          if not TMobileEQModular(MEQ).waitGBM.isWait then AddPMItem(PMItem,'DM_waitGBM','прибытия в ГБМ',AWaitGBM)
            else AddPMItem(PMItem,'DM_waitGBM','Ред. прибытия в ГБМ',AWaitGBM);
          AddPMItem(PM.Items,'DM_ShowModularStatus','Показать статус',AShowModularStatus);
      end;
     end;
     {if not TMobileEQModular(EQ).waitPowerON then AddPMItem(PM,'DM_WaitPowerOn','Ожидать включения',AWaitPowerOn)
        else AddPMItem(PM,'DM_NotWaitPowerOn','Не ожидать включения',ANoWaitPowerOn);
     if not TMobileEQModular(EQ).waitNotWork then AddPMItem(PM,'DM_WaitNotWork','Ожидать статус не "Готов"',AWaitNotWork)
        else AddPMItem(PM,'DM_NotWaitNotWork','Не ожидать статус не "Готов"',ANoWaitNotWork);
     if not TMobileEQModular(EQ).waitGBM then AddPMItem(PM,'DM_WaitNotWork','Ожидать статус не "Готов"',AWaitNotWork)
        else AddPMItem(PM,'DM_NotWaitNotWork','Не ожидать статус не "Готов"',ANoWaitNotWork);}
end;

function TfrmMain.GetCountEQinCategory: integer;
begin
     result:=0;
     if PCMain.ActivePage.Name='tsEquipment' then result:=countEquipment;
     if PCMain.ActivePage.Name='tsExcavs' then result:=countExcavs;
     if PCMain.ActivePage.Name='tsServer' then Result:=countServers;
     if PCMain.ActivePage.Name='tsNetworking' then Result:=countNetworkEQ;
     if PCMain.ActivePage.Name='tsDrills' then Result:=countDrills;
     if PCMain.ActivePage.Name='tsSZMs' then Result:=countSZMs;
end;

function TfrmMain.GetCurrentEQTable: TStringGrid;
var EQIndex:integer;
    EQ:TEquipment;
begin
     getEQInformation(result,EQIndex,EQ);
end;

procedure TfrmMain.getEQInformation(var tbl: TStringGrid;
  var EQIndex: integer;var EQ: TEquipment);
var intfcName:string;
begin
     if PCMain.ActivePage.Name='tsEquipment' then begin
        tbl:=SGEquipment;
        EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
        try
          EQ:=MobileEQArray[EQIndex];
        except
          EQ:=nil;
        end;
     end;
     if PCMain.ActivePage.Name='tsExcavs' then begin
        tbl:=SGExcavs;
        EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
        try
          EQ:=ExcavsArray[EQIndex];
        except
          EQ:=nil;
        end;
     end;
     if PCMain.ActivePage.Name='tsServer' then begin
        tbl:=SGServer;
        EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
        try
          EQ:=ServersArray[EQIndex];
        except
          EQ:=nil;
        end;
     end;
     if PCMain.ActivePage.Name='tsNetworking' then begin
        tbl:=SGNetwork;
        EQIndex:=tbl.row*tbl.ColCount+tbl.Col+1;
        try
          EQ:=NetworkEQArray[EQIndex];
        except
          EQ:=nil;
        end;
     end;
     if PCMain.ActivePage.Name='tsDrills' then begin
        tbl:=SGDrills;
        EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
        try
          EQ:=DrillsArray[EQIndex];
        except
          EQ:=nil;
        end;
     end;
     if PCMain.ActivePage.Name='tsSZMs' then begin
        tbl:=SGSZMs;
        EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
        try
          EQ:=SZMsArray[EQIndex];
        except
          EQ:=nil;
        end;
     end;
end;

function TfrmMain.GetEquipmentByName(name: string): TEquipment;
var
  f: Boolean;
  i: integer;
  EQ:TEquipment;
begin
     f:=false;
     i:=0;
     result:=nil;
     while (not f) and (i<EQALLList.Count-1) do begin
          EQ:=TEQuipment(EQAllList[i]^);
          if EQ.name=name then begin
            result:=EQ;
            f:=true;
          end;
          inc(i);
     end;
end;

function TfrmMain.GetInterface(Act: TAction): CInterface;
var intfcname:string;
    tbl:TStringGrid;
    EQIndex:integer;
    EQ:TEquipment;
begin
      result:=nil;
      getEQInformation(tbl,EQIndex,EQ);
      try
        intfcName:=TMenuItem(TAction(Act).ActionComponent).Parent.Name;
        intfcname:=Copy(intfcname,4,Length(intfcname)-3);
        result:=EQ.Interfaces.getbyName(intfcName);
     except
        result:=nil;
     end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     if Application.MessageBox('Завершить работу программы?','Вопрос',MB_YESNO)=IDNo then begin
        Action:=caNone;
        exit;
     end;
     StatusBar1.Panels[0].Text:='Подождите, идет завершение потоков';
     if Assigned(ControllerThread) then ControllerThread.Terminate;
     if Assigned(MyTimerThread) then MyTimerThread.Terminate;
     if Assigned(Sound) then Sound.Terminate;
     if Assigned(ftpThread) then begin
        ftpThread.Terminate;
        WaitForSingleObject(ftpThread.Handle,1000);
     end;
     FreeAndNil(ftpThread);
     if Assigned(TasksManager) then begin
        TasksManager.Terminate;
        StatusBar1.Panels[0].Text:='Подождите. Идет завершение задач';
        StatusBar1.Repaint;
        if Assigned(TasksManager) then WaitForSingleObject(TasksManager.Handle,10000);
        FreeAndNil(TasksManager);
        StatusBar1.Panels[0].Text:='Менеджер задач уничтожен';
        StatusBar1.Repaint;
     end;
     sleep(500);
     //if (Action=cafree) then FormDestroy(sender);
end;

procedure TfrmMain.SGEquipmentDblClick(Sender: TObject);
var equipmentIndex:integer;
  EQ:TEquipment; // Ссылка на объект, который нужно отрисовывать
  cnt:integer;
  sig_lev:shortint;
  p1,p2:TPoint;
begin
     equipmentIndex:=TStringGrid(sender).Row*TStringGrid(sender).ColCount+TStringGrid(sender).Col+1;
     EQ:=nil;
     cnt:=0;
     if TStringGrid(sender).Name = 'SGExcavs' then begin
        EQ:=ExcavsArray[equipmentIndex];
        cnt:=countExcavs;
     end;
     if TStringGrid(sender).Name = 'SGEquipment' then begin
        EQ:=MobileEQArray[equipmentIndex];
        cnt:=countEquipment;
     end;
     if TStringGrid(sender).Name = 'SGDrills' then begin
        EQ:=DrillsArray[equipmentIndex];
        cnt:=countDrills;
     end;
     if TStringGrid(sender).Name = 'SGSZMs' then begin
        EQ:=SZMsArray[equipmentIndex];
        cnt:=countSZMs;
     end;
     if not Assigned(EQ) then exit;
     // Если доступен WiFi интерфейс, то по двойному щелчку вывести уровень сигнала
     if EQ.Interfaces.getByName('WiFi')<>nil then begin
        sig_lev:=TWiFiInterface(EQ.Interfaces.getByName('WiFi')).GetLastSignal;
        LHint.Font.Size:=14;
        LHint.Caption:='Сигнал: '+inttostr(sig_lev);
        PHint.Height:=abs(PHint.Font.Height)+10;
        PHint.Width:=130;
        p1.Y:=Mouse.CursorPos.Y-10-PHint.Height;
        p1.X:=Mouse.CursorPos.X-(PHint.Width div 2);
        p2:=ScreenToClient(p1);
        PHint.Top:=p2.Y;
        PHint.Left:=p2.X;
        PHint.Visible:=true;
        HintShowedSec:=0;
        PHint.BringToFront;
     end;
end;

procedure TfrmMain.SGEquipmentDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var i,j,k,x1,y1:integer;
  CellColor:TColor;
  equipmentIndex:integer;
  EQ:TEquipment; // Ссылка на объект, который нужно отрисовывать
  MEQ:TMobileEquipment;
  cnt:integer;
  dx:integer;
  oldcolor: TColor;
  r1:TRect;
  rw:integer;
  dr: word;
begin
     equipmentIndex:=ARow*TStringGrid(sender).ColCount+ACol+1;
     EQ:=nil;
     cnt:=0;
     if TStringGrid(sender).Name = 'SGExcavs' then begin
        EQ:=ExcavsArray[equipmentIndex];
        cnt:=countExcavs;
     end;
     if TStringGrid(sender).Name = 'SGNetwork' then begin
        EQ:=NetworkEQArray[equipmentIndex];
        cnt:=countNetworkEQ;
     end;
     if TStringGrid(sender).Name = 'SGEquipment' then begin
        EQ:=MobileEQArray[equipmentIndex];
        cnt:=countEquipment;
     end;
     if TStringGrid(sender).Name = 'SGDrills' then begin
        EQ:=DrillsArray[equipmentIndex];
        cnt:=countDrills;
     end;
     if TStringGrid(sender).Name = 'SGSZMs' then begin
        EQ:=SZMsArray[equipmentIndex];
        cnt:=countSZMs;
     end;
     if equipmentIndex>cnt then exit;
     // Вычисляем, какого цвета будет ячейка
     // Если хотя бы по одному интерфейсу нет данных, то все красным
     // Если хотя бы по одному интерфейсу статус не готов, то не готов
     case EQ.Status of
         1: CellColor:=color_Work;
         2: CellColor:=color_NoData;
         3: CellColor:=color_Disable;
         4: CellColor:=color_NotReady;
         5: CellColor:=color_Damage;
         6: CellColor:=color_restored;
         else CellColor:=color_unknown;
     end;
     with (sender as TStringGrid).Canvas do begin
         Brush.Color:=CellColor;
         FillRect(Rect);
         TextOut(Rect.Left+2,Rect.Top+2,EQ.name);
         y1:=Rect.Top+2;
         for i := 1 to EQ.Interfaces.count do begin
            case EQ.Interfaces[i].status of
              // Данные есть
              1: Brush.Color:=color_Work;
              // Данных нет
              2: Brush.Color:=color_NoData;
              // Мониторинг отключен
              3: Brush.Color:=color_Disable;
              // Статус не готов
              4: Brush.Color:=color_NotReady;
              // Мониторинг отключен из-за неисправности
              5: Brush.Color:=color_Damage;
              // Мониторинг отключен из-за неисправности, но данные есть
              6: Brush.Color:=color_restored;
           else
              Brush.Color:=color_unknown
           end;
           x1:=Rect.Left+12;
           y1:=y1+20;
           Rectangle(x1, y1, x1+17, y1+17);
           Brush.Color:=CellColor;
           TextOut(x1+27, y1+2, EQ.interfaces[i].DisplayName );
           // Вывод отображаемых параметров интерфейса
           for j := 1 to EQ.interfaces[i].DisplayParameters.Count do begin
                  y1:=y1+20;
                  TextOut(x1,y1+2,EQ.interfaces[i].DisplayParameters[j].displayName+': '+EQ.interfaces[i].DisplayParameters[j].value+' '+EQ.interfaces[i].DisplayParameters[j].edizm);
           end;
         end;
         // Если оборудование ожидает включения, то рисуем зеленый круг
         if EQ.ClassParent.ClassParent=TMobileEquipment then begin
             dx:=0;
             oldcolor:=Pen.Color;
             // Выводим картинки для техники с ожиданиями
             MEQ:=TMobileEquipment(EQ);
             rw:=16;
             dr:=2;
             r1.Left:=Rect.Right-rw-dr;
             r1.Right:=r1.Left+rw;
             r1.Top:=Rect.Top+dr;
             r1.Bottom:=r1.Top+rw;
             for k := 0 to MEQ.waitList.Count - 1 do begin
                 if TwaitAction(MEQ.waitList[k]^).isWait then begin
                    Images.Draw(TStringGrid(sender).Canvas,r1.Left,r1.Top,k);
                    r1.Left:=r1.Left-dr-rw;
                    r1.Right:=r1.Left+rw;
                 end;

             end;

             {if TMobileEQModular(EQ).waitPowerON then begin
                Pen.Color:=clBlue;
                Brush.Color:=clGreen;
                Ellipse(Rect.Right-15,Rect.Top+5,Rect.Right-5,Rect.Top+15);
             end;
             if TMobileEQModular(EQ).waitNotWork then begin
                if TMobileEQModular(EQ).waitPowerON then begin
                   dx:=15
                end;
                Pen.Color:=clBlue;
                Brush.Color:=clYellow;
                Ellipse(Rect.Right-15-dx,Rect.Top+5,Rect.Right-5-dx,Rect.Top+15);
             end;}
             Pen.Color:=oldcolor;
         end;
     end;

end;

procedure TfrmMain.SGNetworkContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
  var tbl:TStringGrid;
      cnt:integer;
      ACol,ARow,EQIndex:integer;
      i:integer;
      EQ:TEquipment;
      intfc:CInterface;
      intfcName:string;
      currentitem:TMenuItem;
      mso:integer;
begin
     {tbl:=SGNetwork;
     cnt:=countNetworkEQ;
     tbl.MouseToCell(MousePos.X,mousepos.Y,Acol,Arow);
     tbl.Col:=Acol;
     tbl.Row:=ARow;
     EQIndex:=ARow*tbl.ColCount+Acol+1;
     // Если индекс оборудования больше, чем максимально возможный индекс
     // то есть тыкнули на пустую ячейку, то не отображаем меню и выходим
     if EQIndex>cnt then begin
        for i:=0 to PMEquipment.Items.Count-1 do PMEquipment.Items[i].Visible:=false;
        exit;
     end;
     EQ:=NetworkEQArray[EQIndex];
     NNetworkInterfaces.Visible:=false;
     NNetworkWiFi.Visible:=false;
     for I := 1 to EQ.Interfaces.count do begin
         IntfcName:=EQ.Interfaces[i].name;
         CurrentItem:=NNetworkInterfaces.Find(IntfcName);
         if currentItem<>nil then begin
            NNetworkInterfaces.Visible:=true;
            currentItem.Visible:=true;
            mso:=EQ.Interfaces[i].GetMonitoringStatus;
            if EQ.Interfaces[i].MonitoringStatus<>mos_Monitoring then begin
               currentItem.Items[0].enabled:=true;
               currentItem.Items[1].enabled:=false;
               currentItem.Items[2].enabled:=true;
            end else begin
               currentItem.Items[0].enabled:=false;
               currentItem.Items[1].enabled:=true;
               currentItem.Items[2].enabled:=false;
            end;
         end;
     end;   }
end;

procedure TfrmMain.SGServerContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
 var tbl:TStringGrid;
      cnt:integer;
      ACol,ARow,EQIndex:integer;
      i:integer;
      EQ:TEquipment;
begin
     PMEquipment.Items.Clear;
     tbl:=SGServer;
     cnt:=countServers;
     tbl.MouseToCell(MousePos.X,mousepos.Y,Acol,Arow);
     tbl.Col:=Acol;
     tbl.Row:=ARow;
     EQIndex:=ARow*tbl.ColCount+Acol+1;
     // Если индекс оборудования больше, чем максимально возможный индекс
     // то есть тыкнули на пустую ячейку, то не отображаем меню и выходим
     if EQIndex>cnt then begin
        for i:=0 to PMEquipment.Items.Count-1 do PMEquipment.Items[i].Visible:=false;
        exit;
     end;
     EQ:=ServersArray[EQIndex];
     GenerateSysUtilsMenuItems(PMEquipment,EQ);
     GenerateInterfacesMenuItems(PMEquipment,EQ);
end;

procedure TfrmMain.SGServerDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var Cellcolor:TColor;
    i,x1,y1:integer;
    str:string;
    serverIndex:integer;
begin
  ServerIndex:=ARow*SGServer.ColCount+ACol+1;
  if ServersArray[ServerIndex]<>nil then begin
     with (sender as TStringGrid).Canvas do begin
         case ServersArray[serverIndex].Status of
              1: Cellcolor:=color_Work;
              2: Cellcolor:=color_NoData;
              3: Cellcolor:=color_Disable;
              4: Cellcolor:=color_NotReady;
              5: Cellcolor:=color_Damage;
              6: Cellcolor:=color_restored;
              else CellColor:=color_unknown;
         end;
         Pen.Color:=clBlack;
         Brush.Color:=CellColor;
         FillRect(Rect);
         TextOut(Rect.Left+2,Rect.Top+2,ServersArray[ServerIndex].name);
         // Выводим по очереди все интерфейсы сервера
         for i := 1 to ServersArray[serverIndex].Interfaces.count do begin
             case ServersArray[serverIndex].Interfaces[i].status of
                // Данные есть
                1: Brush.Color:=color_Work;
                // Данных нет
                2: Brush.Color:=color_NoData;
                // Мониторинг отключен
                3: Brush.Color:=color_Disable;
                // Статус не готов
                4: Brush.Color:=color_NotReady;
                // Мониторинг отключен из-за неисправности
                5: Brush.Color:=color_Damage;
                // Мониторинг отключен из-за неисправности, но данные есть
                6: Brush.Color:=color_restored;
             else
                Brush.Color:=color_unknown
             end;
             x1:=Rect.Left+12;
             y1:=Rect.Top+2+i*20;
             Rectangle(x1, y1, x1+17, y1+17);
             str:=ServersArray[serverIndex].Interfaces[i].DisplayName+'. '+ServersArray[serverIndex].Interfaces[i].comment;
             TextOut(x1+27, y1+2, str);
         end;
     end;
  end else Brush.Color:=color_unknown;
end;

procedure TfrmMain.SGTasksContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
  var ACol,Arow:integer;
begin
     SGTasks.MouseToCell(MousePos.X,mousepos.Y,Acol,Arow);
     SGTasks.Row:=Arow;
     SGTasks.Col:=ACol;
end;

procedure TfrmMain.SGTasksDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var str1:string;
    task:TTask;
  fillcolor1: TColor;
  strstatus: string;
begin
     with SGTasks.Canvas do begin
       if (Arow>0) and (Assigned(TasksManager)) then begin
          if ARow <= TasksManager.TasksCount then begin
            //FillRect(Rect);
            try
              task:=TasksManager.TasksThreads[Arow-1].task;
            except
              exit;
            end;
            case task.Status of
                tst_unknown:
                    begin
                        fillcolor1:=clWhite;
                        strstatus:='';
                    end;
                tst_running:
                    begin
                        fillcolor1:=clWhite;
                        strstatus:=inttostr(task.PercentCompleted)+'%';
                    end;
                tst_success:
                    begin
                        fillcolor1:=rgb(171,255,150);
                        strstatus:='Успешно';
                    end;
                tst_fail:
                    begin
                        fillcolor1:=rgb(255,150,170);
                        strstatus:='Ошибка';
                    end;
                tst_abort:
                    begin
                        fillcolor1:=rgb(150,171,255);
                        strstatus:='Отменена';
                    end;
                tst_warning:
                    begin
                        fillcolor1:=rgb(255,238,156);
                        strstatus:='Предупреждение';
                    end;
            end;
            case ACol of
              0: begin
                  str1:=strstatus;
              end;
              1: if task.DisplayName<>'' then str1:=task.DisplayName else str1:=task.Name;
              2: str1:=inttostr(task.sleeptime);
              3: str1:=FormatDateTime('dd.mm.yyyy hh:mm',task.LastRun);
              4: str1:=FormatDateTime('dd.mm.yyyy hh:mm',task.NextRun);
            end;
            Brush.Color:=fillcolor1;
            FillRect(Rect);
            TextOut(Rect.Left+2, Rect.Top+2, str1);
          end;
       end;
     end;
end;

function TfrmMain.StatusInterfaceEquipmentMon(intfc:CInterface): boolean;
begin
     Application.MessageBox(PChar(intfc.DetailsMonitoringStatus),'Информация');
end;

procedure TfrmMain.SuspendMonitoringBy1Hour(intfc: CInterface);
begin

end;

// Проверка зависших подключений после проблем с сетью
procedure TfrmMain.TimConnectControlTimer(Sender: TObject);
var tempQuery:TADOQuery;
begin
    
end;

procedure TfrmMain.TimerHintTimer(Sender: TObject);
begin
     if PHint.Visible then begin
        if HintShowedSec<3 then inc(hintShowedSec) else begin
            PHint.Visible:=false;
            HintShowedSec:=0;
        end;
     end;
end;

procedure TfrmMain.TmTimeTimer(Sender: TObject);
begin
     LTime.Caption:=FormatDateTime('hh:nn:ss',Time);
end;

procedure TfrmMain.SetGridSizes(tbl:TStringGrid);
var i,j,k, maxLinesCount, LinesCount, maxLenCellWidth, cnt :integer;
    str:string;
    EQ:TEquipment;
    a1,a2:integer;
    textHeight:integer;
begin
     a1:=40;
     a2:=12;
     maxlenCellWidth:=0;
     maxLinesCount:=0;
     textHeight:=tbl.Canvas.TextHeight('F');
     if tbl.Name='SGExcavs' then cnt:=countExcavs;
     if tbl.Name='SGNetwork' then cnt:=countNetworkEQ;
     if tbl.Name='SGEquipment' then cnt:=countEquipment;
     if tbl.Name='SGServer' then cnt:=countServers;
     if tbl.Name='SGDrills' then cnt:=countDrills;
     if tbl.Name='SGSZMs' then cnt:=countSZMs;

     i:=1;
     while (i<=cnt) do begin
          if tbl.Name='SGExcavs' then EQ:=ExcavsArray[i];
          if tbl.Name='SGNetwork' then EQ:=NetworkEQArray[i];
          if tbl.Name='SGEquipment' then EQ:=MobileEQArray[i];
          if tbl.Name='SGServer' then EQ:=ServersArray[i];
          if tbl.Name='SGDrills' then EQ:=DrillsArray[i];
          if tbl.Name='SGSZMs' then EQ:=SZMsArray[i];

         if tbl.Canvas.TextWidth(EQ.name)>maxlenCellWidth then maxlenCellWidth:=tbl.Canvas.TextWidth(EQ.name);
         LinesCount:=1;
         // Проверяем длину названия интерфейсов
         for j := 1 to EQ.Interfaces.count do begin
             inc(LinesCount);
             // У названия интерфейса отступ от левого края 27 пикселей
             if (tbl.Canvas.TextWidth(EQ.Interfaces[j].DisplayName)+a1)>maxlenCellWidth then maxlenCellWidth:=tbl.Canvas.TextWidth(EQ.Interfaces[j].DisplayName)+a1;
             // Для каждого из интерфейсов проверяем длинны параметров
             for k := 1 to EQ.Interfaces[j].DisplayParameters.Count do begin
                 inc(LinesCount);
                 str:=EQ.Interfaces[j].DisplayParameters[k].displayName+': '+EQ.Interfaces[j].DisplayParameters[k].FormatVal+EQ.Interfaces[j].DisplayParameters[k].edizm;
                 if (tbl.Canvas.TextWidth(str)+a2)>maxlenCellWidth then maxlenCellWidth:=tbl.Canvas.TextWidth(str)+a2;
             end;
         end;
         if LinesCount>maxLinesCount then maxLinesCount:=LinesCount;
         inc(i);
     end;
     if maxLenCellWidth>a1 then tbl.DefaultColWidth:=maxLenCellWidth else maxLenCellWidth:=a1;
     tbl.DefaultRowHeight:=maxLinesCount*20;
     if tbl.Name='SGNetwork' then begin
        tbl.DefaultColWidth:=tbl.DefaultColWidth+10;
        tbl.DefaultRowHeight:=tbl.DefaultRowHeight+10;
     end;
     if tbl.Name='SGServer' then begin
        tbl.DefaultColWidth:=tbl.Width -5;
     end;
end;

procedure TfrmMain.SetTasksGridSizes;
var i:integer;
begin
     SGTasks.ColWidths[0]:=80;
     SGTasks.ColWidths[2]:=80;
     SGTasks.ColWidths[3]:=150;
     SGTasks.ColWidths[4]:=150;
     SGTasks.ColWidths[1]:=SGTasks.Width-SGTasks.ColWidths[0]-SGTasks.ColWidths[2]-SGTasks.ColWidths[3]-SGTasks.ColWidths[4];
     if SGTasks.ColWidths[1]<200 then SGTasks.ColWidths[1]:=200;
     SGTasks.Cells[0,0]:='Выполнение';
     SGTasks.Cells[1,0]:='Название';
     SGTasks.Cells[2,0]:='Интервал, с';
     SGTasks.Cells[3,0]:='Послед. пров.';
     SGTasks.Cells[4,0]:='След. пров.';
     if Assigned(TasksManager) then SGTasks.RowCount:=TasksManager.TasksCount+1 else SGTasks.RowCount:=1;
end;

procedure TfrmMain.SGEquipmentContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
  var Acol, ARow:integer;
  var EQIndex:integer;
  var i:integer;
    tbl:TStringGrid;
    EQ:TEquipment;
    cnt:integer;
begin
     PMEquipment.Items.Clear;
     tbl:=GetCurrentEQTable;
     tbl.MouseToCell(MousePos.X,mousepos.Y,Acol,Arow);
     tbl.Col:=Acol;
     tbl.Row:=ARow;
     getEQInformation(tbl,EQIndex,EQ);
     cnt:=GetCountEQinCategory;
     // Если индекс оборудования больше, чем максимально возможный индекс
     // то есть тыкнули на пустую ячейку, то не отображаем меню и выходим
     if EQIndex>cnt then begin
        for i:=0 to PMEquipment.Items.Count-1 do PMEquipment.Items[i].Visible:=false;
        exit;
     end;
     GenerateSysUtilsMenuItems(PMEquipment,EQ);
     GenerateInterfacesMenuItems(PMEquipment,EQ);
end;


procedure TfrmMain.ACheckEquipmentExecute(Sender: TObject);
var EQIndex:integer;
    IP:string;
    tbl:TStringGrid;
    EQ:TEquipment;
    cnt:integer;
    i:integer;
begin
     getEQInformation(tbl,EQIndex,EQ);
     cnt:=GetCountEQinCategory;
     if EQIndex<=cnt then begin
        if not MyTimerThread.CheckExecuting then begin
         StatusBar1.Panels[0].Text:='Выполняется проверка '+EQ.name;
         StatusBar1.Repaint;
         for I := 1 to EQ.Interfaces.count do begin
             try
                EQ.Interfaces[i].Check;
             except

             end;
         end;
         StatusBar1.Panels[0].Text:='Проверка '+EQ.name+' завершена';
         tbl.Repaint;
        end else StatusBar1.Panels[0].Text:='Повторите проверку после завершения общей проверки';
     end;
end;

procedure TfrmMain.AConnectBulletExecute(Sender: TObject);
var EQIndex:integer;
    IP:string;
    tbl:TStringGrid;
    EQ:TEquipment;
    cnt:integer;
begin
     getEQInformation(tbl,EQIndex,EQ);
     cnt:=GetCountEQinCategory;
     if EQIndex<=cnt then begin
         if EQ.ClassParent.ClassName='TMobileEQModular' then IP:=TMobileEQModular(EQ).ModemIP
          else if EQ.ClassParent=TKobusEquipment then IP:=TKobusEquipment(EQ).ModemIP
            else IP:=TEquipment(EQ).IPAddress;
         ShellExecute(0,nil,PChar('http://'+IP),nil,nil,SW_restore);
     end;
end;

procedure TfrmMain.AConnectTelnetExecute(Sender: TObject);
var EQIndex:integer;
    IP:string;
    wnd1:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
    cnt:integer;

begin
     if PCMain.ActivePage.Name='tsExcavs' then begin
        tbl:=SGExcavs;
        cnt:=countExcavs;
     end else begin
        tbl:=SGEquipment;
        cnt:=countEquipment;
     end;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if EQIndex<=cnt then begin
         if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex]
            else EQ:=MobileEQArray[EQIndex];
        IP:=TMobileEQModular(EQ).IPAddress;
        ShellExecute(0,nil,PChar('cmd.exe'),pchar('/C "'+'telnet '+IP+'"'),nil,SW_restore);
        sleep(200);
        wnd1:=FindWindow(nil,PChar('Telnet '+IP));
        if wnd1>0 then begin
            sleep(2000);
            SendMessage(wnd1,WM_CHAR,ord('a'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('d'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('m'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('i'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('n'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord(#13),0);
            sleep(1500);
            SendMessage(wnd1,WM_CHAR,ord('m'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('o'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('d'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('u'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('l'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('a'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord('r'),0);
            sleep(10);
            SendMessage(wnd1,WM_CHAR,ord(#13),0);
        end;
     end;
end;

procedure TfrmMain.AConnectVNCAndTelnetExecute(Sender: TObject);
begin
     AConnectTelnet.Execute;
     sleep(100);
     AConnectVNC.Execute;
end;

procedure TfrmMain.AConnectVNCExecute(Sender: TObject);
var EQIndex:integer;
    IP:string;
    flName, Templatename:string;
    vncConf:TStrings;
    i:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
    cnt:integer;
  strparams: string;
begin
     if PCMain.ActivePage.Name='tsExcavs' then begin
        tbl:=SGExcavs;
        cnt:=countExcavs;
     end else begin
        tbl:=SGEquipment;
        cnt:=countEquipment;
     end;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if EQIndex<=cnt then begin
         if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex]
            else EQ:=MobileEQArray[EQIndex];
        IP:=TMobileEQModular(EQ).IPAddress;
        flName:=ExtractFilePath(Application.ExeName)+'Tools\VNC-Viewer.exe';
        TemplateName:=ExtractFilePath(Application.ExeName)+'Tools\Template.vnc';
        // Если в папке с ASUGTKMonitor есть VNCViewer, тозапускаем его
        if FileExists(TemplateName) then begin
            vncConf:=TStringList.Create;
            vncConf.LoadFromFile(TemplateName);
            for i:= 0 to vncConf.Count - 1 do begin
                if pos('Host=',vncConf[i])>0 then vncConf[i]:='Host='+IP;
            end;
            vncConf.SaveToFile(TemplateName);
            FreeAndNil(vncConf);
            strparams:='-WarnUnencrypted=0 -config '+Templatename;
            ShellExecute(0,PChar('open'),PWideChar(flName),pchar(strparams),nil,SW_restore);
        end;
     end;
end;

procedure TfrmMain.AddPMItem(ParentItem: TMenuItem; name, caption: string;
  basicAction: TBasicAction);
var menuItem:TMenuItem;
begin
     MenuItem:=TMenuItem.Create(nil);
     ParentItem.Add(MenuItem);
     MenuItem.Name:=name;
     menuItem.Visible:=true;
     MenuItem.Action:=basicAction;
     MenuItem.Caption:=caption;
end;

procedure TfrmMain.AddPMItem(ParentItem: TMenuItem; name, caption: string;
  proc: TNotifyEvent);
  var menuItem:TMenuItem;
begin
     MenuItem:=TMenuItem.Create(nil);
     ParentItem.Add(MenuItem);
     MenuItem.Name:=name;
     menuItem.Visible:=true;
     MenuItem.OnClick:=PMDisableClick;
     MenuItem.Caption:=caption;
end;

procedure TfrmMain.ADisableMonitoringExecute(Sender: TObject);
var tbl:TStringGrid;
    i:integer;
    EQIndex:integer;
    EQ:TEquipment;
    intfc:CInterface;
    str:string;
begin
     tbl:=GetCurrentEQTable;
     intfc:=GetInterface(TAction(sender));
     DisableInterfaceEquipmentMon(intfc);
     tbl.Repaint;
end;

procedure TfrmMain.AEnableMonitoringExecute(Sender: TObject);
var tbl:TStringGrid;
    EQIndex:integer;
    EQ:TEquipment;
    intfc:CInterface;
begin
     tbl:=GetCurrentEQTable;
     intfc:=GetInterface(TAction(sender));
     intfc.MonitoringOn;
     //EnableInterfaceEquipmentMon(intfc);
     tbl.Repaint;
end;

procedure TfrmMain.AShowModularStatusExecute(Sender: TObject);
var
  EQ: TEquipment;
  EQIndex: Integer;
  tbl: TStringGrid;
  str,str1,str2:string;
  statsStatus:TFullStatsStatus;
  a1,a2:integer;
  p1,p2:TPoint;
  rct:TRect;
begin
     getEQInformation(tbl,EQIndex,EQ);
     if EQ.ClassParent.ClassParent=TMobileEquipment then begin
        statsStatus:=TMobileEquipment(EQ).GetFullSystemStatus;
        str:='';
        str1:=DateTimeToStr(statsStatus.dttmstart);
        str2:=EQ.name+' : '+GetModularstatusName(statsStatus.status)+':'+statsStatus.reasonname;
        str:=str2+#13#10+'Начало: '+str1;
        LHint.Font.Size:=11;
        a1:=LHint.Canvas.TextWidth(str1)+10;
        a2:=LHint.Canvas.TextWidth(str2);
        if a1>a2 then PHint.Width:=a1 else PHint.Width:=a2;
        PHint.Height:=abs(PHint.Font.Height)*2+10;
        LHint.Caption:=str;
        rct:=tbl.CellRect(tbl.Col,tbl.Row);
        p1.Y:=rct.Top+((rct.Bottom-rct.Top) div 2)-(PHint.Height div 2);
        p1.X:=rct.Left+((rct.Right-rct.Left) div 2)-(PHint.Width div 2);
        p2:=p1;
        if p2.X<0 then p2.X:=2;
        if (p2.X+PHint.Width)>frmMain.Width then p2.X:=frmMain.Width-PHint.Width-1;
        PHint.Top:=p2.Y;
        PHint.Left:=p2.X;
        PHint.Visible:=true;
        HintShowedSec:=0;
        PHint.BringToFront;
     end;
end;

procedure TfrmMain.AShowReasonExecute(Sender: TObject);
var tr,msg:string;
    EQIndex:integer;
    tbl:TStringGrid;
    EQ:TEquipment;
    intfc:CInterface;
begin
     getEQInformation(tbl,EQIndex,EQ);
     intfc:=GetInterface(TAction(sender));
     if DM1.qMonitoringStatus.Active then DM1.qMonitoringStatus.Close;
     DM1.qMonitoringStatus.Parameters.ParamByName('id').Value:=EQ.name;
     DM1.qMonitoringStatus.Parameters.ParamByName('interface').Value:=intfc.name;
     DM1.qMonitoringStatus.Open;
     DM1.qMonitoringStatus.Last;
     if DM1.qMonitoringStatus.RecordCount>0 then begin
        msg:=formatDateTime('dd.mm.yy hh:mm',DM1.qMonitoringStatusdatetimestart.Value)+ ': '+DM1.qMonitoringStatusreason.Value+'. '+DM1.qMonitoringStatusFIO.Value;
        Application.MessageBox(PChar(msg),'Сообщение');
     end else Application.MessageBox('Мониторинг по данному оборудованию уже запущен другим пользователем','Сообщение');
     DM1.qMonitoringStatus.Close;
     tbl.Repaint;
end;

procedure TfrmMain.ASuspendAllMonitoringByHourExecute(Sender: TObject);
var tbl:TStringGrid;
    EQIndex:integer;
    EQ:TEquipment;
    i:integer;
begin
     getEQInformation(tbl,EQIndex,EQ);
     for i := 1 to EQ.Interfaces.count do begin
         EQ.Interfaces[i].MonitoringSuspendByHour;
         EQ.Interfaces[i].Check;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.ASuspendDamageMonitoringByHourExecute(Sender: TObject);
var tbl:TStringGrid;
    EQIndex:integer;
    EQ:TEquipment;
    i:integer;
begin
     getEQInformation(tbl,EQIndex,EQ);
     for i := 1 to EQ.Interfaces.count do begin
         if EQ.Interfaces[i].status=s_NoData then begin
             EQ.Interfaces[i].MonitoringSuspendByHour;
             EQ.Interfaces[i].Check;
         end;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.ASuspendMonitoringBy2HoursExecute(Sender: TObject);
var tbl:TStringGrid;
    intfc:CInterface;
    act:TAction;
    itm:TMenuItem;
begin
     if PCMain.ActivePageIndex>0 then begin
         tbl:=GetCurrentEQTable;
         intfc:=GetInterface(TAction(sender));
         intfc.MonitoringSuspend(Now+1/24*2);
         intfc.Check;
         tbl.Repaint;
     end else begin
         act:=TAction(sender);
         CInterface(disable1hArray.Objects[TMenuItem(sender).MenuIndex]).MonitoringSuspend(Now+1/24*2);
         if PMDisable1h.Items.Count<3 then sbDisableCheck.Enabled:=false;
     end;
end;

procedure TfrmMain.ASuspendMonitoringByHourExecute(Sender: TObject);
var tbl:TStringGrid;
    intfc:CInterface;
    act:TAction;
    itm:TMenuItem;
begin
     if PCMain.ActivePageIndex>0 then begin
         tbl:=GetCurrentEQTable;
         intfc:=GetInterface(TAction(sender));
         intfc.MonitoringSuspendByHour;
         intfc.Check;
         tbl.Repaint;
     end else begin
         act:=TAction(sender);
         CInterface(disable1hArray.Objects[TMenuItem(sender).MenuIndex]).MonitoringSuspendByHour;
         if PMDisable1h.Items.Count<3 then sbDisableCheck.Enabled:=false;
     end;
end;

procedure TfrmMain.ATaskLogExecute(Sender: TObject);
var
  taskindex: Integer;
  LogPath: string;
begin
     taskindex:=SGTasks.Row-1;
     if taskindex<0 then exit;
     LogPath:=TasksManager.TasksThreads[taskindex].task.LogFileName;
     if FileExists(LogPath) then begin
        frmLogsViewer.MLogs.Lines.Clear;
        frmLogsViewer.MLogs.Lines.LoadFromFile(LogPath);
        frmLogsViewer.MLogs.Perform(WM_VScroll,SB_BOTTOM,0);
        frmLogsViewer.ShowModal;
     end;
end;

procedure TfrmMain.ATaskStartExecute(Sender: TObject);
var
  taskindex: Integer;
begin
     taskindex:=SGTasks.Row-1;
     if taskindex<0 then exit;
     TasksManager.StartTask(taskindex);
end;

procedure TfrmMain.ATaskStopExecute(Sender: TObject);
var
  taskindex: Integer;
begin
     taskindex:=SGTasks.Row-1;
     if taskindex<0 then exit;
     TasksManager.StopTask(taskindex);
     StatusBar1.Panels[0].Text:='Отправлен сигнал завершения задачи '+TasksManager.TasksThreads[taskindex].task.DisplayName;
end;

procedure TfrmMain.AVEIDataExecute(Sender: TObject);
var tbl:TStringGrid;
    EQIndex:integer;
    EQ:TEquipment;
    sshobj1:TSSHobj;
    frmViewdata:TfrmViewData;
begin
    getEQInformation(tbl,EQindex,EQ);
    sshobj1:=TSSHobj.Create;
    sshobj1.command:='cat /local/log/OMSsniff/'+formatDateTime('yyyy-mm-dd',Now())+'.sniff.eth0.raw | grep "'+EQ.name+'.*VEI"'#13;
    sshobj1.sleeptm:=2000;
    sshobj1.Answer.Clear;
    Application.CreateForm(TfrmViewData,frmViewdata);
    frmViewdata.Caption:=EQ.Name+' - Данные по VEI за сегодня';
    frmViewdata.Show;
    frmViewdata.MData.Lines.Add('Подождите, Загрузка данных');
    if sshobj1.Execute then begin
       frmViewdata.MData.Lines.Clear;
       frmViewdata.MData.Lines.AddStrings(sshobj1.Answer);
       frmViewdata.MData.Repaint;
    end else begin
       frmViewData.MData.Lines.Clear;
       frmViewdata.MData.Lines.Add('Невозможно загрузить данные. Проверьте связь с сервером lgkdisp');
    end;
    FreeAndNil(sshobj1);
end;

procedure TfrmMain.AVeiDisableMonExecute(Sender: TObject);
     var EQIndex:integer;
          tbl:TStringGrid;
          EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     DisableInterfaceEquipmentMon(TTruck(EQ).VEI);
     tbl.Repaint;
end;

procedure TfrmMain.AVeiEnableMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     EnableInterfaceEquipmentMon(TTruck(EQ).VEI);
     tbl.Repaint;
end;

procedure TfrmMain.AVEIStatusMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     StatusInterfaceEquipmentMon(TTruck(EQ).VEI);
end;

procedure TfrmMain.AWaitGBMExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     getEQInformation(tbl,EQIndex,TEquipment(EQ));
     if EQ<>nil then begin
        frmWaitComment.lEQName.Caption:=EQ.name;
        frmWaitComment.lWaitType.Caption:=EQ.waitGBM.GetMenuCaption;
        frmWaitComment.MComment.Clear;
        if not EQ.waitGBM.isWait then frmWaitComment.MComment.Clear else frmWaitComment.MComment.lines.Text:=EQ.waitGBM.comment;
        frmWaitComment.AbortAction:=ANowaitGBM;
        if (frmWaitComment.ShowModal=mrOk) then begin
          EQ.waitGBM.Enable;
          EQ.waitGBM.comment:=frmWaitComment.MComment.Text;
          waitactions:=true;
          SaveWaitActions;
        end;

     end;
     tbl.Repaint;
end;

procedure TfrmMain.AWaitNotWorkExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     getEQInformation(tbl,EQIndex,TEquipment(EQ));
     if EQ<>nil then begin
        frmWaitComment.lEQName.Caption:=EQ.name;
        frmWaitComment.lWaitType.Caption:=EQ.waitNotWork.GetMenuCaption;
        frmWaitComment.MComment.Clear;
        if not EQ.waitNotWork.isWait then frmWaitComment.MComment.Clear else frmWaitComment.MComment.lines.Text:=EQ.waitNotWork.comment;
        frmWaitComment.AbortAction:=ANoWaitNotWork;
        if (frmWaitComment.ShowModal=mrOk) then begin
          EQ.waitNotWork.Enable;
          EQ.waitNotWork.comment:=frmWaitComment.MComment.Text;
          waitactions:=true;
          SaveWaitActions;
        end;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.AWaitPowerOffExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     getEQInformation(tbl,EQIndex,TEquipment(EQ));
     if EQ<>nil then begin
        frmWaitComment.lEQName.Caption:=EQ.name;
        frmWaitComment.lWaitType.Caption:=EQ.waitPowerOff.GetMenuCaption;
        frmWaitComment.MComment.Clear;
        if not EQ.waitPowerOff.isWait then frmWaitComment.MComment.Clear else frmWaitComment.MComment.lines.Text:=EQ.waitPowerOff.comment;
        frmWaitComment.AbortAction:=ANoWaitPowerOff;
        if (frmWaitComment.ShowModal=mrOk) then begin
          EQ.waitPowerOff.Enable;
          EQ.waitPowerOff.comment:=frmWaitComment.MComment.Text;
          waitactions:=true;
          SaveWaitActions;
        end;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.AWaitPowerOnExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEquipment;
    str:string;
begin
     getEQInformation(tbl,EQIndex,TEquipment(EQ));
     if EQ<>nil then begin
        frmWaitComment.lEQName.Caption:=EQ.name;
        frmWaitComment.lWaitType.Caption:=EQ.waitPowerOn.GetMenuCaption;
        if not EQ.waitPowerOn.isWait then frmWaitComment.MComment.Clear else frmWaitComment.MComment.lines.Text:=EQ.waitPowerOn.comment;
        frmWaitComment.AbortAction:=ANoWaitPowerOn;
        if (frmWaitComment.ShowModal=mrOk) then begin
          EQ.waitPowerON.Enable;
          EQ.waitPowerOn.comment:=frmWaitComment.MComment.Text;
          waitActions:=true;
          SaveWaitActions;
        end;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.AWiFiDisableMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     if EQ.ClassName='TExcav' then DisableInterfaceEquipmentMon(TExcav(EQ).WiFi)
        else DisableInterfaceEquipmentMon(TTruck(EQ).WiFi);
     tbl.Repaint;
end;

procedure TfrmMain.AWifiEnableMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     if EQ.ClassName='TExcav' then EnableInterfaceEquipmentMon(TExcav(EQ).WiFi)
        else EnableInterfaceEquipmentMon(TTruck(EQ).WiFi);
     tbl.Repaint;
end;

procedure TfrmMain.AWifiStatusMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     if EQ.ClassName='TExcav' then StatusInterfaceEquipmentMon(TExcav(EQ).WiFi)
        else StatusInterfaceEquipmentMon(TTruck(EQ).WiFi);
     tbl.Repaint;
end;

procedure TfrmMain.AxrebootPTXExecute(Sender: TObject);
var EQIndex:integer;
    IP:string;
    wnd1:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
    cnt:integer;
    Query: TADOQuery;
begin
     if MessageDlg('Вы действительно хотите перезагрузить PTX?',mtWarning,[mbOK,mbCancel],0,mbCancel)=mrOK then begin
         if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
          EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
          if PCMain.ActivePage.Name='tsExcavs' then begin
              EQ:=ExcavsArray[EQIndex];
              cnt:=countExcavs;
          end else begin
              EQ:=MobileEQArray[EQIndex];
              cnt:=countEquipment;
          end;
         if EQIndex<=cnt then begin
            IP:=TMobileEQModular(EQ).IPAddress;
            APingPTX.Execute;
            AConnectTelnet.Execute;
            sleep(1500);
            wnd1:=FindWindow(nil,PChar('Telnet '+IP));
            if wnd1>0 then begin
               SendMessage(wnd1,WM_CHAR,ord(#13),0);
               sleep(1000);
               SendMessage(wnd1,WM_CHAR,ord('x'),0);
               sleep(10);
               SendMessage(wnd1,WM_CHAR,ord('r'),0);
               sleep(10);
               SendMessage(wnd1,WM_CHAR,ord('e'),0);
               sleep(10);
               SendMessage(wnd1,WM_CHAR,ord('b'),0);
               sleep(10);
               SendMessage(wnd1,WM_CHAR,ord('o'),0);
               sleep(10);
               SendMessage(wnd1,WM_CHAR,ord('o'),0);
               sleep(10);
               SendMessage(wnd1,WM_CHAR,ord('t'),0);
               sleep(500);
               SendMessage(wnd1,WM_CHAR,ord(#13),0);

                 //Записываем событие в таблицу log
                 Query := TADOQuery.Create(Self);
                 Query.Connection := DM1.ConnMySQL;
                 Query.Close;
                 Query.SQL.Text := 'Insert into log values('+QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss',now))+', '+
                   QuotedStr('xreboot on '+IP+' execute success')+')';
                 try Query.ExecSQL;
                 finally Query.Close; Query.Free;
                 end;

            end;
         end;
     end;
end;

procedure TfrmMain.BBDisableSoundClick(Sender: TObject);
begin
     if not sound.Suspended then Sound.suspend;
     BBDisableSound.Enabled:=false
end;

procedure TfrmMain.bClearMessagesClick(Sender: TObject);
var
  LogMessagesPath: string;
begin
     MMessages.Lines.Clear;
     countMessages:=0;
     if LogMessagesName<>'' then begin
        LogMessagesPath:=ExtractFilePath(Application.ExeName)+LogMessagesName;
        SaveLogToFile(LogMessagesPath,'Очищен список сообщений');
     end;
end;

procedure TfrmMain.bClearMessages_oldClick(Sender: TObject);
begin
     MMessages.Lines.Clear;
end;

procedure TfrmMain.bDoWorkClick(Sender: TObject);
var f:boolean;
    s1:string;
    i1:integer;
begin
     if MyTimer.MyTimerThread.CheckExecuting then begin
        if Application.MessageBox('Проверка уже выполняется. Вы действительно хотите перезапустить процесс','Вопрос',MB_YESNO)=IDYES then f:=true else f:=false;
     end else f:=true;
     if f then begin
        BBDisableSoundClick(self);
        //MyTimer.MyTimerThread.FreeOnTerminate:=true;
        MyTimer.MyTimerThread.Terminate;
        frmMain.StatusBar1.Panels[0].Text:='Перезапуск проверки';
        i1:=0;
        while MyTimer.ThreadExecuting and (i1<50) do begin
            sleep(50);
            inc(i1);
        end;
        sleep(100);
        //MyTimer.MyTimerThread.Destroy;
        MyTimer.MyTimerThread := MyTimer.TMyTimerThread.Create(false);
     end;
end;

function TfrmMain.DisableInterfaceEquipmentMon(intfc:CInterface): boolean;
var interfaceID:integer;
   infcindex:integer;
   reason,FIO:string;
   reason_category:integer;
   intfcindex:integer;
begin
  if intfc=nil then begin
         Application.MessageBox(PChar('Неизвестная ошибка '+TMobileEQModular(intfc.owner).name+'.'),'Ошибка');
         exit;
  end;
  if not TEquipment(intfc.owner).getMySQLIndex then begin
         Application.MessageBox(PChar('В базе данных не найдено оборудование с именем '+TMobileEQModular(intfc.owner).name+'.'),'Ошибка');
         exit;
  end;
  // Проверить, есть ли данный интерфейс в списке интерфейсов БД
  intfcindex:=intfc.MySQLID;
  if intfcindex<0 then begin
      Application.MessageBox(PChar('В базе данных не найден интерфейс с именем '+intfc.name),'Ошибка');
      exit;
  end;
  if intfc.GetMonitoringStatus<>mos_Monitoring then begin
     Application.MessageBox(PChar('Нельзя повторно отключить мониторинг.'+intfc.DetailsMonitoringStatus),'Информация');
     SGEquipment.Repaint;
     exit;
  end;
  // Открываем окно заполнения информации по отключению мониторинга
  if not Assigned(frmDisableMonitoring) then
     Application.CreateForm(TfrmDisableMonitoring, frmDisableMonitoring);
  frmDisableMonitoring.lEquipment.Caption:=TMobileEQModular(intfc.Owner).name;
  frmDisableMonitoring.lInterfaceName.Caption:=CInterface(intfc).name;
  frmDisableMonitoring.MReason.Text:='';
  frmDisableMonitoring.cbOffMonitoring.ItemIndex:=1;
  frmDisableMonitoring.ShowModal;
  // Вносим данные о выключении мониторинга в БД
  if frmDisableMonitoring.ModalResult=mrOk then begin
     reason:=frmDisableMonitoring.MReason.Text;
     FIO:=frmDisableMonitoring.EFIO.Text;
     reason_category:=frmDisableMonitoring.cbOffMonitoring.ItemIndex;
     if DM1.qModify.Active then DM1.qModify.Close;
     DM1.qModify.SQL.Clear;
     DM1.qModify.SQL.Add('insert into interface_monitoring_off (equipment, ref_interface, active, datetimestart, reason, FIO, reason_category)');
      DM1.qModify.SQL.Add('values('+inttostr(TMobileEQModular(intfc.owner).MySQLIndex)+','+inttostr(intfcindex)+',1,"'+ FormatDateTime('yyyy-mm-dd hh:mm:ss',Now())+'","'+reason+'","'+FIO+'",'+inttostr(reason_category)+')');
      //Application.MessageBox(PChar(DM1.qModifi.SQL.Text),'');
      DM1.qModify.ExecSQL;
      DM1.qModify.Close;
      // Если по прочей причине, то статус 3, иначе 5
      intfc.Check;
      //SGEquipment.Repaint;
  end;
end;

function TfrmMain.EnableInterfaceEquipmentMon(intfc:CInterface): boolean;
var intfcindex:integer;
    qtmpqry:TADOQuery;
    moindex:integer;
begin
    if not TEquipment(intfc.owner).getMySQLIndex then begin
         Application.MessageBox(PChar('В базе данных не найдено оборудование с именем '+TMobileEQModular(intfc.owner).name+'.'),'Ошибка');
         exit;
    end;
    // Проверить, есть ли данный интерфейс в списке интерфейсов БД
    intfcindex:=intfc.MySQLID;
    if intfcindex<0 then begin
        Application.MessageBox(PChar('В базе данных не найден интерфейс с именем '+intfc.name),'Ошибка');
        exit;
    end;
    if intfc.GetMonitoringStatus=mos_Monitoring then begin
       Application.MessageBox(PChar('Мониторинг интерфейса '+intfc.name+' уже включен.'),'Информация');
       SGEquipment.Repaint;
       exit;
    end;
    // Ищем ID записи отключения мониторинга
    CoInitialize(nil);
    qtmpqry:=TADOQuery.Create(dm1);
    qtmpqry.Connection:=dm1.ConnMySQL;
    qtmpqry.SQL.Add('select max(id) idoff from interface_monitoring_off where Active>0 and Equipment='+inttostr(TEquipment(intfc.Owner).MySQLIndex)+' and ref_interface='+inttostr(intfcindex));
    qtmpqry.Open;
    moindex:=qtmpqry.FieldByName('idoff').AsInteger;
    qtmpqry.Close;
    FreeAndNil(qtmpqry);
    if moindex>0 then begin
        if DM1.qModify.Active then DM1.qModify.Close;
        DM1.qModify.SQL.Clear;
        DM1.qModify.SQL.Add('update interface_monitoring_off ');
        DM1.qModify.SQL.Add('set Active=0, datetimeend="'+FormatDateTime('yyyy-mm-dd hh:mm:ss',Now())+'"');
        DM1.qModify.SQL.Add('where id='+inttostr(moindex));
        DM1.qModify.ExecSQL;
        DM1.qModify.Close;
    end;
    intfc.Check;
end;

procedure TfrmMain.AGPSDisableMonExecute(Sender: TObject);
     var EQIndex:integer;
          tbl:TStringGrid;
          EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     DisableInterfaceEquipmentMon(TTruck(EQ).GPS);
     tbl.Repaint;
end;

procedure TfrmMain.AGPSEnableMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     EnableInterfaceEquipmentMon(TTruck(EQ).GPS);
     tbl.Repaint;
end;

procedure TfrmMain.AGPSSTatusMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     StatusInterfaceEquipmentMon(TTruck(EQ).GPS);
end;

procedure TfrmMain.AMainSettingsExecute(Sender: TObject);
begin
     if not Assigned(frmSettings) then
     Application.CreateForm(TfrmDisableMonitoring, frmSettings);
     frmSettings.eSleepTime.Text:=inttoStr(objSettings.SleepTimeSeconds);
     frmSettings.ShowModal();
end;

procedure TfrmMain.ANetWiFiDisableMonExecute(Sender: TObject);
var EQIndex:integer;
    reason,FIO:string;
    reason_category:integer;
begin
{     EQIndex:= SGNetwork.row*SGNetwork.ColCount+SGNetwork.Col+1;
     if not Assigned(frmDisableMonitoring) then
        Application.CreateForm(TfrmDisableMonitoring, frmDisableMonitoring);
     frmDisableMonitoring.lEquipment.Caption:=NetworkEQArray[EQIndex].name;
     frmDisableMonitoring.lInterfaceName.Caption:=NetworkEQArray[EQIndex].WiFi.name;
     frmDisableMonitoring.MReason.Text:='';
     frmDisableMonitoring.cbOffMonitoring.ItemIndex:=1;
     frmDisableMonitoring.ShowModal;
     // Вносим данные о выключении мониторинга в БД
     if frmDisableMonitoring.ModalResult=mrOk then begin
            reason:=frmDisableMonitoring.MReason.Text;
            FIO:=frmDisableMonitoring.EFIO.Text;
            reason_category:=frmDisableMonitoring.cbOffMonitoring.ItemIndex;
            NetworkEQArray[EQIndex].WiFi.MonitoringOff(reason,FIO,reason_category);
            SGNetwork.Repaint;
     end;}
end;

procedure TfrmMain.ANetWiFiEnableMonExecute(Sender: TObject);
var EQIndex:integer;
begin
     {EQIndex:= SGNetwork.row*SGNetwork.ColCount+SGNetwork.Col+1;
     NetworkEQArray[EQIndex].WiFi.MonitoringOn;
     SGNetwork.Repaint;}
end;

procedure TfrmMain.ANetWiFiStatusMonExecute(Sender: TObject);
var EQIndex:integer;
begin
     {EQIndex:= SGNetwork.row*SGNetwork.ColCount+SGNetwork.Col+1;
     StatusInterfaceEquipmentMon(NetworkEQArray[EQIndex].WiFi);}
end;

procedure TfrmMain.ANowaitGBMExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     getEQInformation(tbl,EQIndex,TEquipment(EQ));
     if EQ<>nil then begin
        EQ.waitGBM.Disable;
        SaveWaitActions;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.ANoWaitNotWorkExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     getEQInformation(tbl,EQIndex,Tequipment(EQ));
     if EQ<>nil then begin
        EQ.waitNotWork.Disable;
        SaveWaitActions;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.ANoWaitPowerOffExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     getEQInformation(tbl,EQIndex,TEquipment(EQ));
     if EQ<>nil then begin
        EQ.waitPowerOff.disable;
        SaveWaitActions;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.ANoWaitPowerOnExecute(Sender: TObject);
     var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     getEQInformation(tbl,EQIndex,TEquipment(EQ));
     if EQ<>nil then begin
        EQ.waitPowerON.Disable ;
        SaveWaitActions;
     end;
     tbl.Repaint;
end;

procedure TfrmMain.APingExecute(Sender: TObject);
var tbl:TStringGrid;
    EQIndex:integer;
    EQ:TEquipment;
    cnt:integer;
    IP:string;
begin
     getEQInformation(tbl,EQIndex,EQ);
     cnt:=GetCountEQinCategory;
     if EQIndex<=cnt then begin
         IP:=TEquipment(EQ).IPAddress;
         ShellExecute(0,nil,PChar('cmd.exe'),pchar('/C "'+'ping '+IP+' -t"'),nil,SW_restore);
     end;
end;

procedure TfrmMain.APingPTXBulletExecute(Sender: TObject);
var EQIndex:integer;
    IP,IPModem:string;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
    cnt:integer;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
      EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
      if PCMain.ActivePage.Name='tsExcavs' then begin
          EQ:=ExcavsArray[EQIndex];
          cnt:=countExcavs;
      end else begin
          EQ:=MobileEQArray[EQIndex];
          cnt:=countEquipment;
      end;
     if EQIndex<=cnt then begin
        IP:=TMobileEQModular(EQ).IPAddress;
        IPModem:=TMobileEQModular(EQ).ModemIP;
        ShellExecute(0,nil,PChar('cmd.exe'),pchar('/C "'+'ping '+IP+' -t"'),nil,SW_restore);
        sleep(50);
        ShellExecute(0,nil,PChar('cmd.exe'),pchar('/C "'+'ping '+IPModem+' -t"'),nil,SW_restore);
     end;
end;

procedure TfrmMain.APingPTXExecute(Sender: TObject);
var EQIndex:integer;
    IP:string;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
    cnt:integer;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
      EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
      if PCMain.ActivePage.Name='tsExcavs' then begin
          EQ:=ExcavsArray[EQIndex];
          cnt:=countExcavs;
      end else begin
          EQ:=MobileEQArray[EQIndex];
          cnt:=countEquipment;
      end;
     if EQIndex<=cnt then begin
        IP:=TMobileEQModular(EQ).IPAddress;
        ShellExecute(0,nil,PChar('cmd.exe'),pchar('/C "'+'ping '+IP+' -t"'),nil,SW_restore);
     end;
end;

procedure TfrmMain.ApplicationEvents1Exception(Sender: TObject; E: Exception);
var strs:TStringList;
  i: Integer;
begin
     strs:=TStringList.Create;
     try
        JclLastExceptStackListToStrings(strs,true,true,true,true);
        strs.Insert(0,E.Message);
        strs.Insert(1,'');
        flname:=ExtractFilePath(Application.ExeName)+'LastException.log';
        strs.SaveToFile(flname);
     finally
        FreeAndNil(strs);
     end;
end;

procedure TfrmMain.APressDisableMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     DisableInterfaceEquipmentMon(TTruck(EQ).Pressure);
     tbl.Repaint;
end;

procedure TfrmMain.APressEnableMonExecute(Sender: TObject);
var EQIndex:integer;
    tbl:TStringGrid;
    EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     EnableInterfaceEquipmentMon(TTruck(EQ).Pressure);
     tbl.Repaint;
end;

procedure TfrmMain.APressStatusMonExecute(Sender: TObject);
     var EQIndex:integer;
         tbl:TStringGrid;
         EQ:TMobileEQModular;
begin
     if PCMain.ActivePage.Name='tsExcavs' then tbl:=SGExcavs else tbl:=SGEquipment;
     EQIndex:= tbl.row*tbl.ColCount+tbl.Col+1;
     if PCMain.ActivePage.Name='tsExcavs' then EQ:=ExcavsArray[EQIndex] else EQ:=MobileEQArray[EQIndex];
     StatusInterfaceEquipmentMon(TTruck(EQ).Pressure);
end;

procedure TfrmMain.AReWriteInterfacesExecute(Sender: TObject);
var conntemp:TADOConnection;
    qrytemp:TADOQuery;
    i,j:integer;
    EQ:TEquipment;
    intfcid:integer;
    EQId:integer;
begin
     CoInitialize(nil);
     Conntemp:=TADOConnection.Create(nil);
     Conntemp.KeepConnection:=false;
     Conntemp.LoginPrompt:=false;
     Conntemp.Provider:='MSDASQL.1';
     conntemp.ConnectionString:=dm1.ConnMySQL.ConnectionString;
     qryTemp:=TADOQuery.Create(nil);
     qryTemp.Connection:=Conntemp;
     // Очищаем список интерфейсов
     qrytemp.SQL.Clear;
     qrytemp.SQL.Add('delete from equipment_interfaces');
     try
         qrytemp.ExecSQL;
         for i:=0 to EQALLList.Count-1 do begin
             EQ:=TEquipment(EQALLList[i]^);
             for j := 1 to EQ.Interfaces.count do begin
                 if EQ.Interfaces[j].status<>s_Disable then begin
                    if EQ.GetMySQLIndex then EQid:=EQ.MySQLIndex else EQid:=-1;
                    intfcid:=EQ.Interfaces[j].MySQLID;
                    if (intfcid>-1) and (EQid>-1) then begin
                       qrytemp.SQL.Clear;
                       qrytemp.SQL.Add('insert into equipment_interfaces(equipment,interface) values ('+inttostr(eqid)+','+inttostr(intfcid)+')');
                       qrytemp.ExecSQL;
                    end;
                 end;
             end;
         end;
     except
         Application.MessageBox('Ошибка при заполнении интерфейсов','Ошибка');
     end;
     FreeAndNil(qrytemp);
     FreeAndNil(conntemp);
     Application.MessageBox('заполнение интерфейсов выполнено','Информация');
end;

initialization
  JclStartExceptionTracking;

finalization
  JclStopExceptionTracking;

end.
