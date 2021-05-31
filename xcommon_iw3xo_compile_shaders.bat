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
shader_tool debug_texcoords
shader_tool debug_texcoords_dtex
shader_tool iw3xo_showcollision_fakelight
shader_tool iw3xo_showcollision_wire
shader_tool postfx_cellshading
shader_tool postfx_clear_white
shader_tool postfx_outliner
shader_tool postfx_ssao
shader_tool postfx_ssao_apply
shader_tool postfx_ssao_blur
shader_tool postfx_ssao_depth
shader_tool postfx_ssao_normal

@echo off
echo.
echo --------------------- Done ----------------------------
cd %COMPILEDIR%
PAUSE