unit MyTimer;

interface
uses Classes, forms, controls, DelphiCryptlib, cryptlib,
     Graphics, MyUtils, ComCtrls, DateUtils, Grids;

type TChecking =(cpNone, cpServers, cpEquipment, cpExcavs, cpNetwork, cpWaitAct, cpDrills, cpSZMs);

type
  TMyTimerThread = class(TThread)
  private
    { Private declarations }
    FCurrentChecking:TChecking;
    procedure SetCurrentChecking(value:TChecking);
    procedure runCheckStatusInterface;
  protected
    CurrentEquipmentNotMonitoring:shortint;
    CurrentInterfaceName:string;
    currentEquipment:string;
    LastJobDateTime:TDateTime;
    LastJobDateTimeEquipment : TDateTime;
    LastJobDateTimeExcavs : TDateTime;
    LastJobDateTimeServers : TDateTime;
    LastJobDateTimeNetwork : TDateTime;
    LastJobDateTimeDrills:  TDateTime;
    LastJobDateTimeSZMs: TDateTime;
    LastJobDateTimeWaitAct : TDateTime;
    waitmsg:string;       // ��������� �� �������� �������� �������
    messageStatusbar:string;
    StatusBarToWrite:TStatusBar;
    property CurrentChecking:TChecking read FCurrentChecking write SetCurrentChecking;
    Procedure runCheckEquipment;
    procedure runCheckExcavs;
    procedure runCheckServers;
    procedure runCheckNetworkEQ;
    procedure runCheckDrills;
    procedure RunCheckSZMs;
    procedure runCheckWaitAct;
    procedure EnableMonitoringInterfaces;
    procedure RefreshStatusNextJob;
    procedure BeginExecuteRepaint;
    procedure endExecuteRepaint;
    Procedure WriteStatusExecute;
    procedure WriteButtonExecuteTitle;
    procedure Execute; override;
    procedure SetDefaults;    // �������� ���������
    procedure SaveWaitList;
    //Procedure DoWork;
  public
    CheckExecuting:boolean; // ���� ���������� ��������
    MonitoringLogFile:string;
    constructor Create(CreateSuspended:boolean);
    destructor Destroy;
  end;

type TControllerMonitorThread= class (TThread)
  private
    procedure RestartMonitoring;
  protected
    procedure Execute; override;
end;

  var sleeptime:integer;     // ����� � ������������, ����� ������� ���������� ��������� ��������
      MyTimerThread:TMyTimerThread;
      ControllerThread:TControllerMonitorThread;
      flname:string;
      ThreadExecuting:boolean; // ���� ����������� ��������

implementation

uses SysUtils, Main, DM, ActiveX;
{ TMyTimerThread }


procedure TMyTimerThread.runCheckDrills;
var i,j:integer;
begin
     // �������� ����������
     CheckExecuting:=true;
     CurrentChecking:=cpDrills;
     if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� ���������� ������');
     if not terminated then synchronize(WriteButtonExecuteTitle);
     StatusBarToWrite:=frmMain.statusbarDrills;
     if objSettings.ShowDrills then begin
         if not terminated then begin
             for i := 1  to Main.countDrills do begin
                 messageStatusbar:='�������� ���������: '+inttostr(i)+' �� '+inttostr(Main.countDrills);
                 if not Terminated then Synchronize(WriteStatusExecute);
                 if not terminated then begin
                     for j := 1 to Main.DrillsArray[i].Interfaces.count do begin
                        if (Main.DrillsArray[i].Interfaces[j].MonitoringSetting in [1,2]) then begin
                          // ���� �������� �� �����������, �� ���� 2 ������� � ��������� �������
                          if (not Terminated) and (not Main.DrillsArray[i].Interfaces[j].Check) then begin
                             sleep(2000);
                             Main.DrillsArray[i].Interfaces[j].Check;
                          end;
                          if (not Terminated) and (objSettings.AutoEnableMonitoring) and (Main.DrillsArray[i].Interfaces[j].status=s_restored) then Main.DrillsArray[i].Interfaces[j].MonitoringOn;
                        end;
                     end;
                 end;
             end;
         end;
     end;
     LastJobDateTimeDrills:=Now();
    messageStatusbar:='�������� ���������� ��������� '+FormatDateTime('dd.mm.yy hh:nn',LastJobDateTimeDrills)+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',LastJobDateTimeDrills+(objSettings.SleepTimeDrills/(3600*24)));
    if not terminated then Synchronize(WriteStatusExecute);
    if not terminated then synchronize(endExecuteRepaint);
    CurrentChecking:=cpNone;
    CheckExecuting:=false;
    if not terminated then synchronize(WriteButtonExecuteTitle);
    if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� ���������� ���������');
end;

procedure TMyTimerThread.runCheckEquipment;
var
  i,j: integer;
begin
     flname:=ExtractFilePath(Application.ExeName)+'errorlogs.txt';
     CheckExecuting:=true;
     CurrentChecking:=cpEquipment;
     if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� ���������� ������');
     if not terminated then synchronize(WriteButtonExecuteTitle);
     StatusBarToWrite:=frmMain.statusbarEquipment;
     for i := 1  to Main.countEquipment do begin
         messageStatusbar:='�������� ���������: '+inttostr(i)+' �� '+inttostr(Main.countEquipment);
         if not Terminated then Synchronize(WriteStatusExecute);
         if not terminated then begin
             for j := 1 to Main.MobileEQArray[i].Interfaces.count do begin
                if (Main.MobileEQArray[i].Interfaces[j].MonitoringSetting in [1,2]) then begin
                  try
                      Main.MobileEQArray[i].Locked.Enter;
                      // ���� �������� �� �����������, �� ���� 2 ������� � ��������� �������
                      if not(Terminated) and (not Main.MobileEQArray[i].Interfaces[j].Check) then begin
                         Main.MobileEQArray[i].Locked.Leave;
                         sleep(2000);
                         Main.MobileEQArray[i].Locked.Enter;
                         Main.MobileEQArray[i].Interfaces[j].Check;
                      end;
                      Main.MobileEQArray[i].Locked.Leave;
                  except

                  end;
                  if (not Terminated) and (objSettings.AutoEnableMonitoring) and (Main.MobileEQArray[i].Interfaces[j].status=s_restored) then MobileEQArray[i].Interfaces[j].MonitoringOn;
                end;
             end;
         end;
     end;
    LastJobDateTimeEquipment:=Now();
    messageStatusbar:='�������� ���������� ��������� '+FormatDateTime('dd.mm.yy hh:nn',LastJobDateTimeEquipment)+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',LastJobDateTimeEquipment+(objSettings.SleepTimeEquipment/(3600*24)));
    if not terminated then Synchronize(WriteStatusExecute);
    if not terminated then synchronize(endExecuteRepaint);
    CurrentChecking:=cpNone;
    CheckExecuting:=false;
    synchronize(WriteButtonExecuteTitle);
    if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� ���������� ���������');
end;

procedure TMyTimerThread.runCheckExcavs;
var i,j:integer;
begin
     // �������� ������������
     CheckExecuting:=true;
     CurrentChecking:=cpExcavs;
     if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� ������������ ������');
     if not terminated then synchronize(WriteButtonExecuteTitle);
     StatusBarToWrite:=frmMain.statusbarExcavs;
     if objSettings.ShowExcavs then begin
         if not terminated then begin
             for i := 1  to Main.countExcavs do begin
                 messageStatusbar:='�������� �����������: '+inttostr(i)+' �� '+inttostr(Main.countExcavs);
                 if not Terminated then Synchronize(WriteStatusExecute);
                 if not terminated then begin
                     for j := 1 to Main.ExcavsArray[i].Interfaces.count do begin
                        if (Main.ExcavsArray[i].Interfaces[j].MonitoringSetting in [1,2]) then begin
                          // ���� �������� �� �����������, �� ���� 2 ������� � ��������� �������
                          if (not Terminated) and (not Main.ExcavsArray[i].Interfaces[j].Check) then begin
                             sleep(2000);
                             Main.ExcavsArray[i].Interfaces[j].Check;
                          end;
                          if (not Terminated) and (objSettings.AutoEnableMonitoring) and (Main.ExcavsArray[i].Interfaces[j].status=s_restored) then Main.ExcavsArray[i].Interfaces[j].MonitoringOn;
                        end;
                     end;
                 end;
             end;
         end;
     end;
     LastJobDateTimeExcavs:=Now();
    messageStatusbar:='�������� ������������ ��������� '+FormatDateTime('dd.mm.yy hh:nn',LastJobDateTimeExcavs)+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',LastJobDateTimeExcavs+(objSettings.SleepTimeExcavs/(3600*24)));
    if not terminated then Synchronize(WriteStatusExecute);
    if not terminated then synchronize(endExecuteRepaint);
    CurrentChecking:=cpNone;
    CheckExecuting:=false;
    if not terminated then synchronize(WriteButtonExecuteTitle);
    if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� ������������ ���������');
end;

procedure TMyTimerThread.runCheckNetworkEQ;
var i,j:integer;
begin
     // �������� �������� ������������
     CheckExecuting:=true;
     CurrentChecking:=cpNetwork;
     if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� �������� ������������ ������');
     if not terminated then synchronize(WriteButtonExecuteTitle);
     StatusBarToWrite:=frmMain.statusbarNetwork;
     if objSettings.ShowNetwork then begin
         if not terminated then begin
             for i := 1  to Main.countNetworkEQ do begin
                 messageStatusbar:='�������� �������� ������������: '+inttostr(i)+' �� '+inttostr(Main.countNetworkEQ);
                 if not Terminated then Synchronize(WriteStatusExecute);
                 if not terminated then begin
                     for j := 1 to Main.NetworkEQArray[i].Interfaces.count do begin
                        if (Main.NetworkEQArray[i].Interfaces[j].MonitoringSetting in [1,2]) then begin
                          // ���� �������� �� �����������, �� ���� 2 ������� � ��������� �������
                          if (not Terminated) and (not Main.NetworkEQArray[i].Interfaces[j].Check) then begin
                             sleep(2000);
                             Main.NetworkEQArray[i].Interfaces[j].Check;
                          end;
                          if (not Terminated) and (objSettings.AutoEnableMonitoring) and (Main.NetworkEQArray[i].Interfaces[j].status=s_restored) then Main.NetworkEQArray[i].Interfaces[j].MonitoringOn;
                        end;
                     end;
                 end;
             end;
         end;
     end;
     LastJobDateTimeNetwork:=Now();
    messageStatusbar:='�������� �������� ������������ ��������� '+FormatDateTime('dd.mm.yy hh:nn',LastJobDateTimeNetwork)+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',LastJobDateTimeNetwork+(objSettings.SleepTimeNetwork/(3600*24)));
    if not terminated then Synchronize(WriteStatusExecute);
    if not terminated then synchronize(endExecuteRepaint);
    CurrentChecking:=cpNone;
    CheckExecuting:=false;
    if not terminated then synchronize(WriteButtonExecuteTitle);
    if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� �������� ������������ ���������');
end;

// ��������� �������� ��������
procedure TMyTimerThread.runCheckServers;
var i2,j2:integer;
begin
    CheckExecuting:=true;
    CurrentChecking:=cpServers;
    if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� �������� ������');
    synchronize(WriteButtonExecuteTitle);
    StatusBarToWrite:=frmMain.statusbarServers;
    if not Terminated then begin
        for i2 := 1 to Main.CountServers do begin
            messageStatusbar:='�������� ������� '+ServersArray[i2].name;
            if not terminated then synchronize(WriteStatusExecute);
            if not terminated then begin
                for j2:=1 to ServersArray[i2].Interfaces.count do begin
                    //Application.MessageBox(PWideChar(ServersArray[i2].name+' '+inttostr(ServersArray[i2].Interfaces.count)),'');
                    if not Terminated then ServersArray[i2].Interfaces[j2].Check;
                    // ���� �������� ��������� ��������������� ��������� �����������, �� ��������� �� ��������������� ����������
                    if (not Terminated) and (objSettings.AutoEnableMonitoring) and (ServersArray[i2].Interfaces[j2].status=s_restored) then ServersArray[i2].Interfaces[j2].MonitoringOn;
                end;
            end;
        end;
    end;
    LastJobDateTimeServers:=Now();
    messageStatusbar:='�������� �������� ��������� '+FormatDateTime('dd.mm.yy hh:nn',LastJobDateTimeServers)+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',LastJobDateTimeServers+(objSettings.SleepTimeServers/(3600*24)));
    if not terminated then Synchronize(WriteStatusExecute);
    if not terminated then synchronize(endExecuteRepaint);
    CurrentChecking:=cpNone;
    CheckExecuting:=false;
    if not terminated then synchronize(WriteButtonExecuteTitle);
    if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� �������� ���������');
end;

procedure TMyTimerThread.runCheckStatusInterface;
begin

end;

procedure TMyTimerThread.RunCheckSZMs;
var i,j:integer;
begin
     // �������� ����������
     CheckExecuting:=true;
     CurrentChecking:=cpSZMs;
     if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� ��� ������');
     if not terminated then synchronize(WriteButtonExecuteTitle);
     StatusBarToWrite:=frmMain.statusBarSZMs;
     if objSettings.ShowDrills then begin
         if not terminated then begin
             for i := 1  to Main.countSZMs do begin
                 messageStatusbar:='�������� ���: '+inttostr(i)+' �� '+inttostr(Main.countSZMs);
                 if not Terminated then Synchronize(WriteStatusExecute);
                 if not terminated then begin
                     for j := 1 to Main.SZMsArray[i].Interfaces.count do begin
                        if (Main.SZMsArray[i].Interfaces[j].MonitoringSetting in [1,2]) then begin
                          // ���� �������� �� �����������, �� ���� 2 ������� � ��������� �������
                          if (not Terminated) and (not Main.SZMsArray[i].Interfaces[j].Check) then begin
                             sleep(2000);
                             Main.SZMsArray[i].Interfaces[j].Check;
                          end;
                          if (not Terminated) and (objSettings.AutoEnableMonitoring) and (Main.SZMsArray[i].Interfaces[j].status=s_restored) then Main.SZMsArray[i].Interfaces[j].MonitoringOn;
                        end;
                     end;
                 end;
             end;
         end;
     end;
     LastJobDateTimeSZMs:=Now();
    messageStatusbar:='�������� ��� ��������� '+FormatDateTime('dd.mm.yy hh:nn',LastJobDateTimeSZMs)+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',LastJobDateTimeSZMs+(objSettings.SleepTimeDrills/(3600*24)));
    if not terminated then Synchronize(WriteStatusExecute);
    if not terminated then synchronize(endExecuteRepaint);
    CurrentChecking:=cpNone;
    CheckExecuting:=false;
    if not terminated then synchronize(WriteButtonExecuteTitle);
    if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� ���������� ���������');
end;

procedure TMyTimerThread.runCheckWaitAct;
var i,j,k:integer;
    arr:TEquipmentArray;
    cnt:integer;
    waitAct:TwaitAction;
    needdisable:boolean;
  wapc: Boolean;
  datetimestr: string;
  EQ:TEquipment;
  MEQ:TMobileEquipment;
begin
     waitmsg:='';
     CheckExecuting:=true;
     CurrentChecking:=cpWaitAct;
     if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� �������� ������� ������');
     if not terminated then synchronize(WriteButtonExecuteTitle);
     StatusBarToWrite:=frmMain.statusbarEquipment;
     messageStatusbar:='�������� �������� �������';
     if not Terminated then Synchronize(WriteStatusExecute);
     needdisable:=false;
     //for j := 1 to 2 do begin
     for j := 0 to EQALLList.Count-1 do begin

         {if j=1 then begin
            // ��������� ���������
            arr:=MobileEQArray;
            cnt:=countEquipment;
         end else begin
            // ��������� �����������
            arr:=ExcavsArray;
            cnt:=countExcavs;
         end;}

         //for i := 1  to cnt do begin
         EQ:=TEquipment(EQAllList[j]^);
         if EQ.ClassParent.ClassParent=TMobileEquipment then begin
             MEQ:=TMobileEquipment(EQ);
             for k := 0 to MEQ.waitList.count - 1 do begin
                 if not terminated then begin
                    waitAct:=TWaitAction(MEQ.waitList[k]^);
                    if waitAct.isWait then begin
                       if waitAct.come and (not waitAct.isPrevCome) then begin
                          datetimestr:=FormatDateTime('dd.mm.yy hh:mm',Now);
                          waitmsg:=waitmsg+datetimestr+' '+waitAct.GetMessage+#13#10;
                          // 2019-12-23 �� ��������� �������� �������������, ��� ��� ������ ����� ���� �� ���������
                          // ������ �����, ��������� ������������ ���� ��� ��� ����������� ���������� ��������.
                          // � ��������� ��� ��������� ����������� ����� ����, ��� ��������� �������� ���������, � ����� ����� ��������.
                          // ��������, ������� ��������� ���������. ��������� ������� ���������. �������� ���������.
                          // ����� ����� �������� �����-�� ����� ����� ����������. �������������� ������ �� ����������.
                          // �� ����� ����,��� �������� ����������, ��������� ����� ������ ������� ��� ��������� � ������� � ���������.
                          //waitAct.Disable;
                       end else needdisable:=false;
                    end;
                 end;
             end;
         end;
     end;
    // if needdisable then Main.waitActions:=false;
    LastJobDateTimeWaitAct:=Now();
    messageStatusbar:='�������� �������� ������� ��������� '+FormatDateTime('dd.mm.yy hh:nn',LastJobDateTimeWaitAct);
    synchronize(saveWaitList);
    if not terminated then Synchronize(WriteStatusExecute);
    if not terminated then synchronize(endExecuteRepaint);
    CurrentChecking:=cpNone;
    CheckExecuting:=false;
    synchronize(WriteButtonExecuteTitle);
    if objSettings.MonitoringLog then SaveLogToFile(MonitoringLogFile,'�������� �������� ������� ���������');
end;

procedure TMyTimerThread.SaveWaitList;
begin
     frmMain.SaveWaitActions;
end;

procedure TMyTimerThread.SetCurrentChecking(value: TChecking);
begin
     FCurrentChecking:=value;
     if not terminated then synchronize(WriteButtonExecuteTitle);
end;

procedure TMyTimerThread.SetDefaults;
begin
     EnableMonitoringInterfaces;
     if not frmMain.NVolumeAll.Checked then frmMain.NVolumeAllClick(frmMain);
end;

procedure TMyTimerThread.WriteButtonExecuteTitle;
begin
     if CurrentChecking=cpNone then frmMain.bDoWork.Caption:='��������� ��������'
     else frmMain.bDoWork.Caption:='������������� ��������';
end;

Procedure TMyTimerThread.WriteStatusExecute;
var ap:TTabSheet;
  I: Integer;
begin
    StatusBarToWrite.Panels[0].Text:=messageStatusbar;
    frmMain.StatusBar1.Panels[0].Text:=messageStatusbar;
    ap:=frmMain.PCMain.ActivePage;
    for I := 0 to ap.ControlCount-1 do begin
        if ap.Controls[i].ClassType=TStringGrid then ap.Controls[i].Repaint;
    end;
end;

procedure TMyTimerThread.RefreshStatusNextJob;
begin
     frmMain.StatusBar1.Panels[0].Text:='�������� ��������� '+FormatDateTime('dd.mm.yy hh:mm',LastJobDateTime)+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',Now+(sleeptime/1000/(3600*24)));
end;

// ��������� ��������� ����������� ����� �� ������ ��������
Procedure TMyTimerThread.BeginExecuteRepaint;
begin
    frmMain.bDoWork.Caption:='������������� ��������';
end;

// ��������� ��������� ����������� ����� �� ��������� ���������� ��������
constructor TMyTimerThread.Create(CreateSuspended: boolean);
begin
  inherited Create(CreateSuspended);
  CoInitialize(nil);
end;

destructor TMyTimerThread.Destroy;
begin
  CoUninitialize;
  inherited;
end;

procedure TMyTimerThread.EnableMonitoringInterfaces;
var i,j:integer;
begin
     for i := 1  to Main.countEquipment do begin
         if not terminated then begin
             for j := 1 to Main.MobileEQArray[i].Interfaces.count do begin
                if (Main.MobileEQArray[i].Interfaces[j].status in [s_damage,s_restored]) then begin
                   frmMain.EnableInterfaceEquipmentMon(Main.MobileEQArray[i].Interfaces[j]);
                end;
             end;
         end;
     end;
    for i := 1 to Main.countExcavs do begin
        if not terminated then begin
             for j := 1 to Main.ExcavsArray[i].Interfaces.count do begin
                if (Main.ExcavsArray[i].Interfaces[j].status in [s_damage,s_restored]) then begin
                   frmMain.EnableInterfaceEquipmentMon(Main.ExcavsArray[i].Interfaces[j]);
                end;
             end;
         end;
    end;
    for i := 1 to Main.countNetworkEQ do begin
        if not terminated then begin
             for j := 1 to Main.NetworkEQArray[i].Interfaces.count do begin
                if (Main.NetworkEQArray[i].Interfaces[j].status in [s_damage,s_restored]) then begin
                   Main.NetworkEQArray[i].Interfaces[j].MonitoringOn;
                end;
             end;
         end;
    end;
end;

Procedure TMyTimerThread.endExecuteRepaint;
var i2, i3, i4, i5:integer;
    msg:string;
    datetimestr:string;
    Alarm:boolean;
begin
    Alarm:=false;
    //frmMain.SGEquipment.Repaint;
    //frmMain.SGServer.Repaint;
    datetimestr:=FormatDateTime('dd.mm.yy hh:mm',Now);
    //frmMain.StatusBar1.Panels[0].Text:='�������� ��������� '+datetimestr+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',Now+(sleeptime/1000/(3600*24)));
    msg:='';

    // �������� ��������� �� ��������
    if CurrentChecking=cpServers then begin
      if not objSettings.NotCheckServers then begin
        for i4:=1 to countServers do begin
           for i5 := 1 to ServersArray[i4].Interfaces.count do begin
               if ServersArray[i4].Interfaces[i5].Status=2 then begin
                  msg:=msg+datetimestr+' '+ServersArray[i4].name+' - '+ServersArray[i4].Interfaces[i5].ErrorStr+#13#10;
                  Alarm:=true;
                  frmMain.sbDisableCheck.Enabled:=true;
               end;
           end;
        end;
      end;
    end;
    // �������� ��������� �� �������� ������������
    if CurrentChecking=cpNetwork then begin
      for i4:=1 to countNetworkEQ do begin
         for i5 := 1 to NetworkEQArray[i4].Interfaces.count do begin
             if (NetworkEQArray[i4].Interfaces[i5].Status=2) and (NetworkEQArray[i4].Interfaces[i5].MonitoringSetting=1) then begin
                msg:=msg+datetimestr+' '+NetworkEQArray[i4].name+': '+NetworkEQArray[i4].Interfaces[i5].DisplayName+' - '+NetworkEQArray[i4].Interfaces[i5].ErrorStr+#13#10;
                frmMain.sbDisableCheck.Enabled:=true;
             end;
         end;
      end;
    end;
    // �������� ��������� �� ���������� ������������
    if CurrentChecking=cpEquipment then begin
      for i4:=1 to countEquipment do begin
         for i5 := 1 to MobileEQArray[i4].Interfaces.count do begin
             if (MobileEQArray[i4].Interfaces[i5].Status=2) and (MobileEQArray[i4].Interfaces[i5].MonitoringSetting=1) then begin
                msg:=msg+datetimestr+' '+MobileEQArray[i4].name+': '+MobileEQArray[i4].Interfaces[i5].DisplayName+' - '+MobileEQArray[i4].Interfaces[i5].ErrorStr+#13#10;
                frmMain.sbDisableCheck.Enabled:=true;
             end;
         end;
      end;
    end;
    // ������ ��������� �� ������������
    if CurrentChecking=cpExcavs then begin
      for i4:=1 to countExcavs do begin
         for i5 := 1 to ExcavsArray[i4].Interfaces.count do begin
             if (ExcavsArray[i4].Interfaces[i5].Status=2) and (ExcavsArray[i4].Interfaces[i5].MonitoringSetting=1) then begin
                msg:=msg+datetimestr+' '+ExcavsArray[i4].name+': '+ExcavsArray[i4].Interfaces[i5].DisplayName+' - '+ExcavsArray[i4].Interfaces[i5].ErrorStr+#13#10;
                frmMain.sbDisableCheck.Enabled:=true;
             end;
         end;
      end;
    end;
    // ������ ��������� �� ����������
    if CurrentChecking=cpDrills then begin
      for i4:=1 to countDrills do begin
         for i5 := 1 to DrillsArray[i4].Interfaces.count do begin
             if (DrillsArray[i4].Interfaces[i5].Status=2) and (DrillsArray[i4].Interfaces[i5].MonitoringSetting=1) then begin
                msg:=msg+datetimestr+' '+DrillsArray[i4].name+': '+DrillsArray[i4].Interfaces[i5].DisplayName+' - '+DrillsArray[i4].Interfaces[i5].ErrorStr+#13#10;
                frmMain.sbDisableCheck.Enabled:=true;
             end;
         end;
      end;
    end;
    if CurrentChecking=cpSZMs then begin
      for i4:=1 to countSZMs do begin
         for i5 := 1 to SZMsArray[i4].Interfaces.count do begin
             if (SZMsArray[i4].Interfaces[i5].Status=2) and (SZMsArray[i4].Interfaces[i5].MonitoringSetting=1) then begin
                msg:=msg+datetimestr+' '+SZMsArray[i4].name+': '+SZMsArray[i4].Interfaces[i5].DisplayName+' - '+SZMsArray[i4].Interfaces[i5].ErrorStr+#13#10;
                frmMain.sbDisableCheck.Enabled:=true;
             end;
         end;
      end;
    end;
    // ������ ��������� �� ��������� ������������
    if CurrentChecking=cpWaitAct then begin
       if waitmsg<>'' then msg:=msg+waitmsg;
    end;
    // ����� ��������� � ���������
    if msg<>'' then begin
       frmMain.MMessages.Lines.Add(msg);
       if (not objSettings.NotShowErrors) or (waitmsg<>'') then begin
         waitmsg:='';
         frmMain.PCMain.ActivePage:=frmMain.TSMessages;
         frmMain.RxTrayIcon1DblClick(self);
         if objSettings.Sound.Enable or Alarm then begin
            Main.Sound.resume;
            frmMain.BBDisableSound.Enabled:=true;
            frmMain.BBDisableSound.SetFocus;
         end;
       end;
    end;
    LastJobDateTime:=Now();
    // ���������� ������� �� ������, ���� ������������ �� ����� ������ ��
    sleeptime:=objSettings.SleepTimeSeconds*1000;
    //frmMain.StatusBar1.Panels[0].Text:='�������� ��������� '+FormatDateTime('dd.mm.yy hh:mm',Now())+'. ����. ��������: '+FormatDateTime('dd.mm.yy hh:mm',Now+(sleeptime/1000/(3600*24)));
    frmMain.bDoWork.Caption:='��������� ��������';
end;

{procedure TMyTimerThread.DoWork;
begin
   //currentmark:=0;
   Synchronize(beginExecuteRepaint);
   CheckExecuting:=true;
   if not objSettings.NotCheckServers then runCheckServers;
   runCheckEquipment;
   frmMain.SGEquipment.Repaint;
   runCheckExcavs;
   CheckExecuting:=false;
   if not terminated then Synchronize(endExecuteRepaint);
end;}


procedure TMyTimerThread.Execute;
begin
  // ����� ��� - 10 �����
  ThreadExecuting:=true;
  CurrentChecking:=cpNone;
  MonitoringLogFile:=ExtractFilePath(Application.ExeName)+'Monitoring.log';
  LastJobDateTime:=StrToDateTime('01.01.2013 00:00');
  LastJobDateTimeEquipment:=LastJobDateTime;
  LastJobDateTimeExcavs:=LastJobDateTime;
  LastJobDateTimeServers:=LastJobDateTime;
  LastJobDateTimeNetwork:=LastJobDateTime;
  LastJobDateTimeDrills:=LastJobDateTime;
  LastJobDateTimeWaitAct:=LastJobDateTime;
  sleeptime:=objSettings.SleepTimeSeconds*1000;
  FreeOnTerminate := false;
  repeat
    try
      if (not Terminated) and (not objSettings.NotCheckServers) and (Now()-LastJobDateTimeServers>=MSecondToTime(objSettings.SleepTimeServers*1000)) then RunCheckServers;
      sleep(100);

      if (not Terminated) and (objSettings.ShowNetwork) and (Now()-LastJobDateTimeNetwork>=MSecondToTime(objSettings.SleepTimeNetwork*1000)) then RunCheckNetworkEQ;
      sleep(100);
      // �������� �������� ���������/���������� �������
      if (not Terminated) and (Main.waitActions) and (Now()-LastJobDateTimeWaitAct>=StrToTime('00:02:00')) then RunCheckWaitAct;
      sleep(100);
      if (not Terminated) and (Now()-LastJobDateTimeEquipment>=MSecondToTime(objSettings.SleepTimeEquipment*1000)) then runCheckEquipment;
      sleep(100);
      if (not Terminated) and (objSettings.ShowExcavs) and (Now()-LastJobDateTimeExcavs>=MSecondToTime(objSettings.SleepTimeExcavs*1000)) then RunCheckExcavs;
      if (not Terminated) and (objSettings.ShowDrills) and (Now()-LastJobDateTimeDrills>=MSecondToTime(objSettings.SleepTimeDrills*1000)) then RunCheckDrills;
      if (not Terminated) and (objSettings.ShowDrills) and (Now()-LastJobDateTimeSZMs>=MSecondToTime(objSettings.SleepTimeDrills*1000)) then RunCheckSZMs;
    except

    end;
    // �������� � ini ���� ����� ��������� ��������
    objSettings.LastCheckDateTime:=Now();
    sleep(100);
  until Terminated;
  ThreadExecuting:=false;
end;

{ TControllerMonitorThread }

procedure TControllerMonitorThread.Execute;
var sleeptm:integer;
    difftime:TTime;
    restarting:boolean;
begin
  inherited;
  // ������������� ��������  �� ��������� 5 �����
  sleeptm:=5*60000;
  repeat
    sleep(sleeptm);
    restarting:=false;
    // ������� ������� �� ��������� ����������� ��������, ������� ���������� ��� ������������
    difftime:=1/24/3600*objSettings.SleepTimeSeconds *3;
    if (not objSettings.NotCheckServers) and ((Now()-MyTimerThread.LastJobDateTimeServers)>difftime) then restarting:=true;
    if (not restarting) and (objSettings.ShowNetwork) and ((Now()-MyTimerThread.LastJobDateTimeNetwork)>difftime) then restarting:=true;
    if (not restarting) and ((Now()-MyTimerThread.LastJobDateTimeEquipment)>difftime) then restarting:=true;
    if (not restarting) and (objSettings.ShowExcavs) and ((Now()-MyTimerThread.LastJobDateTimeExcavs)>difftime) then restarting:=true;
    if (not restarting) and (objSettings.ShowDrills) and ((Now()-MyTimerThread.LastJobDateTimeDrills)>difftime) then restarting:=true;
    if restarting then synchronize(RestartMonitoring);
  until Terminated;
end;

procedure TControllerMonitorThread.RestartMonitoring;
var i1:integer;
begin
     frmMain.BBDisableSoundClick(self);
     MyTimer.MyTimerThread.Terminate;
     frmMain.StatusBar1.Panels[0].Text:='���������� ��������';
     i1:=0;
     while MyTimer.ThreadExecuting and (i1<50) do begin
         sleep(50);
         inc(i1);
     end;
     sleep(100);
     MyTimer.MyTimerThread := MyTimer.TMyTimerThread.Create(false);
end;

end.

