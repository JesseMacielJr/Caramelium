#include "lex.yy.c"

const char *token_name(int token) {
  switch (token) {
  case INICIO_BLOCO:
    return "INICIO_BLOCO";
  case FIM_BLOCO:
    return "FIM_BLOCO";
  case DECLARACAO:
    return "DECLARACAO";
  case ATRIBUICAO:
    return "ATRIBUICAO";
  case INTERROGACAO:
    return "INTERROGACAO";
  case DOIS_PONTOS:
    return "DOIS_PONTOS";
  case VIRGULA:
    return "VIRGULA";
  case IDENTIFICADOR:
    return "IDENTIFICADOR";
  case INTEIRO:
    return "INTEIRO";
  case FLOAT:
    return "FLOAT";
  case STRING:
    return "STRING";
  case NOME_BLOCO:
    return "NOME_BLOCO";
  case RETURN:
    return "RETURN";
  case CONTINUE:
    return "CONTINUE";
  case SETA_DUPLA:
    return "SETA_DUPLA";
  case SOMA:
    return "SOMA";
  case SUB:
    return "SUB";
  case MULT:
    return "MULT";
  case DIV:
    return "DIV";
  case MOD:
    return "MOD";
  case SOMA_ATRIBUICAO:
    return "SOMA_ATRIBUICAO";
  case SUB_ATRIBUICAO:
    return "SUB_ATRIBUICAO";
  case MULT_ATRIBUICAO:
    return "MULT_ATRIBUICAO";
  case DIV_ATRIBUICAO:
    return "DIV_ATRIBUICAO";
  case MOD_ATRIBUICAO:
    return "MOD_ATRIBUICAO";
  case AND:
    return "AND";
  case OR:
    return "OR";
  case NOT:
    return "NOT";
  case IGUAL:
    return "IGUAL";
  case NOT_IGUAL:
    return "NOT_IGUAL";
  case MENOR:
    return "MENOR";
  case MAIOR:
    return "MAIOR";
  case MENOR_IGUAL:
    return "MENOR_IGUAL";
  case MAIOR_IGUAL:
    return "MAIOR_IGUAL";
  case PONTOEVIRGULA:
    return "PONTOEVIRGULA";
  case ABRE_PARENTESES:
    return "ABRE_PARENTESES";
  case FECHA_PARENTESES:
    return "FECHA_PARENTESES";
  default:
    return "ERRO";
  }
}

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
