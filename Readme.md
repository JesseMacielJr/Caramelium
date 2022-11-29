# Requisitos

É necessário possuir os seguintes programas instalados:

- Bison 2.4.1 ou superior
- Flex 2.5.1 ou superior
- GCC (testado na versão 9.2)

Instale Bison e Flex no PC.

# Execução

Execute os comandos a seguir:

```shell
bison -d parser.y --debug
flex lexer.l
gcc parser.tab.c -o compilador

# CMD:
compilador programas/fibonacci.dog --run

# PowerShell:
.\compilador programas/fibonacci.dog --run

# Linux:
./compilador programas/fibonacci.dog --run

```

Ou use o arquivo `executa.bat` (ou `executa.sh`, no Linux):

```
executa.bat programas/fibonacci.dog --run
```

## Argumentos de linha de comando:

```
Uso: compilador [OPÇÕES] ARQUIVO

ARQUIVO         O arquivo fonte.
-o ARQUIVO      Escreve o código transpilado para C em ARQUIVO.
--build         Transpila e compila programa. Saída fica em 'build\out.exe'.
--run           Transpila, compila e roda o programa.
--tokens        Imprime os tokens do código fonte na tela
```
