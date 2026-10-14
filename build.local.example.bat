@echo off
rem Machine-specific paths for building this tree. NOT tracked by git.
rem Copy build.local.example.bat -> build.local.bat and edit for your machine.
rem Every build script reads these; none of them hardcodes a path itself.
rem --- Visual Studio environment (vcvars64.bat or a wrapper around it) ---
set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

rem --- toolchain ---
set "CMAKE=cmake.exe"
set "NINJA=ninja.exe"
set "NVCC=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.6/bin/nvcc.exe"
set "CUDA_ARCH=89"

rem --- parallelism: 4 keeps nvcc peak memory sane on a laptop GPU ---
set "JOBS=4"
