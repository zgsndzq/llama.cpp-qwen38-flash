@echo off
rem Incremental rebuild of llama-server only, into its own log.
rem Machine-specific paths come from build.local.bat.
setlocal
cd /d "%~dp0"
set "LOGDIR=%~dp0..\build\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>nul
set "LOG=%LOGDIR%\_build_srv.log"
if not exist "%~dp0build.local.bat" (
  echo MISSING build.local.bat - copy build.local.example.bat and edit the paths > "%LOG%"
  echo DONE >> "%LOG%"
  exit /b 9
)
call "%~dp0build.local.bat"
call "%VCVARS%"
if errorlevel 1 ( echo VCVARS_FAILED > "%LOG%" & exit /b 1 )

echo BUILD_START %DATE% %TIME% > "%LOG%"
"%NINJA%" -C ..\build\src -j %JOBS% llama-server >> "%LOG%" 2>&1
echo BUILD_EXIT=%ERRORLEVEL% >> "%LOG%"
if exist ..\build\src\bin\llama-server.exe (echo SERVER_OK >> "%LOG%")
echo DONE >> "%LOG%"
endlocal
