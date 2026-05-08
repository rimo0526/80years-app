@echo off
title Deploy to GitHub Pages
set FLUTTER=C:\flutter\bin\flutter.bat
cd /d "%~dp0"

set LOG=%~dp0deploy_log.txt
del /q "%~dp0deploy_DONE.flag" 2>nul

echo === START %DATE% %TIME% === > "%LOG%" 2>&1

REM ============================================================
REM Step 1: 設定値の読込／要確認項目
REM ============================================================
REM この .bat と同じディレクトリに deploy.config.txt を置いてください
REM 中身は次の2行：
REM   GITHUB_REPO=https://github.com/USERNAME/80years-app.git
REM   COMMIT_MSG=Deploy v0.x.0

if not exist "%~dp0deploy.config.txt" (
  echo deploy.config.txt が見つかりません >> "%LOG%" 2>&1
  echo deploy.config.txt を作成して以下を記載してください: >> "%LOG%" 2>&1
  echo. >> "%LOG%" 2>&1
  echo   GITHUB_REPO=https://github.com/USERNAME/80years-app.git >> "%LOG%" 2>&1
  echo   COMMIT_MSG=Deploy v0.1.0 >> "%LOG%" 2>&1
  echo CONFIG_NOT_FOUND > "%~dp0deploy_DONE.flag"
  exit /b 1
)

for /f "tokens=1,2 delims==" %%A in ('type "%~dp0deploy.config.txt"') do (
  if /i "%%A"=="GITHUB_REPO" set GITHUB_REPO=%%B
  if /i "%%A"=="COMMIT_MSG" set COMMIT_MSG=%%B
)

if "%GITHUB_REPO%"=="" (
  echo GITHUB_REPO not set in deploy.config.txt >> "%LOG%" 2>&1
  echo CONFIG_INCOMPLETE > "%~dp0deploy_DONE.flag"
  exit /b 1
)

if "%COMMIT_MSG%"=="" set COMMIT_MSG=Deploy %DATE% %TIME%

echo GITHUB_REPO = %GITHUB_REPO% >> "%LOG%" 2>&1
echo COMMIT_MSG = %COMMIT_MSG% >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

REM ============================================================
REM Step 2: flutter build web --release
REM ============================================================
echo === [1] flutter build web --release === >> "%LOG%" 2>&1
call "%FLUTTER%" build web --release --web-renderer canvaskit >> "%LOG%" 2>&1
if errorlevel 1 (
  echo BUILD_FAILED >> "%LOG%" 2>&1
  echo BUILD_FAILED > "%~dp0deploy_DONE.flag"
  exit /b 1
)
echo. >> "%LOG%" 2>&1

REM ============================================================
REM Step 3: build/web 内で git init して gh-pages へ push
REM ============================================================
cd /d "%~dp0build\web"

echo === [2] git init in build/web === >> "%LOG%" 2>&1
if exist .git rd /s /q .git
git init -b gh-pages >> "%LOG%" 2>&1

echo === [3] git add . === >> "%LOG%" 2>&1
git add . >> "%LOG%" 2>&1

echo === [4] git commit === >> "%LOG%" 2>&1
git commit -m "%COMMIT_MSG%" >> "%LOG%" 2>&1

echo === [5] git remote add origin === >> "%LOG%" 2>&1
git remote add origin "%GITHUB_REPO%" >> "%LOG%" 2>&1

echo === [6] git push --force === >> "%LOG%" 2>&1
git push -f origin gh-pages >> "%LOG%" 2>&1
if errorlevel 1 (
  echo PUSH_FAILED >> "%LOG%" 2>&1
  echo PUSH_FAILED > "%~dp0deploy_DONE.flag"
  exit /b 1
)

cd /d "%~dp0"

echo. >> "%LOG%" 2>&1
echo === END %DATE% %TIME% === >> "%LOG%" 2>&1
echo ============================================== >> "%LOG%" 2>&1
echo  Deployment SUCCESS >> "%LOG%" 2>&1
echo  URL will be live in 1-5 minutes at: >> "%LOG%" 2>&1
echo  https://USERNAME.github.io/80years-app/ >> "%LOG%" 2>&1
echo  (USERNAME は実値で読み替え) >> "%LOG%" 2>&1
echo ============================================== >> "%LOG%" 2>&1
echo SUCCESS > "%~dp0deploy_DONE.flag"
exit /b 0
