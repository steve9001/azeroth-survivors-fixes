@echo off
setlocal
cd /d "%~dp0"
echo == Azeroth Survivors wrapper: setup
echo.
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is not installed. Installing Node.js LTS with winget...
  winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
  echo.
  echo Node.js was installed. CLOSE this window, then run setup.cmd a second time.
  echo ^(A new window is needed so Windows picks up the updated PATH.^)
  pause
  exit /b 0
)
echo Node.js found:
node --version
echo.
echo Installing Electron into node_modules\ ^(about 100 MB, from the npm registry and the
echo Electron project's GitHub releases^)...
echo.
call npm install --no-fund --no-audit
if errorlevel 1 (
  echo.
  echo npm install failed. Check the internet connection and run setup.cmd again.
  pause
  exit /b 1
)
echo.
rem Electron 45+ no longer downloads its binary during npm install; it waits for the
rem first run. start.cmd launches electron.exe directly, so fetch the binary now.
rem On older Electron this script finds the binary already there and exits at once.
echo Downloading the Electron binary...
node node_modules\electron\install.js
if not exist "node_modules\electron\dist\electron.exe" (
  echo.
  echo The Electron download failed: node_modules\electron\dist\electron.exe is missing.
  echo Check the internet connection and antivirus quarantine, then run setup.cmd again.
  pause
  exit /b 1
)
echo.
echo Done. Double-click start.cmd to play.
pause
