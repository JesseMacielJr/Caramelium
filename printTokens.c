#include "lex.yy.c"

int main(int argc, char *argv[]) {

  int i = 0;
  while (1) {
    int x = yylex();
    if (x == 0)
      break;

    switch (x) {
    case INICIO_BLOCO:
      printf("INICIO_BLOCO");
      break;
    case FIM_BLOCO:
      printf("FIM_BLOCO");
      break;
    case DECLARACAO:
      printf("DECLARACAO");
      break;
    case ATRIBUICAO:
      printf("ATRIBUICAO");
      break;
    case INTERROGACAO:
      printf("INTERROGACAO");
      break;
    case DOIS_PONTOS:
      printf("DOIS_PONTOS");
      break;
    case VIRGULA:
      printf("VIRGULA");
      break;
    case IDENTIFICADOR:
      printf("IDENTIFICADOR");
      break;
    case INTEIRO:
      printf("INTEIRO");
      break;
    case FLOAT:
      printf("FLOAT");
      break;
    case STRING:
      printf("STRING");
      break;
    case NOME_BLOCO:
      printf("NOME_BLOCO");
      break;
    case RETURN:
      printf("RETURN");
      break;
    case CONTINUE:
      printf("CONTINUE");
      break;
    case SETA_DUPLA:
      printf("SETA_DUPLA");
      break;
    case SOMA:
      printf("SOMA");
      break;
    case SUB:
      printf("SUB");
      break;
    case MULT:
      printf("MULT");
      break;
    case DIV:
      printf("DIV");
      break;
    case MOD:
      printf("MOD");
      break;
    case SOMA_ATRIBUICAO:
      printf("SOMA_ATRIBUICAO");
      break;
    case SUB_ATRIBUICAO:
      printf("SUB_ATRIBUICAO");
      break;
    case MULT_ATRIBUICAO:
      printf("MULT_ATRIBUICAO");
      break;
    case DIV_ATRIBUICAO:
      printf("DIV_ATRIBUICAO");
      break;
    case MOD_ATRIBUICAO:
      printf("MOD_ATRIBUICAO");
      break;
    case AND:
      printf("AND");
      break;
    case OR:
      printf("OR");
      break;
    case NOT:
      printf("NOT");
      break;
    case IGUAL:
      printf("IGUAL");
      break;
    case NOT_IGUAL:
      printf("NOT_IGUAL");
      break;
    case MENOR:
      printf("MENOR");
      break;
    case MAIOR:
      printf("MAIOR");
      break;
    case MENOR_IGUAL:
      printf("MENOR_IGUAL");
      break;
    case MAIOR_IGUAL:
      printf("MAIOR_IGUAL");
      break;
    case PONTOEVIRGULA:
      printf("PONTOEVIRGULA");
      break;
    case ABRE_PARENTESES:
      printf("ABRE_PARENTESES");
      break;
    case FECHA_PARENTESES:
      printf("FECHA_PARENTESES");
      break;
    default:
      printf("ERRO");
      break;
    }
    printf("\n");
  }

  return 0;
}
