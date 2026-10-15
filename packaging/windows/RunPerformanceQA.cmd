@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0RunPerformanceQA.ps1"
set "qa_exit=%ERRORLEVEL%"
echo.
if not "%qa_exit%"=="0" echo Performance QA needs review. Read the summary and logs beside the game.
pause
exit /b %qa_exit%
