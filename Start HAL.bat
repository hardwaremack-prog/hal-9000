@echo off
title HAL 9000
cd /d "%~dp0"
where node >nul 2>nul || (echo Node.js is needed to run HAL - it is the same one The Shelf uses. & pause & exit /b)
node hal-server.js
pause
