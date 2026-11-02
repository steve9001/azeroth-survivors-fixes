@echo off
setlocal
cd /d "%~dp0"
if not exist "node_modules\electron\dist\electron.exe" (
  echo Not set up yet. Run setup.cmd first.
  pause
  exit /b 1
)
rem Launch the Electron binary directly and detach, so no console window lingers.
rem Extra arguments are passed through: start.cmd --windowed
start "" "node_modules\electron\dist\electron.exe" . %*
