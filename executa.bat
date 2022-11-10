bison -d parser.y
flex lexer.l 
g++ parser.tab.c printTokens.c -o caramelium.exe
caramelium.exe < fibonacci.dog
