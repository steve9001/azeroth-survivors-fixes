@echo off
setlocal
rem Microsoft Edge in kiosk mode. Chromium skips the "Press Esc to exit full screen" notice in
rem kiosk mode (chrome/browser/ui/exclusive_access/exclusive_access_manager.cc). It does NOT skip
rem the "has control of your pointer" notice, which still appears after you press Esc.
rem
rem A separate profile folder is used so this starts cleanly even when Edge is already open.
rem The game's save then lives in that profile: move it with the game's Options > Saves.
rem Esc does not leave fullscreen in kiosk mode; Alt+F4 quits.
set "EDGE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" set "EDGE=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" set "EDGE=%LocalAppData%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" (
  echo Microsoft Edge was not found in the usual places.
  pause
  exit /b 1
)
set "PROFILE=%LocalAppData%\AzerothSurvivors\edge-kiosk"
start "" "%EDGE%" --kiosk https://wow.aethus.pl/ --edge-kiosk-type=fullscreen --no-first-run --user-data-dir="%PROFILE%"
