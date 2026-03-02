@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%godot"

where godot >nul 2>nul
if %ERRORLEVEL%==0 (
  godot --path "%PROJECT_DIR%"
  goto :eof
)

where Godot_v4.3-stable_win64.exe >nul 2>nul
if %ERRORLEVEL%==0 (
  Godot_v4.3-stable_win64.exe --path "%PROJECT_DIR%"
  goto :eof
)

echo Godot was not found on PATH.
echo Install Godot 4.x, or add your Godot executable to PATH, then run this file again.
echo Download: https://godotengine.org/download/windows/
pause
