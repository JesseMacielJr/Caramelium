@echo off
bison -d parser.y --debug
flex lexer.l 
gcc parser.tab.c -o compilador.exe
if not exist "build" mkdir build
compilador.exe < %1 > build/out.c
gcc build/out.c -o %1.exe
