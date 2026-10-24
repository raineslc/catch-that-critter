@echo off
rem Starts Catch That Critter in playtest mode from the folder this script lives in (its parent).
rem Godot's own output/error log is saved next to the playtest answer logs, one file per session:
rem   %APPDATA%\Godot\app_userdata\Catch That Critter\playtest\godot_<date>_<time>.log
setlocal
set "PROJECT=%~dp0.."
set "PLAYTEST_FLAG=--playtest"
if "%~1"=="--playtest-full" set "PLAYTEST_FLAG=--playtest-full"
set "GODOT="
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*") do (
  if exist "%%D\Godot_v4.7.2-stable_win64.exe" set "GODOT=%%D\Godot_v4.7.2-stable_win64.exe"
)
if not defined GODOT (
  echo Could not find Godot 4.7.2. Install it with: winget install GodotEngine.GodotEngine
  pause
  exit /b 1
)
set "LOGDIR=%APPDATA%\Godot\app_userdata\Catch That Critter\playtest"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "STAMP=%%i"
start "" "%GODOT%" --path "%PROJECT%" --maximized --verbose --log-file "%LOGDIR%\godot_%STAMP%.log" -- %PLAYTEST_FLAG%
