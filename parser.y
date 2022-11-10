%{
	#include <stdio.h>
	#include <math.h> 
	#include <stdlib.h>
	#include <string.h>
	#include <cstdio>
	#include <iostream>
	#include "no.h"

	using namespace std;
	#define YYERROR_VERBOSE
	extern "C" int yylex();
	extern "C" int yyparse();
	extern "C" FILE *yyin;
	void yyerror(const char *s);


%}

%union{
	No *pnt;
}

%token INICIO_BLOCO
%token FIM_BLOCO
%token DECLARACAO
%token ATRIBUICAO
%token INTERROGACAO
%token DOIS_PONTOS
%token VIRGULA
%token IDENTIFICADOR
%token INTEIRO
%token FLOAT
%token STRING
%token NOME_BLOCO
%token RETURN
%token CONTINUE
%token SETA_DUPLA
%token SOMA
%token SUB
%token MULT
%token DIV
%token MOD
%token SOMA_ATRIBUICAO
%token SUB_ATRIBUICAO
%token MULT_ATRIBUICAO
%token DIV_ATRIBUICAO
%token MOD_ATRIBUICAO
%token AND
%token OR
%token NOT
%token IGUAL
%token NOT_IGUAL
%token MENOR
%token MAIOR
%token MENOR_IGUAL
%token MAIOR_IGUAL
%token PONTOEVIRGULA
%token ABRE_PARENTESES
%token FECHA_PARENTESES

%%

programa
    : expr PONTOEVIRGULA
    | expr PONTOEVIRGULA programa


expr: literal
    | IDENTIFICADOR
    | ABRE_PARENTESES expr FECHA_PARENTESES
    | opAritmetica
    | opLogica
    | opRelacional
    | chamadaFuncao
    | funcao
    | declaracao
    | opAtribuicao
    | condicao
    | bloco
    | return
    | continue

literal: INTEIRO | FLOAT | STRING

opAritmetica
    : SUB expr
    | expr SOMA expr
    | expr SUB expr
    | expr MULT expr
    | expr DIV expr
    | expr MOD expr

opLogica
    : NOT expr
    | expr AND expr
    | expr OR expr

opRelacional
    : expr IGUAL expr
    | expr NOT_IGUAL expr
    | expr MENOR expr
    | expr MAIOR expr
    | expr MENOR_IGUAL expr
    | expr MAIOR_IGUAL expr

chamadaFuncao: IDENTIFICADOR ABRE_PARENTESES exprsVirgula FECHA_PARENTESES

exprsVirgula
    : expr
    | expr VIRGULA
    | expr VIRGULA exprsVirgula

funcao: ABRE_PARENTESES identificadoresVirgula FECHA_PARENTESES SETA_DUPLA expr

identificadoresVirgula
    : IDENTIFICADOR
    | IDENTIFICADOR VIRGULA
    | IDENTIFICADOR VIRGULA identificadoresVirgula

declaracao: IDENTIFICADOR DECLARACAO expr

opAtribuicao
    : IDENTIFICADOR ATRIBUICAO expr
    | IDENTIFICADOR SOMA_ATRIBUICAO expr
    | IDENTIFICADOR SUB_ATRIBUICAO expr
    | IDENTIFICADOR MULT_ATRIBUICAO expr
    | IDENTIFICADOR DIV_ATRIBUICAO expr
    | IDENTIFICADOR MOD_ATRIBUICAO expr

condicao
    : expr INTERROGACAO expr
    | expr INTERROGACAO expr DOIS_PONTOS expr

bloco
    : INICIO_BLOCO exprsBloco FIM_BLOCO
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO exprsBloco FIM_BLOCO

exprsBloco
    : expr
    | expr PONTOEVIRGULA
    | expr PONTOEVIRGULA exprsBloco

return
    : RETURN
    | RETURN expr
    | RETURN NOME_BLOCO
    | RETURN NOME_BLOCO expr

continue: CONTINUE NOME_BLOCO

%%

const char* token_name(int t) {
    return yytname[YYTRANSLATE(t)];
}

void yyerror(const char *s) {
  printf("%s\n", s);
}
