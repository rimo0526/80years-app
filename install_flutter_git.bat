@echo off
title Flutter SDK Install via git clone
set LOG=%~dp0install_flutter_log.txt
set FLUTTER_DIR=C:\flutter

echo === START %DATE% %TIME% === > "%LOG%" 2>&1

echo. >> "%LOG%" 2>&1
echo === [1] check git === >> "%LOG%" 2>&1
where git >> "%LOG%" 2>&1
if errorlevel 1 (
  echo GIT_NOT_FOUND >> "%LOG%" 2>&1
  echo DONE > "%~dp0install_flutter_DONE.flag"
  exit /b 1
)

echo. >> "%LOG%" 2>&1
echo === [2] check existing flutter dir === >> "%LOG%" 2>&1
if exist "%FLUTTER_DIR%\bin\flutter.bat" (
  echo flutter dir already exists at %FLUTTER_DIR% >> "%LOG%" 2>&1
  goto :addpath
)

echo. >> "%LOG%" 2>&1
echo === [3] git clone flutter (stable, depth 1) === >> "%LOG%" 2>&1
echo Cloning to %FLUTTER_DIR% ... please wait 1-3 minutes >> "%LOG%" 2>&1
git clone https://github.com/flutter/flutter.git -b stable --depth 1 "%FLUTTER_DIR%" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo CLONE_FAILED >> "%LOG%" 2>&1
  echo DONE > "%~dp0install_flutter_DONE.flag"
  exit /b 1
)

:addpath
echo. >> "%LOG%" 2>&1
echo === [4] add to user PATH === >> "%LOG%" 2>&1
powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('PATH','User'); if($p -notlike '*C:\flutter\bin*'){[Environment]::SetEnvironmentVariable('PATH', $p + ';C:\flutter\bin', 'User'); Write-Output 'added'} else {Write-Output 'already in PATH'}" >> "%LOG%" 2>&1

echo. >> "%LOG%" 2>&1
echo === [5] flutter --version (using full path) === >> "%LOG%" 2>&1
call "%FLUTTER_DIR%\bin\flutter.bat" --version >> "%LOG%" 2>&1

echo. >> "%LOG%" 2>&1
echo === [6] flutter pub get === >> "%LOG%" 2>&1
cd /d "%~dp0"
call "%FLUTTER_DIR%\bin\flutter.bat" pub get >> "%LOG%" 2>&1

echo. >> "%LOG%" 2>&1
echo === [7] flutter analyze --no-pub === >> "%LOG%" 2>&1
call "%FLUTTER_DIR%\bin\flutter.bat" analyze --no-pub >> "%LOG%" 2>&1

echo. >> "%LOG%" 2>&1
echo === [8] flutter test --no-pub --reporter=compact === >> "%LOG%" 2>&1
call "%FLUTTER_DIR%\bin\flutter.bat" test --no-pub --reporter=compact >> "%LOG%" 2>&1

echo. >> "%LOG%" 2>&1
echo === END %DATE% %TIME% === >> "%LOG%" 2>&1
echo DONE > "%~dp0install_flutter_DONE.flag"
exit /b 0
