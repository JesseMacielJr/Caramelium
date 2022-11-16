@echo off
bison -d parser.y --debug
flex lexer.l 
gcc parser.tab.c -o compilador.exe
if not exist "build" mkdir build
compilador.exe %*
