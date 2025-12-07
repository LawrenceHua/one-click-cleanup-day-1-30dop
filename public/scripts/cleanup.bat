@echo off
echo Starting One-Click Cleanup for Windows...

echo Cleaning User Temp Files...
del /q/f/s %TEMP%\*
rd /s /q %TEMP%

echo Cleaning System Temp Files (Requires Admin)...
del /q/f/s C:\Windows\Temp\*
rd /s /q C:\Windows\Temp

echo Flushing DNS Cache...
ipconfig /flushdns

echo.
echo Cleanup Complete!
pause

