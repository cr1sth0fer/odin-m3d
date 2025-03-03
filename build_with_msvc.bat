@echo off

cl /Wall /Fo /O2 m3d.obj m3d.c /std:c11
rem llvm-lib m3d.obj
rem del m3d.obj
rem move m3d.lib m3d_windows_amd64.lib
