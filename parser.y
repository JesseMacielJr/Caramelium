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

%token <pnt> INICIO_BLOCO
%token <pnt> FIM_BLOCO
%token <pnt> DECLARACAO
%token <pnt> ATRIBUICAO
%token <pnt> INTERROGACAO
%token <pnt> DOIS_PONTOS
%token <pnt> VIRGULA
%token <pnt> IDENTIFICADOR
%token <pnt> INTEIRO
%token <pnt> FLOAT
%token <pnt> STRING
%token <pnt> NOME_BLOCO
%token <pnt> RETURN
%token <pnt> CONTINUE
%token <pnt> SETA_DUPLA
%token <pnt> SOMA
%token <pnt> SUB
%token <pnt> MULT
%token <pnt> DIV
%token <pnt> MOD
%token <pnt> SOMA_ATRIBUICAO
%token <pnt> SUB_ATRIBUICAO
%token <pnt> MULT_ATRIBUICAO
%token <pnt> DIV_ATRIBUICAO
%token <pnt> MOD_ATRIBUICAO
%token <pnt> AND
%token <pnt> OR
%token <pnt> NOT
%token <pnt> IGUAL
%token <pnt> NOT_IGUAL
%token <pnt> MENOR
%token <pnt> MAIOR
%token <pnt> MENOR_IGUAL
%token <pnt> MAIOR_IGUAL
%token <pnt> PONTOEVIRGULA
%token <pnt> ABRE_PARENTESES
%token <pnt> FECHA_PARENTESES
%type <pnt> programa

%%

programa: IGUAL {}
/*
programa: (expr PONTOEVIRGULA)* {
    raiz = $2
}

expr: literal
    | IDENTIFICADOR
    | ABRE_PARENTESES expr FECHA_PARENTESES
    | opAritmetrica
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

opAritmetica: SUB expr
    | expr SOMA expr
    | expr SUB expr
    | expr MULT expr
    | expr DIV expr
    | expr MOD expr
opLogica: NOT expr
    | expr AND expr
    | expr OR expr
opRelacional: expr IGUAL expr
    | expr NOT_IGUAL expr
    | expr MENOR expr
    | expr MAIOR expr
    | expr MENOR_IGUAL expr
    | expr MAIOR_IGUAL expr

chamadaFuncao: IDENTIFICADOR ABRE_PARENTESES (expr VIRGULA)* (expr)? FECHA_PARENTES

funcao: ABRE_PARENTESES (IDENTIFICADOR VIRGULA)* (IDENTIFICADOR)? FECHA_PARENTES SETA_DUPLA expr

declaracao: IDENTIFICADOR DECLARACAO expr

opAtribuicao: IDENTIFICADOR ATRIBUICAO expr
    | IDENTIFICADOR SOMA_ATRIBUICAO expr
    | IDENTIFICADOR SUB_ATRIBUICAO expr
    | IDENTIFICADOR MULT_ATRIBUICAO expr
    | IDENTIFICADOR DIV_ATRIBUICAO expr
    | IDENTIFICADOR MOD_ATRIBUICAO expr

condicao: expr INTERROGACAO expr (DOIS_PONTOS expr)?

bloco: (NOME_BLOCO DOIS_PONTOS)? INICIO_BLOCO (expr PONTOEVIRGULA)* (expr)? FIM_BLOCO

return: RETURN (NOME_BLOCO)? (expr)?

continue: CONTINUE NOME_BLOCO
*/

%%

const char* token_name(int t) {
    return yytname[YYTRANSLATE(t)];
}

void yyerror(const char *s) {
  printf("%s\n", s);
}
