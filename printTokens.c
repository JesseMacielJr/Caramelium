#include "lex.yy.c"

const char *token_name(int t);

int main(int argc, char *argv[]) {

  int i = 0;
  while (1) {
    int token = yylex();
    if (token == 0)
      break;

    printf("%-16s %s", token_name(token), yytext);
    printf("\n");
  }

  return 0;
}
