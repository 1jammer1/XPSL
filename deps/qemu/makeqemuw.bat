@echo off
echo.Making consoleless variant:
for %%F in ("%~dp0qemu-system-*.exe") do echo %%~nFw.exe && copy "%%~dpnxF" "%%~dpnFw.exe">nul 2>&1 && "%~dp0pehdr.exe" "%%~dpnFw.exe" +win >nul
pause