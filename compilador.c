#include "lex.yy.c"
#include "parser.tab.c"

int main(int argc, char *argv[]) {
    yydebug = 0;
    yyparse();
}
