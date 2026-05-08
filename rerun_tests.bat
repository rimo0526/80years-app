@echo off
title Flutter Re-test (after fixes)
set FLUTTER=C:\flutter\bin\flutter.bat
set LOG=%~dp0rerun_log.txt
cd /d "%~dp0"

del /q "%~dp0rerun_DONE.flag" 2>nul

echo === START %DATE% %TIME% === > "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === [1] flutter pub get === >> "%LOG%" 2>&1
call "%FLUTTER%" pub get >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === [2] flutter analyze --no-pub === >> "%LOG%" 2>&1
call "%FLUTTER%" analyze --no-pub >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === [3] flutter test --no-pub --reporter=compact === >> "%LOG%" 2>&1
call "%FLUTTER%" test --no-pub --reporter=compact >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === END %DATE% %TIME% === >> "%LOG%" 2>&1
echo DONE > "%~dp0rerun_DONE.flag"
exit /b 0
