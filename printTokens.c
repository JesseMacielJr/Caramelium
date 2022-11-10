#include "lex.yy.c"

int main(int argc, char *argv[])
{

  while (yylex())
  {
    printf("Rodrigo\n");
  }

  return 0;
}