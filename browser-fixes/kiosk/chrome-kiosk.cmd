@echo off
setlocal
rem Google Chrome in kiosk mode. Same effect and same limits as edge-kiosk.cmd: the fullscreen
rem notice is suppressed, the pointer-capture notice is not. Alt+F4 quits.
set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" (
  echo Google Chrome was not found in the usual places.
  pause
  exit /b 1
)
set "PROFILE=%LocalAppData%\AzerothSurvivors\chrome-kiosk"
start "" "%CHROME%" --kiosk https://wow.aethus.pl/ --no-first-run --user-data-dir="%PROFILE%"
