@echo off
title Restart Flutter Chrome
set FLUTTER=C:\flutter\bin\flutter.bat
cd /d "%~dp0"

echo === Killing existing flutter / dart processes ===
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter_tester.exe 2>nul

REM 注：cmd.exe で動いている flutter run は WindowTitle で識別
taskkill /F /FI "WINDOWTITLE eq Flutter Web Run - capitalism game" 2>nul

REM ポート 8080 を使ってるプロセスも念のため停止
for /f "tokens=5" %%P in ('netstat -ano ^| findstr :8080') do (
  taskkill /F /PID %%P 2>nul
)

echo.
echo === Waiting 3s then starting fresh ===
timeout /t 3 >nul

echo === flutter run -d chrome ===
call "%FLUTTER%" run -d chrome --web-port=8080
