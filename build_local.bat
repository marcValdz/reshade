@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ==========================================
echo  Build ReShade Local
echo ==========================================

echo.
echo [1/4] Removing files known to cause stale/incorrect builds...
if exist "res\version.h" (
    del /f /q "res\version.h"
    echo   Deleted res\version.h ^(regenerated from git tag on next build^)
)
if exist "bin" (
    rd /s /q "bin"
    echo   Deleted bin\
)

echo.
echo [2/4] Locating MSBuild...
set "MSBUILD="
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do (
    set "MSBUILD=%%i"
)
if not defined MSBUILD (
    where msbuild >nul 2>nul
    if !errorlevel! equ 0 (
        set "MSBUILD=msbuild"
    ) else (
        echo   ERROR: Could not find MSBuild. Install Visual Studio / Build Tools with the C++ workload.
        goto :fail
    )
)
echo   Using: !MSBUILD!

echo.
echo [3/4] Updating git submodules...
git submodule update --init --recursive
if !errorlevel! neq 0 (
    echo   ERROR: submodule update failed.
    goto :fail
)

echo.
echo [4/4] Building ReShade ^(32-bit, 64-bit, Setup^)...
"!MSBUILD!" ReShade.sln /p:Configuration=Release /p:Platform=32-bit
if !errorlevel! neq 0 goto :fail

"!MSBUILD!" ReShade.sln /p:Configuration=Release /p:Platform=64-bit
if !errorlevel! neq 0 goto :fail

"!MSBUILD!" ReShade.sln /p:Configuration="Release Setup"
if !errorlevel! neq 0 goto :fail

echo.
echo ==========================================
echo  Build succeeded.
echo  32-bit: bin\Win32\Release\ReShade32.dll
echo  64-bit: bin\x64\Release\ReShade64.dll
echo  Setup:  bin\AnyCPU\Release\ReShade Setup.exe
echo ==========================================
pause
exit /b 0

:fail
echo.
echo ==========================================
echo  Build FAILED. See errors above.
echo ==========================================
pause
exit /b 1
