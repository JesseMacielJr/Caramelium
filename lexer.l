%{

  #include <stdio.h>

  int yylex();
  #include "parser.tab.h"
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

[-+]?[0-9]+ { 
  return INTEIRO;
}
[-+]?[0-9]+("."[0-9]*)([eE]"-"?[0-9]*)? { 
  return FLOAT;
}
[a-zA-Z][a-zA-z0-9]* { 
  return IDENTIFICADOR;
}

\".*\" { return STRING; }

\$[a-zA-Zç][a-zA-z0-9ç]*   { return NOME_BLOCO; }

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
