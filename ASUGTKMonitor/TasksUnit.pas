unit TasksUnit;
interface
uses classes, windows, sysutils, DM, Forms, MyUtils,
ExtCtrls, Graphics, StrUtils, JPEG,
GifIMG, pngImage, inifiles, DateUtils, ActiveX, DB, ADODB,
ScorpioLists, ScorpioSSH, Log, syncObjs, ScorpioDB;

type TTaskStatus=(tst_success,tst_fail,tst_abort,tst_running,tst_unknown,tst_warning);

type TMySQLStatus=record
       id:Largeint;
       equipmentID:integer;
       status:integer;
       tmstart:TDateTime;
       tmend:TDateTime;
       asuid:string;
       reasonname:string;
end;
type TMySQLStatusList = array of TMySQLStatus;

type TDBVariable = class
    private
      Fobjectname:string;
      Fvariablename:string;
      QMyVar:TMyADOQuery;
      function GetValue:string;
      procedure SetValue(value:string);
    public
      connMySQL:TMyADOConnection;
      property value:string read GetValue write SetValue;
      constructor Create(connection:TMyADOConnection; objname,varname:string);
      destructor Destroy; override;
end;

// ��������������� ���������� ��� ������ �� ������ �� �����
type TTaskThread = class;

TTask=class (TPersistent)
        LogList:TStrings;
      private
        FName:string;
        FDisplayName :string;
        Fsleeptime:integer;    // ���������� ����� ��������� ����� � ��������
        FNextRun:TDateTime;
        FLastRun:TDateTime;
        //FLastCompleted:TDateTime;
        FLogFileName:string;
        FPercentCompleted:real;
        FChanged:boolean;
        FStatus:TTaskStatus;
        FAborted:boolean;
        Thread:TTaskThread;
        Locked:TCriticalSection;
        function getAborted:boolean;
        procedure setAborted(value:boolean);
        procedure ExecuteTask; virtual; abstract;
        procedure setSleepTime(const Value:integer);
        function  getSleepTime:integer;
        procedure SetDisplayName(const Value:string);
        function  getDisplayName:string;
        procedure SetNextRun(const Value:TDateTime);
        function  getNextRun:TDateTime;
        procedure SetLastRun(const Value:TDateTime);
        function  getLastRun:TDateTime;
        procedure SetPercentCompleted(const Value:integer);
        procedure SetCurrentPercent(const Value:real);
        function getCurrentPercent:real;
        function getPercentCompleted:integer;
        function getStatus:TTaskStatus;
        function GetChanged:boolean;
        procedure setStatus(value:TTaskStatus);
        procedure CloseConnections; virtual;         // ������� ��� ���������� � ��
        procedure initDBConnections; virtual;        // ������������� ����������� � ��
        procedure DestroyDBConnections; virtual;     // ����������� ���������� � ��
        procedure ReinitConnections; virtual;        // ����������������� ���������� � ��
        procedure CalculateNextRun;virtual;
      public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runNow:boolean=true); virtual;
        destructor Destroy; override;
        property Aborted:boolean read getAborted write setAborted;        // ���� ����, ��� ���������� ������ �����������
        property Name:string read FName write FName;
        property DisplayName:string read getDisplayName write SetDisplayName;
        property sleeptime:integer read GetSleepTime write SetSleepTime;
        property NextRun:TDateTime read getNextRun write SetNextRun;
        property LastRun:TDateTime read getLastRun write SetLastRun;
        property LogFileName:string read FLogFileName write FLogFileName;
        property PercentCompleted:integer read getPercentCompleted write setPercentCompleted;
        property CurrentPercent: real read getCurrentPercent write setCurrentPercent;   // ������� ����������� ������. ����� ������ ��������, ��� PercentCompleted
        property Changed:boolean read getChanged;
        property Status:TTaskStatus read GetStatus write SetStatus;       // ������ ���������� ������

        Procedure Execute;
        //function Lock:boolean;
        procedure WriteLog(str:string);                           // ��������� ������ ������ � ���� ����
        procedure ClearOldLogs;                 // ��������� ������� ������ �����
        //procedure Unlock;
        procedure SetChanged;
        Procedure SetNotChanged;
        procedure Abort;                      // �������������� ���������� ������ ������
end;

     cTask = class of TTask;

TTaskThread=class(TThread)
      task:TTask;
  private
    procedure OutputLog;
   protected
      procedure Execute; override;
      //procedure OutputLog;
   public
      constructor Create(classTask:CTask;sleeptimesec:integer);
      destructor Destroy; override;
      procedure Terminate;
end;

type TtaskResetPressureGSP=class(TTask)
      private
        OSSHPress:TSSHobj;
        procedure ExecuteTask; override;
      public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;

end;

{type TTaskManageGPSFile=class(TTask)
     private
        FSourcePath:string;
        FDestinationPathName:string;
        procedure ExecuteTask; override;
     public
        property SourcePath:string read FSourcePath;
        property DestinationPathName:string read FDestinationPathName;
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
end;}

type TTaskGetGPSInformation=class(TTask)
     private
        connStat:TMyADOConnection;
        qryStat:TMyADOQuery;
        FSourceFolder:string;
        FShiftCount:integer;
        FStatFileName:string;
        FPercentStepByShift:integer;                    // ��� �������� ���������� ������. ��� 1-� ����� - 100%, ��� 2-�-50%
        FsecondsToFindStats:integer;
        procedure ExecuteTask; override;
        procedure getGPSbyShift(shift:string);                // �������� � �������� ���������� �� ���� �����
        procedure CalculateNextRun; override;
        procedure CloseConnections; override;
     public
        procedure getGPSInfo(startshift:string;countshifts:integer);  // �������� � �������� ���������� �� countshifts ����, ������� � startshift
        property SourceFolder:string read FSourceFolder write FSourceFolder;     // �������� ���� � ������������ GPS
        property ShiftCount:integer read FShiftCount write FShiftCount;         // ���������� ���� ��� ��������
        property StatFileName:string read FStatFileName write FStatFileName;
        property secondsToFindStats:integer read FsecondsToFindStats write FsecondsToFindStats; // ����������� ��������� ���������� ������� ����� ���������� �� ������� ����������
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;
end;

type TLocPoints = array [0..9] of TPoint;

// ������ ��������� ������� ����� �������
type TTaskGenerateImagePitgraph=class(TTask)
type TExcavInfo=record
     name:string;
     x:integer;
     y:integer;
     lastgpstime:LongInt;
end;

     private
        FSourcepitloc:string;
        FSourceTravel:string;
        FSourceExcav:string;
        FDestinationFileName:string;
        FFillColor:TColor;              // ���� ������� ����� �������
        FDrawColor:TColor;              // ���� ����� ����� �������
        FImageWidth:integer;            // ����� �������
        FImageHeight:integer;           // ������ �������
        FScaleImageToMeters: real;      // ������� �������, ������ �� �������
        FPGStartX:integer;              // ��������� � �������� ��������������� �������
        FPGStartY:integer;
        FPGEndX:integer;
        FPGEndY:integer;
        FGenerateTextData: boolean;     // ���� �������� ������ � ������� � ��������� ����
                                        // ���� ���� �������, �� �� FDestinationFileName
                                        // � ��������� ���� ����� �������� ������ �� �������� � �������
        FGenerateImage:boolean;         // ���� ��������� ������ ������� �� �������
        FDestPitlocFileName:string;     // ���� ���������� ������ �� ��������
        FDestRoadsFileName:string;      // ���� ���������� ������ � �������
        FpitlocTemp:string;             // ��������� ���� � ��������� ��������
        FRoadsTemp:string;              // ��������� ���� � ��������
        FSourcePitlocTemp:string;
        FSourceTravelTemp:string;
        FDrawControlPoints:boolean;
        FTextSize:integer;
        FDrawLabel:boolean;
        FShowExcavs:boolean;
        imagePitgraph:TBitmap;
        function ConvertToCanvas(Point:TPoint): TPoint;
        procedure DrawPitloc(name:string; xm,ym : integer); // ��������� ��������� ������� ����� ������� �� �������
        procedure DrawRoad(startid,endid:string;startx,starty,endx,endy:integer;roadpoints:TLocPoints; closed:boolean=false); // ��������� ��������� ������ �� �������
        // ��������� ��������� ����������� �� �����
        // �������� �����������, ���������� ������� ���� �������� �� ����� ������ �����.
        // ���� ������� ��������� ������ �����, �� ������������ �������� ������� ������, ���� ������� ������ �����, �� ������� ������
        procedure DrawExcav(exinfo:TExcavinfo);
        procedure paintExcavs;                               // ��������� ��������� ������� ������������
        procedure ExecuteTask; override;
        procedure CalculateNextRun; override;
     public
        property SourcePitloc: string read FSourcepitloc write FSourcePitloc;       // ���� � ����� � ��������� �������
        property SourceTravel: string read FSourceTravel write FSourceTravel;       // ���� � ����� � �������� �������
        property SourceExcav: string read FSourceExcav write FSourceExcav;           // ���� � ����� � ������� �� ������������
        property DestinationFileName: string read FDestinationFileName write FDestinationFileName; // ���� � ��������� �����
        property FillColor:TColor read FFillColor write FFillColor default clWhite;
        property DrawColor:TColor read FDrawColor write FDrawColor default clBlack;
        property DrawControlPoints: boolean read FDrawControlPoints write FDrawControlPoints default true; // ���� ��������� ���� ����������� �����
        property TextSize:integer read FTextSize write FTextSize default 7;     // ������ ������ �� �������� � ��������
        property DrawLabel:boolean read FDrawLabel write FDrawLabel default false; // �������� ���� � ����� ���������� ��������� �����
        property ShowExcavs:boolean read FShowExcavs write FShowExcavs default false; // ���������� �� �� ����� �������������� ������������
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
end;
// ������ ��������� ������� ����� ������� ��� ������� ������
type TTaskGenerateImagePitgraphASUGTK=class(TTaskGenerateImagePitgraph)
     private
        procedure CalculateNextRun; override;
     public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
end;




type TTaskGenerateImagePitD6=class(TTask)
type TExcavInfo=record
     name:string;
     x:integer;
     y:integer;
     lastgpstime:LongInt;
end;

     private
        FDestDir:string;                // ����� ����������
        FDestFileName:string;           // �������� ��� �����
        FFillColor:TColor;              // ���� ������� ����� �������
        FDrawColor:TColor;              // ���� ����� ����� �������
        FImageWidth:integer;            // ����� �������
        FImageHeight:integer;           // ������ �������
        FScaleImageToMeters: real;      // ������� �������, ������ �� �������
        FPGStartX:integer;              // ��������� � �������� ��������������� �������
        FPGStartY:integer;
        FPGEndX:integer;
        FPGEndY:integer;
        //FGenerateTextData: boolean; � Dispatch 6 ������ ����� ����� �� ��     // ���� �������� ������ � ������� � ��������� ����
                                        // ���� ���� �������, �� �� FDestinationFileName
                                        // � ��������� ���� ����� �������� ������ �� �������� � �������
        FGenerateImage:boolean;         // ���� ��������� ������ ������� �� �������
        FDrawControlPoints:boolean;
        FTextSize:integer;
        FDrawLabel:boolean;
        FShowExcavs:boolean;
        FDestinationFilename:string;
        imagePitgraph:TBitmap;
        tempPitloc: TStrings;
        ConnD6:TMyADOConnection;
        QSQL1:TMyADOQuery;
        function ConvertToCanvas(Point:TPoint): TPoint;
        procedure DrawPitloc(name:string; xm,ym : integer; unitid:integer); // ��������� ��������� ������� ����� ������� �� �������
        procedure DrawRoad(startid,endid:string;startx,starty,endx,endy:integer;roadpoints:TLocPoints; closed:boolean=false); // ��������� ��������� ������ �� �������
        // ��������� ��������� ����������� �� �����
        // �������� �����������, ���������� ������� ���� �������� �� ����� ������ �����.
        // ���� ������� ��������� ������ �����, �� ������������ �������� ������� ������, ���� ������� ������ �����, �� ������� ������
        procedure DrawExcav(exinfo:TExcavinfo);
        procedure paintExcavs;                               // ��������� ��������� ������� ������������
        procedure ExecuteTask; override;
        procedure CalculateNextRun; override;
        procedure CloseConnections; override;
        function DrawPitlocs:boolean;                              // ������ ������� �������� �������
        function DrawRoads:boolean;                                // ������ ������ �� �����
        procedure initDBConnections; override;
        procedure DestroyDBConnections; override;
     public
        property DestDir:string read FDestDir write FDestDir;   //  ����� ����������
        property DestFileName:string read FDestFileName write FDestFileName;  // �������� ��� �����
        property FillColor:TColor read FFillColor write FFillColor default clWhite;
        property DrawColor:TColor read FDrawColor write FDrawColor default clBlack;
        property DrawControlPoints: boolean read FDrawControlPoints write FDrawControlPoints default true; // ���� ��������� ���� ����������� �����
        property TextSize:integer read FTextSize write FTextSize default 7;     // ������ ������ �� �������� � ��������
        property DrawLabel:boolean read FDrawLabel write FDrawLabel default false; // �������� ���� � ����� ���������� ��������� �����
        property ShowExcavs:boolean read FShowExcavs write FShowExcavs default false; // ���������� �� �� ����� �������������� ������������
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
end;

// ������ ��������� ����� ������� ��� ������� ������
type TTaskGenerateImagePitD6ASUGTK=class(TTaskGenerateImagePitD6)
     private
        procedure CalculateNextRun; override;
     public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
end;

// ������ ���������� ���������� �� ������� �������� ��� ������������
type TTaskCalcStatWiFiByEquipment=class(TTask)
  private
        FDaysToCalc: integer;           // ���������� ���� �� ������� ����� ����������� ����������
        FConnMysql:TMyADOConnection;
        FQTemp:TMyADOQuery;
        FQTemp2:TMyADOQuery;
        FQTemp3:TMyADOQuery;
        FFirstDate:TDate;               // ������ ���� ���������� ����������
        FLastDate:TDate;                // ��������� ���� ��� ����������
        FPercentStep:real;              // �������, �� ������� ��������� ��������� ��� ������� 1 ���
        procedure ExecuteTask; override;
        procedure SetDaysToCalc(const Value:integer);
        procedure CalculateNextRun; override;
        procedure CloseConnections; override;
  public
        property DaysToCalc:integer read FDaysToCalc write SetDaysToCalc;
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;
        procedure WriteStatistic(dt:TDate);
end;

// ������ ����� ������ ��������. ������ �� �����
type TTaskUpdateDrillStatus=class(TTask)
  ReadyBreaksCategories: TIntList;
  private
        connMySQL1:TMyADOConnection;
        QMySQL1:TMyADOQuery;
        QMySQL2:TMyADOQuery;
        connKobus1:TMyADOConnection;
        Qpg1:TMyADOQuery;
        FLastBreakageId:integer;
        function getModemIdByPriborId(priborId:integer):integer;

        function getStatusByBreak(breakId,ParentBreakId:integer):TStatssStatus;
        // ���������� �������� ����� tmstart � tmend. ������� ���������� ��������� ����������� �������� � ������� Statss
        // � ������ ������ ������ -1
        function UpdateStatus(modemId:integer;status:integer;tmstart,tmend:TDateTime;checkToUnknown:boolean=false):integer; // ���������� �������
        procedure UpdateNotFinishedBreakages;           // ���������� ������������� ��������, ������� ���� �������� � ��
        procedure ExecuteTask; override;
  public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;
end;

// [2021-07-05] ������ ������ ��������� ������ � �� ubiquiti �� �� kobus_lgok

type TTaskGetBVUGPS=class(TTask)
  type TCurrEQ = class
       priborid:integer;
       name:string;
       equipment_id:integer;
       //modemid:integer;
       lastWritedGPS:TDateTime;
  end;
  private
        connMySQLGPS:TMyADOConnection;
        QMySQLBGPS:TMyADOQuery;
        QMySQLPribors:TMyADOQuery;
        connKobusGPS:TMyADOConnection;
        QpgGps:TMyADOQuery;
        CurrEQ:TCurrEQ;
        PercentByPribor: Real;
        procedure InsertCurrEQCoord(x,y:integer;dttm:TDateTime);
        Procedure writeCurrEQCoordPoint(statssid:integer; x,y:integer; dttm:TDateTime);   // ������ � ����� �� ������� statss c id statssid ���������
                                                              // � ���������� ������� last_gps_writed � ������� kobus_pribors
        procedure WriteCoordsCurrEQ;  // ������ ��������� � ���������� ��� ������������ CurrEQ
        function getModemIdByPriborId(priborId:integer):integer; // ��������� id-������ �� id-�������
        function getEquipmentIdByPriborId(priborId:integer):integer;
        procedure ExecuteTask; override;
        procedure CloseConnections; override;
        procedure initDBConnections; override;
        procedure DestroyDBConnections; override;
  public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;
end;

// [2021-08-15] ������ ������ ����������� ���������� � ������� wifi_stat_map_data
type TTaskCalcWiFiStatMap=class(TTask)
   private
        connMySQL1:TMyADOConnection;
        QMySQLEQuipment:TMyADOQuery;
        QMySQL2:TMyADOQuery;
        procedure ExecuteTask; override;
        procedure CloseConnections; override;
   public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;
end;

// [2021-09-10] ������ �������� �������� �� ������ �������
type TTaskGetModularStatuses=class(TTask)
    private
        connMySQL1:TMyADOConnection;
        connD6:TMyADOConnection;
        QPVstatuses:TMyADOQuery;
        QMySQL1:TMyADOQuery;
        QMySQL2:TMyADOQuery;
        shiftindex:integer;
        minendtime:integer;
        mysqlError:boolean;
        procedure ExecuteTask; override;
        function WriteCurrentStatus(status:TModularStatus):boolean;
        procedure SaveStatistic(shiftid,shseconds:integer);
        procedure CloseConnections; override;
    public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;
end;

// [2022-07-15] ������ �������� �������� �� ������ Dispatch 6
type TTaskGetDispatch6Statuses=class(TTask)
    private
        connMySQL1:TMyADOConnection;
        connD6:TMyADOConnection;
        QD6statuses:TMyADOQuery;
        QMyActiveEquipment:TMyADOQuery;
        QMySQL1:TMyADOQuery;
        //QMySQL2:TMyADOQuery;
        shiftindex:integer;
        minendtime:integer;
        mysqlError:boolean;
        PercentBy1EQ: real;
        function DeleteMySQLStatus(id:Largeint):boolean;         // �������� ������� �� Mysql
        function GetMySQlStatuses(equipmentId:integer;tmstart,tmend:TDateTime):TMySQLStatusList;
        function FreeMySQLStatus(MySQLStatus:TMySQLStatus;tmstart,tmend:TDateTime):boolean;    // ���������� ����� � ������� MySQLStatus � tmstart �� tmend
        function MoveMySQLStatus(id:Largeint;newtmstart,newtmend:TDateTime):boolean;   // ������� ������ ������� ������ � ��������� ��� �������
        function insertMySQLStatus(equipmentId:integer;status:integer;tmstart,tmend:TDatetime;asuid:string; reasonname:string):boolean;  // �������� ������ � MySQL
        procedure WriteStatusesForEquipment(equipmentId:Largeint;EquipmentName:string;FirstStateId:Largeint);  // ��������� � ������ �������� ���
        function WriteStatus(equipmentId:integer;status:integer;tmstart,tmend:TDatetime;asuid:string;reason:string):boolean; // ������ �������
        function WriteLastStatusId(equipmentid:integer;asuid:Int64):boolean;    //������ id ���������� ������������ �������
        procedure CloseConnections; override;
        procedure initDBConnections; override;        // ������������� ����������� � ��
        procedure DestroyDBConnections; override;
        procedure ExecuteTask; override;
    public
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
    destructor Destroy; override;
end;

type TTaskGetGPSDispatch6=class(TTask)
  private
        connD6:TMyADOConnection;
        connMySQL:TMyADOConnection;
        QD6GPS:TMyADOQuery;
        QMyD6GPS1:TMyADOQuery;
        DBLastGPSD6Id:TDBVariable;
        counterrors:integer;
        counterrorsLogs:integer;                      // ���������� ������ ������ ��� ������ �����. ����������� ������ ������ �� ����� ����������
        procedure CloseConnections; override;
        procedure initDBConnections; override;        // ������������� ����������� � ��
        procedure DestroyDBConnections; override;
        function GetEQidByName(EQName:string):Largeint; // ��������� ������� Mysql ������������ �� �����
        function InsertGPS(EQName:string;dttm:TDatetime;x,y:real):boolean; // ������� ���������� � �� ubiquiti
  public
        procedure ExecuteTask; override;
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;
end;

// [2021-09-15] ������ ������ �������� �� �� ����� � ������� stats_status
type TTaskGetDrillStatuses=class(TTask)
  private
        connMySQL1:TMyADOConnection;
        QMySQL1:TMyADOQuery;
        QMySQL2:TMyADOQuery;
        connKobus1:TMyADOConnection;
        Qpg1:TMyADOQuery;
        FLastBreakageId:integer;
        FLimitStatuses:integer;
        ReadyBreaksCategories: TIntList;
        procedure initDBConnections; override;        // ������������� ����������� � ��
        procedure DestroyDBConnections; override;
        function DeleteMySQLStatus(id:Largeint):boolean;         // �������� ������� �� Mysql
        function MoveMySQLStatus(id:Largeint;newtmstart,newtmend:TDateTime):boolean;   // ������� ������ ������� ������ � ��������� ��� �������
        function insertMySQLStatus(equipmentId:integer;status:integer;tmstart,tmend:TDatetime;asuid:string):boolean;  // �������� ������ � MySQL
        function FreeMySQLStatus(MySQLStatus:TMySQLStatus;tmstart,tmend:TDateTime):boolean;    // ���������� ����� � ������� MySQLStatus � tmstart �� tmend
        function FindMySQLStatusBeforeTime(equipmentId:integer;dttm:TDateTime):TMySQLStatus;    // ��������� ������� ����� �������� dttm
        function getEquipmentIdByPriborId(priborId:integer):integer;
        function GetMySQlStatuses(equipmentId:Largeint;tmstart,tmend:TDateTime):TMySQLStatusList;
        function getStatusByBreak(breakId,ParentBreakId:integer):TStatssStatus;
        function isUsedInMonitoring(eqid:Integer):shortint;
        // ���������� �������� ����� tmstart � tmend. ������� ���������� ��������� ����������� �������� � ������� Statss
        // � ������ ������ ������ -1
        //function UpdateStatus(equipmentId:integer;status:integer;tmstart,tmend:TDateTime;asuid:integer):integer; // ���������� �������
        //function insertStatus(equipmentId:integer;status:integer;tmstart,tmend:TDatetime;asuid:integer):integer; // ������� ������ �������
        function WriteStatus(equipmentId:integer;status:integer;tmstart,tmend:TDatetime;asuid:string):boolean;  // ����� ����������� ������� ������ ��������
        procedure UpdateNotFinishedBreakages;           // ���������� ������������� ��������, ������� ���� �������� � ��
        procedure WriteLastReadyStatusesForEQ;          // ��������� ������ ���������� ������� ����� ��� �������, ��� ��� � ������ ����������� ������� ����� � ���������, ��� ���� ��� �������, ������ ������� � ������
        procedure ExecuteTask; override;
        procedure CloseConnections; override;
  public
        property LimitStatuses:integer read FLimitStatuses write FLimitStatuses;
        constructor Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true); override;
        destructor Destroy; override;
end;


type TTaskThreadArray= array of TTaskThread;

   TTasksManagerThread=class(TThread)
   private
       //FCurrentTaskIndex:integer; // ������ ��������� ������ � ��������� �����
       TTA:TTaskThreadArray;    // ������ ������� ��� ���������� �����
       function GetTasksCount:integer;  // ���������� �����
       procedure startAllTasks;   // ��������� ��� ������
       procedure stopAllTasks;    // ������������� ��� ������
       function getTaskClass(taskname:string):cTask; // �������� ����� ������ �� �����
   protected
       Log:TLog;
       //property CurrentTaskIndex:integer read FCurrentTaskIndex write FCurrentTaskIndex;

       procedure Execute; override;
       Procedure RepaintTasks;
       //procedure RepaintTask;
   public
       constructor Create;
       destructor Destroy; override;
       function AddTask(taskname:string;sleeptime:integer):boolean;   // ���������� ����� ������
       function InsertTask(index:integer;taskname:string;sleeptime:integer):boolean;  // ������� ������ � ������ ����� ������� �����
       property TasksThreads: TTaskThreadArray read TTA;
       property TasksCount:integer read GetTasksCount; // ���������� �����
       procedure StopTask(index:integer);
       procedure StartTask(index:integer);
   end;


implementation

uses Main;

{ TTask }

procedure TTask.Abort;
begin
     setAborted(true);
     // [2022-07-27] ������ ����� ������, ����� ���������� ������ ����������
     //Status:=tst_abort;
end;

procedure TTask.CalculateNextRun;
begin
     if sleeptime>0 then NextRun:=LastRun+1/24/3600*sleeptime else NextRun:=LastRun+1/24/3600*10;
end;

procedure TTask.ClearOldLogs;
var
  a: Integer;
  fileextension:string;
  flsize: LongInt;
  flname: string;
  flpath1: string;
begin
     // ��������� ������ �����
     flsize:=SizeOfFile(LogFileName);
     // ���� ������ ������ ���������, �� ��������� ������ ���
     if (flsize>10*1024*1024) then begin
         // �������� ��� ��������� ���� � ��� ����������
         a:=LastPos('.',LogFileName);
         fileextension:=Copy(LogFileName,a,Length(LogFileName)-a+1);
         flname:=Copy(LogFileName,0,a-1);
         flpath1:=flname+'.1'+fileextension;
         try
            if FileExists(flpath1) then DeleteFile(flpath1);
            MoveFile(PWideChar(LogFileName),PWideChar(flpath1));
         except
           on E: Exception do begin
            WriteLog('������ ����������� ����� ���� ��� ������� �������. '+ E.Message);
           end;
         end;
     end;
end;

constructor TTask.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
     inherited Create;
     Locked:=TCriticalSection.Create;
     LogList:=TStringList.Create;
     PercentCompleted:=100;
     self.Name:= RightStr(self.ClassName,Length(self.ClassName)-5);
     LogFileName:=self.name+'.txt';
     Thread:=owner;
     self.sleeptime:=sleeptimesec;
     Status:=tst_unknown;
     if not runnow then CalculateNextRun;
     self.initDBConnections;
end;

destructor TTask.Destroy;
begin
     DestroyDBConnections;
     FreeAndNil(LogList);
     FreeAndNil(Locked);
     inherited;
end;

procedure TTask.DestroyDBConnections;
begin

end;

procedure TTask.Execute;
begin
    self.Aborted:=false;
    self.CloseConnections;
    LastRun:=Now();
    CalculateNextRun;
    PercentCompleted:=0;
    if status=tst_fail then begin
      WriteLog('���������� ���������� ������� ����������� �������.');
      WriteLog('����������������� ����� � ������ ������');
      try
        ReinitConnections;
      except
        WriteLog('������ ����������������� ����� ���');
        exit;
      end;
    end;
    status:=tst_running;
    ClearOldLogs;
    Status:=tst_running;
    WriteLog(' ');
    WriteLog('������� '+Self.Name+' ��������');
    try
      self.ExecuteTask;
    except
      on E: Exception do begin
        WriteLog('�������������� ������ ��� ���������� ������� '+Self.Name+'. '+E.Message);
        Status:=tst_fail;
      end;
    end;
    PercentCompleted:=100;
    if self.Status=tst_running then begin
        if not self.Aborted then Status:=tst_success else Status:=tst_abort;
    end;
    CloseConnections;
    aborted:=false;
    WriteLog('������� '+Self.Name+' ���������');
    WriteLog('-------------'+#13#10);
end;

function TTask.getAborted:boolean;
var
  needchangestatus: Boolean;
begin
     needchangestatus:=false;
     try
        Locked.Enter;
        if Thread.Terminated and not FAborted then begin
          FAborted:=true;
          needchangestatus:=true;
        end;
        result:=FAborted;
     finally
        Locked.Leave;
        if needchangestatus then status:=tst_abort;
     end;
end;

function TTask.GetChanged: boolean;
begin
     Locked.Enter;
     try
        Result:=FChanged;
     finally
        Locked.Leave;
     end;
end;

function TTask.getCurrentPercent: real;
begin
     try
        Locked.Enter;
        result:=FPercentCompleted;
     finally
        Locked.Leave;
     end;
end;

function TTask.getDisplayName: string;
begin
     Locked.Enter;
     try
        Result:=FDisplayName;
     finally
        Locked.Leave;
     end;
end;

function TTask.getLastRun: TDateTime;
begin
     try
       Locked.Enter;
       Result:=FLastRun;
     finally
       Locked.Leave;
     end;
end;

function TTask.getNextRun: TDateTime;
begin
     try
       Locked.Enter;
       Result:=FNextRun;
     finally
       Locked.Leave;
     end;
end;

function TTask.getPercentCompleted: integer;
begin
      result:=round(getCurrentPercent);
end;

function TTask.getSleepTime: integer;
begin
     Locked.Enter;
     try
        Result:=FSleepTime;
     finally
       Locked.Leave;
     end;
end;

function TTask.getStatus: TTaskStatus;
begin
    try
      Locked.Enter;
      Result:=FStatus;
    finally
      Locked.Leave;
    end;
end;

procedure TTask.initDBConnections;
begin

end;

procedure TTask.ReinitConnections;
begin
     try
        DestroyDBConnections;
     except
        WriteLog('����������� ������ � �� ����������� �������');
     end;
     initDBConnections;
end;

procedure TTask.setAborted(value:boolean);
begin
    try
      Locked.Enter;
      FAborted:=value;
    finally
      Locked.Leave;
    end;
end;

procedure TTask.SetChanged;
begin
     try
        Locked.Enter;
        FChanged:=true;
     finally
        Locked.Leave;
     end;
end;

procedure TTask.SetCurrentPercent(const Value: real);
begin
     if FPercentCompleted<>Value then begin
        try
          Locked.Enter;
          FPercentCompleted:=Value;
        finally
          Locked.Leave;
        end;
        SetChanged;
     end;
end;

procedure TTask.SetDisplayName(const Value: string);
begin
     try
       Locked.Enter;
       FDisplayName:=Value;
     finally
       Locked.Leave;
     end;
     SetChanged;
end;

procedure TTask.SetLastRun(const Value: TDateTime);
begin
     try
       Locked.Enter;
       FLastRun:=Value;
     finally
       Locked.Leave;
     end;
     SetChanged;
end;

procedure TTask.SetNextRun(const Value: TDateTime);
begin
     try
       Locked.Enter;
       FNextRun:=Value;
     finally
       Locked.Leave;
     end;
     SetChanged;
end;

procedure TTask.SetNotChanged;
begin
     try
       Locked.Enter;
       FChanged:=False;
     finally
       Locked.Leave;
     end;
end;

procedure TTask.SetPercentCompleted(const Value: integer);
begin
        try
          Locked.Enter;
           if round(FPercentCompleted)<>Value then FPercentCompleted:=Value;
        finally
          Locked.Leave;
        end;
        SetChanged;
end;

procedure TTask.setSleepTime(const Value:integer);
begin
     Locked.Enter;
     try
       if value>=60 then FSleepTime:=Value else begin
          Application.MessageBox('���������� ���������� �������� ������� ������ 1 ������','������');
          exit;
       end;
       NextRun:=LastRun+1/24/3600*sleeptime;
     finally
       Locked.Leave;
     end;
end;

procedure TTask.setStatus(value: TTaskStatus);
begin
     try
       Locked.Enter;
       FStatus:=value;
     finally
       Locked.Leave;
     end;
end;

procedure TTask.CloseConnections;
begin

end;

{
procedure TTask.Unlock;
begin
     FBusy:=false;
end;
}
procedure TTask.WriteLog(str: string);
begin
     if (LogFileName<>'') then SaveToFile(LogFileName,GetNowstr+': '+str);
end;

{ TtaskResetPressureGSP }

constructor TtaskResetPressureGSP.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
     inherited Create(owner,sleeptimesec,runnow);
     Name:='ResetPresspro';
     DisplayName:='������������ ��������� Pressure Pro';
     OSSHPress:=TSSHobj.Create;
     OSSHPress.sleeptm:=1000;
     LogFileName:=ExtractFilePath(Application.ExeName)+'Tasks.log';
end;

destructor TtaskResetPressureGSP.Destroy;
begin
     FreeAndNil(OSSHPress);
     inherited;
end;

procedure TtaskResetPressureGSP.ExecuteTask;
var i,j:integer;
    countretry:integer;
    checkinterval:integer;
    wasCheck:boolean;
    str:string;
    Logged:boolean;
    port:integer;
  findPort: Boolean;
  stepPercent:Real;
  Perc:real;
begin
     Logged:=LogFileName<>'';
     LogList.Clear;
     Perc:=PercentCompleted;
     checkinterval:=10; // �������� �������� ������� ��� ���������� �������� � �������
     if Main.countEquipment=0 then frmMain.InitEquipment(trucks);
     str:=FormatDateTime('dd.mm.yyyy hh:mm',Now())+' '+ '������ ������ "'+DisplayName+'"';
     LogList.Add(str);
     // �������, ����� ������� �� ������ ���������� ���������� �� 1 ������� �������
     if Main.countEquipment>0 then stepPercent:=100/Main.countEquipment;
     for I := 1 to Main.countEquipment do begin
        wasCheck:=false;
        if (MobileEQArray[i].ClassName='TTruck') then begin
           // ���� ������ ���������� ����� 10 ����� �����, �� ��������� ������ PressurePro
           if (TTruck(MobileEQArray[i]).Pressure.LastCheckDateTime<(Now()-1/24/60*checkinterval)) then begin
              countRetry:=0;
              while (countRetry<5) and ( not wasCheck ) do begin
                  wasCheck:=TTruck(MobileEQArray[i]).Pressure.Check;
                  inc(countRetry);
                  sleep(1000);
              end;
           end else wasCheck:=true;
           // ��� ���������� ������ � PTX ��������� ������������� gsp, �� ������� ����� PressurePro
           if (wasCheck) and (TTRuck(MobileEQArray[i]).Pressure.status=2) and (TTRuck(MobileEQArray[i]).Pinged) then begin
              str:=TTRuck(MobileEQArray[i]).name+' - '+TTRuck(MobileEQArray[i]).Pressure.ErrorStr+':'+FormatDateTime('dd.mm.yyyy hh:mm',Now());
              LogList.Add(str);
              if OSSHPress.Lock then begin
                  if TTRuck(MobileEQArray[i]).Pressure.GSPPort<>0 then port:=TTRuck(MobileEQArray[i]).Pressure.GSPPort else port:=129;
                  // ��������� ��, ��� ��� ����������� � OMStip �� �������� ����������� � GSP
                  OSSHPress.sleeptm:=5000;
                  OSSHPress.command:='(sleep 3; echo "exit") | /mms/lib/linux_v9/OMStip '+TTruck(MobileEQArray[i]).IPAddress;
                  OSSHPress.Execute;
                  sleep(1000);
                  OSSHPress.sleeptm:=10000;
                  OSSHPress.command:='(sleep 3; echo "connect Can.'+inttostr(port)+'"; sleep 3;  echo "exit"; sleep 2; echo "exit") | /mms/lib/linux_v9/OMStip '+TTruck(MobileEQArray[i]).IPAddress;
                  findPort:=false;
                  // ������������ � ������ �� ������ ��� ����
                  if OSSHPress.Execute then begin
                     if OSSHPress.Answer.Count>6 then begin
                         if (FindLineSubstringInList('SQ Interface',OSSHPress.Answer)>-1) or (FindLineSubstringInList('PressurePro',OSSHPress.Answer)>-1) then begin
                                findPort:=true;
                                TTRuck(MobileEQArray[i]).Pressure.GSPPort:=port;
                         end;
                     end else sleep(25000);
                     LogList.AddStrings(OSSHPress.Answer);
                  end;
                  // ���� �� ����� ������ �� ������ �����, �� ������������ � �������
                  if not FindPort then begin
                     if port=128 then port:=129 else port:=128;
                     OSSHPress.command:='(sleep 3; echo "connect Can.'+inttostr(port)+'"; sleep 3;  echo "exit"; sleep 2; echo "exit") | /mms/lib/linux_v9/OMStip '+TTruck(MobileEQArray[i]).IPAddress;
                     if OSSHPress.Execute then begin
                             if OSSHPress.Answer.Count>6 then begin
                                 if (FindLineSubstringInList('SQ Interface',OSSHPress.Answer)>-1) or (FindLineSubstringInList('PressurePro',OSSHPress.Answer)>-1) then begin
                                    findPort:=true;
                                    TTRuck(MobileEQArray[i]).Pressure.GSPPort:=port;
                                 end;
                             end else sleep(25000);
                         LogList.AddStrings(OSSHPress.Answer);
                     end;
                  end;
                  // ���� ����� ���� � pressure, �� ������������� ���
                  if findPort then begin
                     LogList.Add('SQ Interface ��������� � ����� Can.'+inttostr(port));
                     OSSHPress.sleeptm:=29500;
                     OSSHPress.command:='(sleep 3; echo "connect Can.'+inttostr(port)+'"; sleep 3;echo presspro; sleep 4; echo "reset"; sleep 2; echo ""; sleep 13; echo ""; sleep 1; echo "exit"; sleep 1; echo "exit"; sleep 1) | /mms/lib/linux_v9/OMStip '+TTruck(MobileEQArray[i]).IPAddress;
                     if OSSHPress.Execute then begin
                        str:='SQ Interface ������� ������������';
                     end else begin
                        str:='�� ������� ������������� SQ Interface';
                     end;
                     LogList.AddStrings(OSSHPress.Answer);
                     LogList.Add(str);
                     LogList.Add('');
                  end else begin
                     str:='SQ Interface �� ������';
                     LogList.Add(str);
                  end;
                  OSSHPress.Unlock;
              end;
           end;
           // ����� ���������� �������� �� ������������ gsp
        end;
        // ����� �������, ���� ��������
        perc:=perc+stepPercent;
        PercentCompleted:=Round(perc);
     end;
     // ����� ����� �� �������� ���������� ������������
     str:=FormatDateTime('dd.mm.yyyy hh:mm',Now())+' '+ '������ ��������� "'+DisplayName+'"';
     LogList.Add(str);
     LogList.Add('-----------------------------------');
     // ����� �����
     if Logged then for I := 0 to LogList.Count - 1 do SaveToFile(LogFileName,LogList[i]);
end;

{ TTasksManagerThread }

function TTasksManagerThread.AddTask(taskname: string; sleeptime:integer): boolean;
var clname:string;
    ct1:cTask;
begin
     ct1:=getTaskClass(taskname);
     if ct1<>nil then begin
          SetLength(TTA,TasksCount+1);
          TTA[self.TasksCount-1]:=TTaskThread.Create(ct1,sleeptime);
          result:=true;
      end else result:=false;
end;

constructor TTasksManagerThread.Create;
var i:integer;
begin
      inherited Create(true);
     Log:=TLog.Create(ExtractFileDir(Application.ExeName)+'\TaskManager.log');
     FreeOnTerminate:=false;
end;

destructor TTasksManagerThread.Destroy;
var i:integer;
begin
     for I := 0 to TasksCount-1 do begin
         try
            FreeAndNil(TTA[i]);
         except
            Log.Write('������ �������� ������ '+inttostr(i));
         end;
     end;
     SetLength(TTA,0);
     FreeAndNil(Log);
     inherited;
end;

procedure TTasksManagerThread.Execute;

var //dttm:TDateTime;
    i:integer;
    NeedRepaint:boolean;
begin
  inherited;
  // ��������� ��� ������
  sleep(1000);
  startAllTasks;
  repeat
      //dttm:=Now();
      NeedRepaint:=false;
      for I := 0 to TasksCount-1 do begin
          try
            if TTA[i].task.Changed then begin
              NeedRepaint:=true;
              Break;
            end;
          except
            Log.Write('������ �������� ��������� ������');
          end;
      end;
      if NeedRepaint then synchronize(RepaintTasks);
      sleep(1000);
  until terminated;
  stopAllTasks;
end;

function TTasksManagerThread.getTaskClass(taskname: string): cTask;
var clname:string;
  ct1: cTask;
begin
    ct1:=nil;
    clname:='TTask'+taskname;
     ct1:=cTask(GetClass(clname));
     if ct1=nil then begin
        // ��������� �� ������ �������� �������
        clname:='';
        if taskname='ResetPresspro' then clname:='TtaskResetPressureGSP';
        if taskname='DrawPitgraph' then clname:='TTaskGenerateImagePitgraph';
        if taskname='DrawPitASUGTK' then clname:='TTaskGenerateImagePitgraphASUGTK';
        if taskname='CalcWiFiStatEQ' then clname:='TTaskCalcStatWiFiByEquipment';
        if clname<>'' then ct1:=cTask(GetClass(clname));
     end;
     result:=ct1;
end;

function TTasksManagerThread.GetTasksCount: integer;
begin
     result:=Length(TTA);
end;

function TTasksManagerThread.InsertTask(index: integer; taskname: string;
  sleeptime: integer): boolean;
var clname:string;
    ct1:cTask;
begin
     ct1:=GetTaskClass(taskname);
     if ct1<>nil then begin
          if index>=TasksCount then SetLength(TTA,index+1);
          TTA[index]:=TTaskThread.Create(ct1,sleeptime);
          result:=true;
      end else result:=false;
end;

procedure TTasksManagerThread.RepaintTasks;
var i:integer;
begin
     frmMain.SGTasks.Repaint;
     for I := 0 to TasksCount-1 do TasksThreads[i].task.SetNotChanged;
     if frmMain.TSEquipment.Visible then frmMain.SGEquipment.Repaint;
end;

procedure TTasksManagerThread.startAllTasks;
var
  i: Integer;
begin
    for i := 0 to self.TasksCount-1 do begin
        TasksThreads[i].Start;
        sleep(100);
    end;
end;

procedure TTasksManagerThread.StartTask(index: integer);
begin
     if assigned(TasksThreads[index].task) then begin
        TasksThreads[index].task.NextRun:=Now();
     end;
end;

procedure TTasksManagerThread.stopAllTasks;
var
  i: Integer;
begin
    for i:= 0 to self.TasksCount-1 do begin
        TasksThreads[i].Terminate;
    end;
    for I := 0 to self.TasksCount-1 do begin
       WaitForSingleObject(TasksThreads[i].Handle,5000);
    end;
end;

procedure TTasksManagerThread.StopTask(index: integer);
begin
     if Assigned(TasksThreads[index]) then begin
        TasksThreads[index].task.WriteLog('��������� ������ ��������������� ���������� �������');
        tasksThreads[index].task.Abort;
     end;
end;

{ TTaskThread }

constructor TTaskThread.Create(classTask: CTask;sleeptimesec:integer);
begin
     inherited Create(true);
     FreeOnTerminate:=false;
     CoInitialize(nil);
     task:=classTask.Create(self,sleeptimesec);
     sleep(100);
     //self.Execute;
end;

destructor TTaskThread.Destroy;
begin
     if Assigned(self.task) then FreeAndNil(self.task);
     CoUninitialize;
end;

procedure TTaskThread.Execute;
var
  dttm: TDateTime;
  st1: string;
begin
  inherited;
  repeat
    dttm:=Now;
    try
      if Assigned(task) and (task.NextRun<dttm) then task.Execute;
    except
      try
        task.WriteLog('������ ���������� ������� '+task.DisplayName);
        task.Status:=tst_fail;
      except
        sleep(10000);
      end;
    end;
    //synchronize(OutputLog);
    sleep(100);
  until Terminated;
  task.Status:=tst_abort;
end;

procedure TTaskThread.OutputLog;
var i:integer;
begin
     frmMain.MMessages.Lines.Add('');
     for I := 0 to task.LogList.Count - 1 do begin
         frmMain.MMessages.Lines.Add(task.LogList[i]);
     end;
end;

procedure TTaskThread.Terminate;
var
  i: Integer;
begin
     if self.task.Status=tst_running then begin
        Self.task.Abort;
        i:=0;
        while (i<20) and (self.task.Status=tst_running) do begin

           sleep(1000);
           inc(i);
        end;
        sleep(1000);
     end;
     inherited Terminate;
end;

{ TTaskManageGPSFile }
{
constructor TTaskManageGPSFile.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
     inherited Create(owner,sleeptimesec,runnow);
     Name:='ManageGPSFile';
     DisplayName:='����������� ����������� ����� GPS';
     LogFileName:=ExtractFilePath(Application.ExeName)+'Tasks.log';
end;

procedure TTaskManageGPSFile.ExecuteTask;
var shiftName:string;
begin

end;
 }
{ TTaskGenerateImagePitgraph }

procedure TTaskGenerateImagePitgraph.CalculateNextRun;
var dttm:TDateTime;
    hour,min,sec,MSec:word;
    dttm1:TDateTime;
    difftime:real;
begin
  // ��� ��� dump_ddb ����������� ������ ��� � 24 ������,
  // �� ������ ����� ��������� � 25 ����� ������� ����
  dttm:=Now;
  DecodeTime(dttm,hour,min,sec,MSec);
  if min<25 then difftime:=0 else difftime:=1/24;
  NextRun:=trunc(dttm)+EncodeTime(hour,25,0,0)+difftime;
end;

function TTaskGenerateImagePitgraph.ConvertToCanvas( Point : TPoint): TPoint;
begin
      result.x :=round((Point.X-FPGStartX)/FScaleImageToMeters);
      result.y :=imagePitgraph.Height - round((point.Y-FPGStartY)/FScaleImageToMeters);
end;

constructor TTaskGenerateImagePitgraph.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
var koefDiag:real;
    destdir:string;
begin
     inherited Create(owner,sleeptimesec,runnow);
     Name:='DrawPitgraph';
     DisplayName:='��������� ����� �������';
     SourcePitloc:='\\[ip]\lgk\dbdat\pitdat\pitdat_pitloc.dat';
     SourceTravel:='\\[ip]\lgk\dbdat\pitdat\pitdat_travel.dat';
     SourceExcav:='\\[ip]\lgk\dbdat\pitdat\pitdat_excav.dat';
     LogFileName:=ExtractFilePath(Application.ExeName)+ Name+'Log.txt';
     FpitlocTemp:=ExtractFilePath(Application.ExeName)+ 'pitlocTemp.txt';
     FRoadsTemp:=ExtractFilePath(Application.ExeName)+ 'roadsTemp.txt';
     FsourcePitlocTemp:=ExtractFileDir(Application.ExeName)+'\sourcePitlocTemp.txt';
     FsourceTravelTemp:=ExtractFileDir(Application.ExeName)+'\sourceTravelTemp.txt';
     destdir:='M:\';
     if DirectoryExists(destdir) then begin
        DestinationFileName:=destdir+'pitgraph.png';
        FDestPitlocFileName:=destdir+'pitloc.txt';
        FDestRoadsFileName:=destdir+'roads.txt';
     end else begin
        DestinationFileName:=ExtractFilePath(Application.ExeName)+ 'pitgraph.png';
        FDestPitlocFileName:=ExtractFilePath(Application.ExeName)+ 'pitloc.txt';
        FDestRoadsFileName:=ExtractFilePath(Application.ExeName)+ 'roads.txt';
     end;
     FPGStartX:=12200;
     FPGEndX:=16300;
     FPGStartY:=2100;
     FPGEndY:=5800;
     FillColor:=clWhite;
     DrawColor:=clBlack;
     FImageWidth:=4096;
     koefDiag:=(FPGEndX-FPGStartX)/(FPGEndY-FPGStartY);
     FImageHeight:=Round(FImageWidth/koefDiag);
     FScaleImageToMeters:=(FPGEndX-FPGStartX)/FImageWidth;
     FGenerateImage:=true;
     FGenerateTextData:=true;
     DrawControlPoints:=true;
end;

procedure TTaskGenerateImagePitgraph.paintExcavs;
var
  SourceExcavTemp: string;
  fExcavs: TextFile;
  currentnum: Integer;
  linefl:string;
  i:integer;
  num:integer;
  exinfo:TExcavInfo;
  valueindex: Integer;
begin
     WriteLog('��������� �������������� ������������');
     if not FileExists(SourceExcav) then begin
        WriteLog('�� ������ ���� '+SourceExcav+'. ��������� �������������� ������������ ����������');
        exit;
     end;
     SourceExcavTemp:=ExtractFilePath(Application.ExeName)+ExtractFileName(SourceExcav);
     if not CopyFile(PChar(SourceExcav),PChar(SourceExcavTemp),false) then begin
       WriteLog('������ ��� ����������� ����� '+SourceExcav);
       exit;
     end;
     try
        AssignFile(fExcavs,SourceExcavTemp);
        Reset(fExcavs);
        WriteLog('����������� ���� �������������� ������������ � ����� � ����������');
     except
        WriteLog('�� ������� ����� ���� '+SourceExcavTemp);
        exit;
     end;
     // �������������� ���������� ������� ����
     try
         currentnum:=0;
         exinfo.name:='';
          exinfo.x:=0;
          exinfo.y:=0;
          exinfo.lastgpstime:=0;
         while (not Eof(fExcavs)) and (not aborted) do begin
            Readln(fExcavs,linefl);
            i:=PosEX(']',linefl,7);
            // ����������� �������� ������ �����
            if i=0 then Continue;
            num:=strtoint(copy(linefl,7,i-7));
            if num<>currentnum then begin
               // ������� ���������� �� �����������
               if (exinfo.name<>'') and (exinfo.x>0) and (exinfo.y>0) and (exinfo.name<>'EX500') then DrawExcav(exinfo);
               exinfo.name:='';
                exinfo.x:=0;
                exinfo.y:=0;
                exinfo.lastgpstime:=0;
               currentnum:=num;
            end;
               // ��������� ������ �� �����������
               // id
               if pos(#9+'id'+#9,linefl)<>0 then begin
                   valueindex:=LastPos(#9,linefl);
                   exinfo.name:=copy(linefl,valueindex+1,Length(linefl)-valueindex+1);
                   Continue;
               end;
               // x
               if pos(#9+'xloc'+#9,linefl)<>0 then begin
                   valueindex:=LastPos(#9,linefl);
                   try
                      exinfo.x:=strtoint(copy(linefl,valueindex+1,Length(linefl)-valueindex+1));
                   except
                      WriteLog('������ �������������� xloc � ����� ����� ��� ����������� '+exinfo.name);
                   end;
                   Continue;
               end;
               if pos(#9+'yloc'+#9,linefl)<>0 then begin
                   valueindex:=LastPos(#9,linefl);
                   try
                      exinfo.y:=strtoint(copy(linefl,valueindex+1,Length(linefl)-valueindex+1));
                   except
                      WriteLog('������ �������������� yloc � ����� ����� ��� ����������� '+exinfo.name);
                   end;
                   Continue;
               end;
               if pos(#9+'lastgpsupdate'+#9,linefl)<>0 then begin
                   valueindex:=LastPos(#9,linefl);
                   try
                      exinfo.lastgpstime:=strtoint(copy(linefl,valueindex+1,Length(linefl)-valueindex+1));
                   except
                      WriteLog('������ �������������� lastgpsupdate � ����� ����� ��� ����������� '+exinfo.name);
                   end;
                   Continue;
               end;
         end;
         if num>0 then begin
               // ������� ���������� �� �����������
               if (exinfo.name<>'') and (exinfo.x>0) and (exinfo.y>0) and (exinfo.name<>'EX500') then DrawExcav(exinfo);
               exinfo.name:='';
                exinfo.x:=0;
                exinfo.y:=0;
                exinfo.lastgpstime:=0;
         end;
         if aborted then begin
            WriteLog('���������� �������������� ���������� ������');
            exit;
         end;
         WriteLog('��������� �������� �������������� ������������');
     finally
        CloseFile(fExcavs);
        try
          DeleteFile(SourceExcavTemp);
          WriteLog('������� ��������� ���� � ��������������� ������������');
        except
          WriteLog('������ �������� ���������� �����'+SourceExcavTemp);
        end;
     end;
end;

procedure TTaskGenerateImagePitgraph.DrawPitloc(name: string; xm, ym: integer);
var picx, picy:integer;
    str1:string;
    isContolPoint:boolean;
    isZa:boolean;
begin
     picx:=round((xm-FPGStartX)/FScaleImageToMeters);
     picy:=imagePitgraph.Height - round((ym-FPGStartY)/FScaleImageToMeters);
     try
       self.imagePitgraph.Canvas.Lock;
       self.imagePitgraph.Canvas.Pen.Color:=DrawColor;
       self.imagePitgraph.Canvas.Brush.Style:=bsSolid;
       self.imagePitgraph.Canvas.Pen.Style:=psSolid;
       self.imagePitgraph.Canvas.Ellipse(picx-2,picy-2,picx+2,picy+2);
       //sleep(20);
       if ((name[1]='D') or (name[1]='M')) then isContolPoint:=true else isContolPoint:=false;
       if (name[1]='Z') then isZa:=true else isZa:=false;

       // ������� �������� ������� ���� �����
       if (not isContolPoint or DrawControlPoints) and (not isZa or not Self.ShowExcavs) then begin
         self.imagePitgraph.Canvas.Font.Size:=TextSize;
         self.imagePitgraph.Canvas.Font.Color:=DrawColor;
         self.imagePitgraph.Canvas.Brush.Style:=bsClear;
         self.imagePitgraph.Canvas.TextOut(picx+3,picy+3,name);
         //sleep(20);
       end;
       //self.imagePitgraph.SaveToFile(DestinationFileName+'.bmp');
       // ���� �������� �����: �������� � ��������� ����, �� ���������� � ���� � ��������� ����
       if FGenerateTextData then begin
          SaveToFile(FpitlocTemp,name+':'+IntToStr(xm)+':'+IntToStr(ym));
       end;
     finally
       self.imagePitgraph.Canvas.Unlock;
     end;
end;

procedure TTaskGenerateImagePitgraph.DrawRoad(startid, endid: string; startx, starty, endx,
  endy: integer; roadpoints: TLocPoints; closed:boolean=false);
var isline:boolean;
  i1: Integer;
  pnts: array of TPoint;
  point1, PointConverted:TPoint;
  roadpointsstr:string;
begin
     try
         self.imagePitgraph.Canvas.Lock;
         roadpointsstr:='';
         if (roadpoints[0].x=1) then isline:=false else isline:=true;
         self.imagePitgraph.Canvas.Pen.Color:=DrawColor;
         if closed then begin
            self.imagePitgraph.Canvas.Pen.Style:=psDot;
            self.imagePitgraph.Canvas.Pen.Color:=clRed;
         end
         else begin
            self.imagePitgraph.Canvas.Pen.Style:=psSolid;
         end;
         if isline then begin
            point1.X:=startx;
            point1.Y:=starty;
            PointConverted:=ConvertToCanvas(point1);
            self.imagePitgraph.Canvas.MoveTo(PointConverted.X,PointConverted.Y);
            point1.X:=endx;
            point1.Y:=endy;
            PointConverted:=ConvertToCanvas(point1);
            self.imagePitgraph.Canvas.LineTo(PointConverted.X,PointConverted.Y);
            //sleep(20);
         end else begin
            // ������ ������
            // ������ �������� �� ������ �����. ������ �� ��������� � �������
            point1.X:=startx;
            point1.Y:=starty;
            pointConverted:=ConvertToCanvas(point1);
            SetLength(pnts,1);
            pnts[high(pnts)]:=PointConverted;
            i1:=1;
            while (roadpoints[i1].x <>0 ) and (roadpoints[i1].y <>0 ) do begin
                  point1:=roadpoints[i1];
                  pointConverted:=ConvertToCanvas(point1);
                  SetLength(pnts,Length(pnts)+1);
                  pnts[high(pnts)]:=PointConverted;
                  inc(i1);
                  roadpointsstr:=roadpointsstr+':'+inttostr(point1.X)+':'+inttostr(point1.Y);
            end;
            point1.X:=endx;
            point1.y:=endy;
            PointConverted:=ConvertToCanvas(point1);
            SetLength(pnts,Length(pnts)+1);
            pnts[high(pnts)]:=PointConverted;
            self.imagePitgraph.Canvas.PolyBezier(pnts);
            //sleep(20);
            {if not PolyBezier(self.imagePitgraph.Canvas.Handle,pnts,Length(pnts)) then begin
               Application.MessageBox('������ ��������� ������ �����','������');
               exit;
            end;}
         end;
         if FGenerateTextData then begin
            SaveToFile(FRoadsTemp,startid+':'+endid+':'+inttostr(startx)+':'+inttostr(starty)+':'+inttostr(endx)+':'+inttostr(endy)+roadpointsstr);
         end;
         self.imagePitgraph.Canvas.Pen.Style:=psSolid;
         self.imagePitgraph.Canvas.Pen.Color:=DrawColor;
     finally
         self.imagePitgraph.Canvas.Unlock;
     end;
end;

// �������� �����������, ���������� ������� ���� �������� �� ����� ������ �����.
// ���� ������� ��������� ������ �����, �� ������������ �������� ������� ������, ���� ������� ������ �����, �� ������� ������
procedure TTaskGenerateImagePitgraph.DrawExcav(exinfo:TExcavinfo);
var picx, picy:integer;
    str1:string;
    isContolPoint:boolean;
  tmNow: longint;
begin
     if exinfo.lastgpstime<1 then exit;
     picx:=round((exinfo.x-FPGStartX)/FScaleImageToMeters);
     picy:=self.imagePitgraph.Height - round((exinfo.y-FPGStartY)/FScaleImageToMeters);
     tmNow:=DateTimeToTimeStamp1970(Now());
     if (tmNow-exinfo.lastgpstime)<(30*24*3600) then begin
         if (tmNow-exinfo.lastgpstime)>(1*24*3600) then self.imagePitgraph.Canvas.Pen.Color:=clRed else self.imagePitgraph.Canvas.Pen.Color:=clGreen;
         self.imagePitgraph.Canvas.Lock;
         try
             self.imagePitgraph.Canvas.Ellipse(picx-3,picy-3,picx+3,picy+3);
             //sleep(20);
             // ������� �������� ������� ���� �����
             self.imagePitgraph.Canvas.Font.Size:=TextSize;
             self.imagePitgraph.Canvas.Font.Color:=self.imagePitgraph.Canvas.Pen.Color;
             self.imagePitgraph.Canvas.Brush.Style:=bsClear;
             self.imagePitgraph.Canvas.TextOut(picx+3,picy+3,exinfo.name);
             //sleep(20);
             self.imagePitgraph.Canvas.Brush.Style:=bsSolid;
             self.imagePitgraph.Canvas.Font.Color:=DrawColor;
             self.imagePitgraph.Canvas.Pen.Color:=DrawColor;
         finally
             self.imagePitgraph.Canvas.Unlock;
         end;
     end;
end;

procedure TTaskGenerateImagePitgraph.ExecuteTask;
var fpitloc, ftravel : TextFile;
    linefl:string;
    i:integer;
    num, currentnum:integer;
    currentid, a:string;
    currentX, currentY :integer;
    valueIndex:integer;
    tempPitloc: TStrings;
    jpgimg:TJPEGImage;
    gifimg:TGifImage;
    pngimg:TPNGImage;
    locstart_id, locend_id:string;
    pitlocindex:integer;
    index1,index2:integer;
    startX, startY, endX, endY : integer;
    roadpoints: TLocPoints;
    posgraph:integer;
    coordname:string;
    numcoord:shortint;
    valuecoord:integer;
    errorStr:string;
    strlog:string;
    isCopiedpitloc:boolean;
    isCopiedTravel:boolean;
    pitlocTemp, roadsTemp:string;
    closed:boolean;
  countlines: Integer;
  countdraw: Integer;
begin
     errorstr:='';
     WriteLog('������ '+self.Name+' ��������');
     if not FileExists(SourcePitloc) then begin
        errorstr:='�� ���������� ���� �������� �������'+ SourcePitloc;
     end;
     if not FileExists(SourceTravel) then begin
        errorstr:='�� ���������� ���� ����� �������'+ SourceTravel;
     end;
     if errorstr<>'' then begin
        WriteLog(errorStr);
        WriteLog('������ ��������� ');
        WriteLog('------------------'+#13#10);
        Status:=tst_fail;
        exit;
     end;
     WriteLog('�������� ����� �������');
     // ������ ������������ �������� ��� ��������� ������ �� ���������� �����
     // ��������� �������� ������ � ������������ �� ��������
     try
        isCopiedPitloc:=CopyFile(PChar(sourcePitloc),PChar(FsourcePitlocTemp),false);
        isCopiedTravel:=CopyFile(PChar(sourceTravel),PChar(FsourceTravelTemp),false);
     except
        WriteLog('������ ����������� ����� �������');
        Status:=tst_fail;
        exit;
     end;

     if isCopiedPitloc then WriteLog('�������� ���� �������� ������� ����������') else WriteLog('������ ����������� ��������� ����� ��������');
     if isCopiedTravel then WriteLog('�������� ���� ����� ������� ����������') else WriteLog('������ ����������� ��������� ����� �����');
     if not (isCopiedPitloc and isCopiedTravel) then begin
        WriteLog('������ ��������� ');
        WriteLog('------------------'+#13#10);
        Status:=tst_fail;
        exit;
     end;
     try
       self.imagePitgraph:=TBitmap.Create;
       //sleep(100);
       self.imagePitgraph.Height:=FImageHeight;
       self.imagePitgraph.Width:=FImageWidth;
       self.imagePitgraph.TransparentMode:=tmAuto;
       self.imagePitgraph.TransparentColor:=clWhite;
       try
           self.imagePitgraph.Canvas.Lock;
           self.imagePitgraph.Canvas.Pen.Color:=FillColor;
           self.imagePitgraph.Canvas.Brush.Color:=FillColor;
           self.imagePitgraph.Canvas.Brush.Style:=bsSolid;
           self.imagePitgraph.Canvas.Rectangle(0,0,self.imagePitgraph.Width,self.imagePitgraph.Height);
       finally
           self.imagePitgraph.Canvas.Unlock;
       end;
     except
       WriteLog('������ ��� �������� ������� � ������');
       WriteLog('������ ��������� ');
       WriteLog('------------------'+#13#10);
       Status:=tst_fail;
       FreeAndNil(self.imagePitgraph);
       exit;
     end;
     try
        AssignFile(fpitloc,FsourcePitlocTemp);
        Reset(fPitloc);
     except
        WriteLog('�� ������� ������� ���� '+FsourcePitlocTemp);
        WriteLog('������ ��������� ');
        WriteLog('------------------'+#13#10);
        FreeAndNil(self.imagePitgraph);
        Status:=tst_fail;
        exit;
     end;
     currentnum:=0;
     tempPitloc:=TStringList.Create;
     tempPitloc.Clear;
     try
        if FileExists(FpitlocTemp) then DeleteFile(FpitlocTemp);
        if FileExists(FRoadsTemp) then DeleteFile(FRoadsTemp);
     except
        WriteLog('�� ������� ������� ����� '+FDestPitlocFileName+', '+FDestRoadsFileName);
        //WriteLog('������ ��������� ');
        WriteLog('------------------'+#13#10);
        Status:=tst_fail;
        exit;
     end;
     // ������ ������� ��������
     if FGenerateTextData then WriteLog('����� �������� ������ � ��������� ���� ��������')
        else WriteLog('����� �������� ������ � ��������� ���� ���������');
     WriteLog('������ �������� ������� ��������');
     countlines:=0;
     countdraw:=0;
     while not Eof(fPitloc) and (not aborted) do begin
        Readln(fPitloc,linefl);
        inc(countlines);
        i:=PosEX(']',linefl,8);
        // ����������� �������� ������ �����
        if i=0 then Continue;
        num:=strtoint(copy(linefl,8,i-8));
        if num<>currentnum then begin
           // �� ����������� ������� ���������� � ������� ������� �� �������
           if (currentid<>'') and ((currentx>0) or (currenty>0)) then begin
              // ����������� ����� �� KOI8R
              a:=KOI8R2ANSI(currentid);
              currentid:=a;
              if (currentid<>'PIT') then begin
                  tempPitloc.Add(currentid+':'+inttostr(currentx)+':'+inttostr(currenty));
                  if (pos('PD',currentid)=0) then begin
                    DrawPitloc(currentid,currentX,currentY);
                    inc(countdraw);
                  end;
              end;
           end;
           currentnum:=num;
           currentid:='';
           currentX:=0;
           currentY:=0;
        end;
        // ���� ���� ���������� id, �� ����������� �������� �������
        if pos(#9+'id'+#9,linefl)<>0 then begin
           valueindex:=LastPos(#9,linefl);
           currentid:=copy(linefl,valueindex+1,Length(linefl)-valueindex+1);
        end;
        // ���� ���� ���������� xloc, �� ����������� ���������� x
        if pos(#9+'xloc'+#9,linefl)<>0 then begin
           valueindex:=LastPos(#9,linefl);
           currentX:=strtoint(copy(linefl,valueindex+1,Length(linefl)-valueindex+1));
        end;
        // ���� ���� ���������� yloc, �� ����������� ���������� y
        if pos(#9+'yloc'+#9,linefl)<>0 then begin
           valueindex:=LastPos(#9,linefl);
           currentY:=strtoint(copy(linefl,valueindex+1,Length(linefl)-valueindex+1));
        end;
     end;
     if (currentnum>0) and (not aborted) then begin
       // �� ����������� ������� ���������� � ��������� ������� �� �������
           if (currentid<>'') and ((currentx>0) or (currenty>0)) then begin
              // ����������� ����� �� KOI8R
              a:=KOI8R2ANSI(currentid);
              currentid:=a;
              if (currentid<>'PIT') then begin
                  tempPitloc.Add(currentid+':'+inttostr(currentx)+':'+inttostr(currenty));
                  if (pos('PD',currentid)=0) then begin
                      DrawPitloc(currentid,currentX,currentY);
                      inc(countdraw);
                  end;
              end;
           end;
     end;
     CloseFile(fPitloc);
     if aborted then begin
       WriteLog('���������� �������������� ���������� ������');
       exit;
     end;
     WriteLog('��������� '+IntToStr(countlines)+' ����� ����� '+FSourcePitlocTemp+'. ���������� '+IntToStr(countdraw)+' ��������');
     // ������ ������� �����
     WriteLog('������ �������� ������� �����');
     AssignFile(ftravel,FSourceTravelTemp);
     Reset(ftravel);
     currentnum:=0;
     locstart_id:='';
     startx:=0;
     starty:=0;
     locend_id:='';
     endx:=0;
     endy:=0;
     for i := 0 to 9 do begin
         roadpoints[i].x:=0;
         roadpoints[i].y:=0;
     end;
     countlines:=0;
     countdraw:=0;
     while (not Eof(ftravel)) and (not aborted) do begin
        Readln(ftravel,linefl);
        inc(countlines);
        i:=PosEX(']',linefl,8);
        // ����������� �������� ������ �����
        if i=0 then Continue;
        num:=strtoint(copy(linefl,8,i-8));
        if num<>currentnum then begin
           // �������� ���������� ������� ������
           DrawRoad(Locstart_id,locend_id,startx,starty,endx,endy,roadpoints, closed);
           inc(countdraw);
           // �������� �������� ������� ������
           currentnum:=num;
           locstart_id:='';
           startx:=0;
           starty:=0;
           locend_id:='';
           endx:=0;
           endy:=0;
           closed:=false;
           for i := 0 to 9 do begin
               roadpoints[i].x:=0;
               roadpoints[i].y:=0;
           end;
        end;
        // ���� ���� ���������� locstart_id, �� ����������� �������� �������
        if pos(#9+'locstart_id'+#9,linefl)<>0 then begin
           valueindex:=LastPos(#9,linefl);
           Locstart_id:=KOI8R2ANSI(copy(linefl,valueindex+1,Length(linefl)-valueindex+1));
           // ���� ����� � ���c�� �������� ������ ���, �� ���������� �������� � � �
           pitlocIndex:=FindLineSubstringInList(locstart_id,tempPitloc);
           if pitlocindex>-1 then begin
              index1:=pos(':',tempPitloc[pitlocindex]);
              index2:=LastPos(':',tempPitloc[pitlocindex]);
              startx:=strtoint(copy(tempPitloc[pitlocindex],index1+1,index2-index1-1));
              starty:=strtoint(copy(tempPitloc[pitlocindex],index2+1,Length(tempPitloc[pitlocindex])-index2));
           end;
        end;
        // ���� ���� ���������� locend_id, �� ����������� �������� �������
        if pos(#9+'locend_id'+#9,linefl)<>0 then begin
           valueindex:=LastPos(#9,linefl);
           Locend_id:=KOI8R2ANSI(copy(linefl,valueindex+1,Length(linefl)-valueindex+1));
           // ���� ����� � ���c�� �������� ������ ���, �� ���������� �������� � � �
           pitlocIndex:=FindLineSubstringInList(locend_id,tempPitloc);
           if pitlocindex>-1 then begin
              index1:=pos(':',tempPitloc[pitlocindex]);
              index2:=LastPos(':',tempPitloc[pitlocindex]);
              endx:=strtoint(copy(tempPitloc[pitlocindex],index1+1,index2-index1-1));
              endy:=strtoint(copy(tempPitloc[pitlocindex],index2+1,Length(tempPitloc[pitlocindex])-index2));
           end;
        end;
        // ���� ����� ���������� �� ������� �����
        if pos('graph_',linefl)<>0 then begin
           posgraph:=pos('graph_',linefl);
           coordname:=copy(linefl,posgraph-1,1);
           numcoord:=strtoint(copy(linefl,posgraph+6,1));
           valueindex:=Lastpos(#9,linefl);
           valuecoord:=strtoint(copy(linefl,valueindex+1,Length(linefl)-valueindex+1));
           if valuecoord<2147483647 then begin
              if (coordname='x') and ((numcoord>-1)and (numcoord<10)) then roadpoints[numcoord].x:=valuecoord;
              if (coordname='y') and ((numcoord>-1)and (numcoord<10)) then roadpoints[numcoord].y:=valuecoord;
           end;
        end;
        // ���� ���� ���������� closed, �� ��� ������ ����, ������� �� ������
        if pos(#9+'closed'+#9,linefl)<>0 then begin
           valueindex:=LastPos(#9,linefl);
           try
              if strtoint(copy(linefl,valueindex+1,1))=1 then closed:=true else closed:=false;
           except
              closed:=false;
           end;
        end;
     end;
     FreeAndNil(tempPitloc);
     // �������� ���������� ��������� ������
     if currentNum>0 then DrawRoad(Locstart_id,locend_id,startx,starty,endx,endy,roadpoints,closed);
     CloseFile(ftravel);
     if aborted then begin
       WriteLog('���������� �������������� ���������� ������');
       exit;
     end;
     WriteLog('��������� '+IntToStr(countlines)+' ����� ����� '+FSourceTravelTemp+'. ���������� '+IntToStr(countdraw)+' �����');
     if self.ShowExcavs then begin
        // [2021-09-22] ������ ������� ������������
        paintExcavs;
     end;
     // ������� ��������� �����
     {DeleteFile(FsourcePitlocTemp);
     DeleteFile(FsourceTravelTemp);
     WriteLog('��������� ����� �������');}
     if aborted then begin
       WriteLog('���������� �������������� ���������� ������');
       exit;
     end;
     // ���� ����� ���������, �������� ���� � ����� ��������� �����
     if DrawLabel then begin
       self.imagePitgraph.Canvas.Lock;
       try
           self.imagePitgraph.Canvas.Font.Size:=TextSize;
           self.imagePitgraph.Canvas.Font.Color:=DrawColor;
           self.imagePitgraph.Canvas.Brush.Style:=bsClear;
           self.imagePitgraph.Canvas.TextOut(10,10,FormatDateTime('dd.mm.yy hh:nn',Now));
       finally
           self.imagePitgraph.Canvas.Unlock;
       end;
     end;

     WriteLog('�������� ��������� ����� '+DestinationFileName);
     try
        pngimg:=TPngImage.Create;
        pngimg.Assign(self.imagePitgraph);
        pngImg.SaveToFile(DestinationFileName);
        //sleep(500);
        FreeAndNil(pngImg);
     except
        WriteLog('������ ��� ���������� �����');
     end;
     FreeAndNil(self.imagePitgraph);
     // ���� �������� ��������� ��������� ������ �����, �� ���������� ����� � ���������� �������
     // � ����� ����������
     try
     if aborted then begin
        WriteLog('���������� �������������� ���������� ������');
       exit;
     end;
     if FGenerateTextData then begin
        WriteLog('����������� ����� � ������� �� �������� � ����� ����������');
        if FileExists(FpitlocTemp) then CopyFile(PChar(FPitlocTemp),PChar(FDestPitlocFileName),false);
        WriteLog('����������� ����� � ������� � ������� � ����� ����������');
        if FileExists(FRoadsTemp) then CopyFile(PChar(FRoadsTemp),PChar(FDestRoadsFileName),false);
        if FileExists(FpitlocTemp) then DeleteFile(FpitlocTemp);
        if FileExists(FroadsTemp) then DeleteFile(FRoadsTemp);
        WriteLog('��������� ����� ��������� ������ � ������� �������');
     end;
     except
        WriteLog('�� ������� ����������� ����� � ������� � �������');
        WriteLog('������ ����������� ');
        WriteLog('------------------'+#13#10);
        Status:=tst_fail;
        exit;
     end;
     WriteLog('��������� ���������� ������');
     WriteLog('------------------'+#13#10);
end;

{ TTaskGetGPSInformation }

procedure TTaskGetGPSInformation.CalculateNextRun;
var dttm:TDateTime;
    hour,min,sec,MSec:word;
    difftime:TTime;
begin
  // ��� ��� ����������� GPS ����������� ������ 10 �����, ������� � 3 �����,
  // �� ������ ����� ��������� ������ 10 �����, ������� � 4 ������
  dttm:=Now;
  DecodeTime(dttm,hour,min,sec,MSec);
  if (min mod 10)<4 then difftime:=0 else difftime:=1/24/6;
  min:=(min div 10)*10+4;
  NextRun:=trunc(dttm)+EncodeTime(hour,min,0,0)+difftime;
end;

constructor TTaskGetGPSInformation.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
     inherited Create(owner,sleeptimesec,runnow);
     Name:='GetGPSInformation';
     DisplayName:='��������� ��������� GPS � �������';
     SourceFolder:='\\[ip]\lgk\';
     LogFileName:=ExtractFilePath(Application.ExeName)+'\'+ Name + '.txt';
     ShiftCount:=1;
     // ��� �������� TADO �����������
     connStat:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
     qryStat:=TMyADOQuery.Create(nil,connStat);
     secondsToFindStats:=20;
end;

destructor TTaskGetGPSInformation.Destroy;
begin
  FreeAndNil(qryStat);
  FreeAndNil(connStat);
  // [2022-04-22] CoUninitialize ��������� � ����������� ������
  //CoUninitialize;
  inherited;
end;

procedure TTaskGetGPSInformation.ExecuteTask;
var startshift:string;
    dttm:TDateTime;
begin
     CloseConnections;
     dttm:=Now;
     //WriteLog('������ '+self.Name+' ��������');
     startshift:=DateTimeToShiftName(Now-(ShiftCount-1)/2);
     // �������, ������� ��������� ������ ���������� �� ����������� ������ ����� �����
     if (shiftcount=1) and (TimeToShiftSec(Timeof(dttm))<1800) then FPercentStepByShift:=50
        else FPercentStepByShift:=round(100/shiftcount);
     getGPSInfo(startshift,shiftcount);
     // ���� �������������� GPS ������ �� ������� �����,
     // �� ������������ ��� � ����������, ���� ������ �����
     if shiftcount=1 then begin
        if TimeToShiftSec(Timeof(dttm))<1800 then getGPSbyShift(DateTimeToShiftName(Now-0.5));
     end;
     //WriteLog('������ '+self.Name+' ���������');
     //WriteLog('------------------------------');
end;

procedure TTaskGetGPSInformation.getGPSbyShift(shift: string);
var gpsfileName,netFolderName, appPath :string;
    CountLinesFile:integer;
    statcount:integer;
    statFile:TIniFile;
    gpsFile : TextFile;
    j:integer;
    lineoffile:string;
    posstr:integer;
    secondsTime:integer;
    gpsDateTime:TDateTime;
    gpsDate:TDate;
    gpsTime:TTime;
    eqmt:string;
    gpsx,gpsy:string;
    findstat:boolean;
    statid:integer;
    stattime:TTime;
    minDiffTime, currentDiffTime:TTime;
    LastGpsDateTime:TDateTime;
    CurrentPercent:real;
    stepPercentByRow:real;
    modem_id:integer;
    cntprocessed:integer;
  mysqlid: Integer;
begin
    WriteLog('��������� ������ GPS �� ����� '+shift);
    netFolderName:=self.SourceFolder;
    gpsFileName:='gps'+shift+'.dat';
    appPath:=ExtractFileDir(Application.ExeName)+'\';
    statFile:=TIniFile.Create(apppath+'stat.ini');
    if FileExists(netFolderName+gpsfileName) then begin
       try
          CopyFile(PChar(netFolderName+gpsfileName),PChar(apppath+gpsfileName),true);
       except
          WriteLog('������ ����������� ����� '+PChar(netFolderName+gpsfileName)+' � '+PChar(apppath+gpsfileName));
          Status:=tst_fail;
          exit;
       end;
       try
           countLinesFile:=LinesCount(apppath+gpsfileName);
           statcount:=StrToInt(statfile.ReadString('stat',shift,'0'));
           // ���� ���������� ����� � ����� ��������� ���������� ����� � ����������,
           // �� ��������� �������� ��� �����, ������� ����� �� ���� ���������
           if countLinesFile>statcount then begin
              AssignFile(gpsfile,apppath+gpsfileName);
              reset(gpsfile);
              try
                  j:=1;
                  // ������ ���� �� ������������ ������
                  while (j<statcount+1) and not aborted do begin
                      readln(gpsfile, lineoffile);
                      inc(j);
                  end;
                   CurrentPercent:=PercentCompleted;
                   // ���� ������ ���������, �� �������
                   if (CountLinesFile-statcount-1) > 0 then stepPercentByRow:=FPercentStepByShift/(CountLinesFile-statcount-1) else stepPercentByRow:=0;
                   if ((CountLinesFile-statcount-1)>0) and not aborted then begin
                      for j:=statcount+1 to countLinesFile do begin
                          // ���� ����� �����������, �� �������
                          if aborted then Break;
                          readln(gpsfile,lineoffile);
                          if Length(lineoffile)>6 then begin
                             posstr:=Pos(':',lineoffile);
                             // �������� �������� ���� � �������. ��� ���������� ������, ��������� � 01.01.1970
                             secondstime:=StrToInt(copy(lineoffile,1,posstr-1));
                             gpsdatetime:=StrToDateTime('01.01.1970')+(secondstime/(24*3600));
                             //gpsdatetime:=EncodeDateTime(1970,1,1,0,0,0,0)+(secondstime/(24*3600));
                             gpsdate:=DateOf(gpsdatetime);
                             gpstime:=TimeOf(gpsdatetime);
                             delete(lineoffile,1,posstr);
                             // �������� ������ � ������� �������
                             posstr:=Pos(':',lineoffile);
                             eqmt:=copy(lineoffile,1,posstr-1);
                             delete(lineoffile,1,posstr);
                             // ������ � ���������� x
                             posstr:=Pos(':',lineoffile);
                             gpsx:=copy(lineoffile,1,posstr-1);
                             delete(lineoffile,1,posstr);
                             // ������ � ���������� y
                             posstr:=Pos(':',lineoffile);
                             gpsy:=copy(lineoffile,1,posstr-1);
                             {try
                                 if qryStat.Active then qryStat.Close;
                                 qryStat.SQL.Clear;
                                 qryStat.SQL.Add('select id_modem from modems where name="'+eqmt+'"');
                                 qryStat.Open;
                                 if qryStat.RecordCount<>0 then begin
                                    qryStat.First;
                                    modem_id:=qryStat.FieldByName('id_modem').AsInteger;
                                 end else Continue;
                                 qryStat.Close;
                             except
                                 WriteLog('������ ��������� id_modem ��� ������������ '+eqmt);
                                 break;
                             end;}
                             mysqlid:=TEquipment.GetMySQLIndexByName(eqmt);
                             if mysqlid<1 then Continue;
                             statid:=0;
                             stattime:=0;
                             findstat:=false;
                             if qryStat.Active then qryStat.Close;
                             qryStat.SQL.Clear;
                             qryStat.SQL.Add('select s.id, s.datetime as tm');
                             qryStat.SQL.Add('from statss s');
                             qryStat.SQL.Add('where ');
                             qryStat.SQL.Add('(s.id_equipment='+IntToStr(mysqlid)+')');
                             // ��������� ���������������� ������, � �������� ������� ������ ������ �����
                             // [2021-10-11] �������� � ���������

                             qryStat.SQL.Add('and (s.datetime Between "'+MySQLDateTime(gpsdatetime-1/24/3600*secondsToFindStats)+'" and "'+MySQLDateTime(gpsdatetime+1/24/3600*secondsToFindStats)+'")');
                             //.qryStat.Prepared:=true;
                             try
                                qryStat.Open;
                                if qryStat.RecordCount<>0 then qryStat.Last;
                             except
                                WriteLog('������ ��������� ����� ���������� ��� eqmt:'+eqmt);
                                Status:=tst_fail;
                                break;
                             end;
                             findstat:=false;
                             if qryStat.RecordCount<>0 then begin
                                qryStat.First;
                                // ��������� ����� ������������ �������� � ������
                                minDiffTime:=1/24/60;
                                while not qryStat.Eof do begin
                                      currentDiffTime:=Abs(gpsdatetime-qryStat.FieldByName('tm').AsDateTime);
                                      if currentDiffTime<minDiffTime then begin
                                         minDiffTime:=currentDiffTime;
                                         statid:=qrystat.fieldByName('id').AsInteger;
                                         findstat:=true;
                                      end;
                                      qryStat.Next;
                                end;
                             end;
                             qryStat.Close;
                             try
                                if findstat then begin
                                   qryStat.SQL.Clear;
                                   qrystat.SQL.Text:='update statss set x='+gpsx+', y='+gpsy+' where id='+inttostr(statid);
                                   qrystat.ExecSQL;
                                end;
                             except
                                   WriteLog('������ ������ ��������� � ������� statss id:'+IntToStr(statid));
                             end;
                             try
                               // ���������, ���� ���� � ����� ���������� GPS ������, ��� ��������,
                               // �� �������������� � �� ���� � �����
                               //if qryStat.Active then qryStat.Close;
                               qryStat.Active:=false;
                               qryStat.SQL.Clear;
                               qryStat.SQL.Add('select cast(LastGPSDateTime as DateTime) as LastGPS from equipment where name="'+eqmt+'"');
                               qryStat.Active:=true;
                               LastGpsDateTime:=Now;
                               if qryStat.RecordCount<>0 then begin
                                  qryStat.First;
                                  LastGpsDateTime:=qryStat.FieldByName('LastGPS').AsDateTime;
                               end;
                               qryStat.Close;
                               qryStat.SQL.Clear;
                               if LastGPSDateTime<gpsdatetime then begin
                                  qryStat.SQL.Add('update equipment set LastGPSDateTime="'+FormatDateTime('yyyy-mm-dd hh:nn:ss', gpsdatetime)+'"');
                                  qryStat.SQL.Add('where name="'+eqmt+'"');
                                  qryStat.ExecSQL;
                               end;
                             except

                             end;
                             statfile.WriteString('stat', shift, inttostr(j));
                          end;
                          // ���������� ������� ����������
                          CurrentPercent:=CurrentPercent+stepPercentByRow;
                          if trunc(CurrentPercent)<>PercentCompleted then PercentCompleted:=trunc(CurrentPercent);
                      end;
                   end;
              finally
                   CloseFile(gpsfile);
              end;
           end;
       finally
           // ������� ������������� ����� ����
           DeleteFile(apppath+gpsfileName);
       end;

    end;
    WriteLog('������ �� ����� '+shift+' ��������. ���������� '+inttostr(j-statcount-1)+' �������.');
end;

procedure TTaskGetGPSInformation.getGPSInfo(startshift: string;
  countshifts: integer);
var i:integer;
    sh:string;
    LastShiftdttm:TDateTime;
begin
    LastShiftdttm:=ShiftNameToDateTime(startshift)+(countshifts-1)*0.5;
    for i := 1 to countshifts do begin
        sh:=DateTimeToShiftName(LastShiftdttm-(i-1)*0.5);
        if not aborted then getGPSbyShift(sh) else Status:=tst_abort;
    end;
end;

procedure TTaskGetGPSInformation.CloseConnections;
begin
     try
        connStat.Close;
     except
        WriteLog('������ �������� ���������� �� ��');
     end;
end;

{ TTaskGenerateImagePitgraphASUGTK }

procedure TTaskGenerateImagePitgraphASUGTK.CalculateNextRun;
begin
  inherited;
  // �������� � ������������ ������� ������, ����� ������ ��������� �� ����������� ������
  NextRun:=NextRun+1/24/60;
end;

constructor TTaskGenerateImagePitgraphASUGTK.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
var destdir :string;
    koefDiag:real;
begin
     inherited Create(owner,sleeptimesec,runnow);
     Name:='DrawPitASUGTK';
     DisplayName:='���� ������� ��� ������';
     LogFileName:=ExtractFilePath(Application.ExeName)+ 'DrawPitASUGTKLog.txt';
     FpitlocTemp:=ExtractFilePath(Application.ExeName)+ 'pitlocASUGTKTemp.txt';
     FRoadsTemp:=ExtractFilePath(Application.ExeName)+ 'roadsASUGTKTemp.txt';
     FsourcePitlocTemp:=ExtractFileDir(Application.ExeName)+'\sourcePitlocTemp1.txt';
     FsourceTravelTemp:=ExtractFileDir(Application.ExeName)+'\sourceTravelTemp1.txt';
     destdir:='W:\�����\������� ��� ���\';
     if DirectoryExists(destdir) then begin
        DestinationFileName:=destdir+'Map.png';
        FDestPitlocFileName:=destdir+'pitlocASUGTK.txt';
        FDestRoadsFileName:=destdir+'roadsASUGTK.txt';
     end else begin
        DestinationFileName:=ExtractFilePath(Application.ExeName)+ 'Map.png';
        FDestPitlocFileName:=ExtractFilePath(Application.ExeName)+ 'pitlocASUGTK.txt';
        FDestRoadsFileName:=ExtractFilePath(Application.ExeName)+ 'roadsASUGTK.txt';
     end;
     //FPGStartX:=12200;
     //FPGEndX:=16300;
     //FPGStartY:=2100;
     //FPGEndY:=5800;
     //FillColor:=clWhite;
     //DrawColor:=clBlack;

     FImageWidth:=1280;
     koefDiag:=(FPGEndX-FPGStartX)/(FPGEndY-FPGStartY);
     FImageHeight:=Round(FImageWidth/koefDiag);
     FScaleImageToMeters:=(FPGEndX-FPGStartX)/FImageWidth;
     FGenerateImage:=true;
     // �� ������������ ��������� ������
     FGenerateTextData:=false;
     DrawControlPoints:=false;
     TextSize:=7;
     DrawLabel:=true;
     ShowExcavs:=true;
end;

{ TTaskCalcStatWiFiByEquipment }

procedure TTaskCalcStatWiFiByEquipment.CalculateNextRun;
var dt:TDate;
  sec: Word;
  min: Word;
  hour: Word;
  day: Word;
  month: Word;
  year: Word;
  msec: Word;

begin
  dt:=Now();
  DecodeDateTime(dt+sleeptime/3600/24,year,month,day,hour,min,sec,msec);
  NextRun:=EncodeDateTime(year,month,day,hour,1,0,0);
end;

constructor TTaskCalcStatWiFiByEquipment.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);

begin
     inherited Create(owner,sleeptimesec,runnow);
     Name:='CalcWiFiStatEQ';
     DisplayName:='��������� ���������� WiFi �� ������������';
     // ���������� �������� �� ��������� FDaysToCalc ����
     FDaysToCalc:=70;
     //LogFileName:='';
     // [2022-04-22] CoInitialize ���������� �� �������� ������
     //CoInitialize(nil);
     FConnMysql:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
     FQTemp:=TMyADOQuery.Create(nil,FConnMysql);
     FQTemp2:=TMyADOQuery.Create(nil,FConnMysql);
     FQTemp3:=TMyADOQuery.Create(nil,FConnMysql);
end;

destructor TTaskCalcStatWiFiByEquipment.Destroy;
begin
     if FQTemp.Active then FQTemp.Close;
     FreeAndNil(FQTemp);
     if FQTemp2.Active then FQTemp2.Close;
     FreeAndNil(FQTemp2);
     if FQTemp3.Active then FQTemp3.Close;
     FreeAndNil(FQTemp3);
     //CoUninitialize;
     inherited;
end;

procedure TTaskCalcStatWiFiByEquipment.ExecuteTask;
var mincountRecords:integer;
    counteq:integer;
  dt: TDate;
  curperc:real;
begin
     //CloseConnections;
     WriteLog('������ '+self.Name+' ��������');
     FFirstDate:=Date()-FDaysToCalc;
     FLastDate:=Date();
     if FQTemp.Active then FQTemp.Close;
     FQTemp.SQL.Clear;
     FQTemp.SQL.Add('select count(*) as cnt from log_analize_wifi_by_equip ');
     FQTemp.SQL.Add('where (date>="'+FormatDateTime('yyyy-mm-dd',FFirstDate)+'") and (date<="'+FormatDateTime('yyyy-mm-dd',FLastDate)+'")');
     try
        FQTemp.Open;
     except
        WriteLog('������ ������� � �� MySQL');
        WriteLog('������ '+self.Name+' ���������');
        WriteLog('------------------------------'+#13);
        Status:=tst_fail;
        exit;
     end;
     if FQTemp.FieldByName('cnt').AsInteger=FDaysToCalc then begin
        dt:=FLastDate;
        FPercentStep:=100;
     end else begin
         // ���� ���������� ������� � ��������� ���������� ��������� � ����������� ����
         // ����� ��������� ��� ��� �� �����. ����� ������ ��������� ��������� ����
         // �, ��� �������������, ��������� �� ���� ���� ����������
         if FQTemp.FieldByName('cnt').AsInteger=(FDaysToCalc-1) then dt:=FLastDate
            else dt:=FFirstDate;
         try
          FPercentStep:=100/(FDaysToCalc-FQTemp.FieldByName('cnt').AsInteger);
         except
          FPercentStep:=100;
         end;
     end;
     FQTemp.Close;
     while (dt<=FLastDate) and (not aborted) do begin
           curperc:=CurrentPercent;
           if FQTemp.Active then FQTemp.Close;
           FQTemp.SQL.Clear;
           FQTemp.SQL.Add('select * from log_analize_wifi_by_equip where date="'+FormatDateTime('yyyy-mm-dd',dt)+'"');
           try
              FQTemp.Open;
           except
              WriteLog('������ ������� � �� MySQL');
              WriteLog('������ '+self.Name+' ���������');
              WriteLog('------------------------------'+#13);
              Status:=tst_fail;
              exit;
           end;
           FQTemp.Last;
           if FQTemp.RecordCount=0 then WriteStatistic(dt);
           FQTemp.Close;
           CurrentPercent:=curperc+FPercentStep;
           dt:=dt+1;
     end;
     if aborted then begin
        WriteLog('���������� �������������� ��������� ������');
        exit;
     end;
     WriteLog('������ '+self.Name+' ���������');
     WriteLog('------------------------------'+#13);
end;

procedure TTaskCalcStatWiFiByEquipment.SetDaysToCalc(const Value: integer);
begin
     if Value>0 then FDaysToCalc:=Value;
end;

procedure TTaskCalcStatWiFiByEquipment.CloseConnections;
begin
     try
        FConnMysql.Close;
     except
        WriteLog('������ �������� ����������');
     end;
end;

procedure TTaskCalcStatWiFiByEquipment.WriteStatistic(dt: TDate);
type TQual=record
     count :integer;
     count_success:integer;
     signal_avg:real;
end;
TQualArray = array [0..23] of TQual;
var QualArray:TQualArray;
    i:integer;
    hour:shortint;
  signal: Integer;
  EQId:integer;
  percStep:real;
  EQname:string;
begin
     WriteLog('��������� ���������� �� '+FormatDateTime('dd.mm.yyyy',dt));
     // ������� ��� ���������� �� ����
     if FQTemp2.Active then FQTemp2.Close;
     FQTemp2.SQL.Clear;
     FQTemp2.SQL.Add('delete from wifi_stat_equipment where date="'+FormatDateTime('yyyy-mm-dd',dt)+'"');
     try
        FQTemp2.ExecSQL;
     except
        WriteLog('������ ������� � �� MySQL');
        Status:=tst_fail;
        exit;
     end;
     // �������� ������ ���������� � ������������
     FQTemp2.SQL.Clear;
     FQTemp2.SQL.Add('select id, name from equipment where ((equipment_type=1) or (equipment_type=2)) and (useinMonitoring=1)');
     try
        FQTemp2.Open;
     except
        WriteLog('������ ������� � �� MySQL');
        Status:=tst_fail;
        exit;
     end;
     FQTemp2.Last;
     if (FQTemp2.RecordCount>0) then percStep:=FPercentStep/FQTemp2.RecordCount;
     FQTemp2.First;
     // ��� ������� ��������� � ����������� ��������� � ���������� ���������� �� �����
     while (not FQTemp2.Eof) and (not aborted) do begin
           EQId:=FQTemp2.FieldByName('id').AsInteger;
           EQname:=FQTemp2.FieldByName('name').AsString;
           if FQTemp3.Active then FQTemp3.Close;
           FQTemp3.Clear;
           //FQTemp3.SQL.Add('select s.signal_level, s.time as tm from statss s ');
           //FQTemp3.SQL.Add('where (s.date="'+FormatDateTime('yyyy-mm-dd',dt)+'") and (s.id_equipment='+inttostr(EQId)+') and (s.status=2)');
           FQTemp3.SQL.Add('select s.signal_level, s.datetime as dttm from statss s ');
           FQTemp3.SQL.Add('inner join stats_status ss on (s.datetime >= ss.datetimestart) and (s.datetime<ss.datetimeend)');
           FQTemp3.SQL.Add('where (ss.id_equipment=@eqid) and (ss.datetimestart<="@dttmendday") and (ss.datetimeend>"@dttmstartday") and (ss.status=2)');
           FQTemp3.SQL.Add('and (s.id_equipment=@eqid) and (s.datetime between "@dttmstartday" and "@dttmendday")');
           FQTemp3.vars.Add('eqid',inttostr(EQId));
           FQTemp3.vars.Add('dttmstartday',MySQLDateTime(dt));
           FQTemp3.vars.Add('dttmendday',MySQLDateTime(dt+1-(1/24/3600)));
           try
              FQTemp3.Open;
           except
              WriteLog('������ ������� � �� MySQL');
              Status:=tst_fail;
              exit;
           end;
           FQTemp3.First;
           // �������� ������ �������� ����� �� ����� �����
           for I := 0 to 23 do begin
               QualArray[i].count:=0;
               QualArray[i].count_success:=0;
               QualArray[i].signal_avg:=-100;
           end;
           // ������ ���������� � �������� ����� � ������ � �������������� �� �����
           while (not FQTemp3.Eof) and (not aborted) do begin
               // ���������� ���, � �������� ����������� ������
               hour:=HourOf(FQTemp3.FieldByName('dttm').AsDateTime);
               // ��������� ����� � ���������� ����� ����
               inc(QualArray[hour].count);
               signal:= FQTemp3.FieldByName('signal_level').AsInteger -256;
               if signal > -100 then begin
                  inc(QualArray[hour].count_success);
                  QualArray[hour].signal_avg:=(QualArray[hour].signal_avg*(QualArray[hour].count_success - 1)+signal)/QualArray[hour].count_success;
               end;
               FQTemp3.Next;
           end;
           FQTemp3.Close;
           if aborted then break;
           // ���������� ���������� �� ������� ������� �� ����� � ��
           for I := 0 to 23 do begin
               if QualArray[i].count>0 then begin
                   if FQTemp3.Active then FQTemp3.Close;
                   FQTemp3.SQL.Clear;
                   FQTemp3.SQL.Add('insert into wifi_stat_equipment (date, hour, equipment, count_all, count_success, signal_avg) ');
                   FQTemp3.SQL.Add('values ("'+FormatDateTime('yyyy-mm-dd',dt)+'",'+inttostr(i)+','+inttostr(EQId)+','+inttostr(qualArray[i].count)+','+inttostr(qualArray[i].count_success)+','+StringReplace(FormatFloat('0.00',qualArray[i].signal_avg),',','.',[rfReplaceAll])+')');
                   try
                      FQTemp3.ExecSQL;
                   except
                      WriteLog('������ ������� � �� MySQL');
                      status:=tst_fail;
                      exit;
                   end;
               end;
           end;
           FQTemp2.Next;
           CurrentPercent:=CurrentPercent+percStep;
     end;
     FQTemp2.Close;
     if aborted then exit;
     // ���������� ���������� �� ������������ ������ � ����
     FQTemp2.SQL.Clear;
     FQTemp2.SQL.Add('insert into log_analize_wifi_by_equip (date) values ("'+FormatDateTime('yyyy-mm-dd',dt)+'")');
     try
        FQTemp2.ExecSQL;
     except
        WriteLog('������ ������� � �� MySQL');
        Status:=tst_fail;
        exit;
     end;
     FQTemp2.SQL.Clear;
     WriteLog('C��������� �� '+FormatDateTime('dd.mm.yyyy',dt)+' ������� ��������');
end;


{ TTaskCalcStatWiFiMap }
{
procedure TTaskCalcStatWiFiMap.CalculateNextRun;
begin
  inherited;

end;

constructor TTaskCalcStatWiFiMap.Create;
begin
     inherited;
     Name:='CalcWiFiStatMap';
     DisplayName:='��������� �������� �������� ���� WiFi � �������';
     // ���������� �������� �� ��������� FDaysToCalc ����
     FDaysToCalc:=70;
     LogFileName:='';
     CoInitialize(nil);
     FQTemp:=TADOQuery.Create(nil);
     FQTemp.Connection:=DM1.ConnMySQL;
end;

destructor TTaskCalcStatWiFiMap.Destroy;
begin
     if FQTemp.Active then FQTemp.Close;
     FreeAndNil(FQTemp);
     CoUninitialize;
     inherited;
end;

procedure TTaskCalcStatWiFiMap.ExecuteTask;
var dt:TDate;
    curperc:real;
begin
     WriteLog('������ '+self.Name+' ��������');
     FFirstDate:=Date()-FDaysToCalc+1;
     FLastDate:=Date()-1;
     if FQTemp.Active then FQTemp.Close;
     FQTemp.SQL.Clear;
     FQTemp.SQL.Add('select count(*) as cnt from log_map_settings ');
     FQTemp.SQL.Add('where (date>="'+FormatDateTime('dd.mm.yyyy',FFirstDate)+'") and (date<="'+FormatDateTime('dd.mm.yyyy',FLastDate-1)+'")');
     try
        FQTemp.Open;
     except
        WriteLog('������ ������� � �� MySQL');
        WriteLog('������ '+self.Name+' ���������');
        WriteLog('------------------------------'+#13);
        exit;
     end;
     // ���� ���������� ������� � ��������� ���������� ��������� � ����������� ����
     // ����� ��������� ��� ��� �� �����. ����� ������ ��������� ��������� ����
     // �, ��� �������������, ��������� �� ���� ���� ����������
     if FQTemp.FieldByName('cnt').AsInteger=(FDaysToCalc-1) then dt:=FLastDate
        else dt:=FFirstDate;
     FPercentStep:=100/(FDaysToCalc-FQTemp.FieldByName('cnt').AsInteger);
     FQTemp.Close;
     while dt<=FLastDate do begin
           curperc:=CurrentPercent;
           if FQTemp.Active then FQTemp.Close;
           FQTemp.SQL.Clear;
           FQTemp.SQL.Add('select * from log_analize_wifi_by_equip where date="'+FormatDateTime('dd.mm.yyyy',dt)+'"');
           try
              FQTemp.Open;
           except
              WriteLog('������ ������� � �� MySQL');
              WriteLog('������ '+self.Name+' ���������');
              WriteLog('------------------------------'+#13);
              exit;
           end;
           FQTemp.Last;
           //if FQTemp.RecordCount=0 then WriteStatistic(dt);
           FQTemp.Close;
           CurrentPercent:=curperc+FPercentStep;
           dt:=dt+1;
     end;
     WriteLog('������ '+self.Name+' ���������');
     WriteLog('------------------------------'+#13);
end;

procedure TTaskCalcStatWiFiMap.SetDaysToCalc(const Value: integer);
begin
     if Value>0 then FDaysToCalc:=Value;
end;
 }

{ TTaskUpdateDrillStatus }

constructor TTaskUpdateDrillStatus.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
     inherited Create(owner,sleeptimesec,runnow);
     //Name:='UpdateDrillStatus';
     DisplayName:='������ �������� �� ���������� � ��� � ������� statss';
     //CoInitialize(nil);
     connMySQL1:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
     QMySQL1:=TMyADOQuery.Create(nil,connMySQL1);
     QMySQL2:=TMyADOQuery.Create(nil,connMySQL1);
     connKobus1:=TMyADOConnection.Create(nil,dm1.ConnKobus.ConnectionString);
     Qpg1:=TMyADOQuery.Create(nil,connKobus1);
     ReadyBreaksCategories:=TIntList.Create;
     ReadyBreaksCategories.Add(1001);
     ReadyBreaksCategories.Add(1002);
end;

destructor TTaskUpdateDrillStatus.Destroy;
begin
     if Qpg1.Active then Qpg1.Close;
     if QMySQL1.Active then QMySQL1.Close;
     if QMySQL2.Active then QMySQL2.Close;
     FreeAndNil(Qpg1);
     FreeAndNil(QMySQL1);
     FreeAndNil(QMySQL2);
     FreeAndNil(connMySQL1);
     FreeAndNil(connKobus1);
     FreeAndNil(ReadyBreaksCategories);
     //CoUninitialize;
     inherited;
end;

procedure TTaskUpdateDrillStatus.ExecuteTask;
var
  dtm1: TDateTime;
  breakageId: integer;
  pribor: Integer;
  tmend: TDatetime;
  tmstart: TDateTime;
  breakageParentId: Integer;
  status: ShortInt;
  dtstart: TDate;
  dtend: TDate;
  percentByStep:real;
  maxbreaktmstart:TDateTime;   // ������������ ����� ������ �������.
                              // �����, ����� ��� �����, �� �������� � ��������, ���������� ������ ������
  step1percents: real;
  step2percents: real;
  dttmExecSQL: TDateTime;
  modem_id: Integer;
  writedRows: Integer;    // ���������� ��������, ���������� � �� ubiquiti
  processedRows:integer;
  lastBHistId: integer;
  modem_name: string;
  lastloggedRows: integer;
  currentBreak: Boolean;
  currwrited: Integer;
begin
     // �������� ���������� ������ �� 2 �����
     // 1 - ������ �������� �� ��������� � �������� ����������
     // 2 - ������ ��������� ��������, ��� �������
     step1percents:=99;
     step2percents:=1;
     writedRows:=0;
     lastLoggedRows:=0;
     processedRows:=0;
     if QMySQL1.Active then QMySQL1.Close;
     if Qpg1.Active then QMySQL1.Close;
     WriteLog('������ '+self.Name+' ��������');
     // ��������� ������� � ������� ��������
     try
        UpdateNotFinishedBreakages;
     except
        WriteLog('������ �������� ������������� ��������');
        exit;
     end;
     if aborted then begin
        WriteLog('���������� �������������� ���������� ������');
        exit;
     end;
     QMySQL1.SQL.Clear;
     QMySQL1.SQL.Add('select * from kobus_export order by created');
     try
      QMySQL1.Open;
     except
      WriteLog('������ ������� � �� ubiquity');
      exit;
     end;
     QMySQL1.Last;
     if QMySQL1.RecordCount>0 then begin
        FLastBreakageId:=QMySQL1.FieldByName('LastBreakageHistoryID').AsInteger;
        QMySQL1.Close;
     end else begin
        FLastBreakageId:=0;
        QMySQL1.Close;
        QMySQL1.SQL.Clear;
        QMySQL1.SQL.Add('insert into kobus_export (LastBreakageHistoryID) values(0)');
        try
          QMySQL1.ExecSQL;
        except
          WriteLog('������ ������� � �� ubiquity');
          exit;
        end;
     end;
     WriteLog('��������� ������������ id breakage_history:'+IntToStr(FLastBreakageId));
     Qpg1.SQL.Clear;
     Qpg1.SQL.Add('select h.id, h.pribor_id, h.breakage_id as breakageId, ');
     Qpg1.SQL.Add('h.date_time_begin, h.date_time_end , i.parent_id as break_parent_id ');
     Qpg1.SQL.Add('from breaks.breakage_history h ');
     Qpg1.SQL.Add('left join api.v_breakage_info i on (h.breakage_id=i.id) ');
     Qpg1.SQL.Add('where h.id > '+IntToStr(FLastBreakageId));
     Qpg1.SQL.Add('order by h.id');
     try
        dttmExecSQL:=Now;
        Qpg1.Open;
        Qpg1.Last;
        WriteLog('������� '+ IntToStr(Qpg1.RecordCount)+' �������������� ��������');
        // ��������� ������� �� ��������� ��� 1 ����
        if Qpg1.RecordCount>0 then percentByStep:=step1percents/Qpg1.RecordCount;
        Qpg1.First;
     except
        WriteLog('������ ������� � �� kobus_lgok');
        exit;
     end;

     // ���������� ������ � ���� �������������� �������� � ��
     while (not Qpg1.Eof) and (not aborted) do begin
        currentBreak:=false;
        lastBHistId:=Qpg1.FieldByName('id').AsInteger;
        breakageId:=Qpg1.FieldByName('breakageId').AsInteger;
        breakageParentId:=Qpg1.FieldByName('break_parent_id').AsInteger;
        pribor:=Qpg1.FieldByName('pribor_id').AsInteger;
        tmstart:=Qpg1.FieldByName('date_time_begin').AsDateTime;
        tmend:=qpg1.FieldByName('date_time_end').AsDateTime;
        status:=getStatusByBreak(breakageId,breakageParentId);
        //if ReadyBreaksCategories.Find(breakageParentId)>=0 then status:=ms_ready else status:=ms_damage;
        // ���� id-modem �� pribor
        modem_id:=getModemIdByPriborId(pribor);
        if modem_id<0 then begin
            WriteLog('������ ������ ������ ��� ������� '+IntToStr(pribor));
            WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
            exit;
        end;
        // ���� ����� �����, ��������� ��� ���������� �������
        if modem_id>0 then begin
            // �� �������, ������� �� �����������, ��������� � �������
            if tmend<tmstart then begin
              tmend:=dttmExecSQL;
              currentBreak:=true;
              QMySQL1.SQL.Clear;
              QMySQL1.SQL.Add('insert into kobus_current_breaks set breakId='+IntToStr(lastBHistId)+' ON DUPLICATE KEY UPDATE breakId='+IntToStr(lastBHistId));
              try
                 QMySQL1.ExecSQL;
              except
                 WriteLog('������ ������ ������������� ������� � �� ubiquiti');
                  WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
                 exit;
              end;
            end;
            currwrited:=UpdateStatus(modem_id,status,tmstart,tmend,false);
            if currwrited>=0 then begin
                writedRows:=writedRows+currwrited
            end else begin
               WriteLog('������ ������ �������� ��� ������ '+IntToStr(modem_id));
                WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
                exit;
            end;
            // �������������� ������, ������� ���� �� ���������� �������, ����������, ��� ������ � ��������� �����
            // ��������� ������, ��� ��� ������ ��� �������� �� ����� ��������
            currwrited:=UpdateStatus(modem_id,ms_ready,round(tmstart-7),tmstart-(1/24/3600),true);
            if currwrited>=0 then begin
                writedRows:=writedRows+currwrited;
            end else begin
                  WriteLog('������ ������ �������� ��� ������ '+IntToStr(modem_id));
                  WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
                  exit;
            end;
            // ��������� �������� ���������� ������������� ������� � ������� kobus_export
            QMySQL1.SQL.Clear;
            QMySQL1.SQL.Add('update kobus_export set LastBreakageHistoryID='+inttostr(lastBHistId));
            try
                 QMySQL1.ExecSQL;
            except
                 WriteLog('������ ������ �������������� '+IntToStr(breakageId) + ' � ������� kobus_export');
                  WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
                  exit;
            end;
        end;
        inc(processedRows);
        CurrentPercent:=CurrentPercent+percentByStep;
        FLastBreakageId:=lastBHistId;
        // ���������� � ��� ������ 100000 ���������� �����
        if (writedRows>(lastloggedRows+100000)) then begin
            WriteLog('�� ������� ������ ���������� '+IntToStr(processedRows)+' ��������. �������� '+IntToStr(writedRows)+' �����. ������ ���������� ������������� ������� '+FormatDateTime('dd.mm.yyyy hh:nn',tmstart));
            lastloggedRows:=writedRows;
        end;
        Qpg1.Next;
        // ������ ��������� ��������, ����� �� ����������� �� Ubiquity
        sleep(100);
     end;
     Qpg1.Close;
     if aborted then begin
        WriteLog('���������� �������������� ���������� ������');
        WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
        exit;
     end;
     // ����� �������� ���� �������� ���������� �������� ��� ��������� �������� ����� ��������� �������� � statss � ����������
     QMySQL1.SQL.Clear;
     QMySQL1.SQL.Add('update statss set status='+inttostr(ms_ready)+' where');
     QMySQL1.SQL.Add('(((date="'+MySQLDate(dttmExecSQL)+'") and (time<"'+MySQLTime(dttmExecSQL)+'")) or (date="'+MySQLDate(dttmExecSQL-1)+'"))');
     QMySQL1.SQL.Add('and (status='+inttostr(ms_unknown)+') and id_modem in (select m.id_modem from modems m, equipment e where (e.equipment_type in (5,6)) and (e.id=m.id_equipment))');
     try
          QMySQL1.ExecSQL;
          writedRows:=writedRows+QMySQL1.RowsAffected;
     except
          WriteLog('������ ������ �������� ���������� ����� ��������� ���� ��������');
          WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
          exit;
     end;
     WriteLog('������ ������� ���������. ���������� '+IntToStr(processedRows)+' ��������. �������� '+IntToStr(writedRows)+' �������� � �� ubiquity');
end;

function TTaskUpdateDrillStatus.getModemIdByPriborId(
  priborId: integer): integer;
var
  QMy1: TMyADOQuery;
  modem_name: string;
begin
     result:=0;
     try
        QMy1:=TMyADOQuery.Create(nil,connMySQL1);
        QMy1.SQL.Clear;
        QMy1.SQL.Add('select m.id_modem, m.name from modems m, equipment e, kobus_pribors kp where (kp.pribor_id_kobus='+inttostr(priborId)+') and (e.id=kp.id_equipment) and (m.id_equipment=e.id)');
        try
          QMy1.Open;
        except
          result:=-1;
          exit;
        end;
        QMy1.Last;
        if QMy1.RecordCount>0 then begin
          result:=QMy1.FieldByName('id_modem').AsInteger;
          modem_name:=QMy1.FieldByName('name').AsString;
        end else begin
          result:=0;
        end;
        QMy1.Close;
     finally
        FreeAndNil(QMy1);
     end;
end;

function TTaskUpdateDrillStatus.getStatusByBreak(breakId,
  ParentBreakId: integer): TStatssStatus;
begin
     if ReadyBreaksCategories.Find(ParentBreakId) >=0 then result:=ms_ready else result:=ms_damage;
end;

// �������� ��������, � ������� �� ������ ���������� �������� �� ���� ������� ���������
procedure TTaskUpdateDrillStatus.UpdateNotFinishedBreakages;
var
  QMy1: TMyADOQuery;
  QMy2: TMyADOQuery;
  Qpg: TMyADOQuery;
  breakId: Integer;
  priborId: Integer;
  breakageId: Integer;
  tmstart: TDateTime;
  tmend: TDateTime;
  breakageParentId: Integer;
  modem_id: Integer;
  status: TStatssStatus;
  dttm1: TDateTime;
  countCurrentBreaks: Integer;
  processedBreaks: Integer;
  finishedBreaks: Integer;
begin
     countCurrentBreaks:=0;
     processedBreaks:=0;
     finishedBreaks:=0;
     WriteLog('����� � �������� ��������� ���������� ������� ��������');
     try
         //CoInitialize(nil);
         QMy1:=TMyADOQuery.Create(nil,connMySQL1);
         QMy2:=TMyADOQuery.Create(nil,connMySQL1);
         Qpg:=TMyADOQuery.Create(nil,connKobus1);
         QMy2.SQL.Clear;
         QMy2.SQL.Add('select breakId from kobus_current_breaks');
         QMy2.Open;
         QMy2.Last;
         countCurrentBreaks:=QMy2.RecordCount;
         QMy2.First;
         while (not QMy2.Eof) and (not aborted) do begin
              breakId:=QMy2.FieldByName('breakId').AsInteger;
             Qpg.SQL.Clear;
             Qpg.SQL.Add('select h.pribor_id, h.breakage_id as breakageId, ');
              Qpg.SQL.Add('h.date_time_begin, h.date_time_end , i.parent_id as break_parent_id ');
             Qpg.SQL.Add('from breaks.breakage_history h ');
             Qpg.SQL.Add('left join api.v_breakage_info i on (h.breakage_id=i.id) ');
             Qpg.SQL.Add('where h.id ='+IntToStr(breakId));
             dttm1:=Now;
             Qpg.Open;
             if Qpg.RecordCount<>0 then begin
               Qpg.First;
               priborId:=Qpg.FieldByName('pribor_id').AsInteger;
               breakageId:=Qpg.FieldByName('breakageId').AsInteger;
               tmstart:=Qpg.FieldByName('date_time_begin').AsDateTime;
               tmend:=Qpg.FieldByName('date_time_end').AsDateTime;
               breakageParentId:=Qpg.FieldByName('break_parent_id').AsInteger;
               modem_id:=getModemIdByPriborId(priborId);
               status:=getStatusByBreak(breakageId,breakageParentId);
               if modem_id>0 then begin
                  // 2020-07-03 ����� ����� ����������� ���������� �������� ��� ������ �������,
                  // ������� ��������� � ���������� ��������.
                  // ��� ������������� ������������ ��� ������� ������ ���.
                  // ���������, ����� ����������� ������ ������ �� ��������� �����.
                  if tmend=0 then begin
                     UpdateStatus(modem_Id,status,dttm1-1,dttm1);
                  end else begin
                     UpdateStatus(modem_Id,status,tmend-1,tmend);
                     QMy1.SQL.Clear;
                     QMy1.SQL.Add('delete from kobus_current_breaks where breakId='+IntToStr(breakId));
                     try
                      QMy1.ExecSQL;
                      if QMy1.RowsAffected>0 then inc(finishedBreaks);
                     except

                     end;
                  end;
                  inc(processedBreaks);
               end;
             end else begin
                // ���� ������ � id �� �����, ������ ������� ���� id �� ��
                  QMy1.SQL.Clear;
                   QMy1.SQL.Add('delete from kobus_current_breaks where breakId='+IntToStr(breakId));
                   try
                    QMy1.ExecSQL;
                   except

                   end;
             end;
             Qpg.Close;

             QMy2.Next;
         end;
     finally
        WriteLog('�������: '+IntToStr(countCurrentBreaks)+'. ����������: '+IntToStr(processedBreaks)+'. ���������: '+IntToStr(finishedBreaks));
        FreeAndNil(Qpg);
        FreeAndNil(QMy2);
        FreeAndNil(QMy1);
        //CoUninitialize;
     end;

end;

function TTaskUpdateDrillStatus.UpdateStatus(modemId, status: integer; tmstart,
  tmend: TDateTime; checkToUnknown:boolean=false): integer;
var
  dtstart: TDate;
  dtend: TDate;
begin
     if tmstart>tmend then begin
        Result:=-1;
        exit;
     end;
     dtstart:=DateOf(tmstart);
     dtend:=DateOf(tmend);
      // ���������� � MySQL ������� ��� ������ �����, ������� ��������� � ���������� ����� tmstart � tmend
      QMySQL1.SQL.Clear;
      QMySQL1.SQL.Add('update statss set status='+IntToStr(status)+' where (id_modem='+IntToStr(modemId)+')');
      if dtstart=dtend then begin
          QMySQL1.SQL.Add('and (date="'+MySQLDate(tmstart)+'") and (time between "'+MySQLTime(tmstart)+'" and "'+MySQLTime(tmend)+'") ')
      end else begin
            QMySQL1.SQL.Add('and (');
           QMySQL1.SQL.Add(' ((date="'+MySQLDate(tmstart)+'") and (time>="'+MySQLTime(tmstart)+'"))');
           QMySQL1.SQL.Add('or ((date="'+MySQLDate(tmend)+'") and (time<="'+MySQLTime(tmend)+'"))');
           if dtstart+1<dtend then QMySQL1.SQL.Add('or (date between "'+MySQLDate(tmstart)+'" and "'+MySQLDate(tmend)+'" )');
           QMySQL1.SQL.Add(')');
      end;
      if checkToUnknown then
           QMySQL1.SQL.Add('and (status=0)');
      try
           QMySQL1.ExecSQL;
           result:=QMySQL1.RowsAffected;
      except
          result:=-1;
      end;
end;

{ TTaskGetBVUGPS }

constructor TTaskGetBVUGPS.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
  inherited Create(owner,sleeptimesec,runnow);
     DisplayName:='��������� ��������� ���������� � ��� �� ������ �����';
     //CoInitialize(nil);
     CurrEQ:=TCurrEQ.Create;
end;

destructor TTaskGetBVUGPS.Destroy;
begin
    if Assigned(CurrEQ) then FreeAndNil(CurrEQ);
    //DestroyDBConnections;
     //CoUninitialize;
  inherited;
end;

procedure TTaskGetBVUGPS.DestroyDBConnections;
begin
     if Assigned(QMySQLBGPS) then begin
        if QMySQLBGPS.Active then QMySQLBGPS.Close;
        FreeAndNil(QMySQLBGPS);
     end;
     if Assigned(QMySQLPribors) then begin
        if QMySQLPribors.Active then QMySQLPribors.Close;
        FreeAndNil(QMySQLPribors);
     end;
     if Assigned(QpgGps) then begin
        if QpgGps.Active then QpgGps.Close;
        FreeAndNil(QpgGps);
     end;
     if Assigned(connMySQLGPS) then FreeAndNil(connMySQLGPS);
     if Assigned(connKobusGPS) then FreeAndNil(connKobusGPS);
end;

procedure TTaskGetBVUGPS.ExecuteTask;
var
  countPribors: Integer;
begin
     if QMySQLPribors.Active then QMySQLPribors.Close;
     QMySQLPribors.SQL.Clear;
     QMySQLPribors.SQL.Add('select e.name, e.id, kp.pribor_id_kobus, kp.last_gps_writed');
     QMySQLPribors.SQL.Add('from equipment e left join kobus_pribors kp on (e.id=kp.id_equipment)');
     QMySQLPribors.SQL.Add('where (e.equipment_type in (5,6)) and (e.useInMonitoring=1)');
     try
        QMySQLPribors.Open;
     except
        WriteLog('������ ��� ��������� ������ ������������ �� �� ubiquiti');
        Status:=tst_fail;
        exit;
     end;
     countPribors:=QMySQLPribors.RecordCount;
     WriteLog('������� '+IntToStr(countPribors)+' ������ ������� � ������� kobus_pribors');
     PercentByPribor:=100/countPribors;
     while (not QMySQLPribors.Eof) and (not aborted) do begin
         CurrEQ.priborid:=QMySQLPribors.FieldByName('pribor_id_kobus').AsInteger;
         CurrEQ.name:=QMySQLPribors.FieldByName('name').AsString;
         CurrEQ.equipment_id:=getEquipmentIdByPriborId(CurrEQ.priborid);
         CurrEQ.lastWritedGPS:=QMySQLPribors.FieldByName('last_gps_writed').AsDateTime;
         if CurrEQ.equipment_id>0 then begin
             try
                WriteCoordsCurrEQ;
             except
                WriteLog('������ ������ ��������� �� ������������ '+CurrEQ.name);
             end;
         end else begin
             WriteLog('�� ������� ������ ��� ������������'+CurrEQ.name);
         end;
         QMySQLPribors.Next;
     end;
     if aborted then WriteLog('���������� �������������� ���������� ������');
end;


function TTaskGetBVUGPS.getEquipmentIdByPriborId(priborId: integer): integer;
var QMy1:TMyADOQuery;
begin
     result:=0;
     try
        QMy1:=TMyADOQuery.Create(nil,connMySQLGPS);
        QMy1.SQL.Clear;
        QMy1.SQL.Add('select e.id from equipment e, kobus_pribors kp where (kp.pribor_id_kobus='+inttostr(priborId)+') and (e.id=kp.id_equipment)');
        try
          QMy1.Open;
        except
          result:=-1;
          exit;
        end;
        QMy1.Last;
        if QMy1.RecordCount>0 then begin
          result:=QMy1.FieldByName('id').AsInteger;
        end else begin
          result:=0;
        end;
        QMy1.Close;
     finally
        FreeAndNil(QMy1);
     end;
end;

function TTaskGetBVUGPS.getModemIdByPriborId(priborId: integer): integer;
var
  QMy1: TMyADOQuery;
  modem_name: string;
begin
     result:=0;
     try
        QMy1:=TMyADOQuery.Create(nil,connMySQLGPS);
        QMy1.SQL.Clear;
        QMy1.SQL.Add('select m.id_modem, m.name from modems m, equipment e, kobus_pribors kp where (kp.pribor_id_kobus='+inttostr(priborId)+') and (e.id=kp.id_equipment) and (m.id_equipment=e.id)');
        try
          QMy1.Open;
        except
          result:=-1;
          exit;
        end;
        QMy1.Last;
        if QMy1.RecordCount>0 then begin
          result:=QMy1.FieldByName('id_modem').AsInteger;
          modem_name:=QMy1.FieldByName('name').AsString;
        end else begin
          result:=0;
        end;
        QMy1.Close;
     finally
        FreeAndNil(QMy1);
     end;
end;

procedure TTaskGetBVUGPS.initDBConnections;
begin
     connMySQLGPS:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
     QMySQLBGPS:=TMyADOQuery.Create(nil,connMySQLGPS);
     QMySQLPribors:=TMyADOQuery.Create(nil,connMySQLGPS);
     connKobusGPS:=TMyADOConnection.Create(nil,dm1.ConnKobus.ConnectionString);
     QpgGPS:=TMyADOQuery.Create(nil,connKobusGPS);

end;

procedure TTaskGetBVUGPS.InsertCurrEQCoord(x, y: integer; dttm: TDateTime);
var QMyTemp2:TMyADOQuery;
begin
     try
        QMyTemp2:=TMyADOQuery.Create(nil,connMySQLGPS);
         QMyTemp2.Clear;
         QMyTemp2.SQL.Add('insert into stats_gps (id_equipment,datetime,x,y) values (@eqid,"@dttm",@x,@y)');
         QMyTemp2.vars.Add('eqid',IntToStr(CurrEQ.equipment_id));
         QMyTemp2.vars.Add('dttm',MySQLDateTime(dttm));
         QMyTemp2.vars.Add('x',intToStr(x));
         QMyTemp2.vars.Add('y',intToStr(y));
         try
            QMyTemp2.ExecSQL;
         except
            on E:Exception do begin
              if Pos('Duplicate entry',E.Message)=0 then begin
                WriteLog(E.Message);
                WriteLog('������ ������ ���������� ��� '+CurrEQ.name+'. ���� � ����� ����������: '+FormatDateTime('dd.mm.yyyy hh:nn:ss',dttm));
                Self.Status:=tst_fail;
                exit;
              end;
            end;
         end;
     finally
        FreeAndNil(QMyTemp2);
     end;
end;

procedure TTaskGetBVUGPS.CloseConnections;
begin
  inherited;
  try
      if connMySQLGPS.Connected then connMySQLGPS.Close;
      if connKobusGPS.Connected then connKobusGPS.Close;
  except
      WriteLog('������ �������� ����������� � ��');
  end;
end;

procedure TTaskGetBVUGPS.WriteCoordsCurrEQ;
type TKobuscoord=record
    x:integer;
    y:integer;
    sat_count:integer;
end;

var
  lasttimetoProcess: TDateTime;
  PercentByStep: Real;
  dttmstatss: TDateTime;
  dttmkobus: TDateTime;
  difftm: real;
  difftmold: Real;
  sat_count1: Integer;
  sat_count2: Integer;
  correct: Boolean;
  y: Integer;
  x: Integer;
  dttm: TDateTime;
  statssid: Integer;
  countWrited: Integer;
  dttmfirst: TDateTime;
  dttmkobusprev: TDateTime;
  x1: Integer;
  y1: integer;
  x2: integer;
  y2: integer;
  mindttm: TDatetime;
begin
     // ���� ������ ������������ ����� �� statss ��� ������������, ���� ��������� ���������� ���� �������� ����� 60 ���� �����
     if ((Now-CurrEQ.lastWritedGPS)>60) then begin
        if QMySQLBGPS.Active then QMySQLBGPS.Close;
        QMySQLBGPS.Clear;
        QMySQLBGPS.SQL.Add('select min(datetime) as mindttm from statss where id_equipment=@eqid');
        QMySQLBGPS.vars.Add('eqid',inttostr(CurrEQ.equipment_id));
        try
          QMySQLBGPS.Open
        except
          WriteLog('������ ��������� ������������ �������� �������');
          Status:=tst_fail;
          exit;
        end;
        mindttm:=QMySQLBGPS.FieldByName('mindttm').AsDateTime;
        if CurrEQ.lastWritedGPS<mindttm then CurrEQ.lastWritedGPS:=mindttm;
     end;
     // �������� ������ � ����������� ������ �� �� kobus_lgok � ��������������� �������
     if QpgGPS.Active then QpgGPS.Close;
     QpgGPS.SQL.Clear;
     QpgGPS.SQL.Add('select date_time_kobus, x1,y1, sat_count1, x2, y2, sat_count2 from gps.online_position');
     QpgGPS.SQL.Add('where (pribor_Id='+IntToStr(CurrEQ.priborid)+')');
     QpgGPS.SQL.Add('and (date_time_kobus>'+#39+MySQLDateTime(CurrEQ.lastWritedGPS)+#39+')');
     QpgGPS.SQL.Add('order by date_time_kobus limit 10000');
     try
        QpgGPS.Open;
     except
        WriteLog('������ ������� ��������� ��� '+CurrEQ.name+' �� �� kobus_lgok');
        status:=tst_warning;
        exit;
     end;
     if aborted then exit;
     countwrited:=0;
    if QpgGPS.RecordCount>0 then begin
      QpgGPS.First;
      // ��� ���������� �������, ����� ��� �� ������ lastWritedGPS, ����� ������� �� ������� ������ �� statss
      if CurrEQ.lastWritedGPS>0 then dttmfirst:=CurrEQ.lastWritedGPS else dttmfirst:=QpgGPS.FieldByName('date_time_kobus').AsDateTime;
      QpgGPS.Last;
      lasttimetoProcess:=QpgGPS.FieldByName('date_time_kobus').AsDateTime;
      PercentByStep:=PercentByPribor/QpgGPS.RecordCount;
      // �������� ����� ���������� �� �� ubiquiti ����� � ��������������� �������
      if QMySQLBGPS.Active then QMySQLBGPS.Close;
      QMySQLBGPS.Clear;
      QMySQLBGPS.SQL.Add('select id, datetime from statss where');
      QMySQLBGPS.SQL.Add('(id_equipment=@eqid) and (datetime between "@dttmfirst" and "@dttmlast" )');
      QMySQLBGPS.SQL.Add('order by datetime');
      QMySQLBGPS.vars.Add('eqid',Inttostr(CurrEQ.equipment_id));
      QMySQLBGPS.vars.Add('dttmfirst',MySQLDateTime(dttmfirst));
      QMySQLBGPS.vars.Add('dttmlast',MySQLDateTime(lasttimetoProcess));
      {if DateOf(dttmfirst)=DateOf(lasttimetoProcess) then begin
         QMySQLBGPS.SQL.Add('(date="'+MySQLDate(dttmfirst)+'") and (id_modem='+Inttostr(CurrEQ.modemid)+')');
         QMySQLBGPS.SQL.Add('and (time between "'+MySQLTime(dttmfirst)+'" and "'+MySQLTime(lasttimetoProcess)+'")');
      end else begin
         QMySQLBGPS.SQL.Add('(id_modem='+Inttostr(CurrEQ.modemid)+')');
         QMySQLBGPS.SQL.Add('and (');
         QMySQLBGPS.SQL.Add('((date="'+MySQLDate(dttmfirst)+'") and (time>"'+MySQLTime(dttmfirst)+'"))');
         QMySQLBGPS.SQL.Add('or ((date="'+MySQLDate(lasttimetoProcess)+'") and (time<"'+MySQLTime(lasttimetoProcess)+'"))');
         if DateOf(dttmfirst+1)<Dateof(lasttimetoProcess) then
            QMySQLBGPS.SQL.Add('or (date between "'+MySQLDate(dttmfirst+1)+'" and "'+MySQLDate(lasttimetoProcess-1)+'")');
         QMySQLBGPS.SQL.Add(')');
         QMySQLBGPS.SQL.Add('order by date, time');
      end;}
      try
         QMySQLBGPS.Open;
      except
         WriteLog('������ ������� ����� ���������� ��� '+CurrEQ.name);
         Status:=tst_warning;
         exit;
      end;
      // ���������� ��������������� ��� ������� � ������� �����, ��������� �� ������� ���� � �����
      QpgGPS.First;
      QMySQLBGPS.First;
      dttmstatss:=QMySQLBGPS.FieldByName('datetime').AsDateTime;
      statssid:=QMySQLBGPS.FieldByName('id').AsInteger;
      dttmkobus:=QpgGPS.FieldByName('date_time_kobus').AsDateTime;
      dttmkobusprev:=0;
      difftm:=Now();    // ������������� ����������
      while (not QpgGPS.Eof) and (not QMySQLBGPS.Eof) and (not aborted) do begin
          difftmold:=difftm;
          difftm:=dttmstatss-dttmkobus;
          if dttmstatss>dttmkobus then begin
            QpgGPS.Next;
            CurrentPercent:=CurrentPercent+PercentByStep;
            dttmkobusprev:=dttmkobus;
            dttmkobus:=QpgGPS.FieldByName('date_time_kobus').AsDateTime;
          end else begin
            // ���� ����� � �������� 5 ������, �� �������� ���������� ��� ������
            correct:=false;
            dttm:=0;
            x:=0;
            y:=0;
            if abs(difftm)<1/24/3600*5 then begin
                sat_count1:=QpgGPS.FieldByName('sat_count1').AsInteger;
                sat_count2:=QpgGPS.FieldByName('sat_count2').AsInteger;
                x1:=Round(QpgGPS.FieldByName('x1').AsFloat);
                y1:=Round(QpgGPS.FieldByName('y1').AsFloat);
                x2:=Round(QpgGPS.FieldByName('x2').AsFloat);
                y2:=Round(QpgGPS.FieldByName('y2').AsFloat);
                if (sat_count1>10) and (x1>0) and (y1>0) and (x1<50000) and (y1<50000)  then begin
                    x:=x1;
                    y:=y1;
                    dttm:=dttmstatss;
                    correct:=true;
                end else begin
                   if (sat_count2>10) and (x2>0) and (y2>0) and (x2<50000) and (y2<50000)  then begin
                      x:=x2;
                      y:=y2;
                      dttm:=dttmstatss;
                      correct:=true;
                   end;
                end;
            end;
            if (not correct) and (abs(difftmold)<1/24/3600*5) then begin
               QpgGPS.Prior;
               sat_count1:=QpgGPS.FieldByName('sat_count1').AsInteger;
               sat_count2:=QpgGPS.FieldByName('sat_count2').AsInteger;
               if (sat_count1>10) and (x>0) and (y>0) and (x<50000) and (y<50000) then begin
                    x:=Round(QpgGPS.FieldByName('x1').AsFloat);;
                    y:=Round(QpgGPS.FieldByName('y1').AsFloat);;
                    dttm:=dttmstatss;
                    correct:=true;
                end else begin
                   if (sat_count2>10) and (x>0) and (y>0) and (x<50000) and (y<50000) then begin
                      x:=Round(QpgGPS.FieldByName('x2').AsFloat);
                      y:=Round(QpgGPS.FieldByName('y2').AsFloat);
                      dttm:=dttmstatss;
                      correct:=true;
                   end;
                end;
               QpgGPS.Next;
            end;
            // ���� �������� ����������, �� ���������� �� � Statss ��� ����� �����
            if correct then begin
              writeCurrEQCoordPoint(statssid,x,y,dttm);
              inc(countWrited);
            end;
            QMySQLBGPS.Next;
            dttmstatss:=QMySQLBGPS.FieldByName('datetime').AsDateTime;
            statssid:=QMySQLBGPS.FieldByName('id').AsInteger;
            difftm:=dttmstatss-dttmkobusprev;
            //QpgGPS.Next;
            //CurrentPercent:=CurrentPercent+PercentByStep;
            //dttmkobus:=QpgGPS.FieldByName('date_time_kobus').AsDateTime;
          end;

      end;
    end;
    WriteLog('��� '+CurrEQ.name+' ���������� '+Inttostr(QpgGPS.RecordCount)+' �����. �������� '+IntToStr(countWrited)+' �����.');
end;

procedure TTaskGetBVUGPS.writeCurrEQCoordPoint(statssid:integer; x,y:integer; dttm:TDateTime);
var
  QMySQLTemp:TMyADOQuery;
begin
   //[2022-09-04] ���������� ���������� � ����� �������
   InsertCurrEQCoord(x,y,dttm);
   // [2022-09-04] ���� ��� �������� ������������� ���������� ���������� ����� � �
   QMySQLTemp:=TMyADOQuery.Create(nil,connMySQLGPS);
   if statssid>0 then begin
     QMySQLTemp.SQL.Clear;
     QMySQLTemp.SQL.Add('update statss set x='+IntToStr(x)+',y='+IntToStr(y)+'  where id='+IntToStr(statssid));
     try
        QMySQLTemp.ExecSQL;
        QMySQLTemp.SQL.Clear;
         QMySQLTemp.SQL.Add('update kobus_pribors set last_gps_writed="'+MySQLDateTime(dttm)+'" where pribor_id_kobus='+IntToStr(CurrEQ.Priborid));
         try
            QMySQLTemp.ExecSQL;
              CurrEQ.lastWritedGPS:=dttm;
         except
            WriteLog('������ ���������� last_gps_writed ��� '+CurrEQ.name);
            Status:=tst_warning;
         end;
     except
        WriteLog('������ ������ ���������� ��� ������������ '+CurrEQ.name+' ����� ���������� � id '+IntToStr(statssid));
        status:=tst_warning;
     end;
   end else begin
     WriteLog('������������ '+CurrEQ.name+'. ����������� ������ statssid:'+IntToStr(statssid));
   end;
   FreeAndNil(QMySQLTemp);
end;

{ TTaskCalcWiFiStatMap }

constructor TTaskCalcWiFiStatMap.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
  inherited Create(owner,sleeptimesec,runnow);
     DisplayName:='������ ����� �������� wiFi';
     //CoInitialize(nil);
     connMySQL1:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
     QMySQLEquipment:=TMyADOQuery.Create(nil,connMySQL1);
     QMySQL2:=TMyADOQuery.Create(nil,connMySQL1);
end;

destructor TTaskCalcWiFiStatMap.Destroy;
begin
  if QMySQL2.Active then QMySQL2.Close;
  FreeAndNil(QMySQL2);
  if QMySQLEQuipment.Active then QMySQLEQuipment.Close;
  FreeAndNil(QMySQLEQuipment);
  FreeAndNil(connMySQL1);
  inherited;
end;

procedure TTaskCalcWiFiStatMap.ExecuteTask;
var
  countEQ: Integer;
  percentByEQ: real;
begin
  // ��������� ���������� ������������
  if QMySQLEQuipment.Active then QMySQLEquipment.Close;
  QMySQLEquipment.SQL.Clear;
  QMySQLEquipment.SQL.Add('select id,name, LastGPSDateTime from equipment where equipment_type in (1,2,5,6) and (useInMonitoring>0)');
  try
      QMySQLEquipment.Open;
  except
      WriteLog('�� ������� �������� ������ ���������� ������������');
      exit;
  end;
  countEQ:=QMySQLEquipment.RecordCount;
  percentByEQ:=100/countEQ;
  while not QMySQLEquipment.Eof do begin
      if QMySQL2.Active then QMySQL2.Close;
      QMySQL2.SQL.Clear;
      QMySQL2.SQL.Add('select ');
  end;
end;

procedure TTaskCalcWiFiStatMap.CloseConnections;
begin
  inherited;
    try
       connMySQL1.Close;
    except
       WriteLog('������ ����������� � ��');
    end;
end;

{ TTaskGetModularStatuses }

procedure TTaskGetModularStatuses.CloseConnections;
begin
     try
        connMySQL1.Close;
        connD6.Close;
     except
        WriteLog('������ �������� ���������� �� ��');
     end;
end;

constructor TTaskGetModularStatuses.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
  inherited Create(owner,sleeptimesec,runnow);
     DisplayName:='��������� �������� ������� ������ �������';
     //CoInitialize(nil);
     connMySQL1:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
     QMySQL1:=TMyADOQuery.Create(nil,connMySQL1);
     QMySQL2:=TMyADOQuery.Create(nil,connMySQL1);
     connD6:=TMyADOConnection.Create(nil,dm1.tplConnD6.ConnectionString);
     QPVstatuses:=TMyADOQuery.Create(nil,connD6);
end;

destructor TTaskGetModularStatuses.Destroy;
begin
    if QPVstatuses.Active then QPVstatuses.Close;
    FreeAndNil(QPVstatuses);
    FreeAndNil(connD6);
    if QMySQL2.Active then QMySQL2.Close;
    FreeAndNil(QMySQL2);
    if QMySQL1.Active then QMySQL1.Close;
    FreeAndNil(QMySQL1);
    //CoUninitialize;
  inherited;
end;

procedure TTaskGetModularStatuses.ExecuteTask;
var
  PercentByStep: real;
  currStatus:TModularStatus;
  countwrited: Integer;
  counterrors: Integer;
begin
    // ������� ������ ����������� � ������
    CloseConnections;
    mysqlError:=false;
    shiftindex:=0;
    minendtime:=0;
    // �������� ��������� ��������
    if QMySQL1.Active then QMySQL1.Close;
    QMySQL1.SQL.Clear;
    QMySQL1.SQL.Add('select shiftindex, minendtime from stats_status_settings_modular order by id');
    try
        QMySQL1.Open;
        if QMySQL1.RecordCount>0 then begin
            QMySQL1.Last;
            shiftindex:=QMySQL1.FieldByName('shiftindex').AsInteger;
            minendtime:=QMySQL1.FieldByName('minendtime').AsInteger;
        end;
    except
      on E: Exception do begin
        WriteLog('������ ������ ���������� ������� �� stats_status_settings_modular. '+ E.Message);
        mysqlError:=true;
        Status:=tst_fail;
        exit;
      end;
    end;
    if QMySQL1.Active then QMySQL1.Close;
    // ���� ������� � �� Powerview
    if QPVstatuses.Active then QPVstatuses.Close;
    QPVstatuses.SQL.Clear;
    QPVstatuses.SQL.Add('select top(20000) shiftindex, ddbkey, eqmt, starttime, endtime, status from hist_statusevents');
    QPVstatuses.SQL.Add('where (shiftindex>'+inttostr(shiftindex)+') or (shiftindex='+inttostr(shiftindex)+') and (endtime>'+inttostr(minendtime)+')');
    QPVstatuses.SQL.Add('order by shiftindex, endtime');
    try
         QPVstatuses.Open;
    except
         WriteLog('������ ��������� �������� �� �� Powerview');
         status:=tst_fail;
         exit;
    end;
    WriteLog('������� '+inttostr(QPVstatuses.RecordCount)+' �������������� ��������');
    if aborted then begin
        WriteLog('���������� �������������� ���������� ������');
        exit;
    end;
    countwrited:=0;
    counterrors:=0;
    if QPVstatuses.RecordCount>0 then begin
        PercentByStep:=100/QPVstatuses.RecordCount;
        while (not QPVstatuses.Eof) and (not aborted) do begin
            currstatus.shiftindex:=QPVstatuses.FieldByName('shiftindex').AsInteger;
            currStatus.ddbkey:=QPVstatuses.FieldByName('ddbkey').AsInteger;
            currStatus.eqmt:=QPVstatuses.FieldByName('eqmt').AsString;
            currStatus.starttime:=QPVstatuses.FieldByName('starttime').AsInteger;
            currStatus.endtime:=QPVstatuses.FieldByName('endtime').AsInteger;
            currStatus.status:=QPVstatuses.FieldByName('status').AsInteger;
            if WriteCurrentStatus(currStatus) then begin
               inc(countwrited);
               counterrors:=0;
               SaveStatistic(currStatus.shiftindex,currStatus.endtime);
            end else begin
               // ���� ������ ���������� ������� � mysql, �� ���������� ���������� ���������
               if mysqlError then exit;
            end;
            CurrentPercent:=CurrentPercent+PercentByStep;
            QPVstatuses.Next;
        end;
    end;
    QPVstatuses.Close;
    WriteLog('�������� '+IntToStr(countwrited)+' ��������');
    if aborted then WriteLog('���������� �������������� ���������� ������');
end;

procedure TTaskGetModularStatuses.SaveStatistic(shiftid, shseconds: integer);
begin
     if QMySQL1.Active then QMySQL1.Close;
     QMySQL1.SQL.Clear;
     if shiftid>0 then begin
        QMySQL1.SQL.Add('update stats_status_settings_modular set shiftindex='+inttostr(shiftid)+',');
        QMySQL1.SQL.Add('minendtime='+IntToStr(shseconds));
        QMySQL1.SQL.Add('order by id Desc Limit 1');
        try
            QMySQL1.ExecSQL;
        except
            WriteLog('�� ������� ��������� ���������� �������� ������');
            mysqlError:=true;
            status:=tst_fail;
        end;
     end else begin
        QMySQL1.SQL.Add('insert into stats_status_settings_modular (shiftindex,minendtime)');
        QMySQL1.SQL.Add('values ('+IntToStr(shiftid)+','+IntToStr(shseconds)+')');
        try
            QMySQL1.ExecSQL;
        except
            WriteLog('�� ������� �������� ���������� �������� ������');
            mysqlError:=true;
            Status:=tst_fail;
        end;
     end;
end;

function TTaskGetModularStatuses.WriteCurrentStatus(status:TModularStatus):boolean;
var
  eq_id: Integer;
  countFinded: Integer;
  id1: Integer;
begin
     // ��������� ������� ������� � ����� �� �������� ������ � ����
     // ��� ����� ��� ���������� ������� �������� (��� ������������)
     result:=false;
     if QMySQL1.Active then QMySQL1.Close;
     QMySQL1.SQL.Clear;
     eq_id:=TEquipment.GetMySQLIndexByName(status.eqmt);
     if eq_id>0 then begin
        QMySQL1.SQL.Add('select * from stats_status where (id_equipment='+inttostr(eq_id)+') and (datetimestart="'+MySQLDateTime(ShiftAndSecToDateTime(status.shiftindex,status.starttime))+'") order by datetimestart');
        try
            QMySQL1.Open;
        except
          on E: Exception do begin
            WriteLog('������ �������� ������� � id '+inttostr(status.ddbkey)+'. '+E.Message);
            mysqlError:=true;
            self.Status:=tst_fail;
            exit;
          end;
        end;
        countFinded:=QMySQL1.RecordCount;
        if countFinded>0 then begin
            QMySQL1.Last;
            id1:=QMySQL1.FieldByName('id').AsInteger;
        end else id1:=0;
        QMySQL1.Close;
        // ��������� ������ ���������� ��� ���������� �������
        if (countFinded>0)and (id1>0) then begin
                  if QMySQL2.Active then QMySQL2.Close;
                  QMySQL2.SQL.Clear;
                  QMySQL2.SQL.Add('update stats_status set datetimestart="'+MySQLDateTime(ShiftAndSecToDateTime(status.shiftindex,status.starttime))+'",');
                  QMySQL2.SQL.Add('datetimeend="'+MySQLDateTime(ShiftAndSecToDateTime(status.shiftindex,status.endtime))+'",');
                  QMySQL2.SQL.Add('asu_id="'+IntToStr(status.ddbkey)+'",');
                  QMySQL2.SQL.Add('status='+IntToStr(status.status));
                  QMySQL2.SQL.Add('where id='+inttostr(id1));
                  try
                     QMySQL2.ExecSQL;
                     result:=true;
                  except
                     WriteLog('������ ���������� ������� � id: '+IntToStr(id1)+' id_asu: '+inttostr(status.ddbkey));
                     mysqlError:=true;
                     self.Status:=tst_fail;
                  end;
        end else begin
                  if QMySQL2.Active then QMySQL2.Close;
                  QMySQL2.SQL.Clear;
                  QMySQL2.SQL.Add('insert into stats_status (id_equipment,datetimestart,datetimeend,status,asu_id)');
                  QMySQL2.SQL.Add('values ('+IntToStr(eq_id)+',');
                  QMySQL2.SQL.Add('"'+MySQLDateTime(ShiftAndSecToDateTime(status.shiftindex,status.starttime))+'",');
                  QMySQL2.SQL.Add('"'+MySQLDateTime(ShiftAndSecToDateTime(status.shiftindex,status.endtime))+'",');
                  QMySQL2.SQL.Add(IntToStr(status.status)+',');
                  QMySQL2.SQL.Add(inttostr(status.ddbkey)+')');
                  try
                     QMySQL2.ExecSQL;
                     if QMySQL2.RowsAffected>0 then result:=true;
                  except
                     WriteLog('������ ���������� ������ � ������� �������� � ddbkey: '+inttostr(status.ddbkey));
                     mysqlError:=true;
                     self.Status:=tst_fail;
                  end;
        end;
     end;
end;

{ TTaskGetDrillStatuses }

procedure TTaskGetDrillStatuses.CloseConnections;
begin
  inherited;
  try
      if connMySQL1.Connected then connMySQL1.Close;
      if connKobus1.Connected then connKobus1.Close;
  finally
      WriteLog('������ �������� ����������� � ��');
  end;
end;

constructor TTaskGetDrillStatuses.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
begin
  inherited Create(owner,sleeptimesec,runnow);
     DisplayName:='��������� �������� ������� ������ �����';
     //CoInitialize(nil);
     ReadyBreaksCategories:=TIntList.Create;
     ReadyBreaksCategories.Add(1001);
     ReadyBreaksCategories.Add(1002);
     LimitStatuses:=10000;
end;

function TTaskGetDrillStatuses.DeleteMySQLStatus(id: Largeint):boolean;
var QMyTemp:TMyADOQuery;
begin
     result:=false;
     QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
     try
        QMyTemp.Clear;
        QMyTemp.SQL.Add('delete from stats_status where id=@id');
        //QMyTemp.AddParameter('id',ftLargeint,id);
        QMyTemp.vars.Add('id',IntToStr(id));
        try
           QMyTemp.ExecSQL;
           if QMyTemp.RowsAffected>0 then result:=true;
           result:=true;
        except
           WriteLog('������ �������� ������� id: '+IntToStr(id));
        end;
     finally
        FreeAndNil(QMyTemp);
     end;
end;

destructor TTaskGetDrillStatuses.Destroy;
begin
     FreeAndNil(ReadyBreaksCategories);
     //CoUninitialize;
     inherited;
end;

procedure TTaskGetDrillStatuses.DestroyDBConnections;
begin
     if Assigned(Qpg1) then begin
        if Qpg1.Active then Qpg1.Close;
        FreeAndNil(Qpg1);
     end;
     if Assigned(QMySQL1) then begin
       if QMySQL1.Active then QMySQL1.Close;
       FreeAndNil(QMySQL1);
     end;
     if Assigned(QMySQL2) then begin
       if QMySQL2.Active then QMySQL2.Close;
       FreeAndNil(QMySQL2);
     end;
     if Assigned(connMySQL1) then FreeAndNil(connMySQL1);
     if Assigned(connKobus1) then FreeAndNil(connKobus1);
  inherited;
end;

procedure TTaskGetDrillStatuses.ExecuteTask;
var
  dtm1: TDateTime;
  breakageId: integer;
  pribor: Integer;
  tmend: TDatetime;
  tmstart: TDateTime;
  breakageParentId: Integer;
  status: ShortInt;
  dtstart: TDate;
  dtend: TDate;
  percentByStep:real;
  maxbreaktmstart:TDateTime;   // ������������ ����� ������ �������.
                              // �����, ����� ��� �����, �� �������� � ��������, ���������� ������ ������
  step1percents: real;
  step2percents: real;
  dttmExecSQL: TDateTime;
  writedRows: Integer;    // ���������� ��������, ���������� � �� ubiquiti
  processedRows:integer;
  lastBHistId: integer;
  modem_name: string;
  currentBreak: Boolean;
  currwrited: Integer;
  equipment_id: Integer;
  countFindedStatuses: Integer;
begin
     step1percents:=100;
     step2percents:=0;
     writedRows:=0;
     processedRows:=0;
     tmend:=0;
     if QMySQL1.Active then QMySQL1.Close;
     // ��������� ������� � ������� ��������
     try
        UpdateNotFinishedBreakages;
     except
        WriteLog('������ �������� ������������� ��������');
        self.Status:=tst_fail;
        exit;
     end;
     if aborted then begin
        WriteLog('���������� �������������� ���������� ������');
        exit;
     end;
     QMySQL1.SQL.Clear;
     QMySQL1.SQL.Add('select * from stats_status_settings_kobus order by created');
     try
      QMySQL1.Open;
     except
      WriteLog('������ ������� � �� ubiquity');
      self.status:=tst_fail;
      exit;
     end;
     QMySQL1.Last;
     if QMySQL1.RecordCount>0 then begin
        FLastBreakageId:=QMySQL1.FieldByName('LastBreakageHistoryID').AsInteger;
        QMySQL1.Close;
     end else begin
        FLastBreakageId:=0;
        QMySQL1.Close;
        QMySQL1.SQL.Clear;
        QMySQL1.SQL.Add('insert into stats_status_settings_kobus (LastBreakageHistoryID) values(0)');
        try
          QMySQL1.ExecSQL;
        except
          WriteLog('������ ������� � �� ubiquity');
          self.status:=tst_fail;
          exit;
        end;
     end;
     WriteLog('��������� ������������ id breakage_history:'+IntToStr(FLastBreakageId));
     if Qpg1.Active then QMySQL1.Close;
     Qpg1.SQL.Clear;
     Qpg1.SQL.Add('select h.id, h.pribor_id, h.breakage_id as breakageId, ');
     Qpg1.SQL.Add('h.date_time_begin, h.date_time_end , i.parent_id as break_parent_id ');
     Qpg1.SQL.Add('from breaks.breakage_history h ');
     Qpg1.SQL.Add('left join api.v_breakage_info i on (h.breakage_id=i.id) ');
     Qpg1.SQL.Add('where h.id > '+IntToStr(FLastBreakageId));
     Qpg1.SQL.Add('order by h.id limit '+IntToStr(LimitStatuses));
     percentByStep:=step1percents;
     try
        dttmExecSQL:=Now;
        Qpg1.Open;
        Qpg1.Last;
        WriteLog('������� '+ IntToStr(Qpg1.RecordCount)+' �������������� ��������');
        // ��������� ������� �� ��������� ��� 1 ����
        if Qpg1.RecordCount>0 then percentByStep:=step1percents/Qpg1.RecordCount;
        Qpg1.First;
     except
        WriteLog('������ ������� � �� kobus_lgok');
        self.status:=tst_fail;
        exit;
     end;

     // ���������� ������ � ���� �������������� �������� � ��
     while (not Qpg1.Eof) and (not aborted) do begin
        currentBreak:=false;
        lastBHistId:=Qpg1.FieldByName('id').AsInteger;
        breakageId:=Qpg1.FieldByName('breakageId').AsInteger;
        breakageParentId:=Qpg1.FieldByName('break_parent_id').AsInteger;
        pribor:=Qpg1.FieldByName('pribor_id').AsInteger;
        tmstart:=Qpg1.FieldByName('date_time_begin').AsDateTime;
        tmend:=qpg1.FieldByName('date_time_end').AsDateTime;
        status:=getStatusByBreak(breakageId,breakageParentId);
        // ���� id-equipment �� pribor
        equipment_id:=getEquipmentIdByPriborId(pribor);
        if equipment_id<0 then begin
            WriteLog('������ ������ ������������ ��� ������� '+IntToStr(pribor));
            WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
            exit;
        end;
        // ���� ����� id_equipment, ���������� ������
        if equipment_id>0 then begin
            // �� �������, ������� �� �����������, ��������� � �������
            if tmend<tmstart then begin
              tmend:=dttmExecSQL;
              currentBreak:=true;
              QMySQL1.SQL.Clear;
              QMySQL1.SQL.Add('insert into stats_status_kobus_current_breaks set breakId='+IntToStr(lastBHistId)+' ON DUPLICATE KEY UPDATE breakId='+IntToStr(lastBHistId));
              try
                 QMySQL1.ExecSQL;
              except
                 WriteLog('������ ������ �������������� ������� � �� ubiquiti');
                  WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
                 self.status:=tst_fail;
                 exit;
              end;
            end;
            //currwrited:=insertStatus(equipment_id,status,tmstart,tmend,lastBHistId);
            if WriteStatus(equipment_id,status,tmstart,tmend,IntToStr(lastBHistId)) then begin
                inc(writedRows);
            end else begin
               WriteLog('������ ������ ������� ��� ������������ '+IntToStr(equipment_id));
                WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
                self.status:=tst_fail;
                exit;
            end;
            // ��������� �������� ���������� ������������� ������� � ������� stats_status_settings_kobus
            QMySQL1.SQL.Clear;
            QMySQL1.SQL.Add('update stats_status_settings_kobus set LastBreakageHistoryID='+inttostr(lastBHistId));
            try
                 QMySQL1.ExecSQL;
            except
                 WriteLog('������ ������ �������������� '+IntToStr(breakageId) + ' � ������� stats_status_settings_kobus');
                  WriteLog('���� ���������� '+IntToStr(processedRows)+' ��������. ��������� ������� '+IntToStr(writedRows)+' ������� �� ubiquity');
                  self.status:=tst_fail;
                  exit;
            end;
        end;
        inc(processedRows);
        CurrentPercent:=CurrentPercent+percentByStep;
        FLastBreakageId:=lastBHistId;
        Qpg1.Next;
        // ������ ��������� ��������, ����� �� ����������� �� Ubiquity
        sleep(10);
     end;
     countFindedStatuses:=Qpg1.RecordCount;
     Qpg1.Close;
     if aborted then WriteLog('���������� �������������� ���������� ������');
     // ���� ������������ ����� LimitStatuses �������, ������ �� �������� ��������������
     if (countFindedStatuses<LimitStatuses) and (not aborted) then begin
        // ���������� ��� ���� ������ ������� ����� ���������� ������� ��� ������� � 1
        WriteLastReadyStatusesForEQ;
     end;
     WriteLog('������ ������� ���������. ���������� '+IntToStr(processedRows)+' ��������. �������� '+IntToStr(writedRows)+' �������� � �� ubiquity');
     if tmend>0 then WriteLog('����� ��������� ���������� ������������� �������: '+FormatDateTime('dd.mm.yyyy hh:nn:ss',tmend));
end;


// ��������� ������� ����� �������� dttm
function TTaskGetDrillStatuses.FindMySQLStatusBeforeTime(equipmentId: integer;
  dttm: TDateTime): TMySQLStatus;
  var QMyTemp:TMyADOQuery;
begin
     result.id:=0;
     result.equipmentID:=0;
     result.status:=ms_unknown;
     result.tmstart:=0;
     result.tmend:=0;
     result.asuid:='';
     QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
     try
        QMyTemp.Clear;
        QMyTemp.SQL.Add('select * from stats_status where (id_equipment=@eqid) and (datetimeend<="@dttm")');
        QMyTemp.SQL.Add('order by datetimeend DESC LIMIT 1');
        {QMyTemp.AddParameter('eqid',ftLargeint,equipmentId);
        QMyTemp.AddParameter('dttm',ftString,MySQLDateTime(dttm));}
        QMyTemp.vars.Add('eqid',inttostr(equipmentId));
        QMyTemp.vars.Add('dttm',MySQLDateTime(dttm));
        try
           QMyTemp.Open;
           if QMyTemp.RecordCount>0 then begin
               result.id:=QMyTemp.FieldByName('id').AsLargeInt;
               result.equipmentID:=QMyTemp.FieldByName('id_equipment').AsLargeInt;
               result.status:=QMyTemp.FieldByName('status').AsInteger;
               result.tmstart:=QMyTemp.FieldByName('datetimestart').AsDateTime;
               result.tmend:=QMyTemp.FieldByName('datetimeend').AsDateTime;
               result.asuid:=QMyTemp.FieldByName('asu_id').AsString;
           end;
           QMyTemp.Close;
        except
           WriteLog('������ ������ ��������������� ������� ��� ������������ '+inttostr(equipmentId)+' ��� ������� '+DateTimeToStr(dttm));
        end;
     finally
       FreeAndNil(QMyTemp);
     end;
end;

// ���������� ����� � ������� MySQLStatus � tmstart �� tmend
function TTaskGetDrillStatuses.FreeMySQLStatus(MySQLStatus: TMySQLStatus;
  tmstart, tmend: TDateTime):boolean;
  var f:boolean;
begin
     if tmstart>=tmend then begin
        result:=false;
        exit;
     end;
     f:=true;
     if (tmstart<=MySQLStatus.tmstart) then begin
        if tmend>=MySQLStatus.tmend then begin
           f:=DeleteMysqlStatus(MySQLStatus.id);
        end else begin
           if tmend>MySQLStatus.tmstart then begin
              f:=MoveMySQLStatus(MySQLStatus.id,tmend,MySQLStatus.tmend);
           end;
        end;
     end else begin
        if tmstart<MySQLStatus.tmend then begin
           if tmend>=MySQLStatus.tmend then begin
              f:=MoveMySQLStatus(MySQLStatus.id,MySQLStatus.tmstart,tmstart);
           end else begin
              f:=MoveMySQLStatus(MySQLStatus.id,MySQLStatus.tmstart,tmstart);
              if f then insertMySQLStatus(MySQLStatus.equipmentID,MySQLStatus.status,tmend,MySQLStatus.tmend,MySQLStatus.asuid);
           end;
        end;

     end;
     result:=f;
end;

function TTaskGetDrillStatuses.getEquipmentIdByPriborId(
  priborId: integer): integer;
  var QMy1:TMyADOQuery;
begin
     result:=0;
     try
        QMy1:=TMyADOQuery.Create(nil,connMySQL1);
        QMy1.SQL.Clear;
        QMy1.SQL.Add('select e.id from equipment e, kobus_pribors kp where (kp.pribor_id_kobus='+inttostr(priborId)+') and (e.id=kp.id_equipment)');
        try
          QMy1.Open;
        except
          result:=-1;
          exit;
        end;
        QMy1.Last;
        if QMy1.RecordCount>0 then begin
          result:=QMy1.FieldByName('id').AsInteger;
        end else begin
          result:=0;
        end;
        QMy1.Close;
     finally
        FreeAndNil(QMy1);
     end;
end;

function TTaskGetDrillStatuses.GetMySQlStatuses(equipmentId: Largeint; tmstart,
  tmend: TDateTime): TMySQLStatusList;
  var QMyTemp:TMyADOQuery;
      statuslist:TMySQLStatusList;
  statcount: Integer;
begin
     SetLength(statuslist,0);
     QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
     try
        QMyTemp.SQL.Clear;
        QMyTemp.Clear;
        QMyTemp.SQL.Add('select * from stats_status');
        QMyTemp.SQL.Add('where (id_equipment=@eqid) and ((datetimestart between "@tmstart" and "@tmend")or(datetimeend between "@tmstart" and "@tmend"))');
        QMyTemp.vars.Add('eqid',IntToStr(equipmentId));
        QMyTemp.vars.Add('tmstart',MySQLDateTime(tmstart));
        QMyTemp.vars.Add('tmend',MySQLDateTime(tmend));
        try
           QMyTemp.Open;
           while not QMyTemp.Eof do begin
                 statcount:=Length(statuslist)+1;
                 SetLength(statuslist,statcount);
                 statuslist[statcount-1].id:=QMyTemp.FieldByName('id').AsLargeInt;
                 statuslist[statcount-1].equipmentID:=QMyTemp.FieldByName('id_equipment').AsLargeInt;
                 statuslist[statcount-1].status:=QMyTemp.FieldByName('status').AsInteger;
                 statuslist[statcount-1].tmstart:=QMyTemp.FieldByName('datetimestart').AsDateTime;
                 statuslist[statcount-1].tmend:=QMyTemp.FieldByName('datetimeend').AsDateTime;
                 statuslist[statcount-1].asuid:=QMyTemp.FieldByName('asu_id').AsString;
                 QMyTemp.Next;
           end;
           QMyTemp.Close;
        except on E:Exception do begin
          WriteLog('������ ��������� ������ �������� ��� ������������ id_equipment:'+IntToStr(equipmentId)+'. ����� ������: '+DateTimeToStr(tmstart)+'. ����� ���������: '+DateTimeToStr(tmend));
          WriteLog(E.Message);
        end;
        end;
     finally
         FreeAndNil(QMyTemp);
     end;
     Result:=statuslist;
end;

function TTaskGetDrillStatuses.getStatusByBreak(breakId,
  ParentBreakId: integer): TStatssStatus;
begin
     if ReadyBreaksCategories.Find(ParentBreakId) >=0 then result:=ms_ready else result:=ms_damage;
end;

procedure TTaskGetDrillStatuses.initDBConnections;
begin
      inherited;
      connMySQL1:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
     QMySQL1:=TMyADOQuery.Create(nil,connMySQL1);
     QMySQL2:=TMyADOQuery.Create(nil,connMySQL1);
     connKobus1:=TMyADOConnection.Create(nil,dm1.ConnKobus.ConnectionString);
     Qpg1:=TMyADOQuery.Create(nil,connKobus1);
end;

function TTaskGetDrillStatuses.insertMySQLStatus(equipmentId, status: integer;
  tmstart, tmend: TDatetime; asuid: string):boolean;
var QMyTemp:TMyADOQuery;
begin
     result:=false;
     if (equipmentId<1) or (tmstart>tmend) or (tmstart<0) then begin
        exit;
     end;
     QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
     try
         QMyTemp.Clear;
         QMyTemp.SQL.Add('insert into stats_status (id_equipment,status,datetimestart,datetimeend,asu_id) ');
         QMyTemp.SQL.Add('values(@eqid,@status,"@dttmstart","@dttmend","@asuid")');
         {QMyTemp.AddParameter('eqid',ftLargeint,equipmentId);
         QMyTemp.AddParameter('status',ftInteger,status);
         QMyTemp.AddParameter('dttmstart',ftString,tmstart);
         QMyTemp.AddParameter('dttmend',ftString,tmend);
         QMyTemp.AddParameter('asuid',ftString,asuid);}
         QMyTemp.vars.Add('eqid',inttostr(equipmentId));
         QMyTemp.vars.Add('status',inttostr(status));
         QMyTemp.vars.Add('dttmstart',MySQLDateTime(tmstart));
         QMyTemp.vars.Add('dttmend',MySQLDateTime(tmend));
         QMyTemp.vars.Add('asuid',asuid);
         try
            QMyTemp.ExecSQL;
            if QMyTemp.RowsAffected>0 then result:=true;
         except
            WriteLog('������ ���������� ������� ������������ � �� stats_status');
         end;
     finally
         FreeAndNil(QMyTemp);
     end;
end;

function TTaskGetDrillStatuses.isUsedInMonitoring(eqid: Integer): ShortInt;
{
������� ����������, ������� �� ���������� ��� ������������
���������:
-1 - ����������
0  - ��������
1  - �������
}
var
  QMyTemp: TMyADOQuery;
begin
     try
        QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
        QMyTemp.SQL.Add('select useInMonitoring from equipment where id=@eqid');
        QMyTemp.vars.Add('eqid',IntToStr(eqid));
        try
           QMyTemp.Open;
        except
           WriteLog('������ ��������� ������� ����������� ������������ equipment.id:'+IntToStr(eqid));
           result:=-1;
           exit;
        end;
        if QMyTemp.RecordCount>0 then begin
           if QMyTemp.FieldByName('useInMonitoring').AsInteger=1 then result:=1 else result:=0;
        end else result:=-1;
     finally
       FreeAndNil(QMyTemp);
     end;
end;

{function TTaskGetDrillStatuses.insertStatus(equipmentId, status: integer; tmstart,
  tmend: TDatetime; asuid: integer): integer;
var
  id1: Integer;
begin
     if (equipmentId<1) or (tmstart>tmend) or (tmstart<0) then begin
        result:=-1;
        exit;
     end;
     if QMySQL1.Active then QMySQL1.Close;
     QMySQL1.SQL.Clear;
     QMySQL1.SQL.Add('select id from stats_status where (asu_id="'+inttostr(asuid)+'")');
     QMySQL1.SQL.Add('and (id_equipment='+IntToStr(equipmentId)+')');
     QMySQL1.SQL.Add('order by id');
     try
        QMySQL1.Open;
     except
        result:=-1;
        exit;
     end;
     if QMySQL1.RecordCount>0 then begin
          QMySQL1.Close;
          result:=UpdateStatus(equipmentid,status,tmstart,tmend,asuid);
     end else begin
         QMySQL1.Close;
         QMySQL1.SQL.Clear;
         QMySQL1.SQL.Add('insert into stats_status (id_equipment,status,datetimestart,datetimeend,asu_id) values(');
         QMySQL1.SQL.Add(inttostr(equipmentId)+',');
         QMySQL1.SQL.Add(inttostr(status)+',');
         QMySQL1.SQL.Add('"'+MySQLDateTime(tmstart)+'",');
         QMySQL1.SQL.Add('"'+MySQLDateTime(tmend)+'",');
         QMySQL1.SQL.Add('"'+IntToStr(asuid)+'"');
         QMySQL1.SQL.Add(')');
         try
            QMySQL1.ExecSQL;
            result:=QMySQL1.RowsAffected;
         except
            result:=-1;
         end;
     end;
end;}

function TTaskGetDrillStatuses.MoveMySQLStatus(id: Largeint; newtmstart,
  newtmend: TDateTime):boolean;
var QMyTemp:TMyADOQuery;
begin
    result:=false;
    if (id<1) or (newtmstart>newtmend) then exit;
    QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
    try
       QMyTemp.Clear;
       QMyTemp.SQL.Add('update stats_status set datetimestart="@tmstart", datetimeend="@tmend" where id=@id');
       {QMyTemp.AddParameter('tmstart',ftString,MySQLDateTime(newtmstart));
       QMyTemp.AddParameter('tmend',ftString,MySQLDateTime(newtmend));
       QMyTemp.AddParameter('id',ftLargeint,id);}
       QMyTemp.vars.Add('tmstart',MySQLDateTime(newtmstart));
       QMyTemp.vars.Add('tmend',MySQLDateTime(newtmend));
       QMyTemp.vars.Add('id',inttostr(id));
       try
          QMyTemp.ExecSQL;
          //if QMyTemp.RowsAffected>0 then result:=true;
          result:=true;
       except on E:Exception do begin
            WriteLog('������ ��������� �������');
            WriteLog(E.Message);
       end;
       end;
    finally
      FreeAndNil(QMyTemp);
    end;
end;

procedure TTaskGetDrillStatuses.UpdateNotFinishedBreakages;
var
  QMy1: TMyADOQuery;
  QMy2: TMyADOQuery;
  Qpg: TMyADOQuery;
  breakId: Integer;
  priborId: Integer;
  breakageId: Integer;
  tmstart: TDateTime;
  tmend: TDateTime;
  breakageParentId: Integer;
  equipment_id: Integer;
  status: TStatssStatus;
  dttm1: TDateTime;
  countCurrentBreaks: Integer;
  processedBreaks: Integer;
  finishedBreaks: Integer;
  id1: Integer;
begin
     countCurrentBreaks:=0;
     processedBreaks:=0;
     finishedBreaks:=0;
     WriteLog('����� � �������� ��������� ���������� ������� ��������');
     try
         //CoInitialize(nil);
         QMy1:=TMyADOQuery.Create(nil,connMySQL1);
         QMy2:=TMyADOQuery.Create(nil,connMySQL1);
         Qpg:=TMyADOQuery.Create(nil,connKobus1);
         QMy2.SQL.Clear;
         QMy2.SQL.Add('select breakId from stats_status_kobus_current_breaks');
         QMy2.Open;
         QMy2.Last;
         countCurrentBreaks:=QMy2.RecordCount;
         QMy2.First;
         while (not QMy2.Eof) and (not aborted) do begin
              breakId:=QMy2.FieldByName('breakId').AsInteger;
             Qpg.SQL.Clear;
             Qpg.SQL.Add('select h.id, h.pribor_id, h.breakage_id as breakageId, ');
              Qpg.SQL.Add('h.date_time_begin, h.date_time_end , i.parent_id as break_parent_id ');
             Qpg.SQL.Add('from breaks.breakage_history h ');
             Qpg.SQL.Add('left join api.v_breakage_info i on (h.breakage_id=i.id) ');
             Qpg.SQL.Add('where h.id ='+IntToStr(breakId));
             dttm1:=Now;
             try
                Qpg.Open;
             except
                WriteLog('������ ��������� �������� �� �� �����');
                exit;
             end;
             if Qpg.RecordCount<>0 then begin
               Qpg.First;
               id1:=Qpg.FieldByName('id').AsInteger;
               priborId:=Qpg.FieldByName('pribor_id').AsInteger;
               breakageId:=Qpg.FieldByName('breakageId').AsInteger;
               tmstart:=Qpg.FieldByName('date_time_begin').AsDateTime;
               tmend:=Qpg.FieldByName('date_time_end').AsDateTime;
               breakageParentId:=Qpg.FieldByName('break_parent_id').AsInteger;
               equipment_id:=getEquipmentIdByPriborId(priborId);
               status:=getStatusByBreak(breakageId,breakageParentId);
               if equipment_id>0 then begin
                  if (tmend=0) and (((self.LastRun-tmstart)<30) or (isUsedInMonitoring(equipment_id)=1)) then begin
                     //UpdateStatus(equipment_Id,status,tmstart,dttm1,id1);
                     WriteStatus(equipment_id,status,tmstart,dttm1,inttostr(id1));
                  end else begin
                     if tmend=0 then tmend:=dttm1;
                     WriteStatus(equipment_id,status,tmstart,tmend,inttostr(id1));
                     //UpdateStatus(equipment_Id,status,tmstart,tmend,id1);
                     QMy1.SQL.Clear;
                     QMy1.SQL.Add('delete from stats_status_kobus_current_breaks where breakId='+IntToStr(breakId));
                     try
                      QMy1.ExecSQL;
                      if QMy1.RowsAffected>0 then inc(finishedBreaks);
                     except

                     end;
                  end;
                  inc(processedBreaks);
               end;
             end else begin
                // ���� ������ � id �� �����, ������ ������� ���� id �� ��
                  QMy1.SQL.Clear;
                   QMy1.SQL.Add('delete from stats_status_kobus_current_breaks where breakId='+IntToStr(breakId));
                   try
                    QMy1.ExecSQL;
                   except

                   end;
             end;
             Qpg.Close;

             QMy2.Next;
         end;
     finally
        WriteLog('�������: '+IntToStr(countCurrentBreaks)+'. ����������: '+IntToStr(processedBreaks)+'. ���������: '+IntToStr(finishedBreaks));
        if Assigned(Qpg) then FreeAndNil(Qpg);
        if Assigned(QMy2) then FreeAndNil(QMy2);
        if Assigned(QMy1) then FreeAndNil(QMy1);
        //CoUninitialize;
     end;

end;

{function TTaskGetDrillStatuses.UpdateStatus(equipmentId, status: integer; tmstart,
  tmend: TDateTime; asuid: integer): integer;
begin
     if tmstart>tmend then begin
        Result:=-1;
        exit;
     end;
      QMySQL1.SQL.Clear;
      QMySQL1.SQL.Add('update stats_status set status='+IntToStr(status)+', ');
      QMySQL1.SQL.Add('datetimestart="'+MySQLDateTime(tmstart)+'",');
      QMySQL1.SQL.Add('datetimeend="'+MySQLDateTime(tmend)+'"');
      QMySQL1.SQL.Add(' where (asu_id="'+IntToStr(asuid)+'")');
      QMySQL1.SQL.Add('and (id_equipment='+IntToStr(equipmentId)+')');
      try
           QMySQL1.ExecSQL;
           result:=QMySQL1.RowsAffected;
      except
          result:=-1;
      end;
end;}

procedure TTaskGetDrillStatuses.WriteLastReadyStatusesForEQ;
var
  eqid: Largeint;
  LastStatus:TMySQLStatus;
  f: Boolean;
begin
     // �������� ������ ������������
     QMySQL1.Clear;
     QMySQL1.SQL.Add('select id from equipment where (equipment_type in (5,6)) and (useInMonitoring=1)');
     try
        QMySQL1.Open;
        f:=true;
         while (not QMySQL1.Eof) and f do begin
            eqid:=QMySQL1.FieldByName('id').AsLargeInt;
            LastStatus:=FindMySQLStatusBeforeTime(eqid,Now());
            // ���� ����� �� ���������� ������� ������ ������, �� ���������� ������
            if (LastStatus.id>0) and ((self.LastRun-LastStatus.tmend)>1/24/60) then begin
                if (LastStatus.status=ms_ready) and (LastStatus.asuid='') then begin
                   f:=MoveMySQLStatus(LastStatus.id,LastStatus.tmstart,self.LastRun);
                end else begin
                   f:=insertMySQLStatus(eqid,ms_ready,LastStatus.tmend,self.LastRun,'');
                end;
            end;
            QMySQL1.Next;
         end;
     except
        WriteLog('������ ��������� ������ ���������� � ��� ��� ������ ��������� ����������');
        exit;
     end;

     QMySQL1.Close;
end;

function TTaskGetDrillStatuses.WriteStatus(equipmentId, status: integer;
  tmstart, tmend: TDatetime; asuid: string): boolean;
var MySQLStatusesintm:TMySQLStatusList;
    i:integer;
  currstatnum: Integer;
    MySQLStatusBefore:TMySQLStatus;
    f:Boolean;
begin
     result:=true;
     if tmstart>tmend then begin
        WriteLog('����� ������ ������� '+DatetimeToStr(tmstart)+' ����� ������� ��������� ������� '+DateTimeToStr(tmend));
        Result:=false;
        exit;
     end;
     f:=false;
     MysqlStatusesintm:=GetMySQlStatuses(equipmentId,tmstart,tmend);
     currstatnum:=-1;
     for I := 0 to Length(MySQLStatusesintm)-1 do begin
         // ������� ������ ������, ������� ������������ � �������
         if (currstatnum=-1) and (asuid=MysqlStatusesintm[i].asuid) then begin
            // ����� �������, ��� �������� asu_id ��������� ���������. ��� ����� �������������� ����� ���������
            currstatnum:=i;
            f:=true;
         end else begin
            f:=FreeMySQLStatus(MysqlStatusesintm[i],tmstart,tmend);
         end;
         if not f then begin
            WriteLog('������ ������������ ������� � '+DatetimeToStr(tmstart)+' �� '+DateTimeToStr(tmend)+' ��� ������ �������');
            result:=false;
            exit;
         end;
     end;
     // ���� ����� ������, �� �������������� ���, ���� ���, �� ��������� ����� ������
     if currstatnum>-1 then begin
        f:=MoveMySQLStatus(MysqlStatusesintm[currstatnum].id,tmstart,tmend);
     end else begin
        f:=insertMySQLStatus(equipmentId,status,tmstart,tmend,asuid);
     end;
     if not f then begin
        WriteLog('������ ������ � �� �������. id ������������:'+inttostr(equipmentId)+', ������:'+datetimetostr(tmstart)+', �����:'+datetimetostr(tmend)+', ������:'+IntToStr(status)+', asuid:'+asuid);
        result:=false;
        exit;
     end;
     // ���� ��������� ������, ������� ��� �� ��������
     MySQLStatusBefore:=FindMySQLStatusBeforeTime(equipmentId,tmstart);
     // ���� ������ ������, ���������� � ������� ������� ������ �����
     if MySQLStatusBefore.id>0 then begin
        if (tmstart-MySQLStatusBefore.tmend)>=2/24/3600 then begin
           if (MySQLStatusBefore.status=ms_ready) and (MySQLStatusBefore.asuid='') then begin
              MoveMySQLStatus(MySQLStatusBefore.id,MySQLStatusBefore.tmstart,tmstart);
           end else begin
              insertMySQLStatus(equipmentId,ms_ready,MySQLStatusBefore.tmend,tmstart,'');
           end;
        end;
     end;
end;

{ TTaskGenerateImagePitD6 }

procedure TTaskGenerateImagePitD6.CalculateNextRun;
var dttm:TDateTime;
    hour,min,sec,MSec:word;
    dttm1:TDateTime;
    difftime:real;
begin
  // ��� ��� dump_ddb ����������� ������ ��� � 24 ������,
  // �� ������ ����� ��������� � 25 ����� ������� ����
  dttm:=Now;
  DecodeTime(dttm,hour,min,sec,MSec);
  if min<25 then difftime:=0 else difftime:=1/24;
  NextRun:=trunc(dttm)+EncodeTime(hour,25,0,0)+difftime;
end;

procedure TTaskGenerateImagePitD6.CloseConnections;
begin
  inherited;
  try
      connD6.Close;
  finally
      WriteLog('������ �������� ����������� � ��');
  end;

end;

function TTaskGenerateImagePitD6.ConvertToCanvas( Point : TPoint): TPoint;
begin
      result.x :=round((Point.X-FPGStartX)/FScaleImageToMeters);
      result.y :=imagePitgraph.Height - round((point.Y-FPGStartY)/FScaleImageToMeters);
end;

constructor TTaskGenerateImagePitD6.Create(owner:TTaskThread;sleeptimesec:integer;runnow:boolean=true);
var koefDiag:real;
    destdir:string;
begin
     inherited Create(owner,sleeptimesec,runnow);
     Name:='GenerateImagePitD6';
     DisplayName:='��������� ����� ������� Dispatch 6';
     LogFileName:=ExtractFilePath(Application.ExeName)+ Name+'Log.txt';
     self.DestDir:='Z:\Map\';
     self.DestFileName:='pitgraph.png';
     FPGStartX:=12000;
     FPGEndX:=17000;
     FPGStartY:=2000;
     FPGEndY:=6000;
     FillColor:=clWhite;
     DrawColor:=clBlack;
     FImageWidth:=4096;
     koefDiag:=(FPGEndX-FPGStartX)/(FPGEndY-FPGStartY);
     FImageHeight:=Round(FImageWidth/koefDiag);
     FScaleImageToMeters:=(FPGEndX-FPGStartX)/FImageWidth;
     FGenerateImage:=true;
     DrawControlPoints:=true;
end;

procedure TTaskGenerateImagePitD6.paintExcavs;
var
  SourceExcavTemp: string;
  fExcavs: TextFile;
  currentnum: Integer;
  linefl:string;
  i:integer;
  num:integer;
  exinfo:TExcavInfo;
  valueindex: Integer;
begin
     WriteLog('��������� �������������� ������������');
     QSQL1.Clear;
     QSQL1.SQL.Add('select FieldId, FieldXloc,FieldYLoc,FieldLastGPSUpdate from dbo.PitExcav');
     try
        QSQL1.Open;
     except
        WriteLog('������ ��������� ������ ������������ �� �� D6');
        Status:=tst_fail;
        exit;
     end;
     while (not QSQL1.Eof) and (not self.Aborted) do begin
        exinfo.name:=QSQL1.FieldByName('FieldId').AsString;
        exinfo.x:=QSQL1.FieldByName('FieldXLoc').AsInteger;
        exinfo.y:=QSQL1.FieldByName('FieldYLoc').AsInteger;
        exinfo.lastgpstime:=QSQL1.FieldByName('FieldLastGPSUpdate').AsLargeInt;
        DrawExcav(exinfo);
        QSQL1.Next;
     end;
     QSQL1.Close;
     if aborted then begin
            WriteLog('���������� �������������� ���������� ������');
            exit;
     end;
     WriteLog('��������� �������� �������������� ������������');
end;

procedure TTaskGenerateImagePitD6.DrawPitloc(name: string; xm, ym: integer; unitid:integer);
var picx, picy:integer;
    str1:string;
    isContolPoint:boolean;
    isZa:boolean;
begin
     picx:=round((xm-FPGStartX)/FScaleImageToMeters);
     picy:=imagePitgraph.Height - round((ym-FPGStartY)/FScaleImageToMeters);
     try
       self.imagePitgraph.Canvas.Lock;
       self.imagePitgraph.Canvas.Pen.Color:=DrawColor;
       self.imagePitgraph.Canvas.Brush.Style:=bsSolid;
       self.imagePitgraph.Canvas.Pen.Style:=psSolid;
       self.imagePitgraph.Canvas.Ellipse(picx-2,picy-2,picx+2,picy+2);
       //sleep(20);
       {if ((name[1]='D') or (name[1]='M')) then isContolPoint:=true else isContolPoint:=false;
       if (name[1]='Z') then isZa:=true else isZa:=false;}
       if unitid=235 then isContolPoint:=true else isContolPoint:=false;
       if unitid=232 then isZa:=true else isZa:=false;

       // ������� �������� ������� ���� �����
       if (not isContolPoint or DrawControlPoints) and (not isZa or not Self.ShowExcavs) then begin
         self.imagePitgraph.Canvas.Font.Size:=TextSize;
         self.imagePitgraph.Canvas.Font.Color:=DrawColor;
         self.imagePitgraph.Canvas.Brush.Style:=bsClear;
         self.imagePitgraph.Canvas.TextOut(picx+3,picy+3,name);
         //sleep(20);
       end;
       //self.imagePitgraph.SaveToFile(DestinationFileName+'.bmp');
       // ���� �������� �����: �������� � ��������� ����, �� ���������� � ���� � ��������� ����
       // ��� D6 �� ���������. ����� ����� �� ��
       {if FGenerateTextData then begin
          SaveToFile(FpitlocTemp,name+':'+IntToStr(xm)+':'+IntToStr(ym));
       end;}
     finally
       self.imagePitgraph.Canvas.Unlock;
     end;
end;

function TTaskGenerateImagePitD6.DrawPitlocs:boolean;
var
  countdraw: Integer;
  currentId: string;
  currentx: Integer;
  currenty: Integer;
  countRecords:integer;
  unitid: Integer;
begin
     result:=true;
     WriteLog('������ �������� ������� ��������');
     //tempPitloc:=TStringList.Create;
     //tempPitloc.Clear;

     {if FGenerateTextData then WriteLog('����� �������� ������ � ��������� ���� ��������')
        else WriteLog('����� �������� ������ � ��������� ���� ���������');}
     countdraw:=0;
     QSQL1.Clear;
     QSQL1.SQL.Add('select FieldId, FieldXloc, FieldYLoc, FieldUnit from PITPitloc where FieldRegion>0');
     try
        QSQL1.Open;
     except
        WriteLog('������ ��������� ������ �������� �������');
        Status:=tst_fail;
        result:=false;
        exit;
     end;
     countRecords:=QSQL1.RecordCount;
     while (not QSQL1.Eof) and ( not aborted ) do begin
        currentId:=QSQL1.FieldByName('FieldId').AsString;
        currentx:=QSQL1.FieldByName('FieldXloc').AsInteger;
        currenty:=QSQL1.FieldByName('FieldYloc').AsInteger;
        unitid:=QSQL1.FieldByName('FieldUnit').AsInteger;
        if (currentid<>'PIT') then begin
            //tempPitloc.Add(currentid+':'+inttostr(currentx)+':'+inttostr(currenty));
            if (pos('PD',currentid)=0) then begin
              DrawPitloc(currentid,currentX,currentY,unitid);
              inc(countdraw);
            end;
        end;
        QSQL1.Next;
     end;
     if QSQL1.Active then QSQL1.Close;
     WriteLog('������� '+IntToStr(countRecords)+' �������� �������. ���������� '+IntToStr(countdraw)+' ��������');
end;

procedure TTaskGenerateImagePitD6.DrawRoad(startid, endid: string; startx, starty, endx,
  endy: integer; roadpoints: TLocPoints; closed:boolean=false);
var isline:boolean;
  i1: Integer;
  pnts: array of TPoint;
  point1, PointConverted:TPoint;
  roadpointsstr:string;
begin
     try
         self.imagePitgraph.Canvas.Lock;
         roadpointsstr:='';
         if (roadpoints[0].x=1) then isline:=false else isline:=true;
         self.imagePitgraph.Canvas.Pen.Color:=DrawColor;
         if closed then begin
            self.imagePitgraph.Canvas.Pen.Style:=psDot;
            self.imagePitgraph.Canvas.Pen.Color:=clRed;
         end
         else begin
            self.imagePitgraph.Canvas.Pen.Style:=psSolid;
         end;
         if isline then begin
            point1.X:=startx;
            point1.Y:=starty;
            PointConverted:=ConvertToCanvas(point1);
            self.imagePitgraph.Canvas.MoveTo(PointConverted.X,PointConverted.Y);
            point1.X:=endx;
            point1.Y:=endy;
            PointConverted:=ConvertToCanvas(point1);
            self.imagePitgraph.Canvas.LineTo(PointConverted.X,PointConverted.Y);
            //sleep(20);
         end else begin
            // ������ ������
            // ������ �������� �� ������ �����. ������ �� ��������� � �������
            point1.X:=startx;
            point1.Y:=starty;
            pointConverted:=ConvertToCanvas(point1);
            SetLength(pnts,1);
            pnts[high(pnts)]:=PointConverted;
            i1:=1;
            while (roadpoints[i1].x <>0 ) and (roadpoints[i1].y <>0 ) do begin
                  point1:=roadpoints[i1];
                  pointConverted:=ConvertToCanvas(point1);
                  SetLength(pnts,Length(pnts)+1);
                  pnts[high(pnts)]:=PointConverted;
                  inc(i1);
                  roadpointsstr:=roadpointsstr+':'+inttostr(point1.X)+':'+inttostr(point1.Y);
            end;
            point1.X:=endx;
            point1.y:=endy;
            PointConverted:=ConvertToCanvas(point1);
            SetLength(pnts,Length(pnts)+1);
            pnts[high(pnts)]:=PointConverted;
            self.imagePitgraph.Canvas.PolyBezier(pnts);
            //sleep(20);
            {if not PolyBezier(self.imagePitgraph.Canvas.Handle,pnts,Length(pnts)) then begin
               Application.MessageBox('������ ��������� ������ �����','������');
               exit;
            end;}
         end;
         // ��� D6 �� ���������. ������ ����� ����� �� ��.
         {if FGenerateTextData then begin
            SaveToFile(FRoadsTemp,startid+':'+endid+':'+inttostr(startx)+':'+inttostr(starty)+':'+inttostr(endx)+':'+inttostr(endy)+roadpointsstr);
         end;}
         self.imagePitgraph.Canvas.Pen.Style:=psSolid;
         self.imagePitgraph.Canvas.Pen.Color:=DrawColor;
     finally
         self.imagePitgraph.Canvas.Unlock;
     end;
end;

function TTaskGenerateImagePitD6.DrawRoads: boolean;
var
  recordscount: Integer;
  Locstart_id: string;
  locend_id: string;
  startx: Integer;
  starty: Integer;
  endx: Integer;
  endy: Integer;
  closed: Boolean;
  roadpoints: TLocPoints;
  i: Integer;
  countdraw: Integer;
begin
     WriteLog('������ �������� ������� �����');
     if QSQL1.Active then QSQL1.Close;
     QSQL1.Clear;
     QSQL1.SQL.Add('SELECT 	pt.id, plstart.FieldId as startId, plstart.FieldXloc as startx,	plstart.FieldYloc as starty,');
	   QSQL1.SQL.Add('plend.FieldId as endId, plend.FieldXloc as endx, plend.FieldYloc as endy, pt.FieldClosed,');
     QSQL1.SQL.Add('(select [value] from PITTravelXgraphArray where (id=pt.id) and ([index]=1)) as xm1,');
     QSQL1.SQL.Add('(select [value] from PITTravelYgraphArray where (id=pt.id) and ([index]=1)) as ym1,');
     QSQL1.SQL.Add('(select [value] from PITTravelXgraphArray where (id=pt.id) and ([index]=2)) as xm2,');
     QSQL1.SQL.Add('(select [value] from PITTravelYgraphArray where (id=pt.id) and ([index]=2)) as ym2');
     QSQL1.SQL.Add('FROM PITTravel pt inner join PITPitloc plstart on (pt.FieldLocstart=plstart.id)');
     QSQL1.SQL.Add('inner join PITPitloc plend on (pt.FieldLocend=plend.id)');
     try
        QSQL1.Open;
     except
        WriteLog('������ ��������� ������ �����');
        result:=false;
        Status:=tst_fail;
        exit;
     end;
     countdraw:=0;
     recordscount:=QSQL1.RecordCount;
     for i := 0 to 9 do begin
         roadpoints[i].x:=0;
         roadpoints[i].y:=0;
     end;
     while (not QSQL1.Eof) and (not aborted) do begin
        Locstart_id:=QSQL1.FieldByName('startId').AsString;
        locend_id:=QSQL1.FieldByName('endId').AsString;
        startx:=QSQL1.FieldByName('startx').AsInteger;
        starty:=QSQL1.FieldByName('starty').AsInteger;
        endx:=QSQL1.FieldByName('endx').AsInteger;
        endy:=QSQL1.FieldByName('endy').AsInteger;
        if (QSQL1.FieldByName('xm1').AsLargeInt<2147483647) and (QSQL1.FieldByName('ym1').AsLargeInt<2147483647) and (QSQL1.FieldByName('xm2').AsLargeInt<2147483647) and (QSQL1.FieldByName('ym2').AsLargeInt<2147483647) then
        begin
          roadpoints[0].X:=1;
          roadpoints[0].Y:=1;
          roadpoints[1].X:=QSQL1.FieldByName('xm1').AsLargeInt;
          roadpoints[1].Y:=QSQL1.FieldByName('ym1').AsLargeInt;
          roadpoints[2].X:=QSQL1.FieldByName('xm2').AsLargeInt;
          roadpoints[2].Y:=QSQL1.FieldByName('ym2').AsLargeInt;
        end else begin
          roadpoints[0].X:=0;
          roadpoints[0].Y:=0;
          roadpoints[1].X:=0;
          roadpoints[1].Y:=0;
          roadpoints[2].X:=0;
          roadpoints[2].Y:=0;
        end;
        if QSQL1.FieldByName('FieldClosed').Asinteger<>0 then closed:=true else closed:=false;
        DrawRoad(Locstart_id,locend_id,startx,starty,endx,endy,roadpoints, closed);
        inc(countdraw);
        QSQL1.Next;
     end;
     QSQL1.Close;
     WriteLog('������� '+IntToStr(recordscount)+' �����. ���������� '+IntToStr(countdraw)+' �����.');
     result:=true;
end;

// �������� �����������, ���������� ������� ���� �������� �� ����� ������ �����.
// ���� ������� ��������� ������ �����, �� ������������ �������� ������� ������, ���� ������� ������ �����, �� ������� ������


procedure TTaskGenerateImagePitD6.DestroyDBConnections;
begin
  inherited;
  if Assigned(QSQL1) then begin
     if QSQL1.Active then QSQL1.Close;
     FreeAndNil(QSQL1);
  end;
  if Assigned(ConnD6) then FreeAndNil(ConnD6);
end;

procedure TTaskGenerateImagePitD6.DrawExcav(exinfo:TExcavinfo);
var picx, picy:integer;
    str1:string;
    isContolPoint:boolean;
  tmNow: longint;
begin
     if exinfo.lastgpstime<1 then exit;
     picx:=round((exinfo.x-FPGStartX)/FScaleImageToMeters);
     picy:=self.imagePitgraph.Height - round((exinfo.y-FPGStartY)/FScaleImageToMeters);
     tmNow:=DateTimeToTimeStamp1970(Now());
     if (tmNow-exinfo.lastgpstime)<(30*24*3600) then begin
         if (tmNow-exinfo.lastgpstime)>(1*24*3600) then self.imagePitgraph.Canvas.Pen.Color:=clRed else self.imagePitgraph.Canvas.Pen.Color:=clGreen;
         self.imagePitgraph.Canvas.Lock;
         try
             self.imagePitgraph.Canvas.Ellipse(picx-3,picy-3,picx+3,picy+3);
             //sleep(20);
             // ������� �������� ������� ���� �����
             self.imagePitgraph.Canvas.Font.Size:=TextSize;
             self.imagePitgraph.Canvas.Font.Color:=self.imagePitgraph.Canvas.Pen.Color;
             self.imagePitgraph.Canvas.Brush.Style:=bsClear;
             self.imagePitgraph.Canvas.TextOut(picx+3,picy+3,exinfo.name);
             //sleep(20);
             self.imagePitgraph.Canvas.Brush.Style:=bsSolid;
             self.imagePitgraph.Canvas.Font.Color:=DrawColor;
             self.imagePitgraph.Canvas.Pen.Color:=DrawColor;
         finally
             self.imagePitgraph.Canvas.Unlock;
         end;
     end;
end;

procedure TTaskGenerateImagePitD6.ExecuteTask;
var
  errorstr: string;
  pngimg:Tpngimage;
begin
     errorstr:='';
     WriteLog('������ '+self.Name+' ��������');
     if DirectoryExists(self.DestDir) then begin
        FDestinationFileName:=self.DestDir+Self.DestFileName;
     end else begin
        WriteLog('���������� '+self.DestDir+' ����������. ����� ����� �������� � ���������� � ����������.');
        FDestinationFileName:=ExtractFilePath(Application.ExeName)+ self.DestFileName;
     end;
     try
       self.imagePitgraph:=TBitmap.Create;
       //sleep(100);
       self.imagePitgraph.Height:=FImageHeight;
       self.imagePitgraph.Width:=FImageWidth;
       self.imagePitgraph.TransparentMode:=tmAuto;
       self.imagePitgraph.TransparentColor:=clWhite;
       try
           self.imagePitgraph.Canvas.Lock;
           self.imagePitgraph.Canvas.Pen.Color:=FillColor;
           self.imagePitgraph.Canvas.Brush.Color:=FillColor;
           self.imagePitgraph.Canvas.Brush.Style:=bsSolid;
           self.imagePitgraph.Canvas.Rectangle(0,0,self.imagePitgraph.Width,self.imagePitgraph.Height);
       finally
           self.imagePitgraph.Canvas.Unlock;
       end;
     except
       WriteLog('������ ��� �������� ������� � ������');
       WriteLog('������ ��������� ');
       WriteLog('------------------'+#13#10);
       Status:=tst_fail;
       FreeAndNil(self.imagePitgraph);
       exit;
     end;
     // ������ ������� ��������
     if not DrawPitlocs then begin
        Status:=tst_fail;
        exit;
     end;
     if aborted then begin
       WriteLog('���������� �������������� ���������� ������');
       exit;
     end;

     // ������ ������� �����
     if not DrawRoads then begin
        status:=tst_fail;
        exit;
     end;
     if aborted then begin
       WriteLog('���������� �������������� ���������� ������');
       exit;
     end;
     // [2021-09-22] ������ ������� ������������
     if self.ShowExcavs then begin
        paintExcavs;
     end;
     if aborted then begin
       WriteLog('���������� �������������� ���������� ������');
       exit;
     end;
     // ���� ����� ���������, �������� ���� � ����� ��������� �����
     if DrawLabel then begin
       self.imagePitgraph.Canvas.Lock;
       try
           self.imagePitgraph.Canvas.Font.Size:=TextSize;
           self.imagePitgraph.Canvas.Font.Color:=DrawColor;
           self.imagePitgraph.Canvas.Brush.Style:=bsClear;
           self.imagePitgraph.Canvas.TextOut(10,10,FormatDateTime('dd.mm.yy hh:nn',Now));
       finally
           self.imagePitgraph.Canvas.Unlock;
       end;
     end;

     WriteLog('�������� ��������� ����� '+FDestinationFileName);
     pngimg:=TPngImage.Create;
     try
      try

        pngimg.Assign(self.imagePitgraph);
        pngImg.SaveToFile(FDestinationFileName);
        //sleep(500);
        //FreeAndNil(pngImg);
      except
        WriteLog('������ ��� ���������� �����');
      end;
     finally
        FreeAndNil(pngImg);
        //pngimg.Free;
        //pngimg:=nil;
     end;
     FreeAndNil(self.imagePitgraph);
     WriteLog('��������� ���������� ������');
     WriteLog('------------------'+#13#10);
end;

procedure TTaskGenerateImagePitD6.initDBConnections;
begin
  inherited;
   ConnD6:=TMyADOConnection.Create(nil,dm1.tplConnD6.ConnectionString);
   QSQL1:=TMyADOQuery.Create(nil,ConnD6);
end;

{ TTaskGenerateImagePitD6ASUGTK }

procedure TTaskGenerateImagePitD6ASUGTK.CalculateNextRun;
begin
     inherited;
    // �������� � ������������ ������� ������, ����� ������ ��������� �� ����������� ������
    NextRun:=NextRun+1/24/60;
end;

constructor TTaskGenerateImagePitD6ASUGTK.Create(owner: TTaskThread;
  sleeptimesec: integer; runnow: boolean);
var
  koefDiag: real;
begin
      inherited Create(owner,sleeptimesec,runnow);
     Name:='GenerateImagePitD6ASUGTK';
     DisplayName:='��������� ����� ������� Dispatch 6 ��� ������';
     self.DestDir:='W:\�����\������� ��� ���\';
     self.DestFileName:='Map.png';
     LogFileName:=ExtractFilePath(Application.ExeName)+ Name+'Log.txt';
     {FPGStartX:=12200;
     FPGEndX:=16300;
     FPGStartY:=2100;
     FPGEndY:=5800;
     FillColor:=clWhite;
     DrawColor:=clBlack;}
     FImageWidth:=1280;
     koefDiag:=(FPGEndX-FPGStartX)/(FPGEndY-FPGStartY);
     FImageHeight:=Round(FImageWidth/koefDiag);
     FScaleImageToMeters:=(FPGEndX-FPGStartX)/FImageWidth;
     FGenerateImage:=true;
     DrawControlPoints:=false;
     {ConnD6:=TMyADOConnection.Create(nil,dm1.tplConnD6.ConnectionString);
     QSQL1:=TMyADOQuery.Create(nil,ConnD6);}
     TextSize:=7;
     DrawLabel:=true;
     ShowExcavs:=true;
end;

{ TTaskGetDispatch6Statuses }

procedure TTaskGetDispatch6Statuses.CloseConnections;
begin
  inherited;
  try
        self.connMySQL1.Close;
        self.connD6.Close;
  except
        WriteLog('������ �������� ���������� c ��');
  end;
end;

constructor TTaskGetDispatch6Statuses.Create(owner: TTaskThread;
  sleeptimesec: integer; runnow: boolean);
begin
  inherited Create(owner,sleeptimesec,runnow);
     DisplayName:='��������� �������� ������� ������ Dispatch 6';
end;

function TTaskGetDispatch6Statuses.DeleteMySQLStatus(id: Largeint): boolean;
var QMyTemp:TMyADOQuery;
begin
     result:=false;
     QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
     try
        QMyTemp.Clear;
        QMyTemp.SQL.Add('delete from stats_status where id=@id');
        //QMyTemp.AddParameter('id',ftLargeint,id);
        QMyTemp.vars.Add('id',IntToStr(id));
        try
           QMyTemp.ExecSQL;
           if QMyTemp.RowsAffected>0 then result:=true;
           result:=true;
        except
           WriteLog('������ �������� ������� id: '+IntToStr(id));
        end;
     finally
        FreeAndNil(QMyTemp);
     end;
end;

destructor TTaskGetDispatch6Statuses.Destroy;
begin
  inherited;
end;

procedure TTaskGetDispatch6Statuses.DestroyDBConnections;
begin
    if Assigned(self.QD6statuses) then begin
       if self.QD6statuses.Active then self.QD6statuses.Close;
       FreeAndNil(self.QD6statuses);
    end;
    if Assigned(self.connD6) then FreeAndNil(self.connD6);
    if Assigned(Self.QMySQL1) then begin
        if self.QMySQL1.Active then self.QMySQL1.Close;
        FreeAndNil(self.QMySQL1);
    end;
    if Assigned(self.QMyActiveEquipment) then FreeAndNil(self.QMyActiveEquipment);
    if Assigned(self.connMySQL1) then FreeAndNil(self.connMySQL1);
end;

procedure TTaskGetDispatch6Statuses.ExecuteTask;
var
  eqid: Largeint;
  eqname: string;
  FirstStateId: Largeint;
  //currStatus:TModularStatus;
begin
     // �������� ������ ��������� ������������ ������
     if self.QMyActiveEquipment.Active then self.QMyActiveEquipment.Close;
     self.QMyActiveEquipment.Clear;
     self.QMyActiveEquipment.SQL.Add('select e.id, e.name, sssd6.LastStateID from equipment e ');
     self.QMyActiveEquipment.SQL.Add('left join stats_status_settings_dispatch6 sssd6 on (e.id=sssd6.id_equipment)');
     self.QMyActiveEquipment.SQL.Add('where equipment_type in (1,2) and (useInMonitoring=1)');
     self.QMyActiveEquipment.SQL.Add('order by name');
     try
         self.QMyActiveEquipment.Open;
     except
         on E:Exception do begin
            WriteLog('������ ��������� ������ ������������ �� �� ubiquiti');
            WriteLog(E.Message);
            Status:=tst_fail;
            exit;
         end;
     end;
     PercentBy1EQ:=100/self.QMyActiveEquipment.RecordCount;
     while (not self.QMyActiveEquipment.Eof) and (not self.Aborted) do begin
         eqid:=self.QMyActiveEquipment.FieldByName('id').AsLargeInt;
         eqname:=self.QMyActiveEquipment.FieldByName('name').AsString;
         FirstStateId:=self.QMyActiveEquipment.FieldByName('LastStateID').AsLargeInt;
         // ������������ ������� ��� ������� �������
         WriteStatusesForEquipment(eqid,eqname,FirstStateId);
         self.QMyActiveEquipment.Next;
     end;
     self.QMyActiveEquipment.Close;
     status:=tst_success;
end;

function TTaskGetDispatch6Statuses.FreeMySQLStatus(MySQLStatus: TMySQLStatus;
  tmstart, tmend: TDateTime): boolean;
  var f:boolean;
begin
     if tmstart>=tmend then begin
        result:=false;
        exit;
     end;
     f:=true;
     if (tmstart<=MySQLStatus.tmstart) then begin
        if tmend>=MySQLStatus.tmend then begin
           f:=DeleteMysqlStatus(MySQLStatus.id);
        end else begin
           if tmend>MySQLStatus.tmstart then begin
              f:=MoveMySQLStatus(MySQLStatus.id,tmend,MySQLStatus.tmend);
           end;
        end;
     end else begin
        if tmstart<MySQLStatus.tmend then begin
           if tmend>=MySQLStatus.tmend then begin
              f:=MoveMySQLStatus(MySQLStatus.id,MySQLStatus.tmstart,tmstart);
           end else begin
              f:=MoveMySQLStatus(MySQLStatus.id,MySQLStatus.tmstart,tmstart);
              if f then insertMySQLStatus(MySQLStatus.equipmentID,MySQLStatus.status,tmend,MySQLStatus.tmend,MySQLStatus.asuid,MySQLStatus.reasonname);
           end;
        end;

     end;
     result:=f;
end;

function TTaskGetDispatch6Statuses.GetMySQlStatuses(equipmentId:integer; tmstart,
  tmend:TDateTime): TMySQLStatusList;
  var QMyTempD6s:TMyADOQuery;
      statuslist:TMySQLStatusList;
  statcount: Integer;
begin
     SetLength(statuslist,0);
     QMyTempD6s:=TMyADOQuery.Create(nil,self.connMySQL1);
     try
        QMyTempD6s.Clear;
        QMyTempD6s.SQL.Add('select * from stats_status');
        QMyTempD6s.SQL.Add('where (id_equipment=@eqid) and ((datetimestart between "@tmstart" and "@tmend")or(datetimeend between "@tmstart" and "@tmend"))');
        QMyTempD6s.vars.Add('eqid',IntToStr(equipmentId));
        QMyTempD6s.vars.Add('tmstart',MySQLDateTime(tmstart));
        QMyTempD6s.vars.Add('tmend',MySQLDateTime(tmend));
        try
           QMyTempD6s.Open;
           while not QMyTempD6s.Eof do begin
                 statcount:=Length(statuslist)+1;
                 SetLength(statuslist,statcount);
                 statuslist[statcount-1].id:=QMyTempD6s.FieldByName('id').AsLargeInt;
                 statuslist[statcount-1].equipmentID:=QMyTempD6s.FieldByName('id_equipment').AsLargeInt;
                 statuslist[statcount-1].status:=QMyTempD6s.FieldByName('status').AsInteger;
                 statuslist[statcount-1].tmstart:=QMyTempD6s.FieldByName('datetimestart').AsDateTime;
                 statuslist[statcount-1].tmend:=QMyTempD6s.FieldByName('datetimeend').AsDateTime;
                 statuslist[statcount-1].asuid:=QMyTempD6s.FieldByName('asu_id').AsString;
                 statuslist[statcount-1].reasonname:=QMyTempD6s.FieldByName('reason_name').AsString;
                 QMyTempD6s.Next;
           end;
           QMyTempD6s.Close;
        except on E:Exception do begin
          WriteLog('������ ��������� ������ �������� ��� ������������ id_equipment:'+IntToStr(equipmentId)+'. ����� ������: '+DateTimeToStr(tmstart)+'. ����� ���������: '+DateTimeToStr(tmend));
          WriteLog(E.Message);
        end;
        end;
     finally
         if Assigned(QMyTempD6s) then FreeAndNil(QMyTempD6s);
     end;
     Result:=statuslist;
end;

procedure TTaskGetDispatch6Statuses.initDBConnections;
begin
     self.connMySQL1:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
     self.QMyActiveEquipment:=TMyADOQuery.Create(nil,connMySQL1);
     self.QMySQL1:=TMyADOQuery.Create(nil,connMySQL1);
     //QMySQL2:=TMyADOQuery.Create(nil,connMySQL1);
     self.connD6:=TMyADOConnection.Create(nil,dm1.tplConnD6.ConnectionString);
     self.QD6statuses:=TMyADOQuery.Create(nil,connD6);
end;

function TTaskGetDispatch6Statuses.insertMySQLStatus(equipmentId,
  status: integer; tmstart, tmend: TDatetime; asuid: string; reasonname:string): boolean;
var QMyTemp:TMyADOQuery;
begin
     result:=false;
     if (equipmentId<1) or (tmstart>tmend) or (tmstart<0) then begin
        exit;
     end;
     QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
     try
         QMyTemp.Clear;
         QMyTemp.SQL.Add('insert into stats_status (id_equipment,status,datetimestart,datetimeend,asu_id,reason_name) ');
         QMyTemp.SQL.Add('values(@eqid,@status,"@dttmstart","@dttmend","@asuid","@reasonname")');
         QMyTemp.vars.Add('eqid',inttostr(equipmentId));
         QMyTemp.vars.Add('status',inttostr(status));
         QMyTemp.vars.Add('dttmstart',MySQLDateTime(tmstart));
         QMyTemp.vars.Add('dttmend',MySQLDateTime(tmend));
         QMyTemp.vars.Add('asuid',asuid);
         QMyTemp.vars.Add('reasonname',reasonname);
         try
            QMyTemp.ExecSQL;
            if QMyTemp.RowsAffected>0 then result:=true;
         except
            on E:exception do begin
               WriteLog('������ ���������� ������� ������������ � �� stats_status');
               WriteLog(E.Message);
            end;
         end;
     finally
         if Assigned(QMyTemp) then FreeAndNil(QMyTemp);
     end;
end;

function TTaskGetDispatch6Statuses.MoveMySQLStatus(id: Largeint; newtmstart,
  newtmend: TDateTime): boolean;
var QMyTemp:TMyADOQuery;
begin
    result:=false;
    if (id<1) or (newtmstart>newtmend) then exit;
    QMyTemp:=TMyADOQuery.Create(nil,connMySQL1);
    try
       QMyTemp.Clear;
       QMyTemp.SQL.Add('update stats_status set datetimestart="@tmstart", datetimeend="@tmend" where id=@id');
       QMyTemp.vars.Add('tmstart',MySQLDateTime(newtmstart));
       QMyTemp.vars.Add('tmend',MySQLDateTime(newtmend));
       QMyTemp.vars.Add('id',inttostr(id));
       try
          QMyTemp.ExecSQL;
          //if QMyTemp.RowsAffected>0 then result:=true;
          result:=true;
       except on E:Exception do begin
            WriteLog('������ ��������� �������');
            WriteLog(E.Message);
       end;
       end;
    finally
      if Assigned(QMyTemp) then FreeAndNil(QMyTemp);
    end;
end;

function TTaskGetDispatch6Statuses.WriteLastStatusId(equipmentid:integer;
  asuid:int64): boolean;
begin
     result:=false;
     self.QMySQL1.Clear;
     self.QMySQL1.SQL.Add('insert into stats_status_settings_dispatch6 (id_equipment,LastStateID) Values (@eqid,@asuid)');
     self.QMySQL1.SQL.Add('ON DUPLICATE KEY UPDATE LastStateID=@asuid');
     self.QMySQL1.vars.Add('eqid',IntToStr(equipmentid));
     self.QMySQL1.vars.Add('asuid',IntToStr(asuid));
     try
        self.QMySQL1.ExecSQL;
        result:=true;
     except
        WriteLog('������ ���������� ���������� ��������� ��� ��������� id_equipment:'+IntToStr(equipmentid));
     end;
end;

function TTaskGetDispatch6Statuses.WriteStatus(equipmentId, status: integer;
  tmstart, tmend: TDatetime; asuid, reason: string): boolean;
     var MySQLStatusesintm:TMySQLStatusList;
    i:integer;
  currstatnum: Integer;
    MySQLStatusBefore:TMySQLStatus;
    f:Boolean;
begin
     result:=true;
     if tmstart>=tmend then begin
        Result:=false;
        exit;
     end;
     f:=false;
     MysqlStatusesintm:=GetMySQlStatuses(equipmentId,tmstart,tmend);
     currstatnum:=-1;
     for I := 0 to Length(MySQLStatusesintm)-1 do begin
         // ������� ������ ������, ������� ������������ � �������
         if (currstatnum=-1) and (asuid=MysqlStatusesintm[i].asuid) then begin
            // ����� �������, ��� �������� asu_id ��������� ���������. ��� ����� �������������� ����� ���������
            currstatnum:=i;
            f:=true;
         end else begin
            f:=FreeMySQLStatus(MysqlStatusesintm[i],tmstart,tmend);
         end;
         if not f then begin
            result:=false;
            exit;
         end;
     end;
     // ���� ����� ������, �� �������������� ���, ���� ���, �� ��������� ����� ������
     if (currstatnum>-1) then begin
        if (MysqlStatusesintm[currstatnum].tmstart<>tmstart) or (MysqlStatusesintm[currstatnum].tmend<>tmend) then begin
            f:=MoveMySQLStatus(MysqlStatusesintm[currstatnum].id,tmstart,tmend);
        end else f:=true;
     end else begin
        f:=insertMySQLStatus(equipmentId,status,tmstart,tmend,asuid,reason);
     end;
     if not f then begin
        result:=false;
        exit;
     end;
end;

procedure TTaskGetDispatch6Statuses.WriteStatusesForEquipment(
  equipmentId: Largeint; EquipmentName: string; FirstStateId: Largeint);
var
  FirstState: Int64;
  dttmstart: TDatetime;
  dttmend: TDateTime;
  dttmrun: TDateTime;
  m_status: byte;
  asuid: Int64;
  reasonname: string;
  countFinded: Integer;
  countProcessed: Integer;
  countWrited: Integer;
  PercentBy1State:real;
begin
      // ���� �� ������ ������ ������� �������, �� ������ ������ ������ ������ ����� ������� ������� 6 22-06-29
     dttmrun:=Now();
     if FirstStateId>2201010010000000000 then FirstState:=FirstStateId else FirstState:=2201010010000000000;
     if self.QD6statuses.Active then self.QD6statuses.Close;
     self.QD6statuses.Clear;
     self.QD6statuses.SQL.Add('select DATEADD(s,s.FieldTime,i.ShiftStartDateTime) as TimeStart,');
     self.QD6statuses.SQL.Add('enum.Idx as status,');
     self.QD6statuses.SQL.Add('sr.FieldName as reason, s.id');
     self.QD6statuses.SQL.Add('from SHIFTShiftstate s ');
     self.QD6statuses.SQL.Add('left join SHIFTShifteqmt e on (s.FieldEqmt=e.id)');
     self.QD6statuses.SQL.Add('left join common.ShiftInfo i on (s.ShiftId=i.ShiftId)');
     self.QD6statuses.SQL.Add('left join Enum on (s.FieldStatus=Enum.Id)');
     self.QD6statuses.SQL.Add('left join SHIFTShiftreason sr on (s.FieldReasonrec=sr.id)');
     self.QD6statuses.SQL.Add('where (e.FieldId='+#39+'@eqid'+#39+')');
     self.QD6statuses.SQL.Add('and (s.id>=@FirstState)');
     self.QD6statuses.SQL.Add('order by  TimeStart');
     self.QD6statuses.vars.Add('eqid',EquipmentName);
     self.QD6statuses.vars.Add('FirstState',IntToStr(FirstStateId));
     //self.QD6statuses.ReplaceVars;
     try
        self.QD6statuses.Open;
     except
        on E:Exception do begin
            WriteLog('������ ��������� ������ �������� ��� '+EquipmentName);
            WriteLog(E.Message);
            Status:=tst_fail;
            exit;
        end;
     end;
     countFinded:=self.QD6statuses.RecordCount;
     countProcessed:=0;
     countWrited:=0;
     dttmstart:=0;
     dttmend:=0;
     m_status:=ms_unknown;
     asuid:=0;
     if countFinded>0 then begin
       PercentBy1State:=self.PercentBy1EQ/countFinded;
       while (not self.QD6statuses.Eof) and (not self.aborted) and (self.Status<>tst_fail) do begin
          dttmstart:=dttmend;
          dttmend:=self.QD6statuses.FieldByName('TimeStart').AsDateTime;
          if (dttmstart>0) and (dttmend>=StrToDateTime('29.06.2022 7:30:00')) and (m_status<>ms_unknown) then begin
             if WriteStatus(equipmentId,m_status,dttmstart,dttmend,Inttostr(asuid),reasonname) then begin
                WriteLastStatusId(equipmentid,asuid);
                inc(countWrited);
             end;
          end;
          m_status:=self.QD6statuses.FieldByName('status').AsInteger;
          asuid:=self.QD6statuses.FieldByName('id').AsLargeInt;
          reasonname:=self.QD6statuses.FieldByName('reason').AsString;
          inc(countProcessed);
          self.CurrentPercent:=self.CurrentPercent+PercentBy1State;
          self.QD6statuses.Next;
       end;
       if (not self.aborted) and (self.Status<>tst_fail) and (m_status<>ms_unknown) then begin
          dttmstart:=dttmend;
          dttmend:=dttmrun;
          if (dttmstart>0) and (dttmend>=StrToDateTime('29.06.2022 7:30:00')) and (m_status<>ms_unknown) then begin
             if WriteStatus(equipmentId,m_status,dttmstart,dttmend,Inttostr(asuid),reasonname) then begin
                WriteLastStatusId(equipmentid,asuid);
                inc(countWrited);
             end;
          end;
       end;
     end else self.CurrentPercent:=self.CurrentPercent+PercentBy1EQ;
     self.QD6statuses.Close;
     WriteLog('��� '+EquipmentName+' ������� '+IntToStr(countFinded)+' ��������, ���������� '+IntToStr(countProcessed)+' ��������, �������� '+IntToStr(countWrited)+' ��������.');
end;

{ TTaskGetGPSDispatch6 }

procedure TTaskGetGPSDispatch6.CloseConnections;
begin
  inherited;
  try
        self.connMySQL.Close;
        self.connD6.Close;
  except
        WriteLog('������ �������� ���������� c ��');
  end;

end;

constructor TTaskGetGPSDispatch6.Create(owner: TTaskThread;
  sleeptimesec: integer; runnow: boolean);
begin
  inherited Create(owner,sleeptimesec,runnow);
  DisplayName:='��������� ��������� �� ������ Dispatch 6';
  counterrorsLogs:=10;
end;

destructor TTaskGetGPSDispatch6.Destroy;
begin
  inherited;
end;

procedure TTaskGetGPSDispatch6.DestroyDBConnections;
begin

  if Assigned(DBLastGPSD6Id) then FreeAndNil(DBLastGPSD6Id);
  if Assigned(QD6GPS) then begin
     if QD6GPS.Active then QD6GPS.Close;
     FreeAndNil(QD6GPS);
  end;
  if Assigned(connD6) then FreeAndNil(connD6);
  if Assigned(QMyD6GPS1) then begin
    if QMyD6GPS1.Active then QMyD6GPS1.Close;
    FreeAndNil(QMyD6GPS1);
  end;
  if Assigned(connMySQL) then FreeAndNil(connMySQL);
  inherited;
end;

procedure TTaskGetGPSDispatch6.ExecuteTask;
var
  LastGPSid: string;
  currid: Int64;
  EQName: string;
  dttm: TDatetime;
  x: real;
  y: real;
  countprocessed:integer;
  countwrited:integer;
  percentByStep: real;
begin
     countprocessed:=0;
     countWrited:=0;
     self.counterrors:=0;
     // �������� id ��������� ������������ ����������
     LastGPSid:=DBLastGPSD6Id.value;
     if LastGPSid='' then LastGPSid:='2206290020000000000';
     WriteLog('��������� ������������ ���������� GPS � Dispatch 6 ����� id '+LastGPSid);
     QD6GPS.Clear;
     QD6GPS.SQL.Add('select TOP (10000) id, EquipmentId, Timestamp, positionX, PositionY from ext.ExtPosition');
     QD6GPS.SQL.Add('where ID>@lastgpsid');
     QD6GPS.SQL.Add('order by id');
     QD6GPS.vars.Add('lastgpsid',LastGPSid);
     try
       QD6GPS.Open;
     except
       WriteLog('������ ��������� ��������� �� �� Dispatch 6');
       status:=tst_fail;
       exit;
     end;
     if QD6GPS.RecordCount>0 then percentByStep:=100/QD6GPS.RecordCount;
     while (not QD6GPS.Eof) and (not self.Aborted ) and (self.Status<>tst_fail) do begin
        currid:=QD6GPS.FieldByName('id').AsLargeInt;
        EQName:=QD6GPS.FieldByName('EquipmentId').AsString;
        dttm:=QD6GPS.FieldByName('Timestamp').AsDateTime;
        x:=QD6GPS.FieldByName('positionX').AsFloat;
        y:=QD6GPS.FieldByName('positionY').AsFloat;
        inc(countprocessed);
        if InsertGPS(EQName,dttm,x,y) then begin
           inc(countwrited);
           LastGPSid:=inttostr(currid);
           try
              DBLastGPSD6Id.value:=LastGPSid;
           except
              on E:Exception do begin
                 WriteLog(E.Message);
                 status:=tst_fail;
              end;
           end;
           // ������� �������� �� �� ubiquiti
           sleep(1);
           if self.counterrors>self.counterrorsLogs then WriteLog('��� ������ �� �������� '+IntToStr(self.counterrors-self.counterrorsLogs)+' ���������');
           self.counterrors:=0;
        end else inc(self.counterrors);
        CurrentPercent:=CurrentPercent+percentByStep;
        QD6GPS.Next;
     end;
     if counterrors>counterrorsLogs then WriteLog('��� ������ �� �������� '+IntToStr(counterrors-counterrorsLogs)+' ���������');
     WriteLog('���������� '+IntToStr(countprocessed)+' �������. �������� '+IntToStr(countwrited)+' �������.');
     if (countprocessed>100) and (countwrited=0) then begin
        self.Status:=tst_fail;
        WriteLog('�� ���� �������� �� ����� ����������.');
     end;
end;

function TTaskGetGPSDispatch6.GetEQidByName(EQName: string): Largeint;
begin
     result:=0;
     if self.QMyD6GPS1.Active then self.QMyD6GPS1.Close;
     self.QMyD6GPS1.Clear;
     self.QMyD6GPS1.SQL.Add('select id from equipment where name="@EQname" limit 1');
     self.QMyD6GPS1.vars.Add('EQname',EQName);
     try
        self.QMyD6GPS1.Open;
     except
        WriteLog('������ ��������� id ��� ������������ '+EQName);
        self.Status:=tst_fail;
        exit;
     end;
     if self.QMyD6GPS1.RecordCount>0 then result:=self.QMyD6GPS1.FieldByName('id').AsLargeInt;
     self.QMyD6GPS1.Close;
end;

procedure TTaskGetGPSDispatch6.initDBConnections;
begin
  inherited;
  connD6:=TMyADOConnection.Create(nil,dm1.tplConnD6.ConnectionString);
  QD6GPS:=TMyADOQuery.Create(nil,connD6);
  connMySQL:=TMyADOConnection.Create(nil,dm1.TplConnMySQL.ConnectionString);
  QMyD6GPS1:=TMyADOQuery.Create(nil,connMySQL);
  DBLastGPSD6Id:=TDBVariable.Create(connMySQL,self.ClassName,'LastGPSD6Id');
end;

function TTaskGetGPSDispatch6.InsertGPS(EQName: string; dttm: TDatetime; x,
  y: real): boolean;
var
  eqid: Largeint;
begin
     result:=false;
     // �������� id ������������
     eqid:=GetEQidByName(EQName);
     if eqid=0 then begin
        if (self.counterrors<self.counterrorsLogs) then WriteLog('�� ������� ������������ � ������ '+EQName+' � �� ubiquiti');
        exit;
     end;
     if QMyD6GPS1.Active then QMyD6GPS1.Close;
     QMyD6GPS1.Clear;
     QMyD6GPS1.SQL.Add('insert into stats_gps (id_equipment,datetime,x,y) values (@eqid,"@dttm",@x,@y)');
     QMyD6GPS1.vars.Add('eqid',IntToStr(eqid));
     QMyD6GPS1.vars.Add('dttm',MySQLDateTime(dttm));
     QMyD6GPS1.vars.Add('x',FloatToStrEn(x));
     QMyD6GPS1.vars.Add('y',FloatToStrEn(y));
     QMyD6GPS1.ReplaceVars;
     try
        QMyD6GPS1.ExecSQL;
     except
        on E:Exception do begin
          if (Pos('Duplicate entry',E.Message)=0) then begin
            WriteLog(E.Message);
            WriteLog('������ ������ ���������� ��� '+EQName+'. ���� � ����� ����������: '+FormatDateTime('dd.mm.yyyy hh:nn:ss',dttm));
            Self.Status:=tst_fail;
            exit;
          end;
        end;
     end;
     if QMyD6GPS1.RowsAffected>0 then result:=true;
end;

{ TDBVariable }

constructor TDBVariable.Create(connection:TMyADOConnection; objname, varname: string);
begin
     connMySQL:=connection;
     QMyVar:=TMyADOQuery.Create(nil,connMySQL);
     Fobjectname:=objname;
     Fvariablename:=varname;
end;

destructor TDBVariable.Destroy;
begin
     if Assigned(QMyVar) then begin
        if QMyVar.Active then QMyVar.Close;
        FreeAndNil(QMyVar);
     end;
     connMySQL:=nil;
end;

function TDBVariable.GetValue: string;
begin
     result:='';
     if QMyVar.Active then QMyVar.Close;
     QMyVar.Clear;
     QMyVar.SQL.Add('select value from variables where (object="@obj") and (name="@name")');
     QMyVar.vars.Add('obj',Fobjectname);
     QMyVar.vars.Add('name',Fvariablename);
     try
        QMyVar.Open;
     except
        raise Exception.Create('������ ��������� ���������� �� �� ubiquiti');
        exit;
     end;
     if QMyVar.RecordCount>0 then result:=QMyVar.FieldByName('value').AsString;
     QMyVar.Close;
end;

procedure TDBVariable.SetValue(value: string);
var
  cnt: Integer;
begin
     if QMyVar.Active then QMyVar.Close;
     QMyVar.Clear;
     QMyVar.SQL.Add('select count(*) as cnt from variables where (object="@obj") and (name="@name")');
     QMyVar.vars.Add('obj',Fobjectname);
     QMyVar.vars.Add('name',Fvariablename);
     try
        QMyVar.Open;
     except
        raise Exception.Create('������ �������� ���������� � �� ubiquiti');
        exit;
     end;
     cnt:=QMyVar.FieldByName('cnt').AsInteger;
     QMyVar.Close;
     QMyVar.Clear;
     if cnt>0 then begin
        // ��������� ������
        QMyVar.SQL.Add('update variables set value="@val" where (object="@obj") and (name="@name")');
     end else begin
        // ��������� ������
        QMyVar.SQL.Add('insert into variables (object,name,value) VALUES("@obj","@name","@val")');
     end;
     QMyVar.vars.Add('obj',Fobjectname);
     QMyVar.vars.Add('name',Fvariablename);
     QMyVar.vars.Add('val',value);
     try
        QMyVar.ExecSQL;
     except
        raise Exception.Create('������ ������ ���������� � �� ubiquiti');
        exit;
     end;
end;

initialization
  // ����� ���������� ���������������� �������� ������ TTask,
  // ����� �� ������ ������� ����� ���� ������ �� ����� ������
  Classes.RegisterClass(TtaskResetPressureGSP);
  //Classes.RegisterClass(TTaskManageGPSFile);
  Classes.RegisterClass(TTaskGetGPSInformation);
  Classes.RegisterClass(TTaskGenerateImagePitgraph);
  Classes.RegisterClass(TTaskGenerateImagePitgraphASUGTK);
  Classes.RegisterClass(TTaskGenerateImagePitD6);
  Classes.RegisterClass(TTaskGenerateImagePitD6ASUGTK);
  Classes.RegisterClass(TTaskCalcStatWiFiByEquipment);
  Classes.RegisterClass(TTaskUpdateDrillStatus);
  classes.RegisterClass(TTaskGetBVUGPS);
  classes.RegisterClass(TTaskCalcWifiStatMap);
  classes.RegisterClass(TTaskGetModularStatuses);
  classes.RegisterClass(TTaskGetDispatch6Statuses);
  classes.RegisterClass(TTaskGetDrillStatuses);
  classes.RegisterClass(TTaskGetGPSDispatch6);
end.
