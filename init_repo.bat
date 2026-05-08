@echo off
title Initial Git Repo Setup
cd /d "%~dp0"
set LOG=%~dp0init_repo_log.txt

del /q "%~dp0init_repo_DONE.flag" 2>nul

echo === START %DATE% %TIME% === > "%LOG%" 2>&1

if not exist "%~dp0deploy.config.txt" (
  echo deploy.config.txt not found >> "%LOG%" 2>&1
  echo CONFIG_NOT_FOUND > "%~dp0init_repo_DONE.flag"
  exit /b 1
)

for /f "tokens=1,2 delims==" %%A in ('type "%~dp0deploy.config.txt"') do (
  if /i "%%A"=="GITHUB_REPO" set GITHUB_REPO=%%B
)

echo GITHUB_REPO = %GITHUB_REPO% >> "%LOG%" 2>&1
echo. >> "%LOG%" 2>&1

if exist "%~dp0.git" (
  echo .git already exists, skipping init >> "%LOG%" 2>&1
) else (
  echo === [1] git init === >> "%LOG%" 2>&1
  git init -b main >> "%LOG%" 2>&1
)

git config --get user.name >nul 2>&1
if errorlevel 1 (
  echo === [2a] git config user.name === >> "%LOG%" 2>&1
  git config user.name "rimo" >> "%LOG%" 2>&1
)
git config --get user.email >nul 2>&1
if errorlevel 1 (
  echo === [2b] git config user.email === >> "%LOG%" 2>&1
  git config user.email "ri.mo.950526@gmail.com" >> "%LOG%" 2>&1
)

git config core.quotepath false >> "%LOG%" 2>&1

echo === [3] git remote === >> "%LOG%" 2>&1
git remote -v >> "%LOG%" 2>&1
git remote get-url origin >nul 2>&1
if errorlevel 1 (
  git remote add origin "%GITHUB_REPO%" >> "%LOG%" 2>&1
) else (
  git remote set-url origin "%GITHUB_REPO%" >> "%LOG%" 2>&1
)

echo === [4] git add === >> "%LOG%" 2>&1
git add . >> "%LOG%" 2>&1

echo === [5] git commit === >> "%LOG%" 2>&1
git commit -m "Initial commit Phase 1 baseline" >> "%LOG%" 2>&1

echo === [6] git push -u origin main === >> "%LOG%" 2>&1
git push -u origin main >> "%LOG%" 2>&1
if errorlevel 1 (
  echo PUSH_FAILED >> "%LOG%" 2>&1
  echo PUSH_FAILED > "%~dp0init_repo_DONE.flag"
  exit /b 1
)

echo. >> "%LOG%" 2>&1
echo === END %DATE% %TIME% === >> "%LOG%" 2>&1
echo SUCCESS > "%~dp0init_repo_DONE.flag"
exit /b 0
