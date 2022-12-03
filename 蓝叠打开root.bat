@echo off
powershell -executionpolicy remotesigned -File "%~dp0%~n0.ps1"
pause