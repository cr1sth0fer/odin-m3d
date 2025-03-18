@echo off

cl m3d.c -std=c99 -o assertions.exe /DASSERTIONS
assertions.exe
del assertions.exe
del m3d.obj
