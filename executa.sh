#!/bin/bash
set -e
bison -d parser.y -Dparse.trace
flex lexer.l 
gcc parser.tab.c -o compilador
mkdir build -p
./compilador ${*:2}
