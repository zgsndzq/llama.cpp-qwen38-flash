@echo off
rem ===========================================================================
rem  Drop a stale CMake cache after this tree has been moved or renamed.
rem
rem  cmake bakes absolute paths into build\src\CMakeCache.txt:
rem    CMAKE_HOME_DIRECTORY  - where the sources live
rem    CMAKE_CUDA_COMPILER   - the nvcc.exe it configured against
rem    CMAKE_MAKE_PROGRAM    - the ninja.exe it configured against
rem  Once any of them is no longer valid, cmake refuses to reuse the cache and
rem  every build script dies at configure time. This checks all three and, when
rem  something is off, removes the cache plus the generated ninja files.
rem  build\src\bin holds the compiled binaries and is never touched.
rem ===========================================================================
setlocal

set "SRC=%~dp0"
set "SRC=%SRC:~0,-1%"
set "BD=%SRC%\..\build\src"

if not exist "%BD%\CMakeCache.txt" exit /b 0

set "STALE=0"
set "WHY="

rem ---------------------------------------------------------- 1. tree moved?
set "HAVE="
for /f "tokens=2 delims==" %%A in ('findstr /b /c:"CMAKE_HOME_DIRECTORY:INTERNAL=" "%BD%\CMakeCache.txt" 2^>nul') do set "HAVE=%%A"
if not defined HAVE goto checktools
set "WANTS=%SRC:\=/%"
set "HAVES=%HAVE:\=/%"
if /i "%HAVES%"=="%WANTS%" goto checktools
set "STALE=1"
set "WHY=tree moved: %HAVES% -^> %WANTS%"

:checktools
rem ------------------------------------------------- 2. tools still in place?
for /f "tokens=2 delims==" %%A in ('findstr /b /c:"CMAKE_CUDA_COMPILER:" /c:"CMAKE_MAKE_PROGRAM:" "%BD%\CMakeCache.txt" 2^>nul') do call :probe "%%A"

:decide
if "%STALE%"=="0" exit /b 0
echo [cache] %WHY%
echo [cache] dropping build\src\CMakeCache.txt - binaries in build\src\bin are kept
del /q "%BD%\CMakeCache.txt" >nul 2>nul
del /q "%BD%\build.ninja" "%BD%\rules.ninja" "%BD%\.ninja_deps" "%BD%\.ninja_log" "%BD%\cmake_install.cmake" >nul 2>nul
if exist "%BD%\CMakeFiles" rd /s /q "%BD%\CMakeFiles" >nul 2>nul
exit /b 0

:probe
set "P=%~1"
set "PN=%P:/=\%"
rem only absolute paths are meaningful here
echo "%PN%" | findstr /c:":" >nul || goto :eof
if exist "%PN%" goto :eof
set "STALE=1"
set "WHY=missing tool: %PN%"
goto :eof
