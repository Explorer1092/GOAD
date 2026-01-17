# Disable screensaver and monitor timeout for unattended operation

Write-Output "Disabling screensaver and monitor timeout..."

Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name ScreenSaveActive -Value 0 -Type DWord
powercfg -x -monitor-timeout-ac 0
powercfg -x -monitor-timeout-dc 0
