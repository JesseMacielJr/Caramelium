Instale Bison e Flex no pc.

Execute os comandos a seguir:

```
bison -d parser.y --debug
flex lexer.l 
gcc parser.tab.c -o compilador

compilador.exe < fibonacci.dog > fibonacci.c
gcc fibonacci.c -o fibonacci.dog.exe
```

Ou use o arquivo executa.bat:

```
executa.bat fibonacci.dog
```
