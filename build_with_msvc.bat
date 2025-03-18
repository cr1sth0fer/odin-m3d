@echo off

cl /c /O2 m3d.c
lib /OUT:m3d_windows_amd64_release.lib m3d.obj
del m3d.obj

cl /c /Zi /Fd:m3d_windows_amd64_debug.pdb m3d.c
lib /OUT:m3d_windows_amd64_debug.lib m3d.obj
del m3d.obj

