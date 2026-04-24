@echo off
setlocal

cd /d "%~dp0"

echo Starting Nation Builder server...
start "" cmd /k "cd /d %~dp0 && node server.js"

timeout /t 4 /nobreak >nul

echo Opening Nation Builder in browser...
start "" "http://localhost:3000/"

endlocal
