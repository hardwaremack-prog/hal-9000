@echo off
title HAL 9000
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0engine\hal-server.ps1"
