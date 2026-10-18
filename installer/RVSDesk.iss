; RVDesk Inno Setup script
;
; Built by build_installer.ps1 (preferred), or manually:
;   ISCC.exe /DAppVersion=x.y.z /DAppVersionQuad=x.y.z.w /DPayloadDir=... /DOutputDir=... RVSDesk.iss
; AppVersion comes from the VERSION file.

#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif

#ifndef AppVersionQuad
  #define AppVersionQuad "0.0.0.0"
#endif

#ifndef PayloadDir
  #define PayloadDir "..\build\payload"
#endif

#ifndef OutputDir
  #define OutputDir "Output"
#endif

#ifndef OutputBase
  #define OutputBase "RVDesk-Setup-" + AppVersion
#endif

#ifndef AppName
  #define AppName "RVDesk"
#endif

#ifndef AppExeName
  #define AppExeName "RVDesk.exe"
#endif

#ifndef AppPublisher
  #define AppPublisher "RithV Services"
#endif

#ifndef AppDirName
  #define AppDirName "RVDesk"
#endif

#ifndef PrivReq
  #define PrivReq "admin"
#endif

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
; AppId is intentionally unchanged for upgrade continuity (existing installs upgrade in place).
AppId={{3D92DD6B-C0B8-464B-BC15-795B5425B4D0}
DefaultDirName={autopf}\{#AppDirName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired={#PrivReq}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBase}
SetupIconFile=..\assets\rvsdesk.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
VersionInfoVersion={#AppVersionQuad}
VersionInfoProductVersion={#AppVersionQuad}
VersionInfoTextVersion={#AppVersionQuad}
VersionInfoProductTextVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} Setup
CloseApplications=yes
RestartApplications=yes
UsePreviousAppDir=yes
UsePreviousGroup=yes
ChangesAssociations=no

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "{#PayloadDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs;


[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Comment: "{#AppName} remote desktop"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent unchecked; WorkingDir: "{app}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\logs"
Type: files; Name: "{app}\*.log"

[Code]
function VerNum(const S: String): Cardinal;
var
  T, Part: String;
  P: Integer;
  N: Cardinal;
begin
  Result := 0;
  T := S;
  while True do
  begin
    P := Pos('.', T);
    if P > 0 then
    begin
      Part := Copy(T, 1, P - 1);
      Delete(T, 1, P);
    end
    else
    begin
      Part := T;
      T := '';
    end;
    N := Cardinal(StrToIntDef(Part, 0));
    if N > 99 then
      N := 99;
    Result := Result * 100 + N;
    if T = '' then
      Break;
  end;
end;

function CompareVer(const A, B: String): Integer;
var
  NA, NB: Cardinal;
begin
  NA := VerNum(A);
  NB := VerNum(B);
  if NA < NB then
    Result := -1
  else if NA > NB then
    Result := 1
  else
    Result := 0;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  SetPreviousData(PreviousDataKey, 'AppVersion', '{#AppVersion}');
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Prev: String;
begin
  Prev := GetPreviousData('AppVersion', '' );
  if (Prev <> '') and (CompareVer(Prev, '{#AppVersion}') > 0) then
    Result := 'A newer version of {#AppName} (' + Prev + ') is already installed. Downgrading is not supported.'
  else
    Result := '';
end;
