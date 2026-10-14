@echo off
rem Clean full rebuild. Wipes build-q8 first so no stale object can survive.
rem Explicit SIMD flags are mandatory under MSVC with GGML_NATIVE=OFF.
rem Machine-specific paths come from build.local.bat.
setlocal
cd /d "%~dp0"
set "LOGDIR=%~dp0..\build\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>nul
set "LOG=%LOGDIR%\_build_clean.log"
if not exist "%~dp0build.local.bat" (
  echo MISSING build.local.bat - copy build.local.example.bat and edit the paths > "%LOG%"
  echo DONE >> "%LOG%"
  exit /b 9
)
call "%~dp0build.local.bat"
call "%VCVARS%"
if errorlevel 1 ( echo VCVARS_FAILED > "%LOG%" & exit /b 1 )

echo WIPE_START %DATE% %TIME% > "%LOG%"
if exist ..\build\src rmdir /s /q ..\build\src
if exist ..\build\src ( echo RMDIR_FAILED >> "%LOG%" & echo DONE >> "%LOG%" & exit /b 3 )
echo WIPE_OK >> "%LOG%"
"%CMAKE%" -B ..\build\src -S . -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_CUDA_ARCHITECTURES=%CUDA_ARCH% ^
  -DCMAKE_CUDA_COMPILER=%NVCC% ^
  -DGGML_CUDA=ON -DGGML_CUDA_FA=ON -DGGML_NATIVE=OFF ^
  -DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_BMI2=ON -DGGML_FMA=ON -DGGML_F16C=ON ^
  -DLLAMA_CURL=OFF -DGGML_CCACHE=OFF >> "%LOG%" 2>&1
echo CFG_EXIT=%ERRORLEVEL% >> "%LOG%"
if not exist ..\build\src\build.ninja ( echo NO_NINJA >> "%LOG%" & echo DONE >> "%LOG%" & exit /b 2 )
echo BUILD_START %DATE% %TIME% >> "%LOG%"
"%NINJA%" -C ..\build\src -j %JOBS% llama-server >> "%LOG%" 2>&1
echo BUILD_EXIT=%ERRORLEVEL% %DATE% %TIME% >> "%LOG%"
if exist ..\build\src\bin\llama-server.exe (echo SERVER_OK >> "%LOG%") else (echo SERVER_MISSING >> "%LOG%")
echo DONE >> "%LOG%"
endlocal
