@echo off
title HAL 9000 - brain download
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0engine\get-brain.ps1"
