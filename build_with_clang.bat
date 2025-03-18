@echo off

clang-cl /c /O2 m3d.c
llvm-lib /OUT:m3d_windows_amd64_release.lib m3d.obj
del m3d.obj

clang-cl /c /Zi /Fd:m3d_windows_amd64_debug.pdb m3d.c
llvm-lib /OUT:m3d_windows_amd64_debug.lib m3d.obj
del m3d.obj

