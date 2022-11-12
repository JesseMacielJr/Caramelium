%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "expr.h"

int yylex();
extern Expr yylval;
#include "parser.tab.h"

int identificador(int token) {
    // todos os identificadores são préfixados com '_' para evitar conflito com
    // variaveis criadas na compilação.
    size_t len = strlen(yytext) + 1;
    void *buffer = malloc (len + 1);
    memcpy (buffer+1, yytext, len);

    yylval.text = buffer;
    yylval.text[0] = '_';
    yylval.var = 0;
    return token;
}

int string(int token) {
    // strings são préfixadas com um cast para (int), porque por enquanto todos
    // os tipos são int.

    size_t len = strlen(yytext) + 1;
    void *buffer = malloc (len + 5);
    memcpy (buffer+5, yytext, len);

    yylval.text = buffer;
    yylval.text[0] = '(';
    yylval.text[1] = 'i';
    yylval.text[2] = 'n';
    yylval.text[3] = 't';
    yylval.text[4] = ')';
    yylval.var = 0;

    return token;
}

int literal(int token) {
    yylval.text = strdup(yytext);
    yylval.var = 0;
    return token;
}
%}

%option yylineno

%%
"{"   { return INICIO_BLOCO; }
"}"   { return FIM_BLOCO; }
":="  { return DECLARACAO; }
"="   { return ATRIBUICAO; }
"?"   { return INTERROGACAO; }
":"   { return DOIS_PONTOS; }
","   { return VIRGULA; }

[0-9]+ { 
  return literal(INTEIRO);
}
[0-9]+("."[0-9]*)([eE]"-"?[0-9]*)? { 
  return literal(FLOAT);
}
[a-zA-Z][a-zA-z0-9]* { return identificador(IDENTIFICADOR); }

\".*\" { return string(STRING); }

\$[a-zA-Zç][a-zA-z0-9ç]*   { return literal(NOME_BLOCO); }

"<-"  { return RETURN; }
"->"  { return CONTINUE; }
"=>"  { return SETA_DUPLA; }
"+"   { return SOMA; }
"-"   { return SUB; }
"*"   { return MULT; }
"/"   { return DIV; }
"%"   { return MOD; }
"+="  { return SOMA_ATRIBUICAO; }
"-="  { return SUB_ATRIBUICAO; }
"*="  { return MULT_ATRIBUICAO; }
"/="  { return DIV_ATRIBUICAO; }
"%="  { return MOD_ATRIBUICAO; }
"&&"  { return AND; }
"||"  { return OR; }
"!"   { return NOT; }
"=="  { return IGUAL; }
"!="  { return NOT_IGUAL; }
"<"   { return MENOR; }
">"   { return MAIOR; }
"<="  { return MENOR_IGUAL; }
">="  { return MAIOR_IGUAL; }
";"   { return PONTOEVIRGULA; }
"("   { return ABRE_PARENTESES; }
")"   { return FECHA_PARENTESES; }
[ \f\n\r\t\v]
"//".*
.       {return *yytext;}
	
%%	

int yywrap(void){
  return 1; 
} 
