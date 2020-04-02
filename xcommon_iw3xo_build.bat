@echo -------------- Setup directory paths ------------------
set COMPILEDIR=%CD%

@echo.
@echo -------------- Deleting old fastfile ------------------
del xcommon_iw3xo.ff

@echo off
echo.
echo --------------- Copy files to raw ---------------------
xcopy shock ..\..\raw\shock /SY
echo.
xcopy images ..\..\raw\images /SY
echo.
xcopy materials ..\..\raw\materials /SY
echo.
xcopy material_properties ..\..\raw\material_properties /SY
echo.
xcopy sound ..\..\raw\sound /SY
echo.
xcopy soundaliases ..\..\raw\soundaliases /SY
echo.
xcopy fx ..\..\raw\fx /SY
echo.
xcopy mp ..\..\raw\mp /SY
echo.
xcopy weapons\mp ..\..\raw\weapons\mp /SY
echo.
xcopy xanim ..\..\raw\xanim /SY
echo.
xcopy xmodel ..\..\raw\xmodel /SY
echo.
xcopy xmodelparts ..\..\raw\xmodelparts /SY
echo.
xcopy xmodelsurfs ..\..\raw\xmodelsurfs /SY
echo.
xcopy ui ..\..\raw\ui /SY
echo.
xcopy ui_mp ..\..\raw\ui_mp /SY
echo.
xcopy english ..\..\raw\english /SY
echo.
xcopy vision ..\..\raw\vision /SY
echo.
xcopy animtrees ..\..\raw\animtrees /SYI > NUL
echo.
xcopy maps ..\..\raw\maps /SY
echo.
xcopy codescripts ..\..\raw\codescripts /SY
echo.
xcopy xcommon_iw3xo.csv ..\..\zone_source /SY

@echo off
echo.
echo --------------- Building fastfiles --------------------
cd ..\..\bin
linker_pc.exe -language english -compress -cleanup xcommon_iw3xo

cd %COMPILEDIR%

@echo off
echo.
echo ----------------- Copy fastfiles ----------------------
copy ..\..\zone\english\xcommon_iw3xo.ff

@echo off
echo.
echo --------------------- Done ----------------------------
PAUSE