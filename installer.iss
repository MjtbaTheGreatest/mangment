; ════════════════════════════════════════════════════════════
; إدارة الطيف - سكريبت إنشاء المثبت
; Inno Setup Script
; ════════════════════════════════════════════════════════════

#define MyAppName "إدارة الطيف"
#define MyAppVersion "1.0.0"
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
; نسخ جميع ملفات البرنامج
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

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
// دالة للتحقق من إصدار سابق
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
  OldPath: String;
begin
  Result := True;
  
  // التحقق من وجود إصدار سابق
  if RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{67E14DCF-FDE2-4A6A-A22E-6E53119042DF}_is1', 'InstallLocation', OldPath) then
  begin
    if MsgBox('تم العثور على إصدار سابق من البرنامج. هل تريد إلغاء تثبيته قبل المتابعة؟', mbConfirmation, MB_YESNO) = IDYES then
    begin
      // إلغاء التثبيت القديم
      Exec(OldPath + '\unins000.exe', '/SILENT', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;

// دالة تُنفذ بعد اكتمال التثبيت
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // يمكن إضافة خطوات إضافية هنا
    // مثل: إنشاء قاعدة البيانات الأولية
  end;
end;

[Messages]
// رسائل مخصصة بالعربية
WelcomeLabel1=مرحباً بك في برنامج إدارة الطيف
WelcomeLabel2=سيقوم هذا المعالج بتثبيت البرنامج على جهازك.%n%nيُنصح بإغلاق جميع التطبيقات الأخرى قبل المتابعة.
ClickNext=اضغط "التالي" للمتابعة، أو "إلغاء" للخروج.
SelectDirLabel3=سيتم تثبيت البرنامج في المجلد التالي.
DiskSpaceMBLabel=يتطلب البرنامج [mb] ميغابايت على الأقل من المساحة الفارغة.
