; Inno Setup Script for MicroLend Flutter Desktop App
; Defines can be overridden via command-line ISCC parameters (e.g. /DMyAppName="MicroLend" /DMyAppVersion="1.0.0" /DAppSlug="microlend" /DExeName="JuanLend.exe")

#ifndef MyAppName
  #define MyAppName "MicroLend"
#endif
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#ifndef AppSlug
  #define AppSlug "microlend"
#endif
#ifndef ExeName
  #define ExeName "JuanLend.exe"
#endif
#ifndef MyAppPublisher
  #define MyAppPublisher "MicroLend Team"
#endif

[Setup]
AppId={{8A3C5F12-9D0E-4F8A-B2C1-6E3A5F7B9C0D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\build\windows\installer
OutputBaseFilename={#AppSlug}-windows-setup-{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#ExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
