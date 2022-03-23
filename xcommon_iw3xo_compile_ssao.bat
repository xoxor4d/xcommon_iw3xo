@echo off
set COMPILEDIR=%CD%
echo.
echo --------------- Copy shader files to raw ---------------------
xcopy src\raw\shader_bin ..\..\raw\shader_bin /SYI
echo.
xcopy src\raw\statemaps ..\..\raw\statemaps /SYI
echo.
xcopy src\raw\techniques ..\..\raw\techniques /SYI
echo.
xcopy src\raw\techsets ..\..\raw\techsets /SYI
echo.

@echo off
echo.
echo --------------- Compiling shaders --------------------
cd ..\..\raw\shader_bin
shader_tool postfx_ssao

@echo off
echo.
echo --------------------- Done ----------------------------
cd %COMPILEDIR%
PAUSE