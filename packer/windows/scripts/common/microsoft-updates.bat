net stop wuauserv

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v EnableFeaturedSoftware /t REG_DWORD /d 1 /f

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v IncludeRecommendedUpdates /t REG_DWORD /d 1 /f

set "TEMP_VBS=%SystemRoot%\Temp\goad-microsoft-updates.vbs"
echo Set ServiceManager = CreateObject("Microsoft.Update.ServiceManager") > "%TEMP_VBS%"
echo Set NewUpdateService = ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") >> "%TEMP_VBS%"

if exist "%TEMP_VBS%" (
  cscript "%TEMP_VBS%"
  del /f /q "%TEMP_VBS%"
) else (
  echo Failed to create "%TEMP_VBS%"
)

net start wuauserv
