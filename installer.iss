; ════════════════════════════════════════════════════════════
; إدارة الطيف - سكريبت إنشاء المثبت
; Inno Setup Script
; ════════════════════════════════════════════════════════════

#define MyAppName "إدارة الطيف"
#define MyAppVersion "1.3.1"
#define MyAppPublisher "Taif Management"
#define MyAppExeName "my_system.exe"

[Setup]
; معلومات التطبيق
AppId={{67E14DCF-FDE2-4A6A-A22E-6E53119042DF}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\TaifManagement
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=TaifManagement-Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

; أيقونة البرنامج
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

; صلاحيات المسؤول
PrivilegesRequired=admin

; معلومات إضافية
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=نظام إدارة الطلبات والتحاسبات
AppCopyright=Copyright © 2024
UninstallDisplayName={#MyAppName}

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

[Tasks]
Name: "desktopicon"; Description: "إنشاء اختصار على سطح المكتب"; GroupDescription: "اختصارات إضافية:"; Flags: unchecked

[Files]
; نسخ جميع ملفات البرنامج - مع استبدال قسري للملفات القديمة
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs uninsrestartdelete

[Icons]
; اختصار في قائمة البرامج
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\إلغاء التثبيت"; Filename: "{uninstallexe}"
; اختصار على سطح المكتب
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; تشغيل البرنامج بعد التثبيت
Filename: "{app}\{#MyAppExeName}"; Description: "تشغيل {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; حذف ملفات البيانات عند إلغاء التثبيت
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}\logs"

[Code]
// دالة للتحقق من إصدار سابق وإلغاء تثبيته تلقائياً
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
  OldPath: String;
  UninstallString: String;
begin
  Result := True;
  
  // التحقق من وجود إصدار سابق
  if RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{67E14DCF-FDE2-4A6A-A22E-6E53119042DF}_is1', 'InstallLocation', OldPath) then
  begin
    // إلغاء التثبيت القديم تلقائياً بدون سؤال
    MsgBox('سيتم إلغاء تثبيت النسخة السابقة وتثبيت النسخة الجديدة...', mbInformation, MB_OK);
    
    // إيقاف البرنامج إذا كان يعمل
    if Exec('taskkill', '/F /IM my_system.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      Sleep(1000);
    
    // إلغاء التثبيت القديم بصمت
    if RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{67E14DCF-FDE2-4A6A-A22E-6E53119042DF}_is1', 'UninstallString', UninstallString) then
    begin
      UninstallString := RemoveQuotes(UninstallString);
      Exec(UninstallString, '/VERYSILENT /NORESTART /SUPPRESSMSGBOXES', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      Sleep(2000); // انتظار اكتمال الحذف
    end;
  end;
end;

// دالة تُنفذ قبل التثبيت لضمان حذف الملفات القديمة
procedure CurStepChanged(CurStep: TSetupStep);
var
  AppDir: String;
begin
  if CurStep = ssInstall then
  begin
    AppDir := ExpandConstant('{app}');
    
    // حذف الملفات الرئيسية القديمة إذا كانت موجودة
    if FileExists(AppDir + '\my_system.exe') then
    begin
      DeleteFile(AppDir + '\my_system.exe');
    end;
    
    if FileExists(AppDir + '\flutter_windows.dll') then
    begin
      DeleteFile(AppDir + '\flutter_windows.dll');
    end;
  end;
  
  if CurStep = ssPostInstall then
  begin
    // يمكن إضافة خطوات إضافية هنا بعد التثبيت
  end;
end;

[Messages]
// رسائل مخصصة بالعربية
WelcomeLabel1=مرحباً بك في برنامج إدارة الطيف
WelcomeLabel2=سيقوم هذا المعالج بتثبيت البرنامج على جهازك.%n%nيُنصح بإغلاق جميع التطبيقات الأخرى قبل المتابعة.
ClickNext=اضغط "التالي" للمتابعة، أو "إلغاء" للخروج.
SelectDirLabel3=سيتم تثبيت البرنامج في المجلد التالي.
DiskSpaceMBLabel=يتطلب البرنامج [mb] ميغابايت على الأقل من المساحة الفارغة.
