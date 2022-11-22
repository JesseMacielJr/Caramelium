%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "asprintf.h"

#include "expr.h"
#define YYSTYPE Expr

Expr yylval;

struct Context {
    FILE *output;
    int blocos_len;
    char *blocos[16];
};
typedef struct Context Context;

#include "lex.yy.c"

#define YYERROR_VERBOSE

int yylex();
int yyparse(Context *ctx);
void yyerror(Context *ctx, const char *s);

unsigned int nextVar() {
    static unsigned int var_counter = 0;
    var_counter += 1;
    return var_counter;
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
    int var = nextVar();
    out->var = var;
    if (v > 0) {
        // <r>
        // <id> <op> x<r.var>;
        // int x<var> = <id>;
        asprintf(&out->text, "%s\n%s %s x%d;\nint x%d = %s;",
            r->text, id->text, op, r->var, var, id->text
        );
    } else {
        // %id <op> <r>;
        // int x<var> = <id>;
        asprintf(&out->text, "%s %s %s; int x%d = %s;",
            id->text, op, r->text, var, id->text
        );
    }
}

void declaracao(Expr *out, Expr *id, Expr *r) {
    int v = r->var;
    // int <id>;
    // <atr(<id>, <r>)>

    Expr atr = { 0, 0 };
    atribuicao("=", &atr, id, r);

    asprintf(&out->text, "int %s;\n%s\n",
        id->text, atr.text
    );
    out->var = atr.var;
}

int get_bloco(Context *ctx, char *nome_bloco) {
    for (int i = 0; i < ctx->blocos_len; i++) {
        if (strcmp(nome_bloco, ctx->blocos[i]) == 0) {
            return i;
        }
    }
    
    return -1;
}

int add_bloco(Context *ctx, char *nome_bloco) {
    int bloco = get_bloco(ctx, nome_bloco);
    if (bloco != -1) {
        return bloco;
    }

    ctx->blocos[ctx->blocos_len++] = nome_bloco;
    return ctx->blocos_len - 1;
}

void continua(Context *ctx, Expr *out, Expr *nome_bloco) {
    out->var = nextVar();
    int bloco = add_bloco(ctx, nome_bloco->text);
    asprintf(&out->text, "int x%d = 0; goto S%d;\n", out->var, bloco);
}

void retorna(Context *ctx, Expr *out, Expr *nome_bloco, Expr *expr) {
    out->var = nextVar();

    if (nome_bloco->text == NULL) {
        asprintf(&out->text, "int x%d = 0; return 0;\n", out->var);
        return;
    }

    int bloco = add_bloco(ctx, nome_bloco->text);
    asprintf(&out->text, "int x%d = 0; goto E%d;\n", out->var, bloco);
}

void bloco(Context *ctx, Expr *out, Expr *nome, Expr *comandos, Expr *expr) {
    // int x<var>;
    // S<bloco>: {
    // <comands>
    // <atr(x<var>, <expr>)>
    // break;
    // } E<bloco>:
    
    unsigned int var = nextVar();
    out->var = var;
    char* label = nome->text ? nome->text : "";
    char* comands = comandos->text ? comandos->text : "";
    char* expression = expr->text ? expr->text : "0";

    int bloco = nome->text ? add_bloco(ctx, nome->text) : -1;

    char* bloco_start = ""; 
    char* bloco_end   = "";
    if (bloco != -1) {
        asprintf(&bloco_start, "S%d:", bloco);
        asprintf(&bloco_end, "E%d:", bloco);
    }

    if (expr->text != NULL) {
        Expr atr = { 0, 0 };
        Expr xvar = { 0, var };
        asprintf(&xvar.text, "x%d", var);
        atribuicao("=", &atr, &xvar, expr);

        asprintf(
            &out->text,
            "int x%d;\n%s{\n%s%s;\n}%s",
            var, bloco_start, comands, atr.text, bloco_end
        );
    } else {
        asprintf(
            &out->text,
            "int x%d;\n%s{\n%sx%d=0;\n}%s",
            var, bloco_start, comands, var, bloco_end
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
    "\n"
    "  va_end(args);\n"
    "}\n"
    "void _escreverln(int string, ...) {\n"
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
    | ABRE_PARENTESES expr FECHA_PARENTESES { $$ = $2; }
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
    | expr MENOR_IGUAL expr  { binop("<=", &$$, &$1, &$3); }
    | expr MAIOR_IGUAL expr  { binop(">=", &$$, &$1, &$3); }

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
    { bloco(ctx, &$$, &NONE, &NONE, &NONE); }
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO FIM_BLOCO
    { bloco(ctx, &$$, &$1, &NONE, &NONE); }
    | INICIO_BLOCO expr FIM_BLOCO
    { bloco(ctx, &$$, &NONE, &NONE, &$2); }
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO expr FIM_BLOCO
    { bloco(ctx, &$$, &$1, &NONE, &$4); }

    | INICIO_BLOCO comandos FIM_BLOCO
    { bloco(ctx, &$$, &NONE, &$2, &NONE); }
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO comandos FIM_BLOCO
    { bloco(ctx, &$$, &$1, &$4, &NONE); }
    | INICIO_BLOCO comandos expr FIM_BLOCO
    { bloco(ctx, &$$, &NONE, &$2, &$3); }
    | NOME_BLOCO DOIS_PONTOS INICIO_BLOCO comandos expr FIM_BLOCO
    { bloco(ctx, &$$, &$1, &$4, &$5); }

return
    : RETURN                 { retorna(ctx, &$$, &NONE, &NONE); }
    | RETURN expr            { retorna(ctx, &$$, &NONE, &$2);}
    | RETURN NOME_BLOCO      { retorna(ctx, &$$, &$2, &NONE); }
    | RETURN NOME_BLOCO expr { retorna(ctx, &$$, &$2, &$3);}

continue
    : CONTINUE NOME_BLOCO { continua(ctx, &$$, &$2); }

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

#include <sys/stat.h>
#include <sys/types.h>

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32) && !defined(__CYGWIN__)
int SetConsoleOutputCP(unsigned int wCodePageID);
const bool windows = true;

void _mkdir(char *path) {
    mkdir(path);
}
#else
const bool windows = false;

void _mkdir(char *path) {
    mkdir(path, 0700);
}
#endif

int main(int argc, char *argv[]) {
#if defined(WIN32) || defined(_WIN32) || defined(__WIN32) && !defined(__CYGWIN__)
    SetConsoleOutputCP(65001);
#endif
    yydebug = 0;

    FILE *input = NULL;
    FILE *output = stdout;
    bool build_and_run = false;
    bool print_tokens = false;
    for (int i = 1; i < argc; i++) {
        if (argv[i][0] == '-') {
            if (strcmp(argv[i], "--tokens") == 0) {
                print_tokens = true;
            } else if (strcmp(argv[i], "--run") == 0) {
                struct stat st = {0};
                if (stat("build", &st) == -1) {
                    _mkdir("build");
                }
                output = fopen("build/out.c", "w");
                if (output == NULL) {
                    fprintf(stderr, "Arquivo de saída não encontrado\n");
                    return 5;
                }
                build_and_run = true;
            } else if (strcmp(argv[i], "-o") == 0) {
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

    if (print_tokens) {
        for (;;) {
            int token = yylex();
            if (token == 0) break;

            printf("%-17s %s\n", token_name(token), yytext);
        }
        return 0;
    }

    Context ctx = { output, 0, {} };

    yyparse(&ctx);

    fclose(yyin);
    fclose(output);

    if (build_and_run) {
        if (windows) {
            int res = system("gcc build\\out.c -o build\\out.exe");
            if (res != 0) {
                fprintf(stderr, "Compilação falhou.");
                return 7;
            }
            system(".\\build\\out.exe");
        } else {
            system("gcc build/out.c -o build/out.exe");
            system("./build/out.exe");
        }
    }
}
