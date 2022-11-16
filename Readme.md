# Requisitos


É necessário possuir os seguintes programas instalados:

- Bison 2.4.1 ou superior
- Flex 2.5.1 ou superior
- GCC (testado na versão 9.2)

Instale Bison e Flex no PC.

# Execução

Execute os comandos a seguir:

```
bison -d parser.y --debug
flex lexer.l 
gcc parser.tab.c -o compilador

compilador fibonacci.dog --run
```

Ou use o arquivo `executa.bat`:

```
executa.bat fibonacci.dog --run
```

## Argumentos de linha de comando:

```
Uso: compilador [OPÇÕES] ARQUIVO

ARQUIVO         O arquivo fonte.
-o ARQUIVO      Escreve o código transpilado para C em ARQUIVO.
--run           Transpila, compila e roda o programa.
```
