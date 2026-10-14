@echo off
rem Reconfigure + rebuild llama-server after merging origin/prism (CUDA .cu and CMake changed).
rem Same flags as _build_q8.bat apart from the FA pin. Machine paths from build.local.bat.
setlocal
cd /d "%~dp0"
set "LOGDIR=%~dp0..\build\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>nul
set "LOG=%LOGDIR%\_build_merge.log"
if not exist "%~dp0build.local.bat" (
  echo MISSING build.local.bat - copy build.local.example.bat and edit the paths > "%LOG%"
  echo DONE >> "%LOG%"
  exit /b 9
)
call "%~dp0build.local.bat"
call "%VCVARS%"
if errorlevel 1 ( echo VCVARS_FAILED > "%LOG%" & exit /b 1 )

echo CFG_START %DATE% %TIME% > "%LOG%"
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
