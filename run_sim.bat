@echo off
title AI Simulation 1000 chars
set FLUTTER=C:\flutter\bin\flutter.bat
set DART=C:\flutter\bin\dart.bat
set LOG=%~dp0sim_run_log.txt
cd /d "%~dp0"

del /q "%~dp0sim_DONE.flag" 2>nul

echo === START %DATE% %TIME% === > "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === [1] flutter pub get === >> "%LOG%" 2>&1
call "%FLUTTER%" pub get >> "%LOG%" 2>&1

echo. >> "%LOG%" 2>&1
echo === [2] dart run sim_runner 1000 sim.csv === >> "%LOG%" 2>&1
call "%DART%" run lib/dev/sim_runner.dart 1000 sim.csv >> "%LOG%" 2>&1

echo. >> "%LOG%" 2>&1
echo === END %DATE% %TIME% === >> "%LOG%" 2>&1
echo DONE > "%~dp0sim_DONE.flag"
exit /b 0
