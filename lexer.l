%{
  #include <math.h>
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  using namespace std;
  extern "C" int yylex();
  #include "parser.tab.h"
%}


%%
"{"   { return INICIO_BLOCO; }
"}"   { return FIM_BLOCO; }
":="    { return DECLARACAO; }
"="   { return ATRIBUICAO; }
"?"   { return INTERROGACAO; }
":"   { return DOIS_PONTOS; }
","   { return VIRGULA; }

[-+]?[0-9]+ { 
  yylval.pnt->val = atof(yytext);
  return INTEIRO;
}
[-+]?[0-9]+("."[0-9]*)([eE]"-"?[0-9]*)? { 
  yylval.pnt->val = atof(yytext);
  return FLOAT;
}
[a-zA-Z][a-zA-z0-9]* { 
  strncpy(yylval.pnt->nome, yytext, 256);
  return IDENTIFICADOR;
}

"\".*\""    { return STRING; }
"\$[a-zA-Z][a-zA-z0-9]*"   { return NOME_BLOCO; }
"<-"    { return RETURN; }
"->"    { return CONTINUE; }
"=>"    { return SETA_DUPLA; }
"\+"   { return SOMA; }
"-"   { return SUB; }
"\*"   { return MULT; }
"/"   { return DIV; }
"%"   { return MOD; }
"+="    { return SOMA_ATRIBUICAO; }
"-="    { return SUB_ATRIBUICAO; }
"\*="    { return MULT_ATRIBUICAO; }
"/="    { return DIV_ATRIBUICAO; }
"%="    { return MOD_ATRIBUICAO; }
"&&"    { return AND; }
"||"    { return OR; }
"!"   { return NOT; }
"=="    { return IGUAL; }
"!="    { return NOT_IGUAL; }
"<"   { return MENOR; }
">"   { return MAIOR; }
"<="    { return MENOR_IGUAL; }
">="    { return MAIOR_IGUAL; }
";"   { return PONTOEVIRGULA; }
"("   { return ABRE_PARENTESES; }
")"   { return FECHA_PARENTESES; }
[ \t\n]
"$//.*\n"
.                           {return *yytext;}
	
%%	
int yywrap(void){
  return 1; 
} 