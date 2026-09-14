@if "%_echo%" == "" (@echo off)
verify other 2>nul 
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 (echo Unable to enable extensions) & (exit /b 1)
set script.path=%~dp0\
set script.path=%script.path:\\=\%
set script.path=%script.path:~0,-1%
set script.name=%~n0
pushd %script.path%
if exist  %userprofile%\WindowsApps\AHK2\AutoHotkey64.exe (
  TASKKILL /IM master.exe /F > nul 2>&1 && ping -n 2 127.0.0.1 > nul 2>&1
  start %userprofile%\WindowsApps\AHK2\AutoHotkey64.exe master.ahk %*
) else (
  TASKKILL /IM master.exe /F > nul 2>&1 && ping -n 2 127.0.0.1 > nul 2>&1
  start D:\Games\bin\AHK2\AutoHotkey64.exe master.ahk %*
)
popd
