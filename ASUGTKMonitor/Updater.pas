// � Scorpio [2014-04-01]
// ������ ���������� �������� � ���������� ����������
// ���������� ������� ����� ��� ���������� ����������
// � ��������� �����.
// ���������� ������������ �� �������� ������ ����������� ���������� � ����������
unit Updater;

interface

uses
  Classes, sysUtils, FileVersion, Windows, MyUtils, ShellApi, SHFolder, iniFiles;

type
  TUpdater = class(TThread)
  private
    { Private declarations }
    FLocationUpdate:string;               // ����� � ������������
    FApplicationName:string;              // ��� ����������
    FTempPostfix:string;                   // ���������� � ������ ������ ��� �������� ��������� ������
    FServiceFileName:string;               // �������� ���������� ����� �������� ��� ���������� ����������
    FShowInf:boolean;                      // ���� ����������� ���������� ��� ������������
    FNeedCheckUpdate:boolean;              // ���� ������������� �������� ����������
    function getUpdateApplFullName: string;
    Procedure SetTempPostfix(value:string);
    procedure SetApplicationName(value:string);
    function getApplTempPath: string;
    function getDoUpdate:boolean;
    procedure SetLocationUpdate(value:string);
  protected
    property DoUpdate:boolean read getDoUpdate;                                       // ���� ���������� ����������
    property ApplicationName:string read FApplicationName write SetApplicationName;   // ��� ����� ������������ ����������
    property UpdateApplFullName: string read getUpdateApplFullName;                 // ������ ���� � ����� ���������� ����������
    property ApplTempPath: string read getApplTempPath;                              // ���� � ���������� ����� ����������
    property ServiceFileName: string read FServiceFileName write FServiceFileName;  // �������� ���������� ����� �������� ��� ���������� ����������
    procedure LoadUpdateFile;                                                       // �������� ���������� �� ����
    function NeedUpdate:boolean;                                                    // ������� �������� ����������
    procedure RunUpdateApplication;                                                 // ������ ������������ ����������
    function FinishUpdate:boolean;                                                  // ���������� �������� �� ���������� ����������
    procedure CleanOldUpdateFiles;                                                  // �������� ��������� ������ ���������� � ����������
    function IsRunTempFile:boolean;                                                  // �������� ����, ������� �� ��������� ����
    procedure Execute; override;
  public
    property LocationUpdate:string read FLocationUpdate write SetLocationUpdate;        // ����� � ������������
    property TempPostfix:string read FTempPostfix write setTempPostfix;             // ���������� � ������ ������ ��� �������� ��������� ������
    property ShowInf:boolean read FShowInf;                          // ���� ����������� ���������� �� ����������
    property NeedCheckUpdate:boolean read FNeedCheckUpdate write FNeedCheckUpdate;   // ���� ������������� ���������� �������� ����������
  end;

var UpdateThread: TUpdater;

implementation

uses Main, Forms;

{ TUpdater }

// �������� ��������� ������ ���������� �
procedure TUpdater.CleanOldUpdateFiles;
begin
     DeleteFile(PWideChar(ApplTempPath));
     DeleteFile(PWideChar(ExtractFilePath(Application.ExeName)+ServiceFileName));
end;

procedure TUpdater.Execute;
var UpdFile:TIniFile;
  dttm:TDateTime;
begin
  { Place thread code here }
  if TempPostfix='' then TempPostfix:='_new';
  if ServiceFileName='' then ServiceFileName:='Update_Application.ini';
  if FileExists(ExtractFilePath(Application.ExeName)+ServiceFileName) then begin
     UpdFile:=TIniFile.Create(ExtractFilePath(Application.ExeName)+ServiceFileName);
     ApplicationName:=UpdFile.ReadString('Update','ApplicationName','');
     UpdFile.Free;
  end;
  if ApplicationName='' then ApplicationName:=ExtractFileName(Application.ExeName);
  sleep(100);
  if IsRunTempFile and FinishUpdate then ExitProcess(0);
  CleanOldUpdateFiles;
  while not Terminated do begin
       // ��� � 10 ����� ��������� ����������
       if ((now()-dttm)>1/24/6) or NeedCheckUpdate then begin
          dttm:=now();
          NeedCheckUpdate:=false;
          if not DoUpdate and NeedUpdate then begin
              LoadUpdateFile;
              UpdFile:=TIniFile.Create(ExtractFilePath(Application.ExeName)+ServiceFileName);
              UpdFile.WriteString('Update','ApplicationName',ApplicationName);
              UpdFile.UpdateFile;
              UpdFile.Free;
              FShowInf:=true;
              //Application.MessageBox('������� ����� ������ ���������. ����������� ���������� ','����������');
              sleep(5000);
              FShowInf:=false;
              RunUpdateApplication;
              ExitProcess(0);
           end;
       end;
       sleep(1000);
  end;
end;

// ������� ������ ������ ���������, �������� �� �� ����� ����� ������ � ��������� ��, � ��� ���������
function TUpdater.FinishUpdate: boolean;
var destApplName:string;
begin
     result:=false;
     destApplName:=ExtractFilePath(Application.ExeName)+ApplicationName;
     result:=true;
     DeleteFile(PWideChar(destApplName));
     if not CopyFile(PWideChar(Application.ExeName),PWideChar(destApplName),false) then result:=false;
     // ��������� ����� ������ ���������
     if FileExists(destApplName) then begin
         result:=true;
         DeleteFile(PWideChar(ExtractFilePath(Application.ExeName)+ServiceFileName));
         ShellExecute(0, PChar('open'), PChar(destApplName), nil, nil, SW_SHOWNORMAL);
     end;
end;

function TUpdater.getApplTempPath: string;
var destFolder:string;
    destName:string;
    dotpos:integer;
begin
     destFolder:=ExtractFilePath(Application.ExeName);
     destName:=ExtractFileName(self.ApplicationName);
     dotpos:=LastPos('.',destName);
     Insert(self.TempPostfix,destName,dotpos);
     result:=destFolder+destName;
end;

function TUpdater.getDoUpdate: boolean;
begin
     if FileExists(ExtractFilePath(Application.ExeName)+ServiceFileName) then result:=true else result:=false;
end;

function TUpdater.getUpdateApplFullName: string;
begin
     result:=LocationUpdate+ApplicationName;
end;

function TUpdater.IsRunTempFile: boolean;
begin
     if Application.ExeName=ApplTempPath then result:=true else result:=false;
end;

procedure TUpdater.LoadUpdateFile;
begin
     if FileExists(UpdateApplFullName) then begin
        CopyFile(PWideChar(UpdateApplFullName),PWideChar(ApplTempPath),false);
     end;
end;

function TUpdater.NeedUpdate: boolean;
var ExeFInfo, UpdateFInfo:TFileInfo;
    FindDiff:boolean;
    f1,f2:boolean;
begin
     result:=false;
     if FileExists(UpdateApplFullName) then begin
         f1:=GetFileInfo(Application.ExeName,ExefInfo);
         f2:=GetFileInfo(UpdateApplFullName,UpdatefInfo);
         FindDiff:=false;
         // ���� �� �������� ���������� �� ������ �� ������, �� �������
         if not (f1 and f2) then begin
            result:=false;
            exit;
         end;
         // ���������� ������� ������
         if ExeFInfo.FileVersion.MajorVersion>UpdateFInfo.FileVersion.MajorVersion then begin
            FindDiff:=true;
            Result:=false;
         end else begin
            if ExeFInfo.FileVersion.MajorVersion<UpdateFInfo.FileVersion.MajorVersion then begin
               FindDiff:=true;
               result:=true;
            end;
         end;
         // ���� �� ����� ������� � ������� �������, �� ���������� ������� ������
         if not FindDiff then begin
              if ExeFInfo.FileVersion.MinorVersion>UpdateFInfo.FileVersion.MinorVersion then begin
                FindDiff:=true;
                Result:=false;
             end else begin
                if ExeFInfo.FileVersion.MinorVersion<UpdateFInfo.FileVersion.MinorVersion then begin
                   FindDiff:=true;
                   result:=true;
                end;
             end;
         end;
         // ���� �� ����� ������� � ������� �������, �� ���������� ������
         if not FindDiff then begin
              if ExeFInfo.FileVersion.Release>UpdateFInfo.FileVersion.Release then begin
                FindDiff:=true;
                Result:=false;
             end else begin
                if ExeFInfo.FileVersion.Release<UpdateFInfo.FileVersion.Release then begin
                   FindDiff:=true;
                   result:=true;
                end else result:=false;
             end;
         end;
         // [2021-11-02] ���������� �����. ����� ��� ����������� ������� � ����� �������
         if not FindDiff then begin
              if ExeFInfo.FileVersion.build>UpdateFInfo.FileVersion.build then begin
                FindDiff:=true;
                Result:=false;
             end else begin
                if ExeFInfo.FileVersion.build<UpdateFInfo.FileVersion.build then begin
                   FindDiff:=true;
                   result:=true;
                end else result:=false;
             end;
         end;
     end;
end;

procedure TUpdater.RunUpdateApplication;
var a:string;
begin
     a:=self.ApplTempPath;
     try
        ShellExecute(0, PChar('open'), PChar(a), nil, nil, SW_SHOWNORMAL);
     except

     end;
end;


procedure TUpdater.SetApplicationName(value: string);
var str:string;
begin
     str:=DelDoubleSpaces(value);
     if (str<>'') and (str<>' ') then FApplicationName:=value;
end;

procedure TUpdater.SetLocationUpdate(value: string);
var str:string;
begin
     str:=value;
     if str[Length(str)]<>'\' then str:=str+'\';
     FLocationUpdate:=str;
end;

procedure TUpdater.SetTempPostfix(value: string);
begin
     if value<>'' then FTempPostfix:=value;
end;

end.
