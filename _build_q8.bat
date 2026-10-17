@echo off
rem Configure build-q8 and build llama-server + llama-bench + test-backend-ops.
rem Explicit SIMD flags are mandatory: MSVC + GGML_NATIVE=OFF silently leaves AVX2/BMI2/FMA off.
rem FA kernel coverage is pinned below instead of inheriting the upstream default list.
rem Machine-specific paths come from build.local.bat.
setlocal
cd /d "%~dp0"
set "LOGDIR=%~dp0..\build\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>nul
set "LOG=%LOGDIR%\_build_q8.log"
if not exist "%~dp0build.local.bat" (
  echo MISSING build.local.bat - copy build.local.example.bat and edit the paths > "%LOG%"
  echo DONE >> "%LOG%"
  exit /b 9
)
call "%~dp0build.local.bat"
if defined VCVARS call "%VCVARS%"
if errorlevel 1 ( echo VCVARS_FAILED > "%LOG%" & exit /b 1 )
call "%~dp0_cache_guard.bat"

echo CFG_START %DATE% %TIME% > "%LOG%"
rem If the runtime cannot find a compiled FA vector kernel for our K/V types it silently
rem converts K and V to f16 (the "(slow)" path in fattn.cu) - that changes both speed and
rem numerics. "all" removes that failure mode; the binary grows, nothing else changes.
rem Set to "q4_0-q4_0;q8_0-q8_0;f16-f16" to shrink it again.
set "FAQUANTS=all"
"%CMAKE%" -B ..\build\src -S . -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_CUDA_ARCHITECTURES=%CUDA_ARCH% ^
  -DCMAKE_CUDA_COMPILER=%NVCC% ^
  -DGGML_CUDA=ON -DGGML_CUDA_FA=ON -DGGML_NATIVE=OFF ^
  -DGGML_CUDA_FA_QUANTS=%FAQUANTS% ^
  -DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_BMI2=ON -DGGML_FMA=ON -DGGML_F16C=ON ^
  -DLLAMA_CURL=OFF -DGGML_CCACHE=OFF >> "%LOG%" 2>&1
echo CFG_EXIT=%ERRORLEVEL% >> "%LOG%"
if not exist ..\build\src\build.ninja ( echo NO_NINJA >> "%LOG%" & echo DONE >> "%LOG%" & exit /b 2 )
echo BUILD_START %DATE% %TIME% >> "%LOG%"
rem llama-quantize is included on purpose: it is how the PTQ1_0 conversion is driven, so a
rem user who wants to reproduce the quantisation should not need a second build.
"%NINJA%" -C ..\build\src -j %JOBS% llama-server llama-bench llama-quantize test-backend-ops >> "%LOG%" 2>&1
echo BUILD_EXIT=%ERRORLEVEL% %DATE% %TIME% >> "%LOG%"
if exist ..\build\src\bin\llama-server.exe (echo SERVER_OK >> "%LOG%") else (echo SERVER_MISSING >> "%LOG%")
echo DONE >> "%LOG%"
endlocal
