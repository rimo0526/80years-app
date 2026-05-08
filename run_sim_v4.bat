@echo off
title AI Sim v4 v1.3 retune
set DART=C:\flutter\bin\dart.bat
set LOG=%~dp0sim_v4_log.txt
cd /d "%~dp0"

del /q "%~dp0sim_v4_DONE.flag" 2>nul

echo === START %DATE% %TIME% === > "%LOG%" 2>&1
echo === sim v4 GameEngine v1.3 === >> "%LOG%" 2>&1
call "%DART%" run lib/dev/sim_runner.dart 1000 sim_v4.csv >> "%LOG%" 2>&1
echo === END %DATE% %TIME% === >> "%LOG%" 2>&1
echo DONE > "%~dp0sim_v4_DONE.flag"
exit /b 0
