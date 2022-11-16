%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asprintf.h"

#include "expr.h"
#define YYSTYPE Expr

Expr yylval;

struct Context {
    FILE *output;
};
typedef struct Context Context;

#include "lex.yy.c"

#define YYERROR_VERBOSE

int yylex();
int yyparse(Context *ctx);
void yyerror(Context *ctx, const char *s);

unsigned int nextVar() {
    static unsigned int varCounter = 0;
    varCounter += 1;
    return varCounter;
}

char* concat(char* stra, char* strb) {
    size_t lena = strlen(stra);
    size_t lenb = strlen(strb);
    void *buffer = malloc (lena + lenb + 1);
    memcpy (buffer, stra, lena);
    memcpy (buffer + lena, strb, lenb + 1);
    return buffer;
}

void comando(Expr *out, Expr *tail, Expr *comando) {
    asprintf(&out->text, "%s%s;\n", tail->text ? tail->text : "", comando->text);
}

void uniop(const char* op, Expr *out, Expr *r) {
    if (r->var > 0) {
        // int x<var>; 
        // {
        // <r>
        // x<var> = <op> x<r.var>;
        // }
        int var = nextVar();
        out->var = var;
        asprintf(&out->text, "int x%d;\n{\n%s\nx%d=%sx%d;\n}",
            var, r->text, var, op, r->var
        );
    } else {
        // <op> <r>
        asprintf(&out->text, "%s (%s)", op, r->text);
    }
}

void binop(const char* op, Expr *out, Expr *l, Expr *r) {
    if (l->var > 0 && r->var > 0) {
        // int x<var>; 
        // {
        // <l>
        // <r>
        // x<var> = x<l.var> <op> x<r.var>;
        // }
        int var = nextVar();
        out->var = var;
        asprintf(&out->text, "int x%d;\n{\n%s\n%s\nx%d=x%d%sx%d;\n}",
            var, l->text, r->text, var, l->var, op, r->var
        );
    } else if (l->var > 0 && r->var == 0) {
        // int x<var>; 
        // {
        // <l>
        // x<var> = x<l.var> <op> <r>;
        // }
        int var = nextVar();
        out->var = var;
        asprintf(&out->text, "int x%d;\n{\n%s\nx%d=x%d%s%s;\n}",
            var, l->text, var, l->var, op, r->text
        );
    } else if (l->var == 0 && r->var > 0) {
        // int x<var>; 
        // {
        // <r>
        // x<var> = <l> <op> x<r.var>;
        // }
        int var = nextVar();
        out->var = var;
        asprintf(&out->text, "int x%d;\n{\n%s\nx%d=%s%sx%d;\n}",
            var, r->text, var, l->text, op, r->var
        );
    } else {
        // <l> <op> <r>
        asprintf(&out->text, "(%s) %s (%s)", l->text, op, r->text);
    }
}

void escrever_parametros(char **prelude, char **params, Expr* parametros) {
    if (parametros->tail != NULL) {
        escrever_parametros(prelude, params, parametros->tail);
    }
    if (parametros->var > 0) {
        // int x<var>;
        // {
        // <parametros>
        // x<var> = x<parametros.var>
        // }
        int var = nextVar();
        char *out;
        asprintf(&out, "int x%d;\n{\n%s\nx%d=x%d;\n}\n",
            var, parametros->text, var, parametros->var
        );
        *prelude = concat(*prelude, out);
        char *xvar;
        asprintf(&xvar, ",x%d", var);
        *params = concat(*params, xvar);
    } else {
        char *out;
        asprintf(&out, ",%s", parametros->text);
        *params = concat(*params, out);
    }
}

void chamada_funcao(Expr *out, Expr *nome, Expr *parametros) {
    char* prelude = "";
    char* params = "";
    escrever_parametros(&prelude, &params, parametros);
    asprintf(&out->text, "%s%s(%s)", prelude, nome->text, params+1);
}

void parametro(Expr *out, Expr *tail, Expr *param) {
    if (tail->text) {
        out->tail = (Expr*) malloc(sizeof(Expr));
        *out->tail = *tail;
    }
    out->var = param->var;
    asprintf(&out->text, "%s", param->text);
}

void atribuicao(const char* op, Expr *out, Expr *id, Expr *r) {
    int v = r->var;
    if (v > 0) {
        // <r>
        // <id> <op> x<r.var>;
        asprintf(&out->text, "%s\n%s %s x%d", r->text, id->text, op, r->var);
    } else {
        // %id <op> <r>;
        asprintf(&out->text, "%s %s %s", id->text, op, r->text);
    }
}

void declaracao(Expr *out, Expr *id, Expr *r) {
    int v = r->var;
    // int <id>;
    // <atr(<id>, <r>)>

    Expr atr = { 0, 0 };
    atribuicao("=", &atr, id, r);

    asprintf(&out->text, "int %s;\n%s", id->text, atr.text);
}

void retorna(Expr *out, Expr *nome_bloco, Expr *expr) {
    out->var = nextVar();
    asprintf(&out->text, "int x%d; break;\n", out->var);
}

void continua(Expr *out, Expr *nome_bloco) {
    asprintf(&out->text, "continue;\n");
}

void bloco(Expr *out, Expr *nome, Expr *comandos, Expr *expr) {
    // int x<var>;
    // for(;;){
    // <comands>
    // <atr(x<var>, <expr>)>
    // break;
    // }
    
    unsigned int var = nextVar();
    out->var = var;
    char* label = nome->text ? nome->text : "";
    char* comands = comandos->text ? comandos->text : "";
    char* expression = expr->text ? expr->text : "0";

    if (expr->text != NULL) {
        Expr atr = { 0, 0 };
        Expr xvar = { 0, var };
        asprintf(&xvar.text, "x%d", var);
        atribuicao("=", &atr, &xvar, expr);

        asprintf(
            &out->text,
            "int x%d;\nfor(;;){\n%s%s;\nbreak;\n}",
            var, comands, atr.text
        );
    } else {
        asprintf(
            &out->text,
            "int x%d;\nfor(;;){\n%sx%d=0;\nbreak;\n}",
            var, comands, var
        );
    }
}

void condicao(Expr *out, Expr *cond, Expr *then, Expr *otherwise) {

    unsigned int var = nextVar();
    out->var = var;


    Expr xvar = { 0, var };
    asprintf(&xvar.text, "x%d", var);

    Expr atr_then = { 0, 0 };
    atribuicao("=", &atr_then, &xvar, then);

    Expr atr_else = { 0, 0 };
    if (otherwise->text != NULL) {
        atribuicao("=", &atr_else, &xvar, otherwise);
    } else {
        atr_else.text = "";
    }

    int v = cond->var;
    if (v > 0) {
        // int x<var>;
        // {
        //   <cond>
        //   if (x<cond.var>) {
        //     <atr(x<var>, <then>)>
        //   } else {
        //     <atr(x<var>, <otherwise>)>
        //   }
        // }
        asprintf(&out->text, "int x%d;\n{\n%s\nif(x%d){\n%s;\n}else{\n%s;\n}}",
            var, cond->text, cond->var, atr_then.text, atr_else.text
        );
    } else {
        // if (<cond>) {
        //   <atr(x<var>, <then>)>
        // } else {
        //   <atr(x<var>, <otherwise>)>
        // }
        asprintf(&out->text, "int x%d;\nif(%s){\n%s;\n}else{\n%s;\n}",
            var, cond->text, atr_then.text, atr_else.text
        );
    }
}

void programa(Context *ctx, Expr *prog) {
    const char *prelude = 
    "#include <stdarg.h>\n"
    "#include <stdint.h>\n"
    "#include <stdio.h>\n"
    "\n"
    "#define int int64_t\n"
    "\n"
    "void _escrever(int string, ...) {\n"
    "  va_list args;\n"
    "  va_start(args, string);\n"
    "\n"
    "  char *text = (char *)string;\n"
    "\n"
    "  vprintf(text, args);\n"
    "  printf(\"\\n\");\n"
    "\n"
    "  va_end(args);\n"
    "}\n"
    "\n"
    "int _ler(int string) {\n"
    "  char *text = (char *)string;\n"
    "  printf(\"%s \", text);\n"
    "\n"
    "  int out;\n"
    "  scanf(\"%ld\", &out);\n"
    "  return out;\n"
    "}\n"
    ;

    fprintf(ctx->output, "%sint main() {\n%sreturn 0;\n}\n", 
        prelude, prog->text ? prog->text : ""
    ); 
}

Expr NONE = { NULL, 0 };

%}

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

%parse-param {Context *ctx}

%%

programa
    :          { programa(ctx, &NONE); }
    | comandos { programa(ctx, &$1); }

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
    : IDENTIFICADOR DECLARACAO expr { declaracao( &$$, &$1, &$3); }

opAtribuicao
    : IDENTIFICADOR ATRIBUICAO expr      { atribuicao("=", &$$, &$1, &$3); }
    | IDENTIFICADOR SOMA_ATRIBUICAO expr { atribuicao("+=", &$$, &$1, &$3); }
    | IDENTIFICADOR SUB_ATRIBUICAO expr  { atribuicao("-=", &$$, &$1, &$3); }
    | IDENTIFICADOR MULT_ATRIBUICAO expr { atribuicao("*=", &$$, &$1, &$3); }
    | IDENTIFICADOR DIV_ATRIBUICAO expr  { atribuicao("/=", &$$, &$1, &$3); }
    | IDENTIFICADOR MOD_ATRIBUICAO expr  { atribuicao("%=", &$$, &$1, &$3); }

condicao
    : expr INTERROGACAO expr { condicao(&$$, &$1, &$3, &NONE); }
    | expr INTERROGACAO expr DOIS_PONTOS expr { condicao(&$$, &$1, &$3, &$5); }

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
    : RETURN                 { retorna(&$$, &NONE, &NONE); }
    | RETURN expr            { retorna(&$$, &NONE, &$2);}
    | RETURN NOME_BLOCO      { retorna(&$$, &$1, &NONE); }
    | RETURN NOME_BLOCO expr { retorna(&$$, &$1, &$3);}

continue
    : CONTINUE NOME_BLOCO { continua(&$$, &$2); }

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

void yyerror(Context *ctx, const char *s) {
    fprintf(stderr,"Error | Line: %d\n%s\n",yylineno,s);
}

int main(int argc, char *argv[]) {
    yydebug = 0;

    FILE *input = NULL;
    FILE *output = stdout;
    for (int i = 1; i < argc; i++) {
        if (argv[i][0] == '-') {
            if (strcmp(argv[i], "-o") == 0) {
                i++;
                if (output != stdout) {
                    fprintf(stderr, "É esperado apenas um arquivo de saída.\n");
                    return 2;
                }
                output = fopen(argv[i], "w");
                if (output == NULL) {
                    fprintf(stderr, "Arquivo de saída não encontrado\n");
                    return 5;
                }
            } else {
                fprintf(stderr, "Opção '%s' desconhecida\n", argv[i]);
                return 6;
            }
        } else {
            if (input != NULL) {
                fprintf(stderr, "É esperado apenas um arquivo fonte.\n");
                return 3;
            }
            input = fopen(argv[i], "r");
            if (input == NULL) {
                fprintf(stderr, "Arquivo fonte não encontrado\n");
                return 4;
            }
        }
    }
    
    if (input == NULL) {
        fprintf(stderr, "É esperado o caminho do arquivo fonte como argumento.\n");
        return 1;
    }

    yyin = input;

    Context ctx = { output };

    yyparse(&ctx);

    fclose(yyin);
    fclose(output);
}
