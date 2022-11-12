#!/bin/bash
set -e
bison -d parser.y -Dparse.trace
flex lexer.l 
gcc compilador.c -o compilador
mkdir build -p
./compilador < $1 | tee build/out.c
gcc build/out.c -o build/out
