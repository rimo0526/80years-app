@echo off
title Flutter SDK Check - capitalism game
cd /d "%~dp0"

set LOG=%~dp0flutter_run_log.txt

echo ============================================== > "%LOG%" 2>&1
echo  Flutter SDK Check >> "%LOG%" 2>&1
echo  start: %DATE% %TIME% >> "%LOG%" 2>&1
echo  cwd : %CD% >> "%LOG%" 2>&1
echo ============================================== >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo [1] where flutter / where dart >> "%LOG%" 2>&1
where flutter >> "%LOG%" 2>&1
where dart >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo [2] flutter --version >> "%LOG%" 2>&1
call flutter --version >> "%LOG%" 2>&1
if errorlevel 1 (
  echo FLUTTER_NOT_FOUND >> "%LOG%" 2>&1
  echo end: %DATE% %TIME% >> "%LOG%" 2>&1
  echo DONE > "%~dp0flutter_run_DONE.flag"
  exit /b 1
)
echo. >> "%LOG%" 2>&1

echo [3] flutter pub get >> "%LOG%" 2>&1
call flutter pub get >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo [4] flutter analyze --no-pub >> "%LOG%" 2>&1
call flutter analyze --no-pub >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo [5] flutter test --no-pub --reporter=compact >> "%LOG%" 2>&1
call flutter test --no-pub --reporter=compact >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo ============================================== >> "%LOG%" 2>&1
echo  end: %DATE% %TIME% >> "%LOG%" 2>&1
echo ============================================== >> "%LOG%" 2>&1

echo DONE > "%~dp0flutter_run_DONE.flag"
exit /b 0
