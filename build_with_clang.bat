@echo off

clang -c m3d.c -std=c99 -o m3d.obj -O2
llvm-lib m3d.obj
del m3d.obj
move m3d.lib m3d_windows_amd64.lib