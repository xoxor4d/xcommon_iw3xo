@echo off
echo.
echo --------------- Installing shader_tool ---------------------
xcopy shader_tool\shader_bin ..\..\raw\shader_bin /SYI
if not exist "..\..\raw\shader_bin\backups" mkdir ..\..\raw\shader_bin\backups
echo.
echo --------------------- Done ----------------------------
PAUSE