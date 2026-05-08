@echo off
title Flutter Web Run - capitalism game
set FLUTTER=C:\flutter\bin\flutter.bat
cd /d "%~dp0"

echo ============================================
echo  flutter run -d chrome
echo  This will build and launch Chrome
echo  Build time: 1-2 minutes (first time only)
echo  Press Ctrl+C in this window to stop
echo ============================================
echo.

call "%FLUTTER%" run -d chrome --web-port=8080
