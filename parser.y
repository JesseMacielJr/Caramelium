%{
#include <stdio.h>
#include "asprintf.h"
#define YYERROR_VERBOSE
int yylex();
int yyparse();
void yyerror(const char *s);

#include "expr.h"

Expr yylval;

void comando(Expr *out, Expr *tail, Expr *comando) {
    asprintf(&out->text, "%s%s;\n", tail->text ? tail->text : "", comando->text);
}

void uniop(const char* op, Expr *out, Expr *r) {
    asprintf(&out->text, "(%s %s)", op, r->text);
}

void binop(const char* op, Expr *out, Expr *l, Expr *r) {
    asprintf(&out->text, "(%s %s %s)", l->text, op, r->text);
}

void condicao(Expr *out, Expr *cond, Expr *then, Expr *otherwise) {
    asprintf(&out->text, "(%s ? %s : %s)", cond->text, then->text, otherwise->text);
}

void bloco(Expr *out, Expr *nome, Expr *comandos, Expr *expr) {
    asprintf(&out->text, "%s {\n%s%s\n}", nome->text, comandos->text, expr->text);
}

void chamada_funcao(Expr *out, Expr *nome, Expr *parametros) {
    asprintf(&out->text, "%s(%s)", nome->text, parametros->text);
}

void parametro(Expr *out, Expr *tail, Expr *param) {
    if (tail->text) {
        asprintf(&out->text, "%s, %s", tail->text, param->text);
    } else {
        asprintf(&out->text, "%s", param->text);
    }
}

Expr NONE = { 0 };

%}

%define api.value.type {Expr}

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
%right DECLARACAO ATRIBUICAO SOMA_ATRIBUICAO SUB_ATRIBUICAO MULT_ATRIBUICAO
       DIV_ATRIBUICAO MOD_ATRIBUICAO
%right INTERROGACAO DOIS_PONTOS
%left OR
%left AND
%left IGUAL NOT_IGUAL MENOR MAIOR MENOR_IGUAL MAIOR_IGUAL
%left SOMA SUB
%left MULT DIV MOD
%left NOT // also unary MINUS

%%

programa
    :          { printf("\n"); }
    | comandos { printf("%s\n", $1.text); }

comandos
    : expr PONTOEVIRGULA          { comando(&$$, &NONE, &$1); }
    | comandos expr PONTOEVIRGULA { comando(&$$, &$1, &$2); }

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

literal
    : INTEIRO
    | FLOAT
    | STRING

opAritmetica
    : SUB expr %prec NOT  { uniop("-", &$$, &$2); }
    | expr SOMA expr      { binop("+", &$$, &$1, &$3); }
    | expr SUB expr       { binop("-", &$$, &$1, &$3); }
    | expr MULT expr      { binop("*", &$$, &$1, &$3); }
    | expr DIV expr       { binop("/", &$$, &$1, &$3); }
    | expr MOD expr       { binop("%", &$$, &$1, &$3); }

opLogica
    : NOT expr      { uniop("!", &$$, &$2); }
    | expr AND expr { binop("&&", &$$, &$1, &$3); }
    | expr OR expr  { binop("||", &$$, &$1, &$3); }

opRelacional
    : expr IGUAL expr        { binop("==", &$$, &$1, &$3); }
    | expr NOT_IGUAL expr    { binop("!=", &$$, &$1, &$3); }
    | expr MENOR expr        { binop("<", &$$, &$1, &$3); }
    | expr MAIOR expr        { binop(">", &$$, &$1, &$3); }
    | expr MENOR_IGUAL expr  { binop(">=", &$$, &$1, &$3); }
    | expr MAIOR_IGUAL expr  { binop("<=", &$$, &$1, &$3); }

chamadaFuncao
    : IDENTIFICADOR ABRE_PARENTESES exprsVirgula FECHA_PARENTESES
    { chamada_funcao(&$$, &$1, &$3); }
    | IDENTIFICADOR ABRE_PARENTESES exprsVirgula VIRGULA FECHA_PARENTESES
    { chamada_funcao(&$$, &$1, &$3); }

exprsVirgula
    :                           { $$.text = ""; }
    | expr                      { parametro(&$$, &NONE, &$1); }
    | exprsVirgula VIRGULA expr { parametro(&$$, &$1, &$3); }

declaracao
    : IDENTIFICADOR DECLARACAO expr { binop(":=", &$$, &$1, &$3); }

opAtribuicao
    : IDENTIFICADOR ATRIBUICAO expr      { binop("=", &$$, &$1, &$3); }
    | IDENTIFICADOR SOMA_ATRIBUICAO expr { binop("+=", &$$, &$1, &$3); }
    | IDENTIFICADOR SUB_ATRIBUICAO expr  { binop("-=", &$$, &$1, &$3); }
    | IDENTIFICADOR MULT_ATRIBUICAO expr { binop("*=", &$$, &$1, &$3); }
    | IDENTIFICADOR DIV_ATRIBUICAO expr  { binop("/=", &$$, &$1, &$3); }
    | IDENTIFICADOR MOD_ATRIBUICAO expr  { binop("%=", &$$, &$1, &$3); }

condicao
    : expr INTERROGACAO expr { condicao(&$$, &$1, &$3, &NONE); }
    | expr INTERROGACAO expr DOIS_PONTOS expr { condicao(&$$, &$1, &$3, &$4); }

bloco
    : INICIO_BLOCO FIM_BLOCO
    { bloco(&$$, &NONE, &NONE, &NONE); }
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO FIM_BLOCO
    { bloco(&$$, &$1, &NONE, &NONE); }
    | INICIO_BLOCO expr FIM_BLOCO
    { bloco(&$$, &NONE, &NONE, &$3); }
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO expr FIM_BLOCO
    { bloco(&$$, &$1, &NONE, &$5); }

    | INICIO_BLOCO comandos FIM_BLOCO
    { bloco(&$$, &NONE, &$2, &NONE); }
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO comandos FIM_BLOCO
    { bloco(&$$, &$1, &$4, &NONE); }
    | INICIO_BLOCO comandos expr FIM_BLOCO
    { bloco(&$$, &NONE, &$2, &$3); }
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO comandos expr FIM_BLOCO
    { bloco(&$$, &$1, &$4, &$5); }

return
    : RETURN                 { uniop("<-", &$$, &NONE); }
    | RETURN expr            { uniop("<-", &$$, &$2);}
    | RETURN NOME_BLOCO      { uniop("<-", &$$, &NONE); }
    | RETURN NOME_BLOCO expr { uniop("<-", &$$, &$3);}

continue
    : CONTINUE NOME_BLOCO { uniop("->", &$$, &$2); }

/*
funcao: ABRE_PARENTESES identificadoresVirgula FECHA_PARENTESES SETA_DUPLA expr 
identificadoresVirgula
    : IDENTIFICADOR
    | IDENTIFICADOR VIRGULA
    | IDENTIFICADOR VIRGULA identificadoresVirgula
*/

%%

const char* token_name(int t) {
    return yytname[YYTRANSLATE(t)];
}

void yyerror(const char *s) {
    fprintf(stderr,"Error | Line: %d\n%s\n",yylineno,s);
}
