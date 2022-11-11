%{

  #include <stdio.h>
  #include "expr.h"

  int yylex();
  extern Expr yylval;
  #include "parser.tab.h"

  yytoken_kind_t literal(yytoken_kind_t token);
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
[a-zA-Z][a-zA-z0-9]* { return literal(IDENTIFICADOR); }

\".*\" { return literal(STRING); }

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

yytoken_kind_t literal(yytoken_kind_t token) {
    yylval.text = strdup(yytext);
    return token;
}

int yywrap(void){
  return 1; 
} 
