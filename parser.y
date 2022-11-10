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

%%

programa: IGUAL {}

%%