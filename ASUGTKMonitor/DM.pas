unit DM;

interface

uses
  SysUtils, Classes, forms, DB, ADODB, MyUtils, iniFiles, ActiveX,
  Sockets, syncobjs, xmldom, XMLIntf, msxmldom, XMLDoc, DateUtils, Contnrs, ScorpioSSH,
  ScorpioDB;

const  s_unknown =0;
       s_Work    =1;
       s_NoData  =2;
       s_Disable =3;
       s_NotReady=4;
       s_damage  =5;
       s_restored=6;

// Констатны для статусов сбора статистики
const
       ms_notprocessed=-1;
       ms_unknown=0;
       ms_damage=1;
       ms_ready=2;
       ms_delay=3;
       ms_wait=4;
       ms_down_comp=5;

const mos_Monitoring=0;
        mos_Disable=1;
        mos_Damage=2;

const MaxInterfacesCount=10;
      MaxParametersCount=3;
type TStatssStatus=-1..5;  // константы ms_
type TStatus=0..6;         // Константы s_
type TFullStatsStatus=record
     status:TStatssStatus;
     dttmstart:TDateTime;
     dttmEnd:TDateTime;
     reasonname:string;
end;
type TModularStatusCategory=(notprocessed,unknown,damage,ready,delay,wait);
type TStatsStatus=TModularStatusCategory;
type TModularStatusCategories=set of TModularStatusCategory;

type TEquipmentType=(servers,trucks,excavs,networking,drills,szms);

type
  TDM1 = class(TDataModule)
    ConnPowerViewOld: TADOConnection;
    qStatus: TADOQuery;
    qStatusstarttime: TFloatField;
    qStatusstatus: TFloatField;
    ConnMySQL: TADOConnection;
    qModify: TADOQuery;
    qGetTruckID: TADOQuery;
    qGetTruckIDid: TLargeintField;
    qEquipment: TADOQuery;
    qEquipmentid: TLargeintField;
    qEquipmentname: TWideStringField;
    qPowerViewStatus1: TADOQuery;
    qPowerViewStatus1endtm: TFloatField;
    qEquipmentequipment_type: TIntegerField;
    qMonitoringStatus: TADOQuery;
    qMonitoringStatusid: TAutoIncField;
    qMonitoringStatusreason: TWideStringField;
    qMonitoringStatusFIO: TWideStringField;
    qMonitoringStatusdatetimestart: TDateTimeField;
    qMonitoringStatusreason_category: TSmallintField;
    qPVTemp: TADOQuery;
    qMySQLTemp: TADOQuery;
    qEquipmentip_address: TWideStringField;
    qFindInterface: TADOQuery;
    qExcavs: TADOQuery;
    qExcavsid: TLargeintField;
    qExcavsname: TWideStringField;
    qExcavsip_address: TWideStringField;
    qExcavsequipment_type: TIntegerField;
    ConnMySQLgetGPS: TADOConnection;
    qNetwork: TADOQuery;
    qNetworkid: TLargeintField;
    qNetworkname: TWideStringField;
    qNetworkip_address: TWideStringField;
    qNetworkequipment_type: TIntegerField;
    connMySQLProg: TADOConnection;
    qMysqlProgTemp: TADOQuery;
    TplConnMySQL: TADOConnection;
    tplConnPVold: TADOConnection;
    tempXML: TXMLDocument;
    ConnKobus: TADOConnection;
    tplConnD6: TADOConnection;
  private
    { Private declarations }
  public
    { Public declarations }
    function ConnectedDBUbiquiti : boolean;
  end;

type
  TParameterInterface=class(TObject)
  private
    FdisplayName:string;
    FName:string;
    Fvalue:string;
    Fedizm:string;
    FFormatVal:string;
  public
    property displayName: string read FDisplayName write FDisplayName;
    property name:string read FName write FName;
    property value:string read FValue write FValue;
    property edizm:string read Fedizm write FEdizm;
    property FormatVal:string read FFormatVal write FFormatVal;
end;

type TParameters = class
  private
    FParameters: array of TParameterInterface;
    function getParameter(index1:integer): TParameterInterface;
    function getCount:integer;
  public
    constructor Create;
    destructor destroy;
    property Parameters[index:integer] : TParameterInterface read getParameter; default;
    property Count:integer read getcount;
    procedure Add(Prmtr:TParameterInterface);
    procedure Delete(index1:integer);
end;

type
  CInterface = class(TObject)
    DisplayParameters : TParameters;
  private
    Fname:string;
    FDisplayName:string;
    Fstatus:integer;
    Fcomment:string;
    FErrorStr:string; // Комментарий при отображении ошибки
    FLastCheckDateTime:TDateTime;
    FOwner:TObject;
    FMonitoringStatus:shortint;
    FMonitoringSetting:shortint;
    FResumeMonitoringDateTime:TDateTime;
    function CheckTableMCPar: boolean;    // Старая проверка таблицы hist_mc_par на количество записей за смену. Оказалась не эффективной
    function GetLastDataMCPar: TDateTime;
    function CheckInterface:boolean; virtual; abstract;  // Функция проверки интерфейса
    function getInterfaceMYSQLID: integer; // Поиск номера интерфейса в БД Ubiquiti. Если не найден, возвращает -1
    function GetDetailsMonitoringStatus:string;
    function GetMonitoringSuspended:boolean;
  public
    property name: string read FName write FName;
    property DisplayName: string read FDisplayName write FDisplayName;
    property status: integer read FStatus write FStatus;
    property comment: string read FComment write FComment;
    property ErrorStr:string read FErrorStr write FErrorStr;
    property LastCheckDateTime: TDateTime read FLastCheckDateTime write FLastCheckDateTime;
    property Owner:TObject read FOwner write FOwner;
    property MonitoringStatus: shortint read FMonitoringStatus;
    property MonitoringSetting: shortint read FMonitoringSetting write FMonitoringSetting;
    property DetailsMonitoringStatus:string read GetDetailsMonitoringStatus;
    property ResumeMonitoringDateTime:TDateTime read FResumeMonitoringDateTime;   // Время возобнавления мониторинга интерфейса
    property IsMonitoringSuspended: boolean read GetMonitoringSuspended;        // Приостановлен ли сейчас мониторинг
    constructor Create; overload;
    destructor Destroy;
    procedure Clear(); virtual; // Процедура очистки
    function Check : boolean; virtual; // Функция для запуска проверки интерфейса
    function AddDisplayParameter(parameterName:string): boolean; virtual;
    function GetMonitoringStatus : integer;
    property MySQLID: integer read getInterfaceMYSQLID; // Идентификатор интерфейса в БД Ubiquiti
    procedure MonitoringOn();                           // Процедура включения мониторинга интерфейса
    procedure MonitoringOff(reason,FIO:string;reason_category:integer);                          // Процедура отключения мониторинга интерфейса
    procedure MonitoringSuspend(ResumeTime:TDateTime);
    procedure MonitoringSuspendByHour;
    procedure MonitoringUnsuspend;
end;


type CInterfaces = class
  private
    FInterfaces: array of CInterface;
    FOwner:TObject;
    function getInterface(Index:integer): CInterface;
    function getCount: integer;
  public
    constructor Create;
    destructor Destroy;
    property Interfaces[index:integer]: CInterface read getInterface; default;
    property count:integer read getCount;
    property Owner:TObject read FOwner;
    procedure Add(Intfc:CInterface; MonitoringSetting:shortint);
    procedure Delete(index1:integer);
    function getByName(Name:string):CInterface;
end;

type
  TWiFiInterface = class(CInterface)
    LostPercent:TParameterInterface;
  private
    function CheckInterface : boolean; override;
  public
    constructor Create();
    destructor Destroy();
    function AddDisplayParameter(parameterName:string): boolean; override;
    function GetLastSignal:shortint; // Получение последнего уровня WiFi за последние 30 секунд
    function GetLostPercent(SecondsToCalc:integer):real; overload;
    //function GetLostPercent(SecondsToCalc:integer; StatusesNotCalc:TModularStatusCategories):real; overload;
end;

type TLTEInterface = class(CInterface)
    LostPercent:TParameterInterface;
  private
    checkHours: Integer;                                     // Количество часов, за которые проверяются данные
    NoDataLostPercent: Integer;                              // Порог процента потерь, выше которого считается проблема по связи
    minCountPingToCalculate:integer;                        // Минимальное количество точек статистики для возможности определения статуса
    function CheckInterface : boolean; override;
  public
    constructor Create();
    destructor Destroy();
    function AddDisplayParameter(parameterName:string): boolean; override;
end;

type
  TPingPCInterface = class(CInterface)
    LostPercent:TParameterInterface;
  private
    FcalcSeconds:integer;
    FPercentToBad:real;
    FMinCountPingToCheck:integer;
    function CheckInterface : boolean; override;
  public
    constructor Create();
    destructor Destroy();
    function AddDisplayParameter(parameterName:string): boolean; override;
    //function GetLostPercent(SecondsToCalc:integer):real; overload;
    property CalcSeconds:integer read FcalcSeconds write FcalcSeconds;  // Количество секунд, за которое считается процент потерь
    property PercentToBad:real read FPercentToBad write FPercentToBad;  // Процент потерь для плохого статуса
    property MinCountPingToCheck:integer read FMinCountPingToCheck write FMinCountPingToCheck; // Минимальное количество запросов для актуальности проверки
    function GetLostPercent(SecondsToCalc:integer):real;
end;

type
   TGpsInterface = class(CInterface)
    LastGPSDateTime:TParameterInterface;
  private
    function CheckInterface : boolean; override;
  public
    //function CheckByOMStip :boolean;
    function Check : boolean; override; // Для интерфейса GPS необходимо переопределить проверку
    constructor Create();
    destructor Destroy();
    function AddDisplayParameter(parameterName:string):boolean; override;
end;

type TPressureInterface= class(CInterface)
const Tire_Unknown=0;
   Tire_work=1;
   Tire_NoData=2;
   Tire_NotCorrect=3;
   private
    FCountWorkTires:TParameterInterface;
    FGSPPort:integer;
    function CheckTire(i:integer):shortint;
    function CheckInterface : boolean; override;
   public
    constructor Create();
    destructor Destroy();
    property GSPPort:integer read FGSPPort write FGSPPort;
    property CountWorkTires: TParameterInterface read FCountWorkTires write FCountWorkTires;
    function AddDisplayParameter(parameterName:string): boolean; override;
end;

type TVEIInterface = class(CInterface)
   private
    function CheckInterface : boolean; override;
   public
    constructor Create();
    function AddDisplayParameter(parameterName:string): boolean; override;
end;

type TWeightInterface=class(CInterface)
   private
    //FCountHauls:TParameterInterface;
    function CheckInterface : boolean; override;
   public
    //property CountHauls:TParameterInterface read FCountHauls write FCountHauls;
    constructor Create;
    destructor Destroy;
    function AddDisplayParameter(parameterName:string): boolean; override;
end;

type TOmnicommInterface = class(CInterface)
    private
      function CheckInterface : boolean; override;
    public
      constructor Create();
      function AddDisplayParameter(parameterName:string): boolean; override;
end;

type TPowerViewLoadDataInterface = class(CInterface)
    private
      function CheckLastData : boolean;
      function CheckInterface : boolean; override;
end;

type TRunTransactInterface = class(CInterface)
    private
      function CheckInterface : boolean; override;
end;

type TRunExceptInterface = class(CInterface)
    private
      function CheckInterface : boolean; override;
end;

type TRunGPSInterface = class(CInterface)
    private
      function CheckInterface : boolean; override;
end;

type TFreeSpaceInterface = class(CInterface)
    private
      FthresholdPercent:shortint;
      procedure SetThresholdPercent(value:shortint);
      function CheckInterface : boolean; override;
    public
      property ThresholdPercent:shortint read FThresholdPercent write SetThresholdPercent;
end;

type TRunSniffInterface=class(CInterface)
    private
      function CheckInterface : boolean; override;
end;

type TAvailInterface = class(CInterface)
    private
      function CheckInterface : boolean; override;
    public
      constructor Create();
end;

type TEquipmentPowerStatus=(PS_unknown,PS_off, PS_on);

type TEquipment = class
      Locked:TCriticalSection;
    private
      Fname:string;
      FIPAddress:string;
      //FBusy:boolean;
      FInterfacesEquipment : CInterfaces;
      FAllInterfaces:CInterfaces;
      FMySQLIndex:integer;
      procedure SetIPAddress(const Value: string);
      function GetStatus : TStatus; virtual;
    public
      constructor Create;
      destructor Destroy;
      property name: string read FName write FName;
      property IPAddress:string read FIPAddress write SetIPAddress;
      property Interfaces : CInterfaces read FInterfacesEquipment write FInterfacesEquipment;
      property Status:TStatus read GetStatus;
      //property Busy:boolean read FBusy;             // Флаг занятости оборудования. Если True, то объект занят и с ним работать нельзя
      property MySQLIndex: integer read FMySQLIndex;
      //function Lock : boolean;
      //procedure Unlock;
      function AddInterface(interfaceName:string; MonitoringSetting: shortint):boolean; virtual;
      function Pinged : boolean;      // Флаг того, что оборудование пингуется
      function FindInterfaceByName(InterfaceName:string):CInterface;
      function getIPAddress:string;
      function GetMySQLIndex():boolean;
      class function GetMySQLIndexByName(name:string):integer;
end;

// Классы для запланированных работ
type TwaitAction = class
      private
        Fiswait:boolean;
        FOwner:TEquipment;
        FPrevCome:boolean;
        FCurrCome:boolean;
        FComment: string; // Комментарий к ожидаемому действию
        procedure SetWait(value:boolean);
        function Check: boolean; virtual; abstract;
        function CheckWait: boolean;
      public
        property isWait:boolean read FIsWait write setWait;
        property come:boolean read CheckWait;
        property isPrevCome:boolean read FPrevCome write FPrevCome; // Статус предыдущей проверки.
        property isCurrCome: boolean read FCurrCome write FCurrCome; // Статус последней проверки.
        property comment:string read FComment write FComment; // Комментарий к ожидаемому действию
        constructor Create(Owner:TEquipment);
        procedure Enable;
        procedure Disable;
        function GetMessage:string; virtual;
        function GetMenuCaption:string; virtual;

end;
type TWaitPowerOn = class(TWaitAction)
     private
        function Check: boolean; override;
     public
        function GetMessage:string; override;
        function GetMenuCaption:string;
end;
type TWaitPowerOff=class(TwaitAction)
     private
        function Check: boolean; override;
     public
        function GetMessage:string; override;
        function GetMenuCaption:string;
end;
type TWaitNotWork=class(TwaitAction)
     private
        function Check:boolean; override;
     public
        function GetMessage:string; override;
        function GetMenuCaption:string;
end;
type TWaitGBM=class(TWaitAction)
     private
        function Check:boolean; override;
     public
        function GetMessage:string; override;
        function GetMenuCaption:string;
end;



// Классы, описывающие запланированные работы по технике
type TWorkStatus=shortint;
const PWorkActive=1;
const PWorkSuspend=2;
const PWorkComplete=3;

type TAccessType=0..10;
const access_user=1;
const access_group=2;
const access_all=3;

type TPlannedWork=class
     waitAction:TwaitAction;
     Equipment:TEquipment;
     private
      FworkName:string;
      FStatus:TWorkStatus;
      FComment:string;
      FlastActionDate:TDateTime;
      FCreateDate:TDateTime;
      FdbID:integer;
     public
      property workName:string read FworkName write FWorkName; // Название работы
      property status: TWorkStatus read FStatus write FStatus; // Статус выполнения работы
      property comment:string read FComment write FComment; // Комментарий
      property lastActionDate:TDateTime read FlastActionDate write FlastActionDate;
      property CreateDate:TDateTime read FCreateDate write FCreateDate;

end;

type TPlannedWorksEquipment=class(TObjectList)
      locked:TCriticalSection;
      equipment:TEquipment;
      private
        function GetPlannedWork(index:integer):TPlannedWork;
      public
        property PlannedWork[index:integer]:TPlannedWork read GetPlannedWork;

end;

type TPlannedWorksList=class(TObjectList)
     locked:TcriticalSection;
     private
       function getPlannedWork(index:integer):TPlannedWork;
    function getPlannedWorks(index: integer): TPlannedWork;
     public
       property PlannedWork[index:integer]: TPlannedWork read getPlannedWork;
       function Load:boolean;
       procedure AddWork(EquipmentID:integer;Workname:string;status:TWorkStatus;comment:string;waitActionID:integer;accessid:TAccessType);
       Procedure DeleteAll;
end;

type TModularStatus=record
     shiftindex:integer;
     starttime:integer;
     endtime:integer;
     status:shortint;
     reason:string;
     ddbkey:integer;
     eqmt:string;
end;

// Все мобильное оборудование в карьере (самосвалы, экскаваторы, бурстанки, сзм)
type TMobileEquipment = class(TEquipment)
      WiFi:TWiFiInterface;
      PingPC:TPingPCInterface;
      LTE:TLTEInterface;
      waitPowerOn:TWaitPowerOn;
      waitPowerOff:TWaitPowerOff;
      waitNotWork:TWaitNotWork;

    private
      FModemIP:string;
      FisPowerOn:boolean;
      procedure SetModemIP(value:string);
      function GetPowerStatus:TEquipmentPowerStatus;

      function GetStatus: TStatus; override;
      function getReadySeconds:integer;
    public
      waitList:TList;
      property PowerStatus:TEquipmentPowerStatus read GetPowerStatus;
      property ModemIP:string read FModemIP write SetModemIP;
      property readySeconds:integer read GetReadySeconds;

      constructor Create;
      destructor Destroy;

      function GetSystemStatus: TStatssStatus;
      function GetFullSystemStatus:TFullStatsStatus;
      function AddInterface(interfaceName:string; MonitoringSetting:shortint):boolean; override;
      function GetModemIdx: integer;                        // Получение id-модема
end;

type TMobileEQModular = class(TMobileEquipment)
      GPS:TGPSInterface;
      waitGBM:TWaitGBM;
    private
      function GetFullModularStatus:TModularStatus;
      function GetPosition:string;
    public
      property FullModularStatus:TModularStatus read GetFullModularStatus;
      property Position:string read GetPosition;   // Объект местоположения оборудования
      constructor Create;
      destructor Destroy;
      function GetModularStatus:integer;
      function GetModularReadySeconds:integer;               // Функция возвращает, сколько секунд оборудование находится в статусе готов
      function IsReadyModular: boolean;
      function AddInterface(interfaceName:string; MonitoringSetting:shortint):boolean; override;
end;

type TKobusEquipment = class(TMobileEquipment)
    public
      constructor Create;
      destructor Destroy;
      function GetReadySeconds:integer;                       // Количество секунд с момента, когда закончился последний простой
end;

type TDrill = class(TKobusEquipment)

end;

type TSZM = class(TKobusEquipment)

end;

type TExcav = class(TMobileEQModular)

end;

type TTruck = class(TMobileEQModular)
      VEI:TVEIInterface;
      Pressure:TPressureInterface;
      Omnicomm:TOmnicommInterface;
      Weight:TWeightInterface;
    public
      constructor Create;
      destructor Destroy;
      function AddInterface(interfaceName:string; MonitoringSetting:shortint):boolean; override;
end;

type TNetworkEQ = class(TEquipment)
      Avail:TAvailInterface;
    public
      constructor Create;
      destructor Destroy;
      function AddInterface(interfaceName:string; MonitoringSetting:shortint):boolean; override;
end;

type TServer = class(TEquipment)
     public
      function getIPAddress:string;
end;

type TDispatch = class(TServer)
     IsRunTransact:TRunTransactInterface;
     IsRunExcept:TRunExceptInterface;
     IsRunGPS: TRunGPSInterface;
     FreeSpace:TFreeSpaceInterface;
     IsRunSniff:TRunSniffInterface;
     public
       constructor Create;
       destructor Destroy;
       function AddInterface(interfaceName:string; MonitoringSetting:shortint):boolean; override;
end;

type TPowerView = class(TServer)
       LoadDataInterface: TPowerViewLoadDataInterface;
     public
       constructor Create;
       destructor Destroy;
       function AddInterface(interfaceName:string; MonitoringSetting:shortint):boolean; override;
end;

// 2018-12-25 Вместо массивов оборудования созданы классы списков оборудования

type TEquipmentList = class(TObjectList)

    protected
        function GetItem(Index: Integer): TEquipment; inline;
        procedure SetItem(Index: Integer; Equipment: TEquipment); inline;
    public
        property Items[Index: Integer]: TEquipment read GetItem write SetItem; default;
        function GetEquipmentByMYSQLIndex(index:integer): TEquipment;
end;

// 170313 Классы настроек программы переделаны и перенесены в модуль Settings

type TInterface = record
     name:string;
     MonitoringStatus:shortint;
     parameters: array of string;
end;
type TInterfacesArray=array of TInterface;

type TTaskSettings= record
    name: string;
    sleeptimeSec: integer;
end;
type TApplVersion = record
    Major : shortint;
    Minor : shortint;
    Release : shortint;
    build : integer;
end;
type TNotificationSound = class
      FSettingFileName:string;
      FEnable:boolean;
      Fduration:integer;
      procedure SetEnable(value:boolean);
      procedure SetDuration(value:integer);
    public
      property Enable : boolean read FEnable write SetEnable;
      property Duration : integer read Fduration write SetDuration;
end;

// Класс настроек программы
// 2018-07-13 Старый класс настроек программы. Работает с ini файлом
// Новый класс настроек перенесен в модуль Settings
type TUserGroup=-1..10;
const ug_unknown=-1;
const ug_none=0;
const ug_asugtk=1;
const ug_atu=2;

type TSettingsOld = class
       interfaces: TInterfacesArray;
       tasks: array of TTaskSettings;
     private
       FfileName : string;
       FsleepTimeSeconds : integer;
       FSleepTimeEquipment : integer;
       FSleepTimeExcavs : integer;
       FSleepTimeNetwork:integer;
       FSleepTimeServers : integer;
       FSleepTimeDrills : integer;
       FCopyExe: boolean;
       FNotCheckServers:boolean;
       FNotShowErrors:boolean;
       FClientWidth:integer;
       FClientHeight:integer;
       FUser:string;
       FUpdateFolder:string;
       FUpdatePostfix:string;
       FUpdateEnabled:boolean;
       FShowExcavs:boolean;
       FShowTrucks:boolean;
       FAutoEnableMonitoring:boolean;
       FSound:TNotificationSound;
       FShowNetwork:boolean;
       FShowDrills:Boolean;
       FMonitoringLog:boolean;
       FLastCheckDateTime:TDateTime;
       FUserGroup: TUserGroup;
       FUserID:integer; // индекс пользователя из БД
       FShowClock:boolean;  // Флаг отображения часов на главной форме программы
       function getInterfacesCount:integer;
       function getTasksCount:integer;
       function getIsAdmin:boolean;
       function getApplVersion:TApplVersion;
       procedure SetApplVersion(value:TApplVersion);
       function stringToApplVersion(value:string):TApplVersion;
       function VersionLess(version1,version2:TApplVersion):boolean;
       function GetSleepTimeCategoryValue(value:integer):integer;
       function GetSleepTimeEquipment: integer;
       function GetSleepTimeExcavs:integer;
       function GetSleepTimeServers:integer;
       function GetSleepTimeDrills:integer;
       procedure CreateNewVersionsSettings(var iniFile:TIniFile);       // В эту процедуру добавляются новые настройки
       procedure SetAutoEnableMonitoring(value:boolean);
       procedure setShowClock(value:boolean);
       function SetSetting(category:string;variable:string;value:string):boolean; // Запись настроек в файл settings.ini
    function GetSleepTimeNetwork: integer;
       procedure SetLastCheckDateTime(value:TDateTime);
       function GetUserGroup(username:string):TUserGroup;
       procedure GetUserid(username:string);
     public
       property FileName:string read FFileName write FFileName;
       property SleepTimeSeconds: integer read FSleepTimeSeconds write FSleepTimeSeconds default 600;
       property SleepTimeEquipment: integer read GetSleepTimeEquipment write FSleepTimeEquipment;
       property SleepTimeExcavs: integer read GetSleepTimeExcavs write FSleepTimeExcavs;
       property SleepTimeServers: integer read GetSleepTimeServers write FSleepTimeServers;
       property SleepTimeNetwork: integer read GetSleepTimeNetwork write FSleepTimeNetwork;
       property SleepTimeDrills: integer read GetSleepTimeDrills write FSleepTimeDrills;
       property CopyExe: boolean read FCopyExe;
       property NotCheckServers : boolean read FNotCheckServers write FNotCheckServers;
       property NotShowErrors: boolean read FNotShowErrors write FNotShowErrors;
       property InterfacesCount:integer read getInterfacesCount;
       property TasksCount:integer read getTasksCount;
       property ClientWidth:integer read FClientWidth;
       property ClientHeight:integer read FClientHeight;
       property User:string read FUser;
       property IsAdmin:boolean read getIsAdmin;
       property UpdateFolder:string read FUpdateFolder;
       property UpdatePostfix:string read FUpdatePostfix;
       property UpdateEnabled:boolean read FUpdateEnabled;
       property ShowExcavs:boolean read FShowExcavs write FShowExcavs;             // Флаг отображения мониторинга по экскаваторам
       property ShowTrucks:boolean read FShowTrucks write FShowTrucks;
       property ApplVersion:TApplVersion read getApplVersion write setApplVersion; // Версия программы. Нужна для задания настроек при обновлениях программы
       property Sound: TNotificationSound read FSound write FSound;
       property ShowNetwork:boolean read FShowNetwork write FShowNetwork;         // Флаг отображения списка сетевого оборудования
       property ShowDrills:boolean read FShowDrills write FShowDrills;            // Флаг отображения списка бурстанков
       property MonitoringLog:boolean read FMonitoringLog write FMonitoringLog;   // Флаг логирования процесса мониторинга
       property LastCheckDateTime:TDateTime read FLastCheckDateTime write SetLastCheckDateTime;
       property AutoEnableMonitoring:boolean read FAutoEnableMonitoring write SetAutoEnableMonitoring;
       property UserGroup: TUserGroup read FUserGroup;
       property UserID:integer read FUserID;          // Ид пользователя из БД
       property ShowClock:boolean read FShowClock write setShowClock; // Флаг отображения часов на главной форме
       function ReadSettings(SettingsFileName:string): boolean;
       procedure SetClientSizes(width:integer; height:integer);
       function GetInterfaceIndexByName(interfacename:string):integer;
       function SaveToXML(flname:string):boolean; // Сохранение настроек в XML-файл
       constructor Create;
       destructor Destroy;
end;

var
  DM1: TDM1;
  //OSSH:TSSHobj;

implementation

uses Main;

{$R *.dfm}

{ CInterface }

function CInterface.AddDisplayParameter(parameterName: string): boolean;
begin
     result:=false;
end;

// Функция блокирует объект оборудование и запускает проверку интерфейса
function CInterface.Check: boolean;
var monStat:shortint;
begin
     TEquipment(owner).Locked.Enter;
     result:=false;
     errorstr:='';
     status:=s_unknown;
     {if not TEquipment(Owner).Lock then begin
      TEquipment(Owner).Locked.Leave;
      exit;
     end;}
     //GetMonitoringStatus;
     try
        result:=CheckInterface;
     // Изменения статуса для всех интерфейсов мобильного оборудования
         monStat:=GetMonitoringStatus;
     except
        result:=false;
        //TEquipment(Owner).Unlock;
        TEquipment(Owner).Locked.Leave;
        exit;
     end;
         if (monStat=mos_Disable) then status:=3;
         if (monStat=mos_Damage) then begin
            if (status=1) or (status=6) then status:=6 else status:=5;
         end;
         if (self.Owner.ClassType.ClassParent=TMobileEQModular) then begin
           if status in [0,2] then begin
              try
                  if not (TMobileEQModular(Owner).GetSystemStatus=ms_ready) then status:=s_NotReady;
              except

              end;
           end;
         end;
         if (self.Owner.ClassType.ClassParent=TKobusEquipment) then begin
            if status=s_unknown then status:=s_NotReady;
         end;
     if status<>2 then ErrorStr:='';
     //TEquipment(Owner).Unlock;
     LastCheckDateTime:=Now();
     TEquipment(Owner).Locked.Leave;
end;

function CInterface.CheckTableMCPar: boolean;
var qTempPowerView2:TADOQuery;
    ConnPowerViewTemp:TADOConnection;
    shiftid:integer;
    countToWork, cntRows, shiftsec:integer;
    tm:TTime;
begin
     result:=false;
     {CoInitialize(Nil);
     ConnPowerViewTemp:=TADOConnection.Create(dm1);
     ConnPowerViewTemp.ConnectionString:=dm1.tplConnPV.ConnectionString;
     ConnPowerViewTemp.LoginPrompt:=false;
     ConnPowerViewTemp.KeepConnection:=false;
     qTempPowerView2:=TADOQuery.Create(dm1);
     qTempPowerView2.Connection:=ConnPowerViewTemp;
     tm:=Time();
     shiftid:=DateToShift(Date(),tm);
     shiftsec:=TimeToShiftSec(tm);
     qTempPowerView2.SQL.Add('select count(*) as cntRows from hist_mc_par where shiftindex='+inttostr(shiftid));
     qTempPowerView2.Open;
     qTempPowerView2.First;
     cntRows:=qTempPowerView2.FieldByName('cntRows').AsInteger;
     countToWork:=0;
     if shiftsec>60*4 then countToWork:=10;
     if shiftsec>3600 then countToWork:=100;
     if shiftsec>3600*6 then countToWork:=2000;
     // Если количество записей не меньше порога для текущего времени, то все в порядке
     if cntRows>=countToWork then result:=true;
     qTempPowerView2.Close;
     FreeAndNil(qTempPowerView2);
     FreeAndNil(ConnPowerViewTemp); }
end;

procedure CInterface.Clear;
begin
     status:=0;
     comment:='';
     LastCheckDateTime:=0;
end;

constructor CInterface.Create;
begin
     inherited;
  Clear;
  name:='Интерфейс';
  comment:='';
  errorstr:='';
  MonitoringSetting:=1;
  DisplayParameters:=TParameters.Create;
end;

destructor CInterface.Destroy;
begin
  FreeAndNil(DisplayParameters);
end;

function CInterface.GetDetailsMonitoringStatus: string;
var qMonitStat1:TADOQuery;
    connTempMy:TADOConnection;
begin
     result:='Статус мониторинга неизвестен';
     coInitialize(nil);
     connTempMy:=TADOConnection.Create(dm1);
     connTempMy.ConnectionString:=dm1.TplConnMySQL.ConnectionString;
     connTempMy.LoginPrompt:=false;
     connTempMy.KeepConnection:=false;
     qMonitStat1:=TADOQuery.Create(dm1);
     qMonitStat1.Connection:=dm1.ConnMySQL;
     qMonitStat1.SQL.Add('select imo.id, imo.reason, imo.FIO, imo.datetimestart, imo.reason_category');
     qMonitStat1.SQL.Add('from interface_monitoring_off imo, equipment e, ref_interface ri');
     qMonitStat1.SQL.Add('where (e.Name="'+TEquipment(Owner).name+'") and (e.id=imo.equipment)');
     qMonitStat1.SQL.Add('and (ri.Name="'+name+'") and (ri.id=imo.ref_interface) and (imo.Active=1)');
     qMonitStat1.Open;
     qMonitStat1.Last;
     if qMonitStat1.RecordCount>0 then begin
        result:='Мониторинг интерфейса '+Name+' отключен '+ FormatDateTime('dd.mm.yyyy',qMonitStat1.FieldByName('datetimestart').AsDateTime)+' в '+ FormatDateTime('hh:mm',qMonitStat1.FieldByName('datetimestart').AsDateTime)+'. ';
        result:=result+'ФИО: '+qMonitStat1.FieldByName('FIO').AsString+'. Причина: '+qMonitStat1.FieldByName('reason').AsString;
     end else result:='Мониторинг интерфейса '+Name+' включен';
     FreeAndNil(qMonitStat1);
     FreeAndNil(connTempMy);
end;

// Поиск id интерфейса в БД
function CInterface.getInterfaceMYSQLID: integer;
var qFindIntfcMYSQL:TADOQuery;
    connTempMy:TADOConnection;
begin
     result:=-1;
     CoInitialize(nil);
     connTempMy:=TADOConnection.Create(dm1);
     connTempMy.ConnectionString:=dm1.TplConnMySQL.ConnectionString;
     connTempMy.LoginPrompt:=false;
     connTempMy.KeepConnection:=false;
     qFindIntfcMYSQL:=TADOQuery.Create(dm1);
     qFindIntfcMYSQL.Connection:=connTempMy;
     qFindIntfcMYSQL.SQL.Add('select id, name from ref_interface where name='+#39+name+#39);
     qFindIntfcMYSQL.Open;
     qFindIntfcMYSQL.Last;
     if qFindIntfcMYSQL.RecordCount>0 then result:=qFindIntfcMYSQL.FieldByName('id').AsInteger else result:=-1;
     qFindIntfcMYSQL.Close;
     FreeAndNil(qFindIntfcMySQL);
     FreeAndNil(connTempMy);
end;

function CInterface.GetLastDataMCPar: TDateTime;
var qTempPV:TADOQuery;
    ConnTempPV:TADOConnection;
    tm:TTime;
    shiftid:integer;
    secondsfrom1970:Largeint;
begin
     result:=0;
     {CoInitialize(Nil);
     try
        ConnTempPV:=TADOConnection.Create(dm1);
        ConnTempPV.ConnectionString:=dm1.ConnPowerView.ConnectionString;
        ConnTempPV.LoginPrompt:=false;
        ConnTempPV.KeepConnection:=false;
        qTempPV:=TADOQuery.Create(dm1);
        qTempPV.Connection:=ConnTempPV;
     except
        FreeAndNil(qTempPV);
        FreeAndNil(ConnTempPV);
        result:=0;
        exit;
     end;
     tm:=Time();
     shiftid:=DateToShift(Date(),tm);
     //shiftsec:=TimeToShiftSec(tm);
     qTempPV.SQL.Add('select max(timestamp) as maxtime from hist_mc_par where shiftindex='+inttostr(shiftid));
     try
        qTempPV.Open;
     except
        FreeAndNil(qTempPV);
        FreeAndNil(ConnTempPV);
        result:=0;
        exit;
     end;
     qTempPV.First;
     secondsFrom1970:=qTempPV.FieldByName('maxtime').AsLargeInt;
     qTempPV.Close;
     FreeAndNil(qTempPV);
     FreeAndNil(ConnTempPV);
     try
          result:=StrToDate('01.01.1970')+secondsfrom1970/3600/24;
     except
         result:=0;
     end;}
end;

function CInterface.GetMonitoringStatus: integer;
var qMonitStat:TADOQuery;
    ConnTempMy:TADOConnection;
begin
     if IsMonitoringSuspended then begin
         Result:=mos_Damage;
         FMonitoringStatus:=result;
         exit;
     end;
     if dm1.connectedDBubiquiti then begin
        try
           CoInitialize(nil);
           connTempMy:=TADOConnection.Create(dm1);
           connTempMy.ConnectionString:=dm1.TplConnMySQL.ConnectionString;
           connTempMy.LoginPrompt:=false;
           connTempMy.KeepConnection:=false;
          qMonitStat:=TADOQuery.Create(dm1);
          qMonitStat.Connection:=ConnTempMy;
          qMonitStat.SQL.Clear;
          qMonitStat.SQL.Add('select imo.id, imo.reason, imo.FIO, imo.datetimestart, imo.reason_category');
          qMonitStat.SQL.Add('from interface_monitoring_off imo, equipment e, ref_interface ri');
          qMonitStat.SQL.Add('where (e.Name="'+TEquipment(Owner).name+'") and (e.id=imo.equipment)');
          qMonitStat.SQL.Add('and (ri.Name="'+name+'") and (ri.id=imo.ref_interface) and (imo.Active=1)');
             qMonitStat.Open;
             qMonitStat.Last;
          if qMonitStat.RecordCount>0 then begin
             if qMonitStat.FieldByName('reason_category').AsInteger=0 then result:=mos_Disable else result:=mos_Damage;
          end else result:=mos_Monitoring;
          qMonitStat.Close;
          FreeAndNil(qMonitStat);
          FreeAndNil(ConnTempMy);
        except
            FreeAndNil(qMonitStat);
            FreeAndNil(ConnTempMy);
            result:=mos_Monitoring;
        end;
    end else result:=mos_Monitoring;
    FMonitoringStatus:=result;
end;

function CInterface.GetMonitoringSuspended: boolean;
begin
     result:=FResumeMonitoringDateTime>Now();
end;

procedure CInterface.MonitoringOff(reason,FIO:string;reason_category:integer);
var interfaceID:integer;
   infcindex:integer;
   intfcindex:integer;
begin
  if reason='' then Application.MessageBox(PChar('Не задана причина отключения мониторинга'),'Ошибка');
  if FIO='' then Application.MessageBox(PChar('Не задано ФИО отключающего мониторинг'),'Ошибка');
  if not TEquipment(self.owner).getMySQLIndex then begin
         Application.MessageBox(PChar('В базе данных не найдено оборудование с именем '+TMobileEquipment(self.owner).name+'.'),'Ошибка');
         exit;
  end;
  // Проверить, есть ли данный интерфейс в списке интерфейсов БД
  intfcindex:=self.MySQLID;
  if intfcindex<0 then begin
      Application.MessageBox(PChar('В базе данных не найден интерфейс с именем '+self.name),'Ошибка');
      exit;
  end;
  if self.GetMonitoringStatus<>mos_Monitoring then begin
     Application.MessageBox(PChar('Нельзя повторно отключить мониторинг.'+self.DetailsMonitoringStatus),'Информация');
     exit;
  end;
  // Открываем окно заполнения информации по отключению мониторинга
  if DM1.qModify.Active then DM1.qModify.Close;
  DM1.qModify.SQL.Clear;
  DM1.qModify.SQL.Add('insert into interface_monitoring_off (equipment, ref_interface, active, datetimestart, reason, FIO, reason_category)');
  DM1.qModify.SQL.Add('values('+inttostr(TMobileEquipment(self.owner).MySQLIndex)+','+inttostr(intfcindex)+',1,"'+ FormatDateTime('yyyy-mm-dd hh:mm:ss',Now())+'","'+reason+'","'+FIO+'",'+inttostr(reason_category)+')');
  //Application.MessageBox(PChar(DM1.qModifi.SQL.Text),'');
  DM1.qModify.ExecSQL;
  DM1.qModify.Close;
  self.Check;
end;

procedure CInterface.MonitoringOn;
var intfcindex:integer;
    qtmpqry:TADOQuery;
    connTempMy:TADOConnection;
    moindex:integer;
    isSusp:boolean;
begin
    // Если мониторинг приостановлен, то выключаем приостановление
    issusp:=IsMonitoringSuspended;
    if issusp then MonitoringUnsuspend;
    if not TEquipment(self.owner).getMySQLIndex then begin
         Application.MessageBox(PChar('В базе данных не найдено оборудование с именем '+TEquipment(self.owner).name+'.'),'Ошибка');
         exit;
    end;
    // Проверить, есть ли данный интерфейс в списке интерфейсов БД
    intfcindex:=self.MySQLID;
    if intfcindex<0 then begin
        Application.MessageBox(PChar('В базе данных не найден интерфейс с именем '+self.name),'Ошибка');
        exit;
    end;
    if self.GetMonitoringStatus=mos_Monitoring then begin
       // Если мониторинг перед включением был приостановлен, а не выключен, то не выводить сообщение, а просто выйти
       if not issusp then begin
          Application.MessageBox(PChar('Мониторинг интерфейса '+self.name+' уже включен.'),'Информация');
       end;
       self.Check;
       exit;
    end;
    // Ищем ID записи отключения мониторинга
    CoInitialize(nil);
    connTempMy:=TADOConnection.Create(dm1);
    connTempMy.ConnectionString:=dm1.TplConnMySQL.ConnectionString;
    connTempMy.KeepConnection:=false;
    connTempMy.LoginPrompt:=false;
    qtmpqry:=TADOQuery.Create(dm1);
    qtmpqry.Connection:=connTempMy;
    qtmpqry.SQL.Add('select max(id) idoff from interface_monitoring_off where Active>0 and Equipment='+inttostr(TMobileEquipment(self.Owner).MySQLIndex)+' and ref_interface='+inttostr(intfcindex));
    qtmpqry.Open;
    moindex:=qtmpqry.FieldByName('idoff').AsInteger;
    qtmpqry.Close;
    FreeAndNil(qtmpqry);
    FreeAndNil(connTempMy);
    if moindex>0 then begin
        if DM1.qModify.Active then DM1.qModify.Close;
        DM1.qModify.SQL.Clear;
        DM1.qModify.SQL.Add('update interface_monitoring_off ');
        DM1.qModify.SQL.Add('set Active=0, datetimeend="'+FormatDateTime('yyyy-mm-dd hh:mm:ss',Now())+'"');
        DM1.qModify.SQL.Add('where id='+inttostr(moindex));
        DM1.qModify.ExecSQL;
        DM1.qModify.Close;
    end;
    self.Check;
end;

procedure CInterface.MonitoringSuspend(ResumeTime: TDateTime);
begin
     FResumeMonitoringDateTime:=ResumeTime;
end;

procedure CInterface.MonitoringSuspendByHour;
begin
     FResumeMonitoringDateTime:=Now()+1/24;
end;

procedure CInterface.MonitoringUnsuspend;
begin
     if FResumeMonitoringDateTime>Now() then FResumeMonitoringDateTime:=Now();
end;

{ TParameterInterface }

{ TWiFiInterface }

function TWiFiInterface.AddDisplayParameter(parameterName: string): boolean;
begin
     inherited;
     result:=false;
     if parameterName='LostPercent' then begin
        DisplayParameters.Add(LostPercent);
        result:=true;
     end;
end;

function TWiFiInterface.CheckInterface: boolean;
var //dt: TDate;
  //tm: TTime;
  dttm:TDateTime;
  countPings, countNotSignal, minCountPingToCalculate: integer;
  lostPerc, NoDataLostPercent:real;
  trdy: Boolean;
  eqnum:integer;
  interfaceNum, parameternum: Integer;
  checkHours:shortInt;
  qTempMysql:TADOquery;
  connTempMy:TADOConnection;
  MonStat:shortint;
  queryCreated:boolean;
  //idmodem:integer;
  idequip:integer;
begin
     result:=false;
     status:=0;
     // Искусственное создание ошибок для тестирования
     //status:=2;
     //exit;
     // Конец искусственного создания ошибок
    checkHours:=4; // Количество часов, за которые будет рассчитываться процент потерянных пакетов
    NoDataLostPercent:=7; // Порог срабатывания неисправности по WiFi связи
    minCountPingToCalculate:=240; // Минимальное количество пакетов, которое необходимо для расчетов
    queryCreated:=false;
    if GetMonitoringStatus<>mos_Disable then begin
       //tm:=Time();
       //dt:=Date();
       dttm:=Now;
          CoInitialize(nil);
          connTempMy:=TADOConnection.Create(dm1);
          connTempMy.ConnectionString:=dm1.TplConnMySQL.ConnectionString;
          connTempMy.KeepConnection:=false;
          connTempMy.LoginPrompt:=false;
          qTempMysql:=TADOQuery.Create(dm1);
          qTempMysql.Connection:=connTempMy;
       idequip:=TEquipment(Owner).MySQLIndex;
       qTempMySQL.SQL.Clear;
       // Выбираем, сколько всего было запросов в статусе готов
       qTempMySQL.SQL.Add('select s.signal_level from statss s');
       qTempMysql.SQL.Add('inner join stats_status ss on (s.id_equipment=ss.id_equipment) and (s.datetime>=ss.datetimestart) and (s.datetime<=ss.datetimeend)');
       qTempMysql.SQL.Add('where (s.id_equipment='+IntToStr(idequip)+') and (s.datetime>"'+MySQLDateTime(dttm-(1/24*checkHours))+'")');
       qTempMysql.SQL.Add('and (ss.id_equipment='+IntToStr(idequip)+') and (ss.datetimeend>"'+MySQLDateTime(dttm-(1/24*checkHours))+'") and (ss.status='+IntToStr(ms_ready)+')');
       try
         // Разблокируем доступ к объекту, пока идут вычисления
         TEquipment(Owner).Locked.Leave;
         qTempMySQL.Open;
         // Вычисляем количество всех записей и тех, где уровень сигнала был -100
         qTempMySQL.First;
         countPings:=0;
         countNotSignal:=0;
         while not qTempMySQL.Eof do begin
             inc(countPings);
             // Вычисляем неудачные пинги
             if qTempMySQL.FieldByName('signal_level').AsInteger=156 then inc(countNotSignal);
             qTempMySQL.Next;
         end;
         // Снова блокируем объект для записи данных
         TEquipment(Owner).Locked.Enter;
       except
         result:=false;
         FreeAndNil(qTempMysql);
         FreeAndNil(connTempMy);
         TEquipment(owner).Locked.Enter;
         exit;
       end;
       qTempMySQL.Close;
       // Если создавали новый запрос, то освобождаем память
       FreeAndNil(qTempMysql);
       FreeAndNil(connTempMy);
       status:=0;
       // В статусе Готов был не менее определенного времени за проверяемый интервал
       if countPings>0 then lostperc:=Round(countNotSignal/countPings*100*100)/100 else lostperc:=0;
       if countPings>minCountPingToCalculate then begin
          status:=1;
          if lostperc>NoDataLostPercent then status:=2;
       end;
       LostPercent.value:=formatFloat('#0.00',lostperc);
    end else status:=3;
    if status=2 then ErrorStr:=LostPercent.value+'% потерянных пакетов за последние '+IntToStr(checkHours)+' часов' ;
    result:=true;
end;

constructor TWiFiInterface.Create;
begin
  inherited;
  name:='WiFi';
  DisplayName:='WiFi';
  LostPercent:=TParameterInterface.Create();
  LostPercent.name:='LostPercent';
  LostPercent.displayName:='Потерь';
  LostPercent.value:='0';
  LostPercent.edizm:='%';
  LostPercent.FormatVal:='00,00';
end;

destructor TWiFiInterface.Destroy;
begin
  LostPercent.Free;
  Inherited;
end;

// Возвращает последний уровень сигнала WiFi за последние 30 секунд.
// Если за это время данных нет, то возвращает 0
function TWiFiInterface.GetLastSignal: shortint;
var qTemp:TADOQuery;
    connTempMy:TADOConnection;
begin
 try
     CoInitialize(nil);
     connTempMy:=TADOConnection.Create(dm1);
     connTempMy.ConnectionString:=DM1.TplConnMySQL.ConnectionString;
     connTempMy.KeepConnection:=false;
     connTempMy.LoginPrompt:=false;
     qTemp:=TADOQuery.Create(dm1);
     qTemp.Connection:=dm1.ConnMySQL;
     qTemp.SQL.Add('select signal_level from statss s, equipment e where (e.name="'+TEquipment(Owner).name+'")');
     qTemp.SQL.Add('and (s.id_equipment=e.id) and (s.datetime>="'+MySQLDateTime(Now-StrToTime('00:01:00'))+'") order by datetime');
     try
        qTemp.Open;
        qTemp.Last;
        if qTemp.RecordCount>0 then result:=qTemp.FieldByName('signal_level').AsInteger-256
           else result:=-100;
     except
        result:=0;
     end;
 finally
     FreeAndNil(qTemp);
     FreeAndNil(connTempMy);
     CoUninitialize;
 end;
end;

function TWiFiInterface.GetLostPercent(SecondsToCalc: integer): real;
var ConnTemp:TMyADOConnection;
    qTemp:TMyADOQuery;
    datestr:string;
    Nowdate, dt:TDate;
    dttm,dttm1:TDateTime;
    tm:TTime;
    mysqlid:integer;
    strs:TStrings;
  allCnt: Integer;
  successCnt: Integer;
  nm:string;
begin
    CoInitialize(nil);
    ConnTemp:=TMyADOConnection.Create(dm1,DM1.TplConnMySQL.ConnectionString);
    qTemp:=TMyADOQuery.Create(dm1,ConnTemp);
    dttm:=Now();
    Nowdate:=DateOf(dttm);
    dttm1:=dttm-(SecondsToCalc/24/3600);
    dt:=DateOf(dttm1);
    tm:=TimeOf(dttm1);
    mysqlid:=TMobileEquipment(Owner).MySQLIndex;
    if mysqlid=0 then begin
      FreeAndNil(qTemp);
      FreeAndNil(ConnTemp);
      result:=-1;
      exit;
    end;
    nm:=TMobileEquipment(Owner).name;
    qTemp.SQL.Add('select count(*) as cnt from statss s');
    qTemp.SQL.Add('where (s.id_equipment='+inttostr(mysqlid)+') and (s.datetime>"'+MySQLDateTime(dttm1)+'")');
    try
       qTemp.Open;
       qTemp.First;
        // Количество всех пакетов связи
        allCnt:=qTemp.FieldByName('cnt').AsInteger;
        qTemp.Close;
    except
       result:=-1;
       FreeAndNil(qTemp);
       FreeAndNil(ConnTemp);
       exit;
    end;
    qTemp.SQL.Add('and (s.signal_level>-100)');
    try
       qTemp.Open;
       qTemp.First;
       // Количество непотерянных сигналов
       successCnt:=qTemp.FieldByName('cnt').AsInteger;
       qTemp.Close;
    except
       result:=-1;
       FreeAndNil(qTemp);
       FreeAndNil(ConnTemp);
       exit;
    end;
    // вычисляем процент потерянных пакетов
    if allCnt>0 then begin
       result:=(allCnt-successCnt)/allCnt*100;
    end else result:=-1;
    FreeAndNil(qTemp);
    FreeAndNil(ConnTemp);
end;

{ TEquipment }


function TEquipment.AddInterface(interfaceName: string; MonitoringSetting:shortint): boolean;
begin
     result:=false;
end;

constructor TEquipment.Create;
begin
     inherited;
     FInterfacesEquipment:=CInterfaces.Create;
     FInterfacesEquipment.FOwner:=self;
     Locked:=TCriticalSection.Create;
     GetMySQLIndex;
end;

destructor TEquipment.Destroy;
begin
     FinterfacesEquipment.Free;
     Locked.Free;
end;

function TEquipment.FindInterfaceByName(InterfaceName: string): CInterface;
var i:integer;
begin
     result:=nil;
     for I := 0 to Interfaces.count-1 do begin
         if Interfaces[i].name=InterfaceName then result:=Interfaces[i];
     end;
end;

// Присвоение статуса оборудованию на основе статусов его интерфейсов
function TEquipment.GetStatus: TStatus;
var i:integer;
begin
     result:=s_unknown;
     for I := 1 to Interfaces.count do begin
         if Interfaces[i].status=s_NotReady then result:=s_NotReady;
         if (result<>s_NotReady) and (Interfaces[i].status=s_NoData) then result:=s_NoData;
         if (not (result in [s_NotReady,s_NoData])) and (Interfaces[i].status=s_restored) then result:=s_restored;
         if (not (result in [4,2,6])) and (Interfaces[i].status=5) then result:=5;
         if (not (result in [4,2,6,5])) and (Interfaces[i].status=1) then result:=1;
         if (not (result in [4,2,6,5,1])) and (Interfaces[i].status=3) then result:=3;
     end;
     //if (ClassParent=TMobileEQModular) and (not TMobileEQModular(self).IsReadyModular) and (result in [s_unknown, s_Work]) then result:=s_NotReady;
end;


function TMobileEQModular.AddInterface(interfaceName: string;
  MonitoringSetting: shortint): boolean;
begin
     result:=false;
     result:=inherited AddInterface(interfaceName,MonitoringSetting);
     if interfaceName='GPS' then begin
        Interfaces.Add(GPS,MonitoringSetting);
        result:=true;
     end;
end;

constructor TMobileEQModular.Create;
begin
     inherited;
     GPS:=TGpsInterface.Create;
     GPS.Owner:=self;
     waitGBM:=TWaitGBM.Create(self);
     waitList.Add(@waitGBM);
end;

destructor TMobileEQModular.Destroy;
begin
    FreeAndNil(waitGBM);
    FreeAndNil(GPS);
    inherited;
end;

function TMobileEQModular.GetFullModularStatus: TModularStatus;
var mstat:TModularStatus;
    connTempD6:TMyADOConnection;
    qTemp:TMyADOQuery;
  currentshift: Integer;
  rsn:integer;
begin
     result.status:=ms_unknown;
     result.reason:='Неизвестно';
     {mstat.shiftindex:=0;
     mstat.starttime:=0;
     mstat.endtime:=0;
     mstat.status:=ms_unknown;
     mstat.reason:='';
     connTempD6:=TMyADOConnection.Create(dm1,dm1.tplConnD6.connectionString);
     qTemp:=TMyADOQuery.Create(dm1,connTempD6);
     qTemp.SQL.Clear;
     currentshift:=GetShiftindex(Now());
     qTemp.SQL.Add('select se.starttime, se.endtime, se.status, se.reason, rt.[name]');
     qTemp.SQL.Add('from hist_statusevents se left join hist_reasontable rt ');
     qTemp.SQL.Add('on (se.shiftindex=rt.shiftindex) and (se.reason=rt.reason)');
     qTemp.SQL.Add('where (se.shiftindex='+inttostr(currentshift)+') and (eqmt='+#39+Self.name+#39+')');
     qTemp.SQL.Add('order by starttime');
     try
        qTemp.Open;
        if qTemp.RecordCount>0 then begin
           qTemp.Last;
           mstat.shiftindex:=currentshift;
           mstat.starttime:=qTemp.FieldByName('starttime').AsInteger;
           mstat.endtime:=qTemp.FieldByName('endtime').AsInteger;
           mstat.status:=qTemp.FieldByName('status').AsInteger;
           mstat.reason:=qTemp.FieldByName('name').AsString;
           rsn:=qTemp.FieldByName('reason').AsInteger;
        end;
        qTemp.Close;
        // Если статус начинается с начала смены, то проверяем предыдущие смены,
        // чтобы понять, когда он наступил
        if mstat.starttime=0 then begin
           qTemp.SQL.Clear;
           qTemp.SQL.Add('select se.shiftindex, se.starttime, se.endtime from hist_statusevents');
           qTemp.SQL.Add('where (eqmt='+#39+Self.name+#39') and () ');
        end;
     except

     end;
     result:=mstat;
     FreeAndNil(qTemp);
     FreeAndNil(connTempD6); }
end;

function TMobileEquipment.GetFullSystemStatus: TFullStatsStatus;
var
  connMy1: TMyADOConnection;
  QMy1: TMyADOQuery;
  dttm1: TDateTime;
  dttmend: TDatetime;
begin
     result.status:=ms_unknown;
     result.dttmstart:=0;
     result.dttmEnd:=0;
     result.reasonname:='';
     try
        CoInitialize(nil);
        connMy1:=TMyADOConnection.Create(nil,DM1.ConnMySQL.ConnectionString);
        QMy1:=TMyADOQuery.Create(nil,connMy1);
        dttm1:=Now();
        QMy1.SQL.Add('select status, datetimestart, datetimeend, reason_name from stats_status ');
        QMy1.SQL.Add('where (id_equipment='+IntToStr(self.MySQLIndex)+')');
        QMy1.SQL.Add('and (datetimeend>"'+MySQLDateTime(dttm1-1/24)+'")');
        QMy1.SQL.Add('order by datetimeend desc limit 1');
        try
           QMy1.Open;
           if QMy1.RecordCount>0 then begin
               dttmend:=QMy1.FieldByName('datetimeend').AsDateTime;
               if (dttm1-dttmend)<(1/24) then begin
                  result.status:=QMy1.FieldByName('status').AsInteger;
                  result.dttmstart:=QMy1.FieldByName('datetimestart').AsDateTime;
                  result.dttmEnd:=QMy1.FieldByName('datetimeend').AsDateTime;
                  result.reasonname:=QMy1.FieldByName('reason_name').AsString;
               end;
           end;
           QMy1.Close;
           {if self.ClassParent=TKobusEquipment then begin
                 // Для Кобуса не пишутся статусы в работе
                 // Так что, для него считаем, что статус в работе,
                 // если простой закончился больше 6 минут назад
                 if (dttm1-dttmend)>1/24/60*6 then begin
                    result.status:=ms_ready;

                 end;
           end;}
        except
           result.status:=ms_unknown
        end;
     finally
        FreeAndNil(Qmy1);
        FreeAndNil(connMy1);
        CoUninitialize;
     end;
end;

function TMobileEquipment.GetModemIdx: integer;
var ConnTemp:TMyADOConnection;
    qTemp:TMyADOQuery;
begin
     // Узнаем id модема оборудования
       ConnTemp:=TMyADOConnection.Create(dm1,DM1.TplConnMySQL.ConnectionString);
       qTemp:=TMyADOQuery.Create(dm1,ConnTemp);
       qTemp.SQL.Add('select id_modem from modems m where m.name="'+TMobileEquipment(self).name+'"');
       try
          qTemp.Open;
          qTemp.First;
          result:=qTemp.FieldByName('id_modem').AsInteger;
       except
          result:=0;
       end;
        FreeAndNil(qTemp);
        FreeAndNil(connTemp);
end;

function TMobileEQModular.GetModularReadySeconds: integer;
var shiftid:integer;
    qModularStatus:TMyADOQuery;
    connTempPV:TMyADOConnection;
begin
         result:=-1;
         {shiftid:=DateToShift(Date(),Time());
         CoInitialize(nil);
         connTempPV:=TMyADOConnection.Create(dm1,dm1.tplConnPV.ConnectionString);
         qModularStatus:=TMyADOQuery.Create(dm1,connTempPV);
         qModularStatus.SQL.Clear;
         qModularStatus.SQL.Add('select starttime, status from hist_statusevents');
         qModularStatus.SQL.Add('where (shiftindex='+IntToStr(shiftid)+') and (eqmt='+#39+name+#39+') order by starttime');
         try
             qModularStatus.Open;
             qModularStatus.Last;
             if (qModularStatus.RecordCount>0) then begin
                if qModularStatus.FieldByName('status').AsInteger=ms_ready then begin
                   result:=round((Now-ShiftAndSecToDateTime(shiftid,qModularStatus.FieldByName('starttime').AsInteger-1))*24*3600);
                end;
             end else Result:=-1;
             qModularStatus.Close;
         except
             result:=ms_unknown;
         end;
         FreeAndNil(qModularStatus);
         FreeAndNil(connTempPV); }
end;

function TMobileEQModular.GetModularStatus: integer;
var shiftid:integer;
    qModularStatus:TADOQuery;
    connTempPV:TADOConnection;
    queryCreated:boolean;
begin
         result:=ms_unknown;
         {shiftid:=DateToShift(Date(),Time());
            CoInitialize(nil);
         connTempPV:=TADOConnection.Create(dm1);
         connTempPV.ConnectionString:=dm1.tplConnPV.ConnectionString;
         connTempPV.KeepConnection:=false;
         connTempPV.LoginPrompt:=false;
           qModularStatus:=TADOQuery.Create(dm1);
           qModularStatus.Connection:=connTempPV;
         qModularStatus.SQL.Clear;
         qModularStatus.SQL.Add('select starttime, status from hist_statusevents');
         qModularStatus.SQL.Add('where (shiftindex='+IntToStr(shiftid)+') and (eqmt='+#39+name+#39+') order by starttime');
         try
             qModularStatus.Open;
             qModularStatus.Last;
             if (qModularStatus.RecordCount>0) then Result:=qModularStatus.FieldByName('status').AsInteger
                else Result:=ms_unknown;
             qModularStatus.Close;
         except
             result:=ms_unknown;
         end;
         FreeAndNil(qModularStatus);
         FreeAndNil(connTempPV);   }

end;

function TMobileEQModular.GetPosition: string;
var qTemp:TMyADOQuery;
    connTempPV:TMyADOConnection;
  ConnD6temp: TMyADOConnection;
  Qloc: TMyADOQuery;
begin
    result:='';
    try
      ConnD6temp:=TMyADOConnection.Create(nil,dm1.tplConnD6.ConnectionString);
      Qloc:=TMyADOQuery.Create(nil,ConnD6temp);
      Qloc.SQL.Add('select l.fieldid as loc from pittruck t left join PITPitloc l on (t.fieldloc=l.id)');
      Qloc.SQL.Add('where t.FieldId=''@eqname''');
      Qloc.vars.Add('eqname',self.name);
      try
        Qloc.Open;
        if Qloc.RecordCount>0 then result:=QLoc.FieldByName('loc').AsString;
      except
        result:='';
      end;
    finally
      FreeAndNil(QLoc);
      FreeAndNil(connD6temp);
    end;
end;

function TMobileEquipment.GetPowerStatus: TEquipmentPowerStatus;
var
  sig: integer;
  connTemp:TMyADOConnection;
  qTemp:TMyADOQuery;
begin
     result:=PS_unknown;
     try
       CoInitialize(nil);
       connTemp:=TMyADOConnection.Create(dm1,dm1.TplConnMySQL.ConnectionString);
       qTemp:=TMyADOQuery.Create(dm1,connTemp);
       qTemp.SQL.Add('select time_ping from stats_ping where (id_equipment=@eqid) and (datetime between "@starttm" and "@nowtm")');
       qTemp.vars.Add('eqid',inttostr(self.MySQLIndex));
       qTemp.vars.Add('starttm',MySQLDateTime(Now()-1/24/60*1.5));
       qTemp.vars.Add('nowtm',MySQLDateTime(Now()));
       qTemp.ReplaceVars;
       try
          qTemp.Open;
          while (not qTemp.Eof) and (result=PS_unknown) do begin
              if qTemp.FieldByName('time_ping').AsInteger>-100 then result:=PS_on;
              qTemp.Next;
          end;
          if (result<>PS_on) and (qTemp.RecordCount>0) then result:=PS_off;
          qTemp.Close;
       except
          Result:=PS_unknown;
          exit;
       end;
     finally
       FreeAndNil(qTemp);
       FreeAndNil(connTemp);
     end;
end;

function TMobileEquipment.getReadySeconds: integer;
var
  st: TFullStatsStatus;

begin
     st:=GetFullSystemStatus;
     if st.status=ms_ready then begin
        result:=trunc((Now()-st.dttmstart)*24*3600);
     end else result:=0;
end;

function TMobileEquipment.GetStatus: TStatus;
begin
     result:=inherited;
     if (result=s_Work) and (self.GetSystemStatus in [ms_damage,ms_delay,ms_wait]) then result:=s_NotReady;
end;

function TMobileEquipment.GetSystemStatus: TStatssStatus;
var stat:TFullStatsStatus;
begin
    stat:=GetFullSystemStatus;
    result:=stat.status;
end;

// Функция получения индекса оборудования в таблице MySQL
function TEquipment.GetMySQLIndex : boolean;
var qEquipment:TMyADOQuery;
    connTempMy:TMyADOConnection;
begin
     result:=false;
     if DM1.ConnectedDBUbiquiti then begin
            connTempMy:=TMyADOConnection.Create(dm1,dm1.TplConnMySQL.ConnectionString);
            qEquipment:=TMyADOQuery.Create(DM1,connTempMy);
            qEquipment.SQL.Clear;
            qEquipment.SQL.Add('select id from equipment where name="'+self.Fname+'"');
            qEquipment.Open;
            qEquipment.Last;
            qEquipment.First;
            if qEquipment.RecordCount<>0 then begin
               FMySQLIndex:=qEquipment.FieldByName('id').AsInteger;
               result:=true;
            end;
            qEquipment.Close;
            FreeAndNil(qEquipment);
            FreeAndNil(connTempMy);
     end;

end;

class function TEquipment.GetMySQLIndexByName(name: string): integer;
var qEquipment:TMyADOQuery;
    connTempMy:TMyADOConnection;
begin
     result:=0;
     try
            connTempMy:=TMyADOConnection.Create(dm1,dm1.TplConnMySQL.ConnectionString);
            qEquipment:=TMyADOQuery.Create(DM1,connTempMy);
            qEquipment.SQL.Clear;
            qEquipment.SQL.Add('select id from equipment where name="'+name+'"');
            qEquipment.Open;
            qEquipment.Last;
            qEquipment.First;
            if qEquipment.RecordCount<>0 then begin
               result:=qEquipment.FieldByName('id').AsInteger;
            end;
            qEquipment.Close;
            FreeAndNil(qEquipment);
            FreeAndNil(connTempMy);
     except
        result:=-1;
     end;
end;

function TMobileEQModular.IsReadyModular: boolean;
begin
     if self.GetSystemStatus=2 then result:=true else result:=false;
end;

procedure TMobileEquipment.SetModemIP(value: string);
begin
     if IsIPAddress(Value) then FModemIP := Value else FModemIP:='';
end;

// Вместо самописных блокировок используются критические секции
{function TEquipment.Lock:boolean;
var slp,cnt:integer;
begin
     slp:=50;
     cnt:=0;
     while FBusy and (cnt<100) do begin
         inc(cnt);
         sleep(slp);
     end;
     if not FBusy then begin
        Fbusy:=true;
        result:=true;
     end else result:=false;
end;}

function TEquipment.Pinged: boolean;
var slp:integer;
    cntretry:integer;
    data1:string;
    failPing:integer;
begin
     {result:=false;
     if IsIPAddress(IPAddress) then begin
        cntretry:=0;
        if not OSSH.Lock then exit;
        slp:=OSSH.sleeptm;
        OSSH.Answer.Clear;
        OSSH.sleeptm:=5000;
        OSSH.command:='ping -c 3 '+IPAddress+' | grep -c Unreach';
        // Если команда выполнена успешно, то проверяем полученный результат, чтобы там была цифра 3
        if OSSH.Execute then begin
           if OSSH.Answer.Count>0 then data1:=OSSH.Answer.Strings[OSSH.Answer.Count-1] else data1:='';
           if data1<>'' then begin
              try
                 failPing:=StrToInt(data1);
                 if failPing=0 then result:=true;
              except

              end;
           end;
        end;
        OSSH.sleeptm:=slp;
        OSSH.Unlock;
     end else Application.MessageBox(PChar('Строка '+IPAddress+' не является IP-адресом'),'Ошибка') ; }
end;

procedure TEquipment.SetIPAddress(const Value: string);
begin
  if IsIPAddress(Value) then FIPAddress := Value else FIPAddress:='';
end;

{procedure TEquipment.Unlock;
begin
     FBusy:=false;
end;}

{ TMobileEquipment }

function TEquipment.getIPAddress: string;
var qEquipment:TMyADOQuery;
    connTempMy:TMyADOConnection;
begin
        result:='';
        connTempMy:=TMyADOConnection.Create(dm1,dm1.TplConnMySQL.ConnectionString);
        qEquipment:=TMyADOQuery.Create(DM1,connTempMy);
        qEquipment.Active:=false;
        qEquipment.SQL.Add('select ip_address from equipment where name="'+self.Fname+'"');
        try
          qEquipment.Open;
        except
          result:='';
        end;
        qEquipment.Last;
        qEquipment.First;
        if qEquipment.RecordCount<>0 then begin
           result:=qEquipment.FieldByName('ip_address').AsString;
        end;
        qEquipment.Close;
        qEquipment.Free;
end;

{ TExcav }

function TMobileEquipment.AddInterface(interfaceName: string; MonitoringSetting:shortint): boolean;
begin
     result:=false;
     result:=inherited AddInterface(interfaceName,MonitoringSetting);
     if interfaceName='WiFi' then begin
        Interfaces.Add(WiFi,MonitoringSetting);
        result:=true;
     end;
     if interfaceName='PingPC' then begin
        interfaces.Add(PingPC,MonitoringSetting);
        Result:=true;
     end;
     if interfaceName='LTE' then begin
        Interfaces.Add(LTE,MonitoringSetting);
        result:=true;
     end;
end;

constructor TMobileEquipment.Create;
begin
      inherited;
      WiFi:=TWiFiInterface.Create;
      Wifi.Owner:=Self;
      PingPC:=TPingPCInterface.Create;
      PingPC.Owner:=self;
      //GPS:=TGpsInterface.Create;
      //GPS.Owner:=self;
      LTE:=TLTEInterface.Create;
      LTE.Owner:=self;
      waitPowerOn:=TWaitPowerOn.Create(self);
      waitPowerOff:=TWaitPowerOff.Create(self);
      waitNotWork:=TWaitNotWork.Create(self);
      //waitGBM:=TWaitGBM.Create(self);
      waitList:=TList.Create;
      waitList.Add(@waitPowerOn);
      waitList.Add(@waitPowerOff);
      waitList.Add(@waitNotWork);
      //waitList.Add(@waitGBM);
end;

destructor TMobileEquipment.Destroy;
begin
      FreeAndNil(WiFi);
      //FreeAndNil(GPS);
      FreeAndNil(PingPC);
      FreeAndNil(LTE);
      waitList.Clear;
      FreeAndNil(waitList);
      FreeAndNil(waitPowerOn);
      FreeAndNil(waitPowerOff);
      FreeAndNil(waitNotWork);
      //FreeAndNil(waitGBM);
      inherited;
end;

{ TSettingsOld }


constructor TSettingsOld.Create;
begin
     inherited;
     Sound:=TNotificationSound.Create;
     sound.FSettingFileName:=FileName;
end;

procedure TSettingsOld.CreateNewVersionsSettings(var iniFile: TIniFile);
begin
     if versionLess(ApplVersion,stringToApplVersion('4.1')) and (not iniFile.ValueExists('Update','UpdateEnabled')) then begin
        iniFile.WriteBool('Update','UpdateEnabled',true);
        if User='asugtkadm' then begin
           iniFile.WriteString('Update','UpdateFolder','W:\УКиСС\Участок АСУ ГТК\programs\ASUGTKMonitor\Update\');
        end else begin
           iniFile.WriteString('Update','UpdateFolder','O:\ДИТ\АСУ ГТК\ASUGTKMonitor\');
        end;
     end;
     if versionLess(ApplVersion,stringToApplVersion('4.1.12')) then begin
        if user='asugtkadm' then begin
           iniFile.WriteInteger('BaseSettings','sleepTimeServers',120);
        end;
     end;
     if versionLess(ApplVersion,stringToApplVersion('4.3.2')) then begin
        if user='asugtkadm' then begin
           iniFile.WriteInteger('interfaces','GPS',1);
           iniFile.WriteInteger('GPS','LastGPSDateTime',1);
        end;
     end;
     if versionLess(ApplVersion,stringToApplVersion('4.4')) and (not iniFile.ValueExists('BaseSettings','ShowNetwork')) then begin
        if user='asugtkadm' then begin
           iniFile.WriteInteger('BaseSettings','ShowNetwork',1);
        end;
     end;
     if versionLess(ApplVersion,stringToApplVersion('4.5.1')) and (not iniFile.ValueExists('interfaces','Omnicomm')) then begin
        if user='atu' then begin
           iniFile.WriteInteger('interfaces','Omnicomm',1);
        end;
     end;
     if versionLess(ApplVersion,stringToApplVersion('4.5.3')) and (not iniFile.ValueExists('interfaces','Avail')) then begin
        if user='asugtkadm' then begin
           iniFile.WriteInteger('interfaces','Avail',1);
        end;
     end;
     if versionLess(ApplVersion,stringToApplVersion('4.6.8')) and (not iniFile.ValueExists('BaseSettings','ShowTrucks')) then begin
           iniFile.WriteInteger('BaseSettings','ShowTrucks',1);
     end;
     if versionLess(ApplVersion,stringToApplVersion('4.7.12')) and (not iniFile.ValueExists('interfaces','Weight')) then begin
            if user='atu' then begin
              iniFile.WriteInteger('interfaces','Weight',1);
            end;
     end;
     // Создание переменной для отображения списка бурстанков
     if VersionLess(ApplVersion,stringToApplVersion('4.9')) and (not iniFile.ValueExists('BaseSettings','ShowDrills')) then begin
          if user='asugtkadm' then begin
           iniFile.WriteInteger('BaseSettings','ShowDrills',2);
        end;
     end;
     if VersionLess(ApplVersion,stringToApplVersion('4.14.1')) and (not iniFile.ValueExists('interfaces','PingPC')) then begin
          if user='asugtkadm' then begin
           iniFile.WriteInteger('interfaces','PingPC',1);
           iniFile.WriteInteger('PingPC','LostPercent',1);
        end;
     end;
     if VersionLess(ApplVersion,stringToApplVersion('4.15.6')) and (not iniFile.ValueExists('interfaces','LTE')) then begin
          if user='asugtkadm' then begin
           iniFile.WriteInteger('interfaces','LTE',1);
           iniFile.WriteInteger('LTE','LostPercent',1);
        end;
     end;
end;

destructor TSettingsOld.Destroy;
begin
    Sound.Free;
end;

function TSettingsOld.getApplVersion: TApplVersion;
var iniFile:TIniFile;
begin
     if FileExists(FileName) then begin
        inifile:=TIniFile.Create(FileName);
        result.Major:=iniFile.ReadInteger('Version','Major',0);
        Result.Minor:=iniFile.ReadInteger('Version','Minor',0);
        Result.Release:=iniFile.ReadInteger('Version','Release',0);
        Result.build:=iniFile.ReadInteger('Version','build',0);
        FreeAndNil(iniFile);
     end;
end;

function TSettingsOld.GetInterfaceIndexByName(interfacename: string): integer;
var i:integer;
begin
     result:=-1;
     for I := 0 to getInterfacesCount - 1 do begin
         if LowerCase(interfacename)=LowerCase(interfaces[i].name) then result:=i;
         if result>-1 then break;
     end;
end;

function TSettingsOld.getInterfacesCount: integer;
begin
     result:=Length(interfaces);
end;

function TSettingsOld.getIsAdmin: boolean;
begin
     if User='asugtkadm' then result:=true else result:=false;
end;

function TSettingsOld.GetSleepTimeCategoryValue(value: integer): integer;
begin
     if value<1 then result:=SleepTimeSeconds else result:=value;
end;

function TSettingsOld.GetSleepTimeDrills: integer;
begin
        result:=GetSleepTimeCategoryValue(FSleepTimeDrills);
end;

function TSettingsOld.GetSleepTimeEquipment: integer;
begin
     result:=GetSleepTimeCategoryValue(FSleepTimeEquipment);
end;

function TSettingsOld.GetSleepTimeExcavs: integer;
begin
     result:=GetSleepTimeCategoryValue(FSleepTimeExcavs);
end;

function TSettingsOld.GetSleepTimeNetwork: integer;
begin
  result:=GetSleepTimeCategoryValue(FSleepTimeNetwork);
end;

function TSettingsOld.GetSleepTimeServers: integer;
begin
     result:=GetSleepTimeCategoryValue(FSleepTimeServers);
end;

function TSettingsOld.getTasksCount: integer;
begin
     result:=Length(tasks);
end;

function TSettingsOld.GetUserGroup(username: string): TUserGroup;
var ConnTemp:TMyADOConnection;
    qTemp:TMyADOQuery;
begin
    ConnTemp:=TMyADOConnection.Create(dm1,DM1.TplConnMySQL.ConnectionString);
    qTemp:=TMyADOQuery.Create(dm1,ConnTemp);
    qTemp.SQL.Clear;
    qTemp.SQL.Add('select u.id, u.groupid from users u where login="'+username+'"');
    try
       qTemp.Open;
    except
       result:=ug_unknown;
       FreeAndNil(qTemp);
       FreeAndNil(ConnTemp);
       exit;
    end;
    qTemp.Last;
    if qTemp.RecordCount>0 then result:=qTemp.FieldByName('groupid').AsInteger
      else result:=ug_unknown;
    qTemp.Close;
    FreeAndNil(qTemp);
    FreeAndNil(ConnTemp);
end;

procedure TSettingsOld.GetUserid(username: string);
var ConnTemp:TMyADOConnection;
    qTemp:TMyADOQuery;
begin
    ConnTemp:=TMyADOConnection.Create(dm1,DM1.TplConnMySQL.ConnectionString);
    qTemp:=TMyADOQuery.Create(dm1,ConnTemp);
    qTemp.SQL.Clear;
    qTemp.SQL.Add('select u.id from users u where login="'+username+'"');
    try
        qTemp.Open;
    except
       FUserID:=0;
       FreeAndNil(qTemp);
       FreeAndNil(ConnTemp);
       exit;
    end;
    qTemp.Last;
    if qTemp.RecordCount>0 then FUserID:=qTemp.FieldByName('id').AsInteger
       else FUserID:=0;
    qTemp.Close;
    FreeAndNil(qTemp);
    FreeAndNil(ConnTemp);
end;

function TSettingsOld.ReadSettings(SettingsFileName: string): boolean;
var iniFile:TIniFile;
    vars, pars1:TStrings;
    i,j,k,l:integer;
    PossibleTasks:TStrings;
    PossibleInterfaces:TStrings;
    finfo:TFileInfo;
    fVers:TApplVersion;
begin
  PossibleInterfaces:=TStringList.Create;
  {PossibleInterfaces.Add('WiFi');
  PossibleInterfaces.Add('GPS');
  PossibleInterfaces.Add('Pressure');
  PossibleInterfaces.Add('VEI');
  PossibleInterfaces.Add('Omnicomm');
  PossibleInterfaces.Add('Avail');}
  PossibleTasks:=TStringList.Create;
  // 2020-04-09 Убираем проверку возможных
  {PossibleTasks.Add('ResetPresspro');
  PossibleTasks.Add('DrawPitgraph');
  PossibleTasks.Add('GetGPSInformation');
  PossibleTasks.Add('DrawPitASUGTK');
  PossibleTasks.Add('CalcWiFiStatEQ');}
  if FileExists(settingsFileName) then begin
     FfileName:=SettingsFileName;
     inifile:=TIniFile.Create(settingsFileName);
     FUser:=iniFile.ReadString('Security','User','guest');
     // 2018-12-14 Получаем группу пользователя
     FUserGroup:=getUserGroup(FUser);
     GetUserid(FUser);
     // Запись первичных настроек для новых функций новых версий
     CreateNewVersionsSettings(iniFile);
     // Конец записи первичных настроек для новых функций новых версий
     sleeptimeSeconds:=inifile.ReadInteger('BaseSettings','sleepTime',600);
     FCopyExe:=iniFile.ReadBool('BaseSettings','CopyExe',false);
     NotCheckServers:=iniFile.ReadBool('BaseSettings','NotCheckServers',false);
     NotShowErrors:=iniFile.ReadBool('BaseSettings','NotShowErrors',false);
     ShowTrucks:=iniFile.ReadBool('BaseSettings','ShowTrucks',false);
     ShowExcavs:=iniFile.ReadBool('BaseSettings','ShowExcavs',false);
     ShowNetwork:=iniFile.ReadBool('BaseSettings','ShowNetwork',false);
     ShowDrills:=iniFile.ReadBool('BaseSettings','ShowDrills',false);
     MonitoringLog:=iniFile.ReadBool('BaseSettings','MonitoringLog',false);
     AutoEnableMonitoring:=iniFile.ReadBool('BaseSettings','AutoEnableMonitoring',true);
     // Чтение настроек размера окна
     FClientWidth:=iniFile.ReadInteger('View','ClientWidth',770);
     FClientHeight:=iniFile.ReadInteger('View','ClientHeight',600);
     FShowClock:=iniFile.ReadBool('View','ShowClock',true);
     // Чтение информации об обновлении
     FUpdateEnabled:=iniFile.ReadBool('Update','UpdateEnabled',false);
     FUpdateFolder:=iniFile.ReadString('Update','UpdateFolder','');
     FUpdatePostfix:=iniFile.ReadString('Update','UpdatePostfix','');
     FSleepTimeEquipment:=iniFile.ReadInteger('BaseSettings','sleepTimeEquipment',0);
     FSleepTimeExcavs:=iniFile.ReadInteger('BaseSettings','sleepTimeExcavs',0);
     FSleepTimeServers:=iniFile.ReadInteger('BaseSettings','sleepTimeServers',0);
     FSleepTimeDrills:=iniFile.ReadInteger('BaseSettings','sleepTimeDrills',0);
     FLastCheckDateTime:=iniFile.ReadDateTime('statistic','LastCheckDateTime',0);
     sound.FSettingFileName:=FileName;
     Sound.FEnable:=iniFile.ReadBool('Sound','Enable',true);
     Sound.Fduration:=iniFile.ReadInteger('Sound','Duration',60);
     vars:=TStringList.Create;
     iniFile.ReadSection('Interfaces',vars);
     pars1:=TStringList.Create;
     j:=0;
     for i := 0 to vars.Count - 1 do begin
         if (vars[i]<>'') {and (PossibleInterfaces.IndexOf(vars[i])>-1)} then begin
            inc(j);
            SetLength(interfaces,j);
            interfaces[j-1].name:=vars[i];
            interfaces[j-1].MonitoringStatus:=iniFile.ReadInteger('interfaces',vars[i],1);
            // Проставляем статус мониторинга
            // 0 - Только выводить интерфейс в таблицу и не производить проверку
            // 1 - Выполнять проверки и выводить сообщение о неисправностях
            // 2 - Выполнять проверки, но не выаодить сообщения о неисправностях (для неважных интерфейсов)
            if interfaces[j-1].MonitoringStatus>2 then interfaces[j-1].MonitoringStatus:=1;
            iniFile.ReadSection(interfaces[j-1].name,pars1);
            l:=0;
            for k := 0 to pars1.count - 1 do begin
              if (pars1[k]<>'') and (pars1[k]<>' ') then begin
                 inc(l);
                 SetLength(interfaces[j-1].parameters,l);
                 interfaces[j-1].parameters[l-1]:=pars1[k];
              end;
            end;
         end;
     end;
     // Читаем настройки задач
     vars.Clear;
     iniFile.ReadSection('Tasks',vars);
     j:=0;

     for I := 0 to vars.Count - 1 do begin
         if (vars[i]<>'') {and (PossibleTasks.IndexOf(vars[i])>-1)} then begin
            inc(j);
            SetLength(tasks,j);
            tasks[j-1].name:=vars[i];
            tasks[j-1].sleeptimeSec:=iniFile.ReadInteger('Tasks',vars[i],3600);
            if (tasks[j-1].sleeptimeSec<60) and (tasks[j-1].sleeptimeSec<>0) then begin
               Application.MessageBox('Промежуток между выполнением задач не должен быть меньше 1 минуты','Ошибка');
               iniFile.WriteInteger('Tasks',vars[i],60);
               tasks[j-1].sleeptimeSec:=60;
            end;
         end;
     end;
     // Конец чтения настроек задач
     // Запись запущенной версии программы в файл настроек
     GetFileInfo(Application.ExeName,finfo);
     fVers.Major:=finfo.FileVersion.MajorVersion;
     fVers.Minor:=finfo.FileVersion.MinorVersion;
     fVers.Release:=finfo.FileVersion.Release;
     fVers.build:=finfo.FileVersion.Build;
     ApplVersion:=fVers;
     // Конец записи запущенной версии программы в файл настроек
     iniFile.Destroy;
     FreeAndNil(vars);
     FreeAndNil(pars1);
  end else begin
     FfileName:='';
     sleeptimeSeconds:=600;
     FCopyExe:=false;
     SetLength(interfaces,0);
     setLength(tasks,0);
  end;
  FreeAndNil(PossibleTasks);
  FreeAndNil(PossibleInterfaces);
end;

function TSettingsOld.SaveToXML(flname: string): boolean;
procedure SaveSettings(var nd:IXMLNode);
var tmpnd,tmpnd2:IXMLNode;
begin
     // Информация о безопасности
     tmpnd:=nd.AddChild('security');
     tmpnd2:=tmpnd.AddChild('user');
     tmpnd2.NodeValue:=self.User;
     // Основные настройки
     tmpnd:=nd.AddChild('sleeptimeseconds');
     tmpnd.NodeValue:=Self.SleepTimeSeconds;
     if self.CopyExe then begin
        tmpnd:=nd.AddChild('copyexe');
        tmpnd.NodeValue:='1';
     end;
     if not self.NotCheckServers then begin
        tmpnd:=nd.AddChild('checkservers');
        tmpnd.NodeValue:='1';
     end;
     if self.NotShowErrors then begin
        tmpnd:=nd.AddChild('showerrors');
        tmpnd.NodeValue:='0';
     end;

end;
var XMLS:TXMLDocument;
    setnode:IXMLNode;
begin
     // Удаляем старый файл
     if FileExists(flname) then DeleteFile(flname);
     XMLS:=TXMLDocument.Create(dm1);
     XMLS.XML.Clear;
     XMLS.Active:=true;
     XMLS.Version:='1.0';
     setnode:=XMLs.AddChild('settings');
     SaveSettings(setnode);
end;

procedure TSettingsOld.SetApplVersion(value: TApplVersion);
var iniFile1:TIniFile;
begin
     if FileExists(FileName) then begin
        inifile1:=TIniFile.Create(FileName);
        iniFile1.WriteInteger('Version','Major',value.Major);
        iniFile1.WriteInteger('Version','Minor',value.Minor);
        iniFile1.WriteInteger('Version','Release',value.Release);
        iniFile1.WriteInteger('Version','build',value.build);
        iniFile1.UpdateFile;
        iniFile1.Destroy;
     end;
end;

procedure TSettingsOld.SetAutoEnableMonitoring(value: boolean);
var str:string;
begin
     if value=true then str:='1' else str:='0';
     if SetSetting('BaseSettings','AutoEnableMonitoring',str) then FAutoEnableMonitoring:=value;
end;

procedure TSettingsOld.SetClientSizes(width: integer; height:integer);
var iniFile:TIniFile;
begin
     if FileExists(FileName) and (width>100) and (height>100) then begin
         iniFile:=TIniFile.Create(FileName);
         iniFile.WriteInteger('View','ClientHeight',height);
         iniFile.WriteInteger('View','ClientWidth',width);
         iniFile.UpdateFile;
         FreeAndNil(iniFile);
     end;
end;

procedure TSettingsOld.SetLastCheckDateTime(value: TDateTime);
var iniFile:TIniFile;
begin
     FLastCheckDateTime:=value;
     if FileExists(FileName) then begin
        iniFile:=TIniFile.Create(FileName);
        iniFile.WriteDateTime('statistic','LastCheckDateTime',value);
        iniFile.UpdateFile;
        FreeAndNil(iniFile);
     end;
end;

function TSettingsOld.SetSetting(category, variable, value: string): boolean;
var iniFile:TIniFile;
begin
     result:=false;
     if FileExists(FileName) then begin
        iniFile:=TIniFile.Create(FileName);
        iniFile.WriteString(category,variable,value);
        iniFile.UpdateFile;
        FreeAndNil(iniFile);
        result:=true;
     end;
end;

procedure TSettingsOld.setShowClock(value: boolean);
var str:string;
begin
     if value=true then str:='1' else str:='0';
     if SetSetting('View','ShowClock',str) then FShowClock:=value;
end;

function TSettingsOld.stringToApplVersion(value: string): TApplVersion;
var dotpos, poscopy, posdel :integer;
    str:string;
    i:integer;
    val:integer;
begin
     str:=value;
     result.Major:=0;
     result.Minor:=0;
     result.Release:=0;
     for I := 1 to 3 do begin
         if Length(str)>0 then begin
             dotpos:=pos('.',str);
             if dotpos>0 then begin
                poscopy:=dotpos-1;
                posdel:=dotpos;
             end else begin
                poscopy:=Length(str);
                posdel:=poscopy;
             end;
             try
                val:=strtoint(copy(str,1,poscopy));
             except
                val:=0;
             end;
             case i of
                1: result.Major:=val;
                2: result.Minor:=val;
                3: result.Release:=val;
             end;
             Delete(str,1,posdel);
         end;
     end;
end;

function TSettingsOld.VersionLess(version1, version2: TApplVersion): boolean;
var FindDiff:boolean;
begin
         FindDiff:=false;
         // Сравниваем главные версии
         if version1.Major>version2.Major then begin
            FindDiff:=true;
            Result:=false;
         end else begin
            if version1.Major<version2.Major then begin
               FindDiff:=true;
               result:=true;
            end;
         end;
         // Если не нашли отличия в главных версиях, то сравниваем младшие версии
         if not FindDiff then begin
              if version1.Minor>version2.Minor then begin
                FindDiff:=true;
                Result:=false;
             end else begin
                if version1.Minor<version2.Minor then begin
                   FindDiff:=true;
                   result:=true;
                end;
             end;
         end;
         // Если не нашли отличия в младших версиях, то сравниваем релизы
         if not FindDiff then begin
              if version1.Release>version2.Release then begin
                FindDiff:=true;
                Result:=false;
             end else begin
                if version1.Release<version2.Release then begin
                   FindDiff:=true;
                   result:=true;
                end else result:=false;
             end;
         end;
end;

{ TServer }

function TServer.getIPAddress: string;
begin
     FIPAddress:='';
     if name='lgkdisp' then FIPAddress:='ip1';
     if name='lgkback' then FIPAddress:='ip2';
     if name='PowerView' then FIPAddress:='ip3';
end;

{ TPowerView }

function TPowerView.AddInterface(interfaceName: string;
  MonitoringSetting: shortint): boolean;
begin
     result:= inherited AddInterface(interfaceName,MonitoringSetting);
     if LowerCase(interfaceName)='lastloaddata' then begin
        Interfaces.Add(LoadDataInterface, MonitoringSetting);
        result:=true;
     end;
end;

constructor TPowerView.Create;
begin
     inherited;
     LoadDataInterface:=TPowerViewLoadDataInterface.Create;
     LoadDataInterface.name:='LastLoadData';
     LoadDataInterface.DisplayName:='Выгрузка данных';
     LoadDataInterface.Owner:=self;
end;

destructor TPowerView.Destroy;
begin
     LoadDataInterface.Free;
end;

{ TDispatch }

function TDispatch.AddInterface(interfaceName: string;
  MonitoringSetting: shortint): boolean;
begin
     result:=false;
     result:= inherited AddInterface(interfaceName,MonitoringSetting);
     if LowerCase(interfaceName)='isruntransact' then begin
        Interfaces.Add(IsRunTransact, MonitoringSetting);
        result:=true;
     end;
     if LowerCase(interfaceName)='isrunexcept' then begin
        Interfaces.Add(IsRunExcept, MonitoringSetting);
        result:=true;
     end;
     if LowerCase(interfaceName)='isrungps' then begin
        Interfaces.Add(IsRunGPS, MonitoringSetting);
        result:=true;
     end;
     if LowerCase(interfaceName)='freespacelinux' then begin
        Interfaces.Add(FreeSpace, MonitoringSetting);
        result:=true;
     end;
     if LowerCase(interfaceName)='isrunsniff' then begin
        Interfaces.Add(IsRunSniff, MonitoringSetting);
        result:=true;
     end;
end;

constructor TDispatch.Create;
begin
      inherited;
      IsRunTransact:= TRunTransactInterface.Create;
      IsRunTransact.name:='IsRunTransact';
      IsRunTransact.DisplayName:='Транзакции';
      IsRunTransact.Owner:=Self;
      IsRunExcept:=TRunExceptInterface.Create;
      IsRunExcept.name:='IsRunExcept';
      IsRunExcept.DisplayName:='Исключения';
      IsRunExcept.Owner:=Self;
      IsRunGPS:=TRunGPSInterface.Create;
      IsRunGPS.name:='IsRunGPS';
      IsRunGps.DisplayName:='Сбор GPS';
      IsRunGPS.Owner:=Self;
      FreeSpace:=TFreeSpaceInterface.Create;
      FreeSpace.name:='FreeSpace';
      FreeSpace.DisplayName:='Диск';
      FreeSpace.Owner:=self;
      // Выставляем порог свободного места
      FreeSpace.ThresholdPercent:=15;
      IsRunSniff:=TRunSniffInterface.Create;
      IsRunSniff.name:='IsRunSniff';
      IsRunSniff.DisplayName:='Сбор логов OMSsniff';
      IsRunSniff.Owner:=self;
end;

destructor TDispatch.Destroy;
begin
      IsRunTransact.Free;
      IsRunExcept.Free;
      IsRunGPS.Free;
      FreeSpace.Free;
      IsRunSniff.Free;
end;

{ CInterfaces }

procedure CInterfaces.Add(Intfc: CInterface; MonitoringSetting:shortint);
begin
     SetLength(FInterfaces,Length(FInterfaces)+1);
     FInterfaces[high(FInterfaces)]:=Intfc;
     Intfc.MonitoringSetting:=MonitoringSetting;
end;


constructor CInterfaces.Create;
begin
     inherited;
     SetLength(FInterfaces,0);
end;

procedure CInterfaces.Delete(index1:integer);
var i:integer;
begin
     if (index1>count) or (index1<1) then exit;
     for i:=index1 to count-1 do begin
         FInterfaces[i-1]:=FInterfaces[i];
     end;
     FInterfaces[count-1]:=nil;
     SetLength(FInterfaces,Length(FInterfaces)-1);
end;

destructor CInterfaces.Destroy;
begin
     SetLength(FInterfaces,0);
end;

function CInterfaces.getByName(Name: string): CInterface;
var i:integer;
begin
     result:=nil;
     for i := 0 to Self.count - 1 do begin
         if LowerCase(FInterfaces[i].name)=LowerCase(Name) then result:=FInterfaces[i];
     end;
end;

function CInterfaces.getCount: integer;
begin
     result:=Length(self.FInterfaces);
end;

function CInterfaces.getInterface(Index: integer): CInterface;
begin
     try
      result:=FInterfaces[index-1];
     except
      result:=nil;
     end;
end;

{ TParameters }

procedure TParameters.Add(Prmtr: TParameterInterface);
begin
     SetLength(FParameters,Length(FParameters)+1);
     FParameters[high(FParameters)]:=Prmtr;
end;

constructor TParameters.Create;
begin
     inherited;
     SetLength(FParameters,0);
end;

procedure TParameters.Delete(index1: integer);
var i:integer;
begin
     if (index1>count) or (index1<1) then exit;
     for i:=index1 to count-1 do begin
         FParameters[i-1]:=FParameters[i];
     end;
     FParameters[count-1]:=nil;
     SetLength(FParameters,Length(FParameters)-1);
end;

destructor TParameters.destroy;
begin
     SetLength(FParameters,0);
end;

function TParameters.getCount: integer;
begin
     result:=Length(FParameters);
end;

function TParameters.getParameter(index1: integer): TParameterInterface;
begin
     try
      result:=FParameters[index1-1];
     except
      result:=nil;
     end;
end;

{ TPowerViewLoadDataInterface }

function TPowerViewLoadDataInterface.CheckInterface: boolean;
var f:boolean;
begin
     f:=CheckLastData;
     // Если нет данных на сервере PowerView, то делаем контрольную проверку через 15 секунд
     if f and (status=2) then begin
        TEquipment(Owner).Locked.Leave;
        sleep(15000);
        TEquipment(Owner).Locked.Enter;
        f:=CheckLastData;
     end;
end;

function TPowerViewLoadDataInterface.CheckLastData: boolean;
var dt:TDate;
    tm:TTime;
    shiftindex, shiftSeconds, diffMinutes:integer;
    qPowerViewStatus:TMyADOQuery;
    connTempPV:TMyADOConnection;
    LastDataDateTime:TDateTime;
begin
    result:=false;
    {dt:=Date();
    tm:=Time();
    shiftindex:=DateToShift(dt,tm);
    shiftSeconds:=TimeToShiftSec(tm);
    // Если с начала смены прошло менее 20 минут, то проверять предыдущую смену на наличие данных
    if shiftseconds<1200 then begin
        shiftindex:=shiftindex - 1;
        shiftseconds:=12*3600;
    end;
    // Без него не создаются ADOQuery
    CoInitialize(nil);
    try
      connTempPV:=TMyADOConnection.Create(dm1,dm1.tplConnPV.ConnectionString);
      qPowerViewStatus:=TMyADOQuery.Create(dm1,connTempPV);
    except
      if Assigned(connTempPV) then FreeAndNil(connTempPV);
      if Assigned(qPowerViewStatus) then FreeAndNil(qPowerViewStatus);
      result:=false;
      exit;
    end;
    qPowerViewStatus.SQL.Clear;
    qPowerViewStatus.SQL.Add('select max(endtime) as endtm from hist_statusevents where shiftindex='+inttostr(shiftindex));
    FLastCheckDateTime:=Now();
    try
       TEquipment(Owner).Locked.Leave;
       if not qPowerViewStatus.Active then qPowerViewStatus.Open;
       TEquipment(Owner).Locked.Enter;
    except
       //Application.MessageBox('Нет связи с сервером PowerView. Проверьте работу сервера PowerView','Ошибка');
       TEquipment(Owner).Locked.Enter;
       FreeAndNil(qPowerViewStatus);
       FreeAndNil(connTempPV);
       result:=false;
       exit;
    end;
    qPowerViewStatus.Last;
    lastDataDateTime:=ShiftAndSecToDateTime(shiftindex,qPowerViewStatus.FieldByName('endtm').AsInteger);
    diffMinutes:=round((shiftseconds-qPowerViewStatus.FieldByName('endtm').asinteger)/60);
    if shiftseconds-qPowerViewStatus.FieldByName('endtm').asinteger<1200 then status:=1 else status:=2;
    //status:=2;
    comment:='последняя '+FormatDateTime('dd.mm.yyyy hh:MM',lastDataDateTime)+' ('+inttostr(diffMinutes)+' минут назад)';
    // Записываем ошибку выгрузки
    if status=2 then errorStr:=' Данные не выгружались '+ inttostr(diffMinutes) +' минут. Последняя выгрузка была '+FormatDateTime('dd.mm.yyyy hh:MM',lastDataDateTime)
      else errorStr:='';
    qPowerViewStatus.Close;
    FreeAndNil(qPowerViewStatus);
    FreeAndNil(connTempPV);
    result:=true;   }
end;

{ TRunTransactInterface }

function TRunTransactInterface.CheckInterface: boolean;
var dt:TDate;
    findstr,strproc,s, dateRunStr:string;
    procline,wordindex,a,b,c:integer;
    j:integer;
    year,month,day:word;
    LastDataDateTime:TDateTime;
    monthstr:string;
    str:string;
    f:Boolean;
begin
     {str:='';
     if not OSSH.Lock then exit;
     dt:=Date();
     OSSH.Answer.Clear;
     OSSH.sleeptm:=600;
     OSSH.command:='ps -eaf | grep field';
     findstr:='.transact';
     TEquipment(Owner).Locked.Leave;
     f:=OSSH.Execute;
     TEquipment(Owner).Locked.Enter;
     if f then begin
       procLine:=-1;
       for j:=0 to OSSH.Answer.Count-1 do begin
            if pos(findstr,OSSH.Answer[j]) <> 0 then procline:=j;
       end;
       // Если найдена строка процесса транзакций или исключений, то ставим статусы и ищем время запуска процесса
       if procLine>-1 then begin
          status:=1;
          strProc:=OSSH.Answer[procline];
          Trim(strProc);
          strProc:=DelDoubleSpaces(strProc);
          // Дата или время создания процесса, это 5-е слово в строке
          // Поэтому ищем и вытягиваем 5-е слово
          wordindex:=0;
          while length(strproc)>0 do begin
              a:=pos(' ',strproc);
              inc(wordindex);
              if a=0 then begin
                  b:=length(strproc);
                  c:=length(strproc);
              end else begin
                  b:=a;
                  c:=a-1;
              end;
              s:=copy(strproc,1,c);
              if wordindex=5 then begin
                  dateRunstr:=s;
              end;
              delete(strproc,1,b);
          end;
          DecodeDate(Now(),year,month,day);
          if pos(':',DateRunStr)<>0 then begin
              LastDataDateTime:=dt + StrToTime(dateRunstr);
              if LastDataDateTime>Now() then LastDataDateTime:=LastDataDateTime-1;
          end else begin
              try
                  monthstr:=copy(dateRunStr,1,3);
                  month:=getMonthNumByString(monthstr);
                  day:=strtoint(copy(dateRunStr,4,2));
                  LastDataDateTime:=EncodeDate(year,Month,Day);
                  if LastDataDateTime>Now() then LastDataDateTime:=EncodeDate(year-1,Month,Day);
              except
                  LastDataDateTime:=0;
              end;
          end;

        end else status:=2;
        // Если нет данных с 7:00 до 7:25, значит считаем, что это - пересмена
        if (status=2) and (((Time()>StrToTime('07:00')) and (Time()<StrToTime('07:25'))) or ((Time()>StrToTime('19:00')) and (Time()<StrToTime('19:25')))) then status:=4;
        // Запись ошибки по интерфейсу
        if status=2 then ErrorStr:='Окно транзакций не запущено на сервере '+TDispatch(Owner).name + '. Свяжитесь с диспетчером'
           else ErrorStr:='';
        // Запись комментария к интерфейсу
        if (status=1) and (LastDataDateTime>0) then begin
              str:=str+'. Запущено '+FormatDateTime('dd.mm.yyyy', LastDataDateTime);
              // Если отсутствует время, то выводить только дату
              if LastDataDateTime<>Round(LastDataDateTime) then
                 str:=str+' '+FormatDateTime('hh:MM',LastDataDateTime);
        end;
     end else status:=0;
     comment:=str;
     OSSH.Unlock; }
end;

{ TTruck }

function TTruck.AddInterface(interfaceName: string; MonitoringSetting:shortint): boolean;
var cnt1,cnt2:integer;
begin
     result:=false;
     cnt1:=Interfaces.count;
     inherited;
     if interfaceName='VEI' then begin
        Interfaces.Add(VEI, MonitoringSetting);
     end;
     if interfaceName='Pressure' then begin
        Interfaces.Add(Pressure, MonitoringSetting);
     end;
     if interfaceName='Omnicomm' then begin
        Interfaces.Add(Omnicomm, MonitoringSetting);
     end;
     if interfaceName='Weight' then begin
        Interfaces.Add(Weight, MonitoringSetting);
     end;

     cnt2:=Interfaces.count;
     if cnt2>cnt1 then result:=true;

end;

constructor TTruck.Create;
begin
     inherited;
     VEI:=TVEIInterface.Create;
     VEI.Owner:=Self;

     Pressure:=TPressureInterface.Create;
     Pressure.Owner:=self;
     Omnicomm:=TOmnicommInterface.Create;
     Omnicomm.Owner:=self;
     Weight:=TWeightInterface.Create;
     Weight.Owner:=self;
end;

destructor TTruck.Destroy;
begin
     FreeAndNil(VEI);
     FreeAndNil(Pressure);
     FreeAndNil(Omnicomm);
     FreeAndNil(Weight);
     inherited;
end;

{ TRunExceptInterface }

function TRunExceptInterface.CheckInterface: boolean;
    var dt:TDate;
    findstr,strproc,s, dateRunStr:string;
    procline,wordindex,a,b,c:integer;
    j:integer;
    year,month,day:word;
    LastDataDateTime:TDateTime;
    monthstr, str:string;
    f:boolean;
begin
     {str:='';
     if not OSSH.Lock then exit;
     dt:=Date();
     OSSH.Answer.Clear;
     OSSH.sleeptm:=600;
     OSSH.command:='ps -eaf | grep except';
     findstr:='.except';
     TEquipment(Owner).Locked.Leave;
     f:=OSSH.Execute;
     TEquipment(Owner).Locked.Enter;
     if f then begin
       procLine:=-1;
       for j:=0 to OSSH.Answer.Count-1 do begin
            if pos(findstr,OSSH.Answer[j]) <> 0 then procline:=j;
       end;
       // Если найдена строка процесса транзакций или исключений, то ставим статусы и ищем время запуска процесса
       if procLine>-1 then begin
          status:=1;
          strProc:=OSSH.Answer[procline];
          Trim(strProc);
          strProc:=DelDoubleSpaces(strProc);
          // Дата или время создания процесса, это 5-е слово в строке
          // Поэтому ищем и вытягиваем 5-е слово
          wordindex:=0;
          while length(strproc)>0 do begin
              a:=pos(' ',strproc);
              inc(wordindex);
              if a=0 then begin
                  b:=length(strproc);
                  c:=length(strproc);
              end else begin
                  b:=a;
                  c:=a-1;
              end;
              s:=copy(strproc,1,c);
              if wordindex=5 then begin
                  dateRunstr:=s;
              end;
              delete(strproc,1,b);
          end;
          DecodeDate(Now(),year,month,day);
          if pos(':',DateRunStr)<>0 then begin
              LastDataDateTime:=dt + StrToTime(dateRunstr);
              if LastDataDateTime>Now() then LastDataDateTime:=LastDataDateTime-1;
          end else begin
              try
                  monthstr:=copy(dateRunStr,1,3);
                  month:=getMonthNumByString(monthstr);
                  day:=strtoint(copy(dateRunStr,4,2));
                  LastDataDateTime:=EncodeDate(year,Month,Day);
                  if LastDataDateTime>Now() then LastDataDateTime:=EncodeDate(year-1,Month,Day);
              except
                  LastDataDateTime:=0;
              end;
          end;

        end else status:=2;
        // Если нет данных с 7:00 до 7:25, значит считаем, что это - пересмена
        if (status=2) and (((Time()>StrToTime('07:00')) and (Time()<StrToTime('07:25'))) or ((Time()>StrToTime('19:00')) and (Time()<StrToTime('19:25')))) then status:=4;
        // Запись ошибки по интерфейсу
        if status=2 then ErrorStr:='Окно исключений не запущено на сервере '+TDispatch(Owner).name + '. Свяжитесь с диспетчером'
           else ErrorStr:='';
        // Запись комментария к интерфейсу
        if (status=1) and (LastDataDateTime>0) then begin
              str:=str+'. Запущено '+FormatDateTime('dd.mm.yyyy', LastDataDateTime);
              // Если отсутствует время, то выводить только дату
              if LastDataDateTime<>Round(LastDataDateTime) then
                 str:=str+' '+FormatDateTime('hh:MM',LastDataDateTime);
        end;
     end else status:=0;
     comment:=str;
     OSSH.Unlock; }
end;

{ TRunGPSInterface }

function TRunGPSInterface.CheckInterface: boolean;
var dt:TDate;
    findstr,strproc,s, dateRunStr:string;
    procline,wordindex,a,b,c:integer;
    j:integer;
    year,month,day:word;
    LastDataDateTime:TDateTime;
    monthstr, str:string;
    f:boolean;
begin
     { str:='';
     if not OSSH.Lock then exit;
     dt:=Date();
     OSSH.Answer.Clear;
     OSSH.sleeptm:=600;
     OSSH.command:='ps -eaf | grep gps_data';
     findstr:='gps_data_monitor';
     TEquipment(Owner).Locked.Leave;
     f:=OSSH.Execute;
     TEquipment(Owner).Locked.Enter;
     if f then begin
       procLine:=-1;
       for j:=0 to OSSH.Answer.Count-1 do begin
            if pos(findstr,OSSH.Answer[j]) <> 0 then procline:=j;
       end;
       // Если найдена строка процесса транзакций или исключений, то ставим статусы и ищем время запуска процесса
       if procLine>-1 then begin
          status:=1;
          strProc:=OSSH.Answer[procline];
          Trim(strProc);
          strProc:=DelDoubleSpaces(strProc);
          // Дата или время создания процесса, это 5-е слово в строке
          // Поэтому ищем и вытягиваем 5-е слово
          wordindex:=0;
          while length(strproc)>0 do begin
              a:=pos(' ',strproc);
              inc(wordindex);
              if a=0 then begin
                  b:=length(strproc);
                  c:=length(strproc);
              end else begin
                  b:=a;
                  c:=a-1;
              end;
              s:=copy(strproc,1,c);
              if wordindex=5 then begin
                  dateRunstr:=s;
              end;
              delete(strproc,1,b);
          end;
          DecodeDate(Now(),year,month,day);
          if pos(':',DateRunStr)<>0 then begin
              LastDataDateTime:=dt + StrToTime(dateRunstr);
              if LastDataDateTime>Now() then LastDataDateTime:=LastDataDateTime-1;
          end else begin
              try
                  monthstr:=copy(dateRunStr,1,3);
                  month:=getMonthNumByString(monthstr);
                  day:=strtoint(copy(dateRunStr,4,2));
                  LastDataDateTime:=EncodeDate(year,Month,Day);
                  if LastDataDateTime>Now() then LastDataDateTime:=EncodeDate(year-1,Month,Day);
              except
                  LastDataDateTime:=0;
              end;
          end;

        end else status:=2;
        // Если нет данных с 7:00 до 7:25, значит считаем, что это - пересмена
        if (status=2) and (((Time()>StrToTime('07:00')) and (Time()<StrToTime('07:25'))) or ((Time()>StrToTime('19:00')) and (Time()<StrToTime('19:25')))) then status:=4;
        // Запись ошибки по интерфейсу
        if status=2 then ErrorStr:='Сбор GPS не запущен на сервере '+TDispatch(Owner).name + '. Свяжитесь с диспетчером и попросите перезагрузить Dispatch. Если после перезагрузки сбор gps-координат не возобновится, позвоните администратору'
           else ErrorStr:='';
        // Запись комментария к интерфейсу
        if (status=1) and (LastDataDateTime>0) then begin
              str:=str+'. Запущено '+FormatDateTime('dd.mm.yyyy', LastDataDateTime);
              // Если отсутствует время, то выводить только дату
              if LastDataDateTime<>Round(LastDataDateTime) then
                 str:=str+' '+FormatDateTime('hh:MM',LastDataDateTime);
        end;
     end else status:=0;
     comment:=str;
     OSSH.Unlock;  }
end;

{ TDM1 }

function TDM1.ConnectedDBUbiquiti: boolean;
begin
     result:=true;
    try
        if not DM1.ConnMySQL.Connected then DM1.ConnMySQL.Connected:=true;
    except
        //frmMain.RxTrayIcon1DblClick(self);
        //Application.MessageBox('Нет доступа к базе данных ubiquiti. Не доступна информация о том, на каких самосвалах не производится мониторинг. Программа будет работать, но нельзя будет отключить или включить мониторинг на самовалах','Ошибка');
        result:=false;
    end;
end;

{ TVEIInterface }

function TVEIInterface.AddDisplayParameter(parameterName: string): boolean;
begin

end;

function TVEIInterface.CheckInterface: boolean;
var hour,min,sec,MSec:word;
    DataString,data1:string;
    lastVeiEvent:TDateTime;
    date1:TDate;
    LastVeiTimeString:string;
    MonitoringStatus:shortint;
    minutesToNoData, minutesToBadData:integer;
    dttmdiff:TDateTime;
    dttm:TDateTime;
    f:boolean;
begin
     {result:=false;
     minutesToNoData:=10;
     minutesToBadData:=60;
     if TMobileEquipment(owner).name='A109' then begin
        dttm:=2;
     end;
     if not OSSH.Lock then exit;
     MonitoringStatus:=GetMonitoringStatus;
     if MonitoringStatus<>mos_Disable then begin
          Date1:=Date();
          DecodeTime(Now(),hour,min,sec,MSec);
          dttm:=Now();
          DataString:= 'cat OMSsniff/'+formatDateTime('yyyy-mm-dd',dttm)+'.sniff.eth0.raw | grep "'+TMobileEquipment(owner).name+'.*VEI-DUMP 0[01]" | tail -1'#13;
          OSSH.Answer.Clear;
          OSSH.sleeptm:=2000;
          OSSH.command:=DataString;
          status:=0;
          // Присвоить штампу времени давнее значение
          lastVeiEvent:=1;
          //Application.MessageBox(PChar(currentEquipment+': '+inttostr(cnt1)+': '+data1),'');
          try
              TMobileEquipment(owner).Locked.Leave;
              f:=OSSH.Execute;
              TMobileEquipment(Owner).Locked.Enter;
              if f then begin
                      if OSSH.Answer.Count>0 then data1:=OSSH.Answer.Strings[OSSH.Answer.Count-1] else data1:='';
                      if data1 <>'' then begin
                         if pos(TMobileEquipment(Owner).name,data1)>0 then begin
                            try
                               lastVeiTimeString:=copy(data1,1,8);
                               lastVeiEvent:=Date1+StrToTime(LastVeiTimeString);
                            except
                               status:=0;
                               result:=false;
                            end;
                         end else begin
                            status:=0;
                            result:=false;
                         end;
                         dttmdiff:=dttm-lastVeiEvent;
                         if (dttmdiff)>(1/24/60*minutesToBadData) then status:=2 else status:=s_Work;
                      end else status:=2;
                      if status=s_NoData then ErrorStr:='Вес от блока больше 199 тонн дольше '+inttostr(minutesToBadData)+' минут'
                          else errorstr:='';
                      result:=true;
                      // Если корректных данных нет или были давно, то проверяем на наличие каких-либо данных
                      if (status=s_NoData) or (dttmdiff > (1/24/60*minutesToNoData)) then begin
                          DataString:= 'cat OMSsniff/'+formatDateTime('yyyy-mm-dd',dttm)+'.sniff.eth0.raw | grep "'+TMobileEquipment(owner).name+'.*VEI" | tail -1'#13;
                          OSSH.Answer.Clear;
                          OSSH.command:=DataString;
                          lastVeiEvent:=1;
                          TMobileEquipment(owner).Locked.Leave;
                          f:=OSSH.Execute;
                          TMobileEquipment(owner).Locked.Enter;
                          if f then begin
                              if OSSH.Answer.Count>0 then data1:=OSSH.Answer.Strings[OSSH.Answer.Count-1] else data1:='';
                              if data1 <>'' then begin
                                  if pos(TMobileEquipment(Owner).name,data1)>0 then begin
                                      try
                                         lastVeiTimeString:=copy(data1,1,8);
                                         lastVeiEvent:=Date1+StrToTime(LastVeiTimeString);
                                      except
                                         status:=s_unknown;
                                         result:=false;
                                         exit;
                                      end;
                                  end;
                                  dttmdiff:=dttm-lastVeiEvent;
                                  if dttmdiff>(1/24/60*minutesToNoData) then begin
                                     status:=s_NoData;
                                     ErrorStr:='Нет данных от блока дольше '+inttostr(minutesToNoData)+' минут';
                                  end;
                              end else begin
                                  status:=s_NoData;
                                  ErrorStr:='Нет данных от блока дольше '+inttostr(minutesToNoData)+' минут';
                              end;
                          end;
                      end;
              end else begin
                  // Если поступили некорректные данные, значит запрос SSH еще до конца не выполнился
                  TMobileEquipment(owner).Locked.Leave;
                  sleep(3000);
                  TMobileEquipment(owner).Locked.Enter;
                  status:=0;
                  result:=false;
              end;
          except
             status:=s_unknown;
             result:=false;
             OSSH.Reconnect;
          end;
      end else status:=3;}
      // Если статус 0 или 2 то записываем лог
      {if status in [0,2] then begin
          logstr:=#13#10+'------------------------------------'+#13#10+FormatDateTime('dd.mm.yy hh:mm',Now)+' '+'Cтатус самосвала '+currentEquipment+' --- '+inttostr(veistatus)+#13#10+cmdstr+#13#10+logstr+'--------------------------------'+#13#10;
          SaveToFile(flname,logstr);
      end;}
      {if status<>s_unknown then result:=true else result:=false;
      //if status=2 then ErrorStr:='Нет данных' else ErrorStr:='';
      OSSH.Unlock; }
end;

constructor TVEIInterface.Create;
begin
     inherited;
     name:='VEI';
     DisplayName:='VEI';
end;

{ TPressureInterface }

function TPressureInterface.AddDisplayParameter(parameterName: string): boolean;
begin
     inherited;
     result:=false;
     if parameterName='CountWorkTires' then begin
        DisplayParameters.Add(CountWorkTires);
        result:=true;
     end;
end;

function TPressureInterface.CheckInterface: boolean;
var i:integer;
    TireStatus:shortint;
    counttires:integer;
    qTmpPowerView:TADOQuery;
begin
     result:=false;
     status:=0;
     errorStr:='';
     counttires:=0;
     if GetMonitoringStatus<>mos_Disable then begin
         // Если в БД нет данных за текущую смену, то ждем
         // Проверка на количество записей не эффективна. Нужно проверять время последнего параметра для смены
         {if not CheckTableMCPar then begin
            sleep(5000);
            if not CheckTableMCPar then exit;
         end;}
         // Проверяем данные по каждой из шести шин
         for i:=1 to 6 do begin
             TireStatus:=CheckTire(i);
             if TireStatus=Tire_work then status:=s_Work;
             if (TireStatus=Tire_NotCorrect) and (status<>s_work) then begin
                status:=s_NoData;
                errorstr:='Одинаковые данные от датчиков';
             end;
             if (TireStatus=Tire_NoData) and not (status in [1,2]) then begin
                status:=s_NoData;
                errorstr:='Нет данных ни от одного датчика';
             end;
             if TireStatus=Tire_work then inc(counttires);
         end;
         if status<>s_NoData then errorStr:='';
         // Если статус - нет данных и время последнего параметра в таблице
         if (status=s_NoData) and (Now()-GetLastDataMCPar>StrToTime('00:30:00')) then begin
            TMobileEquipment(owner).Locked.Leave;
            sleep(5000);
            TMobileEquipment(owner).Locked.Enter;
            status:=s_unknown;
         end;
     end else status:=s_Disable;
     CountWorkTires.value:=inttostr(counttires);
     result:=true;
end;


function TPressureInterface.CheckTire(i: integer): shortint;
var Tire_var1, Tire_Var2, Tire_Var3, Tire_Var4:string;
    qTempPowerView:TMyADOQuery;
    connTempPV:TMyADOConnection;
    ViewMinutes:integer;
    TirePressure:double;
    PressEquals:boolean;
    shiftid:integer;
    tm:TTime;
    dttm:TDateTime;
begin
     result:=Tire_Unknown;
     {ViewMinutes:=60; // За какое время необходимо просматривать данные
     case i of
         // Возможные коды шин для разных колес
         // На данный момент Может быть 2 варианта, так как используются 2 типа мониторов
         // 1 - Правая передняя
         1: begin
            Tire_Var1:='32010008';
            Tire_Var2:='32010005';
            Tire_Var3:='32010005';
            Tire_Var4:='6901001E';
         end;
         // 2 - Левая передняя
         2: begin
            Tire_Var1:='32010062';
            Tire_Var2:='32010002';
            Tire_Var3:='32010002';
            Tire_Var4:='6901002D';
         end;
         // 3 - Правая задняя наружная
         3: begin
            Tire_Var1:='3201002F';
            Tire_Var2:='32010029';
            Tire_Var3:='32010023';
            Tire_Var4:='6901003C';
         end;
         // 4 - Правая задняя внутренняя
         4: begin
            Tire_Var1:='3201002C';
            Tire_Var2:='32010026';
            Tire_Var3:='32010020';
            Tire_Var4:='6901004B';
         end;
         // 5 - Левая задняя наружная
         5: begin
            Tire_Var1:='32010041';
            Tire_Var2:='32010047';
            Tire_Var3:='3201004D';
            Tire_Var4:='6901005A';
         end;
         // 6 - Левая задняя внутренняя
         6: begin
            Tire_Var1:='3201003E';
            Tire_Var2:='32010044';
            Tire_Var3:='3201004A';
            Tire_Var4:='69010069';
         end;
         else exit;
     end;
     coInitialize(Nil);
     connTempPV:=TMyADOConnection.Create(dm1,dm1.tplConnPV.ConnectionString);
     qTempPowerView:=TMyADOQuery.Create(dm1,connTempPV);
     qTempPowerView.SQL.Clear;
     shiftid:=DateToShift(Date(),Time());
     qTempPowerView.SQL.Add('select distinct data, [timestamp] from hist_mc_par where ((shiftindex='+inttostr(shiftid)+') ');
     // Если начало дневной или ночной смен, то брать информацию из предыдущей
     tm:=Time();
     //tm:=strtoTime('19:36');
     dttm:=Now();
     //dttm:=StrToDateTime('24.08.15 08:06:00');
     //tm:=StrToTime('08:06:00');
     //dttm:=StrToDate('22.01.2014')+tm;
     if (tm>=StrToTime('7:30')) and (tm<=(StrToTime('7:30')+1/24/60*ViewMinutes)) then
        qTempPowerView.SQL.Add(' or (shiftindex='+inttostr(shiftid-1)+')');
     if (tm>=StrToTime('19:30')) and (tm<=(StrToTime('19:30')+1/24/60*ViewMinutes)) then
        qTempPowerView.SQL.Add(' or (shiftindex='+inttostr(shiftid-1)+')');
     qTempPowerView.SQL.Add(') and (eqmt='+#39+TEquipment(Owner).name+#39+') and ');
     qTempPowerView.SQL.Add('(timestamp>='+inttostr(DateTimeToTimeStamp1970(dttm-(1/24/60*ViewMinutes)))+') and ');
     qTempPowerView.SQL.Add('((id='+#39+Tire_Var1+#39+') or (id='+#39+Tire_Var2+#39+') or (id='+#39+Tire_Var3+#39+')or(id='+#39+Tire_Var4+#39+'))');
     //Application.MessageBox(PChar(qTempPowerView.SQL.Text),'');
     try
        TMobileEquipment(Owner).Locked.Leave;
        qTempPowerView.Open;
        TMobileEquipment(Owner).Locked.Enter;
     except
        result:=Tire_Unknown;
        FreeAndNil(qTempPowerView);
        FreeAndNil(connTempPV);
        TMobileEquipment(Owner).Locked.Enter;
        exit;
     end;
     // Просматриваем данные по шине за последние ViewMinutes минут
     if qTempPowerView.RecordCount<>0 then begin
        qTempPowerView.First;
        TirePressure:=qTempPowerView.FieldByName('data').AsFloat;
        qTempPowerView.Next;
        if not qTempPowerView.Eof then PressEquals:=true else PressEquals:=false;
        while not qTempPowerView.eof do begin
              if qTempPowerView.FieldByName('data').AsFloat<>TirePressure then PressEquals:=false;
              qTempPowerView.Next;
        end;
        if not PressEquals then result:=Tire_work else result:=Tire_NotCorrect;
     end else result:=Tire_NoData;
     qTempPowerView.Close();
     FreeAndNil(qTempPowerView);
     FreeAndNil(connTempPV);  }
end;

constructor TPressureInterface.Create;
begin
     inherited;
     name:='Pressure';
     DisplayName:='Pressure';
     CountWorkTires:=TParameterInterface.Create();
     CountWorkTires.name:='LostPercent';
     CountWorkTires.displayName:='Раб. шин:';
     CountWorkTires.value:='0';
     CountWorkTires.edizm:='';
end;

destructor TPressureInterface.Destroy;
begin
     FreeAndNil(FCountWorkTires);
     inherited;
end;

{ TNotificationSound }


procedure TNotificationSound.SetDuration(value: integer);
var iniFile1:TIniFile;
begin
     if value>0 then begin
        Fduration:=value;
        if FileExists(FSettingFileName) then begin
          inifile1:=TIniFile.Create(FSettingFileName);
          iniFile1.WriteInteger('Sound','Duration',value);
          iniFile1.UpdateFile;
          iniFile1.Destroy;
        end;
     end else Application.MessageBox('Значение параметра sound.duration не может быть меньше 1','Ошибка');
end;

procedure TNotificationSound.SetEnable(value: boolean);
var iniFile1:TiniFile;
    a:shortint;
begin
     FEnable:=value;
     if FileExists(FSettingFileName) then begin
        inifile1:=TIniFile.Create(FSettingFileName);
        if value then a:=1 else a:=0;
        iniFile1.WriteInteger('Sound','Enable',a);
        iniFile1.UpdateFile;
        iniFile1.Destroy;
     end;
end;

{ TGpsInterface }

function TGpsInterface.AddDisplayParameter(parameterName: string): boolean;
begin
     inherited;
     result:=false;
     if parameterName='LastGPSDateTime' then begin
        DisplayParameters.Add(LastGPSDateTime);
        result:=true;
     end;
end;

function TGpsInterface.Check: boolean;
var monStat:integer;
  lostp: Real;
begin
   try
     TEquipment(owner).Locked.Enter;
     result:=false;
     errorstr:='';
     status:=s_unknown;
     try
        result:=CheckInterface;
     // Изменения статуса для всех интерфейсов мобильного оборудования
         monStat:=GetMonitoringStatus;
     except
        result:=false;
        exit;
     end;
         if (monStat=mos_Disable) then status:=s_Disable;
         if (monStat=mos_Damage) then begin
            if (status=1) or (status=6) then status:=6 else status:=5;
         end;
         // Для экскаваторов не проверяем статус Модулар.
         // Вместо этого проверяем процент потерянных пакетов за последние 5 минут.
         // Если процент потерь более 30%, то считаем, что техника выключена
         if self.Owner.ClassType=TExcav then begin
           if status in [0,2] then begin
              try
                  lostp:=TMobileEquipment(Owner).PingPC.GetLostPercent(600);
                  if (lostp>30)and (lostp<=100) then status:=s_NotReady;
              except

              end;
           end;
         end else begin
              if self.Owner.ClassParent=TMobileEQModular then begin
                  try
                      if not (TMobileEQModular(Owner).GetSystemStatus=ms_ready) then status:=s_NotReady;
                  except

                  end;
              end;
         end;
     if status<>2 then ErrorStr:='';
     //TEquipment(Owner).Unlock;
     LastCheckDateTime:=Now();
   finally
     TEquipment(Owner).Locked.Leave;
   end;
end;

{function TGpsInterface.CheckByOMStip: boolean;
var DataString:string;
    numstr:integer;
    OSSH1:TSSHobj;
    f:boolean;
begin
     result:=false;
     OSSH1:=TSSHobj.Create;
     DataString:='( sleep 3; echo "Gps gps"; sleep 3; echo "exit"; sleep 1 ) | OMStip '+TMobileEquipment(Owner).name;
     OSSH1.Answer.Clear;
     OSSH1.sleeptm:=9000;
     OSSH1.command:=DataString;
     try
         TEquipment(owner).Locked.Leave;
         f:=OSSH1.Execute;
         TEquipment(Owner).Locked.Enter;
         if f then begin
            if OSSH1.Answer.Count>0 then begin
               numstr:=FindLineSubstringInList('Lat: ',OSSH1.Answer);
               if numstr>-1 then begin
                  result:=true;
                  if pos('Lat: 1',OSSH1.Answer[numstr])<>0 then begin
                      status:=s_work;
                      self.LastGPSDateTime.value:=FormatDateTime('dd.mm.yy hh:nn',Now);
                  end else begin
                      status:=s_NoData;
                  end;
               end;
            end;
         end;
     except

     end;
     //OSSH1.Destroy;
     FreeAndNil(OSSH1);
end;}

function TGpsInterface.CheckInterface: boolean;
var qTempMySQL:TADOQuery;
    connTempMy:TADOConnection;
    LastGPSdttm:TDateTime;
    countSecondsToBad: integer;
    AllLastGPS:TDateTime;
    periodGPS:integer;
    diffmin:integer;
    readyseconds:integer;
    f:boolean;
    countSecondsToAlarm:integer;
    diffdttm:TDateTime;
begin
  //f:=CheckByOMStip;
  //exit;
  result:=false;
  status:=s_unknown;

  countSecondsToBad:=5*60;
  countSecondsToAlarm:=countSecondsToBad*2;
  // Период передачи пакетов GPS на сервер. Передается значений в пакете - 16, период между значениями - 30 секунд
  periodGPS:=30;
  CoInitialize(nil);
  connTempMy:=TADOConnection.Create(dm1);
  connTempMy.ConnectionString:=dm1.TplConnMySQL.ConnectionString;
  connTempMy.KeepConnection:=false;
  connTempMy.LoginPrompt:=false;
  qTempMysql:=TADOQuery.Create(dm1);
  qTempMysql.Connection:=connTempMy;
  qTempMySQL.SQL.Clear;
  qTempMySQL.SQL.Add('select max(datetime) as LastGPS from stats_gps ');
  qTempMySQL.SQL.Add('where id_equipment="'+inttostr(TMobileEquipment(self.Owner).MySQLIndex)+'"');
  try
     qTempMySQL.Open;
     qTempMySQL.Last;
     if qTempMySQL.RecordCount>0 then LastGPSdttm:=qTempMySQL.FieldByName('LastGPS').AsDateTime else LastGPSdttm:=0;
     qTempMySQL.Close;
     diffdttm:=Now-LastGPSdttm;
     if (diffdttm)<(countSecondsToBad/24/3600) then status:=s_Work else status:=s_NoData;
     // Если оборудование находится в статусе Готов меньше 10 минут, то считать статус неизвестным
     readyseconds:=TMobileEquipment(Owner).readySeconds;
     if status=s_NoData then if (readyseconds<(5*60)) and (readySeconds>0) then status:=s_unknown;
     // Если статус по прежнему нет данных, то проверяем подключением к PTX и проверкой Gps gps
     f:=true;
     //readyseconds:=1000;
     //status:=s_NoData;
     // Если самосвал или экскаватор не в статусе "Готов", то не проверять по OMStip
     if (status=s_NoData) and (TMobileEquipment(self.Owner).readySeconds>0) then begin
        //f:=CheckByOMStip;
        f:=false;
        if f and (status=s_Work) then begin
            // Если данных нет больше времени CountSecondsToAlarm, а по OMStip они есть
            if ((diffdttm*24*3600)>countSecondsToAlarm) and (readyseconds>countSecondsToBad) then begin
               status:=s_NoData;
               diffmin:=trunc((Now-LastGPSdttm)*24*60);
               ErrorStr:='Нет данных GPS '+IntToStr(diffmin)+' мин. Последние данные были '+FormatDateTime('dd.mm.yyyy hh:nn',LastGPSdttm);
               ErrorStr:=Errorstr+'. Данные GPS при подключении OMStip имеются. Вероятно, завис GPS-модуль. Перезагрузите PTX';
            end else LastGPSdttm:=Now();
        end else begin
            if f then begin
               status:=s_NoData;
               diffmin:=trunc((Now-LastGPSdttm)*24*60);
               ErrorStr:='Нет данных GPS '+IntToStr(diffmin)+' мин. Последние данные были '+FormatDateTime('dd.mm.yyyy hh:nn',LastGPSdttm);
               ErrorStr:=ErrorStr+'. Данные GPS при подключении OMStip отсутствуют';
            end else begin
               if ((diffdttm*24*3600)>countSecondsToAlarm) and (readyseconds>countSecondsToBad) then begin
                   status:=s_NoData;
                   diffmin:=trunc((Now-LastGPSdttm)*24*60);
                   ErrorStr:='Нет данных GPS '+IntToStr(diffmin)+' мин. Последние данные были '+FormatDateTime('dd.mm.yyyy hh:nn',LastGPSdttm);
                   ErrorStr:=ErrorStr+'. Не удалось проверить наличие данных через OMStip';
               end else begin
                  status:=s_unknown;
                  ErrorStr:='';
               end;
            end;
        end;
     end;
     // Для проверки
     //if TMobileEquipment(owner).name='A126' then CheckByOMStip;
    if (not f) and (readyseconds<countSecondsToBad) then status:=s_unknown;
    if (LastGPSdttm>strtoDateTime('01.01.2000')) then self.LastGPSDateTime.value:=FormatDateTime('dd.mm.yy hh:nn',LastGPSdttm)
        else self.LastGPSDateTime.value:='неизв.';
     result:=true;
  except
     result:=false;
     status:=s_unknown;
     FreeAndNil(qTempMysql);
     FreeAndNil(connTempMy);
     exit;
  end;
  if (status=s_NoData) and (ErrorStr='') then begin
      diffmin:=trunc((Now-LastGPSdttm)*24*60);
      ErrorStr:='Нет данных GPS '+inttostr(diffmin)+' минут. Последние данные были '+LastGPSDateTime.value;
  end;
  FreeAndNil(qTempMysql);
  FreeAndNil(connTempMy);
end;

constructor TGpsInterface.Create;
begin
  inherited;
  name:='GPS';
  DisplayName:='GPS';
  LastGPSDateTime:=TParameterInterface.Create();
  LastGPSDateTime.name:='LastGPSDateTime';
  LastGPSDateTime.displayName:='Посл.';
  LastGPSDateTime.value:='неизв';
  LastGPSDateTime.edizm:='';
  LastGPSDateTime.FormatVal:='00.00.00 00:00';
end;

destructor TGpsInterface.Destroy;
begin
   LastGPSDateTime.Free;
   inherited;
end;

{ TNetworkEQ }

function TNetworkEQ.AddInterface(interfaceName: string;
  MonitoringSetting: shortint): boolean;
begin
     inherited;
     result:=false;
     if interfaceName='Avail' then begin
        Interfaces.Add(Avail, MonitoringSetting);
        result:=true;
     end;
end;

constructor TNetworkEQ.Create;
begin
     inherited;
     Avail:=TAvailInterface.Create;
     Avail.Owner:=Self;
end;

destructor TNetworkEQ.Destroy;
begin
     FreeAndNil(Avail);
     inherited;
end;


{ TOmnicommInterface }

function TOmnicommInterface.AddDisplayParameter(parameterName: string): boolean;
begin

end;

function TOmnicommInterface.CheckInterface: boolean;
var qTempPowerView:TMyADOQuery;
    connTempPV:TMyADOConnection;
    shiftid:integer;
    tm:TTime;
    dttm:TDateTime;
    ViewMinutes:integer;
    omnicode1,omnicode2:string;
    str1:string;
begin
     result:=false;
     status:=s_unknown;
     {errorStr:='';
     viewMinutes:=30;
     OmniCode1:='FUELMETRIX';
     if GetMonitoringStatus<>mos_Disable then begin
         coInitialize(Nil);
         connTempPV:=TMyADOConnection.Create(dm1,dm1.tplConnPV.ConnectionString);
         qTempPowerView:=TMyADOQuery.Create(dm1,connTempPV);
         qTempPowerView.SQL.Clear;
         shiftid:=DateToShift(Date(),Time());
         qTempPowerView.SQL.Add('select data from hist_mc_par where ((shiftindex='+inttostr(shiftid)+') ');
         // Если начало дневной или ночной смен, то брать информацию из предыдущей
         tm:=Time();
         //tm:=strtoTime('19:36');
         dttm:=Now();
         //dttm:=StrToDate('22.01.2014')+tm;
         if (tm>=StrToTime('7:30')) and (tm<=(StrToTime('7:30')+1/24/60*ViewMinutes)) then
            qTempPowerView.SQL.Add('or (shiftindex='+inttostr(shiftid-1)+')');
         if (tm>=StrToTime('19:30')) and (tm<=(StrToTime('19:30')+1/24/60*ViewMinutes)) then
            qTempPowerView.SQL.Add('or (shiftindex='+inttostr(shiftid-1)+')');
         qTempPowerView.SQL.Add(') and (eqmt='+#39+TEquipment(Owner).name+#39+') and (timestamp>='+inttostr(DateTimeToTimeStamp1970(dttm-(1/24/60*ViewMinutes)))+') and (id='+#39+OmniCode1+#39+')');
         try
            if TEquipment(Owner).name='A119' then
                str1:=qTempPowerView.SQL.Text;
            TEquipment(Owner).Locked.Leave;
            qTempPowerView.Open;
            TEquipment(Owner).Locked.Enter;
         except
            TEquipment(Owner).Locked.Enter;
            result:=false;
            FreeAndNil(qTempPowerView);
            FreeAndNil(connTempPV);
            exit;
         end;
         if qTempPowerView.RecordCount<>0 then status:=s_Work else status:=s_NoData;
         qTempPowerView.Close();
          FreeAndNil(qTempPowerView);
          FreeAndNil(connTempPV);
         if status<>2 then errorStr:='' else errorStr:='Нет данных от датчика Omnicomm более '+inttostr(ViewMinutes) + ' минут';
         // Если статус - нет данных и время последнего параметра в таблице
         if (status=s_NoData) and (Now()-GetLastDataMCPar>StrToTime('00:30:00')) then begin
            TEquipment(Owner).Locked.Leave;
            sleep(2000);
            TEquipment(Owner).Locked.Enter;
            status:=s_unknown;
         end;
     end else status:=s_Disable;
     result:=true; }
end;

constructor TOmnicommInterface.Create;
begin
     inherited;
     name:='Omnicomm';
     DisplayName:='Omnicomm';
end;

{ TAvailInterface }

function TAvailInterface.CheckInterface: boolean;
var qTempMySQL:TMyADOQuery;
    connTempMy:TMyADOConnection;
    //idmodem:integer;
    //dt:TDate;
    //tm:TTime;
    idequip:integer;
    dttm:TDateTime;
    notwork:boolean;
begin
     result:=false;
     status:=0;
     // Искусственное создание ошибок для тестирования
     //status:=s_NoData;
     //exit;
     // Конец искусственного создания ошибок
     if GetMonitoringStatus<>mos_Disable then begin
        //dt:=Date();
        //tm:=time();
        dttm:=Now();
        CoInitialize(nil);
        connTempMy:=TMyADOConnection.Create(dm1,dm1.TplConnMySQL.ConnectionString);
        qTempMySQL:=TMyADOQuery.Create(DM1,connTempMy);
        qTempMySQL.SQL.Clear;

       // Узнаем id модема оборудования
       {qTempMysql.SQL.Add('select id_modem from modems m where m.id_equipment="'+IntToStr(TEquipment(Owner).MySQLIndex)+'"');
       try
          qTempMysql.Open;
       except
          FreeAndNil(qTempMySQL);
          FreeAndNil(connTempMy);
          exit;
       end;
       qTempMysql.First;
       idmodem:=qTempMysql.FieldByName('id_modem').AsInteger;
       qTempMysql.Close;}
       //[2021-10-07]
       idequip:=TEquipment(Owner).MySQLIndex;
       qTempMySQL.SQL.Clear;
       // Выбираем, сколько всего было запросов в статусе готов
       qTempMySQL.SQL.Add('select s.signal_level, s.datetime from stats_ap s');
       //qTempMySQL.SQL.Add('where (s.date="'+FormatDateTime('yyyy-mm-dd',dt)+'") and (s.id_modem='+inttostr(idmodem)+') and (s.time>"'+TimeToStr(tm-(1/24/60))+'")');
       qTempMySQL.SQL.Add('where (id_equipment='+IntToStr(idequip)+') and (s.datetime>"'+MySQLDateTime(dttm-(1/24/60))+'")');
       qTempMySQL.SQL.Add('order by datetime');
       try
          qTempMySQL.Open;
       except
          FreeAndNil(qTempMySQL);
          FreeAndNil(connTempMy);
          exit;
       end;
       qTempMySQL.Last;
       if qTempMySQL.RecordCount<>0 then begin
          qTempMySQL.First;
          notwork:=true;
          while not qTempMySQL.Eof do begin
              if qTempMySQL.FieldByName('signal_level').AsInteger<>156 then notwork:=false;
              qTempMySQL.Next;
          end;
          if notwork then status:=s_NoData else status:=s_work;
       end else status:=s_unknown;
       qTempMySQL.Close;
       Result:=true;
        FreeAndNil(qTempMySQL);
        FreeAndNil(connTempMy);
     end else begin
         result:=true;
         status:=s_Disable;
     end;
     if status=s_NoData then errorstr:='Нет связи' else errorstr:='';
end;

constructor TAvailInterface.Create;
begin
     inherited;
     name:='Avail';
     DisplayName:='Доступ';
end;

{ TWeightInterface }

function TWeightInterface.AddDisplayParameter(parameterName: string): boolean;
begin
     inherited;
     result:=false;
     {if parameterName='CountHauls' then begin
        DisplayParameters.Add(CountHauls);
        result:=true;
     end;}
end;

function TWeightInterface.CheckInterface: boolean;
var ConnTempPV:TMyADOConnection;
    qTempPV:TMyADOQuery;
    shiftindex:integer;
    haulsToBad:integer;
  I: Integer;
  finded: Boolean;
  timedump: Integer;
  dttm: TDatetime;
  a: string;
  b: integer;
  weightworkstr: string;
begin
     result:=false;
     status:=s_unknown;
     {errorStr:='';
     CoInitialize(nil);
     ConnTempPV:=TMyADOConnection.Create(dm1,DM1.ConnPowerView.ConnectionString);
     qTempPV:=TMyADOQuery.Create(dm1,ConnTempPV);
     // Проверяем рейсы самосвала за последние 3 смены
     shiftindex:=GetShiftindex(Now()-1);
     // Количество рейсов без веса, для статуса "Неисправность"
     haulstobad:=2;
     qTempPV.SQL.Clear;
     qTempPV.SQL.Add('select shiftindex, timedump, measureton from hist_dumps');
     qTempPV.SQL.Add('where (shiftindex>='+IntToStr(shiftindex)+') and (truck='+#39+TTruck(Owner).name+#39')');
     qTempPV.SQL.Add('order by shiftindex, timedump');
     qTempPV.Open;
     if qTempPV.RecordCount<>0 then begin
        result:=true;
        status:=s_NoData;
        qTempPV.Last;
        if haulsToBad>qTempPV.RecordCount then haulsToBad:=qTempPV.RecordCount;
        for I := 0 to haulsToBad-1 do begin
            if qTempPV.FieldByName('measureton').AsInteger>=70 then status:=s_Work;
            try
              qTempPV.Prior;
            except
              break;
            end;
        end;
        // Если нет данных, то проверяем, когда были
        if status=s_NoData then begin
           ErrorStr:='Нет корректных данных от весовой системы.';
           qTempPV.Filtered:=false;
           qTempPV.Filter:='measureton>0';
           qTempPV.Filtered:=true;
           shiftindex:=0;
           timedump:=0;
           qTempPV.Last;
           if qTempPV.RecordCount>0 then begin
              shiftindex:=qTempPV.FieldByName('shiftindex').AsInteger;
              timedump:=qTempPV.FieldByName('timedump').AsInteger;
              if shiftindex>0 then begin
                 dttm:=ShiftAndSecToDateTime(shiftindex,timedump);
                 ErrorStr:=ErrorStr+' Последние корректные данные были '+FormatDateTime('dd.mm.yy в HH:MM',dttm);
              end else begin
                 ErrorStr:=ErrorStr+' За последние 3 смены корректных данных по весу не было.';
              end;
           end else ErrorStr:=ErrorStr+' За последние 3 смены корректных данных по весу не было.';
        end;
     end;
     qTempPV.Close;
     // Проверка, включена ли галочка автоматических действий.
     // Если отключена, то интерфейс считается не рабочим.
     qTempPV.SQL.Clear;
     qTempPV.SQL.Add('select acceptsd from truck where id='+#39+TTruck(Owner).name+#39);
     qTempPV.Open;
     if qTempPV.RecordCount>0 then begin
        qTempPV.First;
        try
        a:=qTempPV.FieldByName('acceptsd').AsString;
        b:=StrToInt(copy(a,0,1));
        if b=0 then begin
           if status=s_Work then weightworkstr:=' Вес имеется.' else weightworkstr:='';
           Result:=true;
           status:=s_NoData;
           ErrorStr:=ErrorStr+weightworkstr+' Автоматические действия отключены';
        end;
        except
           result:=false;
        end;
     end;
     qTempPV.Close;
     FreeAndNil(qTempPV);
     FreeAndNil(ConnTempPV);  }
end;

constructor TWeightInterface.Create;
begin
     inherited;
     name:='Weight';
     DisplayName:='Вес';
end;

destructor TWeightInterface.Destroy;
begin
     inherited;
end;

{ TFreeSpaceInterface }

function TFreeSpaceInterface.CheckInterface: boolean;
var findstr:string;
    posproc,j:integer;
    usestr, path,pathmin:string;
    freepercent:integer;
    minfreepercent:integer;
    str:string;
    f:boolean;
begin
     {str:='';
     if not OSSH.Lock then exit;
     OSSH.Answer.Clear;
     OSSH.sleeptm:=600;
     OSSH.command:='df -h';
     TEquipment(Owner).Locked.Leave;
     f:=OSSH.Execute;
     TEquipment(Owner).Locked.Enter;
     if f then begin
       status:=s_unknown;
       // Из строки получаем %
       minfreepercent:=100;
       findstr:='%';
       // Проверяем все разделы и находим наименьший процент свободного места
       for j:=1 to OSSH.Answer.Count-1 do begin
            // Получаем позицию findstr
            posproc:=pos(findstr,OSSH.Answer[j]);
            if posproc>0 then begin
               usestr:=copy(OSSH.Answer[j],posproc-3,3);
               path:=copy(OSSH.Answer[j],posproc+2,Length(OSSH.Answer[j])-posproc-1);
               try
                  freepercent:=100-strtoint(Trim(usestr));
               except
                  freepercent:=100;
               end;
               if freepercent<minfreepercent then begin
                  minfreepercent:=freepercent;
                  pathmin:=path;
               end;
            end;
       end;
       // Если наименьший процент свободного места на разделе меньше порога,
       // то авария
       if minfreepercent>ThresholdPercent then begin
          status:=s_Work;
       end else begin
          status:=s_NoData;
       end;
       if status=s_NoData then ErrorStr:='Осталось '+inttostr(minfreepercent)+'% свободной памяти в разделе '+pathmin else ErrorStr:='';
       str:='. Мин. своб.'+ inttostr(minfreepercent)+'%';
     end else status:=s_unknown;
     comment:=str;
     OSSH.Unlock;}
end;

procedure TFreeSpaceInterface.SetThresholdPercent(value: shortint);
begin
     if (value<100) and (value>0) then FthresholdPercent:=value else Application.MessageBox('Ошибка','Порог срабатывания должен быть в границах от 1 до 99%');
end;

{ TRunSniffInterface }

function TRunSniffInterface.CheckInterface: boolean;
var findstr,strproc:string;
    wordindex:integer;
    a,b,c:integer;
    s:string;
    monthstr,daystr,tmmodifstr:string;
    year,month,day:word;
    ModifiedDateTime:TDateTime;
    minutesToError:integer; // Количество минут для возникновения ошибки
    f:boolean;
begin
     {minutesToError:=20;
     if not OSSH.Lock then exit;
     //dt:=Date();
     OSSH.Answer.Clear;
     OSSH.sleeptm:=600;
     OSSH.command:='ls -lah /local/log/OMSsniff | grep "20..-..-.." | tail -1';
     findstr:='sniff.eth0.raw';
     TEquipment(Owner).Locked.Leave;
     f:=OSSH.Execute;
     TEquipment(Owner).Locked.Enter;
     if f then begin
       // Если найден файл снифов
       if pos(findstr,OSSH.Answer.Text) <> 0 then begin
          status:=1;
          strProc:=OSSH.Answer[0];
          Trim(strProc);
          strProc:=DelDoubleSpaces(strProc);
          // Время изменения файла, это 7-е слово в строке
          // Дата создания файла записаны в 8-м слове
          wordindex:=0;
          while length(strproc)>0 do begin
              a:=pos(' ',strproc);
              inc(wordindex);
              if a=0 then begin
                  b:=length(strproc);
                  c:=length(strproc);
              end else begin
                  b:=a;
                  c:=a-1;
              end;
              s:=copy(strproc,1,c);
              if wordindex=6 then monthstr:=s;
              if wordindex=7 then daystr:=s;
              if wordindex=8 then tmmodifstr:=s;

              delete(strproc,1,b);
          end;
          DecodeDate(Now(),year,month,day);
          month:=getMonthNumByString(monthstr);
          try
              day:=strtoint(daystr);
          except
              day:=0;
          end;
          if pos(':',tmmodifstr)<>0 then begin
              ModifiedDateTime:=EncodeDate(year,month,day) + StrToTime(tmmodifstr);
          end else begin
              try
                  year:=strtoint(tmmodifstr);
                  ModifiedDateTime:=EncodeDate(year,month,day)
              except
                  ModifiedDateTime:=0;
              end;
          end;
          // Сравниваем дату изменения последнего файла с текущим временем
          if (ModifiedDateTime>0) and ((Now-ModifiedDateTime)>(1/24/60*minutesToError)) then status:=2 else status:=1;
        end else status:=2;
        // Запись ошибки по интерфейсу
        if status=2 then ErrorStr:='Запись логов OMSsniff на сервере '+TDispatch(Owner).name + ' не выполняется. Свяжитесь с системным администратором'
           else ErrorStr:='';
     end else status:=0;
     comment:='';
     OSSH.Unlock; }
end;

{ TwaitAction }

function TwaitAction.CheckWait: boolean;
begin
    FPrevCome:=FCurrCome;
    FCurrCome:=Check;
    result:=FCurrCome;
end;

constructor TwaitAction.Create(Owner: TEquipment);
begin
     inherited Create;
     FOwner:=Owner;
     isWait:=false;
     FPrevCome:=false;
     FCurrCome:=false;
     FComment:='';
end;

procedure TwaitAction.Disable;
begin
     SetWait(false);
     FPrevCome:=false;
     FCurrCome:=false;
end;

procedure TwaitAction.Enable;
begin
     SetWait(true);
end;

function TwaitAction.GetMenuCaption: string;
begin
     result:='';
end;

function TwaitAction.GetMessage: string;
begin
     result:='';
end;

procedure TwaitAction.SetWait(value: boolean);
begin
     Fiswait:=value;
end;

{ TWaitPowerOn }

function TWaitPowerOn.Check: boolean;
begin
     result:=false;
     try
        if TMobileEquipment(FOwner).PowerStatus=PS_on then result:=true;
     except

     end;
end;

function TWaitPowerOn.GetMenuCaption: string;
begin
     result:='Включения';
end;

function TWaitPowerOn.GetMessage: string;
var str:string;
begin
     str:='Обнаружено включение '+FOwner.name;
     if self.comment<>'' then str:=str+#13#10+'Комментарий: '+self.comment;
     result:=str;
end;

{ TWaitPowerOff }

function TWaitPowerOff.Check: boolean;
begin
     result:=false;
     try
        if TMobileEquipment(FOwner).PowerStatus=PS_off then result:=true;
     except

     end;
end;

function TWaitPowerOff.GetMenuCaption: string;
begin
     result:='Выключения';
end;

function TWaitPowerOff.GetMessage: string;
var str:string;
begin
     str:='Обнаружено выключение '+FOwner.name+'.';
     if self.comment<>'' then str:=str+#13#10+'Комментарий: '+self.comment;
     result:=str;
end;

{ TWaitNotWork }

function TWaitNotWork.Check: boolean;
begin
     result:=false;
     try
        if FOwner.ClassParent=TMobileEQModular then begin
          if not TMobileEQModular(FOwner).IsReadyModular then result:=true;
        end;
        if FOwner.ClassParent=TKobusEquipment then begin
          if TKobusEquipment(FOwner).GetReadySeconds<(60*6) then Result:=true;
        end;
     except

     end;
end;

function TWaitNotWork.GetMenuCaption: string;
begin
     result:='Статуса Не "Готов"';
end;

function TWaitNotWork.GetMessage: string;
var str:string;
begin
     str:='Обнаружен выход '+FOwner.name+' из состояния "Готов".';
     if self.comment<>'' then str:=str+#13#10+'Комментарий: '+self.comment;
     result:=str;
end;

{ TWaitGBM }

function TWaitGBM.Check: boolean;
var s:string;
begin
     result:=false;
     try
        s:=copy(TMobileEQModular(FOwner).Position,1,3);
        if s='GBM' then result:=true;
     except

     end;
end;

function TWaitGBM.GetMenuCaption: string;
begin
     result:='Прибытия в ГБМ';
end;

function TWaitGBM.GetMessage: string;
var str:string;
begin
     str:=FOwner.name+' находится в мастерской ГБМ.';
     if self.comment<>'' then str:=str+#13#10+'Комментарий: '+self.comment;
     result:=str;
end;

{ TPlannedWorksList }


procedure TPlannedWorksList.AddWork(EquipmentID: integer; Workname: string;
  status: TWorkStatus; comment: string; waitActionID: integer;
  accessid: TAccessType);
begin

end;

procedure TPlannedWorksList.DeleteAll;
begin
     // Удаляем все объекты запланированных работ
     while Self.Count>0 do Self.Delete(0);
end;

function TPlannedWorksList.getPlannedWork(index: integer): TPlannedWork;
begin

end;

function TPlannedWorksList.getPlannedWorks(index: integer): TPlannedWork;
begin

end;

function TPlannedWorksList.Load: boolean;
var ConnTempMYSQL:TMyADOConnection;
    qTemp:TMyADOQuery;
    plWork:TPlannedWork;
begin
    // Очищаем список запланированных работ
    self.deleteAll;
    ConnTempMYSQL:=TMyADOConnection.Create(dm1,DM1.TplConnMySQL.ConnectionString);
    qTemp:=TMyADOQuery.Create(dm1,ConnTempMYSQL);
    qTemp.SQL.Clear;
    qTemp.SQL.Add('SELECT * FROM planned_works');
    qTemp.SQL.Add('WHERE (status=1) and');
    qTemp.SQL.Add('((access=3) or ((access=2)and(groupid='+inttostr(Main.objSettings.UserGroup)+') or ((access=1) and (userid='+inttostr(Main.objSettings.UserID)+')))');
    qTemp.SQL.Add('order by equipment, lastActionsDate');
    try
        qTemp.Open;
    except
        result:=false;
        FreeAndNil(qTemp);
        FreeAndNil(ConnTempMYSQL);
        exit;
    end;
    qTemp.Last;
    qTemp.First;
    while not qTemp.Eof do begin
        // Создаем объекты плановых работ
        plWork:=TPlannedWork.Create;

    end;
    qTemp.Close;
    FreeAndNil(qTemp);
    FreeAndNil(ConnTempMYSQL);
end;

{ TEquipmentList }

function TEquipmentList.GetEquipmentByMYSQLIndex(index: integer): TEquipment;
var
  i: Integer;
begin
     result:=nil;
     // Если MYSQL индекс <1 то выходим
     if index<1 then exit;
     i:=0;
     while i<(self.Count) do begin
         if self[i].MySQLIndex=index then begin
            result:=self[i];
            exit;
         end;
     end;
end;

function TEquipmentList.GetItem(Index: Integer): TEquipment;
begin
    result:= TEquipment(inherited Items[index]);
end;

procedure TEquipmentList.SetItem(Index: Integer; Equipment: TEquipment);
begin
    inherited Items[Index] := Equipment;
end;

{ TPlannedWorksEquipment }

function TPlannedWorksEquipment.GetPlannedWork(index: integer): TPlannedWork;
begin

end;

{ TKobusEquipment }


constructor TKobusEquipment.Create;
begin
     inherited;
end;

destructor TKobusEquipment.Destroy;
begin
     inherited;
end;

function TKobusEquipment.GetReadySeconds: integer;
var connTemp:TMyADOConnection;
    QTemp:TMyADOQuery;
    dttm:TDateTime;
begin
    dttm:=Now();
    try
      CoInitialize(nil);
      connTemp:=TMyADOConnection.Create(nil,dm1.ConnMySQL.ConnectionString);
      QTemp:=TMyADOQuery.Create(nil,connTemp);
      if QTemp.Active then QTemp.Close;
      QTemp.SQL.Clear;
      QTemp.SQL.Add('select max(datetimeend) as dttmenddelay from stats_status where (id_equipment='+IntToStr(self.MySQLIndex)+') and (status<>2)');
      try
          QTemp.Open;
          result:=round((dttm-QTemp.FieldByName('dttmenddelay').AsDateTime)*3600*24);
      except
          result:=0;
      end;
    finally
      FreeAndNil(QTemp);
      FreeAndNil(connTemp);
      CoUninitialize;
    end;
end;


{ TPingPCInterface }

function TPingPCInterface.AddDisplayParameter(parameterName: string): boolean;
begin
     inherited;
     result:=false;
     if parameterName='LostPercent' then begin
        DisplayParameters.Add(LostPercent);
        result:=true;
     end;
end;

function TPingPCInterface.CheckInterface: boolean;
var
  dttm: TDateTime;
  connTempMy: TMyADOConnection;
  idequip: Integer;
  qTempMysql: TMyADOQuery;
  countPings: Integer;
  countlost: Integer;
  lostperc: real;
begin
     result:=false;
     status:=0;
    if CalcSeconds<1 then exit;
    if PercentToBad<0 then exit;
    if MinCountPingToCheck<0 then exit;
    if GetMonitoringStatus<>mos_Disable then begin
       //tm:=Time();
       //dt:=Date();
       dttm:=Now;
          connTempMy:=TMyADOConnection.Create(dm1,dm1.TplConnMySQL.ConnectionString);
          qTempMysql:=TMyADOQuery.Create(dm1,connTempMy);
       idequip:=TEquipment(Owner).MySQLIndex;
       qTempMySQL.Clear;
       // Выбираем, сколько всего было запросов в статусе готов
       qTempMySQL.SQL.Add('select sp.time_ping from stats_ping sp');
       qTempMysql.SQL.Add('inner join stats_status ss on (sp.id_equipment=ss.id_equipment) and (sp.datetime>=ss.datetimestart) and (sp.datetime<=ss.datetimeend)');
       qTempMysql.SQL.Add('where (sp.id_equipment=@ideq) and (sp.datetime>"@dttmstart")');
       qTempMysql.SQL.Add('and (ss.id_equipment=@ideq) and (ss.datetimeend>"@dttmstart") and (ss.status=@msready)');
       qTempMysql.vars.Add('ideq',IntToStr(idequip));
       qTempMysql.vars.Add('dttmstart',MySQLDateTime(dttm-(1/24/3600*CalcSeconds)));
       qTempMysql.vars.Add('msready',IntToStr(ms_ready));
       try
         // Разблокируем доступ к объекту, пока идут вычисления
         TEquipment(Owner).Locked.Leave;
         qTempMySQL.Open;
         // Вычисляем количество всех записей и тех, где уровень сигнала был -100
         qTempMySQL.First;
         countPings:=0;
         countlost:=0;
         while not qTempMySQL.Eof do begin
             inc(countPings);
             // Вычисляем неудачные пинги
             if qTempMySQL.FieldByName('time_ping').AsInteger=-100 then inc(countlost);
             qTempMySQL.Next;
         end;
         // Снова блокируем объект для записи данных
         TEquipment(Owner).Locked.Enter;
       except
         result:=false;
         FreeAndNil(qTempMysql);
         FreeAndNil(connTempMy);
         TEquipment(owner).Locked.Enter;
         exit;
       end;
       qTempMySQL.Close;
       // Если создавали новый запрос, то освобождаем память
       FreeAndNil(qTempMysql);
       FreeAndNil(connTempMy);
       status:=0;
       // В статусе Готов был не менее определенного времени за проверяемый интервал
       if countPings>0 then lostperc:=Round(countlost/countPings*100*100)/100 else lostperc:=0;
       if countPings>MinCountPingToCheck then begin
          status:=s_Work;
          if lostperc>PercentToBad then status:=s_NoData;
       end;
       LostPercent.value:=formatFloat('#0.00',lostperc);
    end else status:=s_Disable;
    if status=s_NoData then ErrorStr:=LostPercent.value+'% потерянных пингов за последние '+FormatFloat('0.##',CalcSeconds/3600)+' часов' ;
    result:=true;
end;

constructor TPingPCInterface.Create;
begin
     inherited;
      name:='PingPC';
      DisplayName:='Связь с ПК';
      LostPercent:=TParameterInterface.Create();
      LostPercent.name:='LostPercent';
      LostPercent.displayName:='Потерь';
      LostPercent.value:='0';
      LostPercent.edizm:='%';
      LostPercent.FormatVal:='00,00';
      // Задаем параметры по-умолчанию
      CalcSeconds:=4*3600;
      PercentToBad:=7;
      MinCountPingToCheck:=240;
end;

destructor TPingPCInterface.Destroy;
begin
     FreeAndNil(LostPercent);
    Inherited;
end;

function TPingPCInterface.GetLostPercent(SecondsToCalc: integer): real;
var
  ConnTemp: TMyADOConnection;
  qTemp: TMyADOQuery;
  dttm: TDateTime;
  Nowdate: TDate;
  dttm1: TDateTime;
  dt: TDate;
  tm: TTime;
  nm: string;
  allCnt: Integer;
  successCnt: Integer;
  eqmysqlid: Integer;

begin
     CoInitialize(nil);
    ConnTemp:=TMyADOConnection.Create(dm1,DM1.TplConnMySQL.ConnectionString);
    qTemp:=TMyADOQuery.Create(dm1,ConnTemp);
    dttm:=Now();
    Nowdate:=DateOf(dttm);
    dttm1:=dttm-(SecondsToCalc/24/3600);
    dt:=DateOf(dttm1);
    tm:=TimeOf(dttm1);
    eqmysqlid:=TMobileEquipment(Owner).MySQLIndex;
    if eqmysqlid=0 then begin
      FreeAndNil(qTemp);
      FreeAndNil(ConnTemp);
      result:=-1;
      exit;
    end;
    nm:=TMobileEquipment(Owner).name;
    qTemp.SQL.Add('select count(*) as cnt from stats_ping sp');
    qTemp.SQL.Add('where (sp.id_equipment='+inttostr(eqmysqlid)+') and (sp.datetime>"'+MySQLDateTime(dttm1)+'")');
    try
       qTemp.Open;
       qTemp.First;
        // Количество всех пакетов
        allCnt:=qTemp.FieldByName('cnt').AsInteger;
        qTemp.Close;
    except
       result:=-1;
       FreeAndNil(qTemp);
       FreeAndNil(ConnTemp);
       exit;
    end;
    qTemp.SQL.Add('and (sp.time_ping>-100)');
    try
       qTemp.Open;
       qTemp.First;
       // Количество непотерянных сигналов
       successCnt:=qTemp.FieldByName('cnt').AsInteger;
       qTemp.Close;
    except
       result:=-1;
       FreeAndNil(qTemp);
       FreeAndNil(ConnTemp);
       exit;
    end;
    // вычисляем процент потерянных пакетов
    if allCnt>0 then begin
       result:=(allCnt-successCnt)/allCnt*100;
    end else result:=-1;
    FreeAndNil(qTemp);
    FreeAndNil(ConnTemp);
end;

{ TLTEInterface }

function TLTEInterface.AddDisplayParameter(parameterName: string): boolean;
begin
     inherited;
     result:=false;
     if parameterName='LostPercent' then begin
        DisplayParameters.Add(LostPercent);
        result:=true;
     end;
end;

function TLTEInterface.CheckInterface: boolean;
var
  dttm: TDateTime;
  connTempMy: TMyADOConnection;
  qTempMysql: TMyADOQuery;
  idequip: Integer;
  countPings: Integer;
  countNotSignal: Integer;
  lostperc: real;
begin
     result:=false;
     status:=0;
     // Искусственное создание ошибок для тестирования
     //status:=2;
     //exit;
     // Конец искусственного создания ошибок
    if GetMonitoringStatus<>mos_Disable then begin
       //tm:=Time();
       //dt:=Date();
       dttm:=Now;
       connTempMy:=TMyADOConnection.Create(dm1,dm1.TplConnMySQL.ConnectionString);
       qTempMysql:=TMyADOQuery.Create(dm1,connTempMy);
       idequip:=TEquipment(Owner).MySQLIndex;
       qTempMySQL.Clear;
       // Выбираем, сколько всего было запросов в статусе готов
       qTempMySQL.SQL.Add('select sl.signal_rsrp from stats_lte sl');
       qTempMysql.SQL.Add('inner join stats_status ss on (sl.id_equipment=ss.id_equipment) and (sl.datetime>=ss.datetimestart) and (sl.datetime<=ss.datetimeend)');
       qTempMysql.SQL.Add('where (sl.id_equipment=@eqid) and (sl.datetime>"@dttmstart")');
       qTempMysql.SQL.Add('and (ss.id_equipment=@eqid) and (ss.datetimeend>"@dttmstart") and (ss.status=@ready_status)');
       qTempMysql.vars.Add('eqid',IntToStr(idequip));
       qTempMysql.vars.Add('dttmstart',MySQLDateTime(dttm-(1/24*checkHours)));
       qTempMysql.vars.Add('ready_status',IntToStr(ms_ready));
       try
         // Разблокируем доступ к объекту, пока идут вычисления
         TEquipment(Owner).Locked.Leave;
         qTempMySQL.Open;
         // Вычисляем количество всех записей и тех, где уровень сигнала был -100
         qTempMySQL.First;
         countPings:=0;
         countNotSignal:=0;
         while not qTempMySQL.Eof do begin
             inc(countPings);
             // Вычисляем неудачные пинги
             if qTempMySQL.FieldByName('signal_rsrp').AsInteger=-150 then inc(countNotSignal);
             qTempMySQL.Next;
         end;
         // Снова блокируем объект для записи данных
         TEquipment(Owner).Locked.Enter;
       except
         result:=false;
         FreeAndNil(qTempMysql);
         FreeAndNil(connTempMy);
         TEquipment(owner).Locked.Enter;
         exit;
       end;
       qTempMySQL.Close;
       // Если создавали новый запрос, то освобождаем память
       FreeAndNil(qTempMysql);
       FreeAndNil(connTempMy);
       status:=0;
       // В статусе Готов был не менее определенного времени за проверяемый интервал
       if countPings>0 then lostperc:=Round(countNotSignal/countPings*100*100)/100 else lostperc:=0;
       if countPings>minCountPingToCalculate then begin
          status:=1;
          if lostperc>NoDataLostPercent then status:=2;
       end;
       LostPercent.value:=formatFloat('#0.00',lostperc);
    end else status:=3;
    if status=2 then ErrorStr:=LostPercent.value+'% потерянных пакетов за последние '+IntToStr(checkHours)+' часов' ;
    result:=true;
end;

constructor TLTEInterface.Create;
begin
  inherited;
  name:='LTE';
  DisplayName:='LTE';
  LostPercent:=TParameterInterface.Create();
  LostPercent.name:='LostPercent';
  LostPercent.displayName:='Потерь';
  LostPercent.value:='0';
  LostPercent.edizm:='%';
  LostPercent.FormatVal:='00,00';
  checkHours:=4; // Количество часов, за которые будет рассчитываться процент потерянных пакетов
  NoDataLostPercent:=5; // Порог срабатывания неисправности по WiFi связи
  // Минимальное количество пакетов, которое необходимо для расчетов
  // Нужно расчитывать из расчета пакет на минуту, потому что, если связи не было, то запросы идут не рав в 10 секунд, а раз в минуту
  minCountPingToCalculate:=120;
end;

destructor TLTEInterface.Destroy;
begin
  FreeAndNil(LostPercent);
  Inherited;
end;



end.

