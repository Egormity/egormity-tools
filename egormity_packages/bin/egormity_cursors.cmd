@echo off
setlocal

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\egormity_cursors\cli.ps1" %*
