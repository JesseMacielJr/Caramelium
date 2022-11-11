%{
	#include <stdio.h>
	#define YYERROR_VERBOSE
	int yylex();
	int yyparse();
	void yyerror(const char *s);
%}

%union{}

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

%right RETURN CONTINUE NOME_BLOCO
%right DECLARACAO ATRIBUICAO SOMA_ATRIBUICAO SUB_ATRIBUICAO MULT_ATRIBUICAO DIV_ATRIBUICAO MOD_ATRIBUICAO
%right INTERROGACAO DOIS_PONTOS
%left IGUAL NOT_IGUAL MENOR MAIOR MENOR_IGUAL MAIOR_IGUAL
%left NOT AND OR
%left SOMA SUB
%left MULT DIV MOD

%%

programa: comandos

comandos
    : expr PONTOEVIRGULA
    | comandos expr PONTOEVIRGULA

expr: literal
    | IDENTIFICADOR
    | ABRE_PARENTESES expr FECHA_PARENTESES
    | opAritmetica
    | opLogica
    | opRelacional
    | chamadaFuncao
    /* | funcao */
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

/* funcao: ABRE_PARENTESES identificadoresVirgula FECHA_PARENTESES SETA_DUPLA expr */
/* identificadoresVirgula */
/*     : IDENTIFICADOR */
/*     | IDENTIFICADOR VIRGULA */
/*     | IDENTIFICADOR VIRGULA identificadoresVirgula */

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
    : INICIO_BLOCO comandos FIM_BLOCO
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO comandos FIM_BLOCO
    | INICIO_BLOCO comandos expr FIM_BLOCO
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO comandos expr FIM_BLOCO

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
    fprintf(stderr,"Error | Line: %d\n%s\n",yylineno,s);
}
