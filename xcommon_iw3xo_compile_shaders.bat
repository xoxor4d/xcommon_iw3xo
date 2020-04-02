@echo off
echo.
echo --------------- Copy shader files to raw ---------------------
xcopy src\raw\shader_bin ..\..\raw\shader_bin /SYI > NUL
echo.
xcopy src\raw\statemap ..\..\raw\statemap /SYI > NUL
echo.
xcopy src\raw\techniques ..\..\raw\techniques /SYI > NUL
echo.
xcopy src\raw\techsets ..\..\raw\techsets /SYI > NUL
echo.

@echo off
echo.
echo --------------- Compiling shaders --------------------
cd ..\..\raw\shader_bin
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
PAUSE