Instale Bison e Flex no pc (sudo apt install Flex Bison)

Execute os comandos a seguir (ou execute o shell script incluído na pasta):

bison -d parser.y
flex lexer.l 
g++ parser.tab.c lex.yy.c -o compilaCBr
echo "----------"
./compilaCBr teste.cbr
g++ teste.cbr.cc -o saida_teste
./saida_teste
echo "----------"
./compilaCBr teste2.cbr
g++ teste2.cbr.cc -o saida_teste2
./saida_teste2
echo "----------"
./compilaCBr teste3.cbr
g++ teste3.cbr.cc -o saida_teste3
./saida_teste3
echo "----------"



