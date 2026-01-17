@echo off
REM Install VMware Tools silently
REM Use VMwareToolsUpgrader.exe as signature to identify VMware Tools ISO

echo Searching for VMware Tools ISO...

for %%d in (D E F G) do (
    if exist "%%d:\VMwareToolsUpgrader.exe" (
        echo Found VMware Tools ISO on %%d:

        REM Try setup64.exe first
        if exist "%%d:\setup64.exe" (
            echo Installing via setup64.exe...
            "%%d:\setup64.exe" /S /v"/qn REBOOT=ReallySuppress"
            goto :done
        )

        REM Try setup.exe
        if exist "%%d:\setup.exe" (
            echo Installing via setup.exe...
            "%%d:\setup.exe" /S /v"/qn REBOOT=ReallySuppress"
            goto :done
        )
    )
)

echo ERROR: VMware Tools ISO not found

:done
echo VMware Tools script finished
