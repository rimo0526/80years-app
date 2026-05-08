@echo off
set LOG=%~dp0find_flutter_log.txt

echo === SCOOP === > "%LOG%" 2>&1
where scoop >> "%LOG%" 2>&1
if exist "%USERPROFILE%\scoop\apps\flutter\current\bin\flutter.bat" echo FOUND: %USERPROFILE%\scoop\apps\flutter\current\bin\flutter.bat >> "%LOG%" 2>&1
if exist "%USERPROFILE%\scoop\shims\flutter.exe" echo FOUND: %USERPROFILE%\scoop\shims\flutter.exe >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === CHOCO === >> "%LOG%" 2>&1
where choco >> "%LOG%" 2>&1
if exist "C:\tools\flutter\bin\flutter.bat" echo FOUND: C:\tools\flutter\bin\flutter.bat >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === STANDARD LOCATIONS === >> "%LOG%" 2>&1
if exist "C:\flutter\bin\flutter.bat" echo FOUND: C:\flutter\bin\flutter.bat >> "%LOG%" 2>&1
if exist "C:\src\flutter\bin\flutter.bat" echo FOUND: C:\src\flutter\bin\flutter.bat >> "%LOG%" 2>&1
if exist "C:\dev\flutter\bin\flutter.bat" echo FOUND: C:\dev\flutter\bin\flutter.bat >> "%LOG%" 2>&1
if exist "%USERPROFILE%\flutter\bin\flutter.bat" echo FOUND: %USERPROFILE%\flutter\bin\flutter.bat >> "%LOG%" 2>&1
if exist "%USERPROFILE%\Documents\flutter\bin\flutter.bat" echo FOUND: %USERPROFILE%\Documents\flutter\bin\flutter.bat >> "%LOG%" 2>&1
if exist "%USERPROFILE%\Downloads\flutter\bin\flutter.bat" echo FOUND: %USERPROFILE%\Downloads\flutter\bin\flutter.bat >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === SEARCH C: === >> "%LOG%" 2>&1
echo (limited to %USERPROFILE% to avoid long search) >> "%LOG%" 2>&1
dir /b /s "%USERPROFILE%\flutter.bat" 2>nul >> "%LOG%"
echo. >> "%LOG%" 2>&1

echo === PATH (one entry per line) === >> "%LOG%" 2>&1
echo %PATH% >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

echo === DONE === >> "%LOG%" 2>&1
echo DONE > "%~dp0find_flutter_DONE.flag"
exit /b 0
