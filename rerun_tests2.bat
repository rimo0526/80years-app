@echo off
title Flutter Re-test 2 (after B4-B5)
set FLUTTER=C:\flutter\bin\flutter.bat
set LOG=%~dp0rerun2_log.txt
cd /d "%~dp0"

del /q "%~dp0rerun2_DONE.flag" 2>nul

echo === START %DATE% %TIME% === > "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === [1] flutter test --no-pub --reporter=compact === >> "%LOG%" 2>&1
call "%FLUTTER%" test --no-pub --reporter=compact >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === END %DATE% %TIME% === >> "%LOG%" 2>&1
echo DONE > "%~dp0rerun2_DONE.flag"
exit /b 0
