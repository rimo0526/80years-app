@echo off
title AI Simulation v2 (events.json 注入)
set FLUTTER=C:\flutter\bin\flutter.bat
set DART=C:\flutter\bin\dart.bat
set LOG=%~dp0sim_v2_log.txt
cd /d "%~dp0"

del /q "%~dp0sim_v2_DONE.flag" 2>nul

echo === START %DATE% %TIME% === > "%LOG%" 2>&1
echo === sim v2 with events.json === >> "%LOG%" 2>&1
call "%DART%" run lib/dev/sim_runner.dart 1000 sim_v2.csv >> "%LOG%" 2>&1
echo === END %DATE% %TIME% === >> "%LOG%" 2>&1
echo DONE > "%~dp0sim_v2_DONE.flag"
exit /b 0
