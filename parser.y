%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "asprintf.h"

#include "expr.h"
#define YYSTYPE Expr

Expr yylval;

/// O nome de cada tipo, quando traduzidos para C. 
char const *ctypes[] = {"int64_t", "double", "const char *", "char", "char"};

/// O nome de cada tipo, quando exibidas em mensagens de erro.
char const *type_names[] = {"inteiro", "float", "string", "void", "diverge"};

/// O tipo que contem as informações compartilhadas durante a compilação.
struct Context {
    /// O arquivo de saída, ao qual o programa compilado em C será escrito.
    FILE *output;

    /// Lista de blocos atualmente declarados. Um nome é adiconado sempre que
    /// entra em um bloco nomeado, e é removido assim que ele termina.
    int blocos_len;
    char *blocos[16];
};
typedef struct Context Context;

#include "lex.yy.c"

#define YYERROR_VERBOSE

int yylex();
int yyparse(Context *ctx);
void yyerror(Context *ctx, const char *s);

/// Retona o próximo número de variável disponível.
unsigned int nextVar() {
    static unsigned int var_counter = 0;
    var_counter += 1;
    return var_counter;
}

/// Faz a concatação de duas strings.
char* concat(char* stra, char* strb) {
    size_t lena = strlen(stra);
    size_t lenb = strlen(strb);
    void *buffer = malloc (lena + lenb + 1);
    memcpy (buffer, stra, lena);
    memcpy (buffer + lena, strb, lenb + 1);
    return buffer;
}

void comando(Expr *out, Expr *tail, Expr *comand) {
    out->type = TY_VOID;
    if (comand->type == TY_DIVERGE || tail && tail->type == TY_DIVERGE) {
        out->type = TY_DIVERGE;
    }
    asprintf(&out->text, "%s%s;\n", tail ? tail->text : "", comand->text);
}

void uniop(const char* op, Expr *out, Expr *r) {
    out->type = r->type;
    if (r->var > 0) {
        // <type> x<var>; 
        // {
        // <r>
        // x<var> = <op> x<r.var>;
        // }
        int var = nextVar();
        out->var = var;
        char const *type = ctypes[out->type];
        asprintf(&out->text, "%s x%d;\n{\n%s\nx%d=%sx%d;\n}",
            type, var, r->text, var, op, r->var
        );
    } else {
        // <op> <r>
        asprintf(&out->text, "%s (%s)", op, r->text);
    }
}

void binop(const char* op, Expr *out, Expr *l, Expr *r) {
    {
        Type a = l->type;
        Type b = r->type;
        if (a == TY_INTEIRO && b == TY_INTEIRO) {
            out->type = TY_INTEIRO;
        } else if (a == TY_INTEIRO && b == TY_FLOAT || a == TY_FLOAT && b == TY_INTEIRO || a == TY_FLOAT && b == TY_INTEIRO) {
            out->type = TY_FLOAT;
        } else if (a == TY_STRING || b == TY_STRING) {
            yyerror(NULL, "operação com tipo 'string' não é valido");
            out->type = TY_STRING;
        } else if (a == TY_DIVERGE) {
            out->type = b;
        } else if (b == TY_DIVERGE) {
            out->type = a;
        } else {
            char *error;
            asprintf(&error, "operação com tipos incompatíveis: esquerda é '%s', mas direita é '%s'",
                type_names[a], type_names[b]
            );
            yyerror(NULL, error);
            out->type = a;
        }
    }

    if (l->var > 0 && r->var > 0) {
        // <type> x<var>; 
        // {
        // <l>
        // <r>
        // x<var> = x<l.var> <op> x<r.var>;
        // }
        int var = nextVar();
        out->var = var;

        char const *type = ctypes[out->type];
        asprintf(&out->text, "%s x%d;\n{\n%s\n%s\nx%d=x%d%sx%d;\n}",
            type, var, l->text, r->text, var, l->var, op, r->var
        );
    } else if (l->var > 0 && r->var == 0) {
        // <type> x<var>; 
        // {
        // <l>
        // x<var> = x<l.var> <op> <r>;
        // }
        int var = nextVar();
        out->var = var;
        char const *type = ctypes[out->type];
        asprintf(&out->text, "%s x%d;\n{\n%s\nx%d=x%d%s%s;\n}",
            type, var, l->text, var, l->var, op, r->text
        );
    } else if (l->var == 0 && r->var > 0) {
        // <type> x<var>; 
        // {
        // <r>
        // x<var> = <l> <op> x<r.var>;
        // }
        int var = nextVar();
        out->var = var;
        char const *type = ctypes[out->type];
        asprintf(&out->text, "%s x%d;\n{\n%s\nx%d=%s%sx%d;\n}",
            type, var, r->text, var, l->text, op, r->var
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
        // <type> x<var>;
        // {
        // <parametros>
        // x<var> = x<parametros.var>
        // }
        char const *type = ctypes[parametros->type];
        int var = nextVar();
        char *out;
        asprintf(&out, "%s x%d;\n{\n%s\nx%d=x%d;\n}\n",
            type, var, parametros->text, var, parametros->var
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
    out->type = TY_INTEIRO;
}

void parametro(Expr *out, Expr *tail, Expr *param) {
    if (tail) {
        out->tail = (Expr*) malloc(sizeof(Expr));
        *out->tail = *tail;
    }
    out->var = param->var;
    out->type = param->type;
    asprintf(&out->text, "%s", param->text);
}

void atribuicao(const char* op, Expr *out, Expr *id, Expr *r) {
    int v = r->var;
    int var = nextVar();
    out->var = var;
    out->type = r->type;
    char const *type = ctypes[out->type];
    if (v > 0) {
        // <r>
        // <id> <op> x<r.var>;
        // <type> x<var> = <id>;
        asprintf(&out->text, "%s\n%s %s x%d;\n%s x%d = %s;",
            r->text, id->text, op, r->var, type, var, id->text
        );
    } else {
        // %id <op> <r>;
        // <type> x<var> = <id>;
        asprintf(&out->text, "%s %s %s; %s x%d = %s;",
            id->text, op, r->text, type, var, id->text
        );
    }
}

void declaracao(Expr *out, Expr *id, Expr *r) {
    int v = r->var;
    // <type> <id>;
    // <atr(<id>, <r>)>

    Expr atr = { 0, 0 };
    atribuicao("=", &atr, id, r);

    out->type = r->type;
    char const *type = ctypes[out->type];
    asprintf(&out->text, "%s %s;\n%s\n",
        type, id->text, atr.text
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

int remove_bloco(Context *ctx, int bloco) {
    ctx->blocos[bloco] = "";
}

void continua(Context *ctx, Expr *out, Expr *nome_bloco) {
    out->type = TY_DIVERGE;
    int bloco = get_bloco(ctx, nome_bloco->text);

    if (bloco == -1) {
        char *error;
        asprintf(&error, "bloco '%s' não está definido nesse escopo",
            nome_bloco->text
        );
        yyerror(NULL, error);

        out->var = 0;
        out->text = "0";
        return;
    }

    char const *type = ctypes[out->type];
    out->var = nextVar();
    asprintf(&out->text, "%s x%d = 0; goto S%d;\n", type, out->var, bloco);
}

void retorna(Context *ctx, Expr *out, Expr *nome_bloco, Expr *expr) {
    out->type = TY_DIVERGE;
    char const *type = ctypes[out->type];

    if (nome_bloco == NULL) {
        asprintf(&out->text, "%s x%d = 0; return 0;\n", type, out->var);
        return;
    }

    int bloco = get_bloco(ctx, nome_bloco->text);
    if (bloco == -1) {
        char *error;
        asprintf(&error, "bloco '%s' não está definido nesse escopo",
            nome_bloco->text
        );
        yyerror(NULL, error);

        out->var = 0;
        out->text = "0";
        return;
    }

    out->var = nextVar();

    asprintf(&out->text, "%s x%d = 0; goto E%d;\n", type, out->var, bloco);
}

void bloco_labels(Context *ctx, Expr* out, Expr* nome, Expr* corpo) {
    // S<bloco>:;
    // <corpo>
    // E<bloco>:;
    *out = *corpo;

    int bloco = get_bloco(ctx, nome->text);
    if (bloco == -1) {
        fprintf(stderr, "bloco não encontrado??");
        exit(-1);
    }
    asprintf(
        &out->text,
        "S%d:; %s\nE%d:;",
        bloco, corpo->text, bloco
    );

    remove_bloco(ctx, bloco);
}

void bloco(Context *ctx, Expr *out, Expr *comandos, Expr *expr) {
    // <type> x<var>;
    // {
    // <comands>
    // <atr(x<var>, <expr>)>
    // }
    
    unsigned int var = nextVar();
    out->var = var;

    char* comands = comandos ? comandos->text : "";
    char* expression = expr ? expr->text : "0";

    out->type = expr ? expr->type : TY_VOID;
    if (comandos && comandos->type == TY_DIVERGE) {
        out->type = TY_DIVERGE;
    }

    char const *type =  ctypes[out->type];

    if (expr != NULL) {
        Expr atr = { 0, 0 };
        Expr xvar = { 0, var };
        asprintf(&xvar.text, "x%d", var);
        atribuicao("=", &atr, &xvar, expr);

        asprintf(
            &out->text,
            "%s x%d;\n{\n%s%s\n}",
            type, var, comands, atr.text
        );
    } else {
        asprintf(
            &out->text,
            "%s x%d;\n{\n%s x%d=0;\n}",
            type, var, comands, var
        );
    }
}

void condicao(Expr *out, Expr *cond, Expr *then, Expr *otherwise) {

    {
        Type a = then->type;
        Type b = otherwise ? otherwise->type : TY_VOID;
        if (a == b) {
            out->type = a;
        } else if (a == TY_INTEIRO && b == TY_FLOAT || a == TY_FLOAT && b == TY_INTEIRO || a == TY_FLOAT && b == TY_INTEIRO) {
            out->type = TY_FLOAT;
        } else if (a == TY_DIVERGE) {
            out->type = b;
        } else if (b == TY_DIVERGE) {
            out->type = a;
        } else {
            char *error;
            asprintf(&error, "operação com tipos incompatíveis: esquerda é '%s', mas direita é '%s'",
                type_names[a], type_names[b]
            );
            yyerror(NULL, error);
            out->type = a;
        }
    }

    unsigned int var = nextVar();
    out->var = var;


    Expr xvar = { 0, var };
    asprintf(&xvar.text, "x%d", var);

    Expr atr_then = { 0, 0 };
    atribuicao("=", &atr_then, &xvar, then);

    Expr atr_else = { 0, 0 };
    if (otherwise != NULL) {
        atribuicao("=", &atr_else, &xvar, otherwise);
    } else {
        atr_else.text = "";
    }

    char const *type = ctypes[out->type];
    int v = cond->var;
    if (v > 0) {
        // <type> x<var>;
        // {
        //   <cond>
        //   if (x<cond.var>) {
        //     <atr(x<var>, <then>)>
        //   } else {
        //     <atr(x<var>, <otherwise>)>
        //   }
        // }
        asprintf(&out->text, "%s x%d;\n{\n%s\nif(x%d){\n%s;\n}else{\n%s;\n}}",
            type, var, cond->text, cond->var, atr_then.text, atr_else.text
        );
    } else {
        // <type> x<var>;
        // if (<cond>) {
        //   <atr(x<var>, <then>)>
        // } else {
        //   <atr(x<var>, <otherwise>)>
        // }
        asprintf(&out->text, "%s x%d;\nif(%s){\n%s;\n}else{\n%s;\n}",
            type, var, cond->text, atr_then.text, atr_else.text
        );
    }
}

void programa(Context *ctx, Expr *prog) {
    const char *prelude = 
    "#include <stdarg.h>\n"
    "#include <stdint.h>\n"
    "#include <stdio.h>\n"
    "\n"
    "\n"
    "void _escrever(const char *string, ...) {\n"
    "  va_list args;\n"
    "  va_start(args, string);\n"
    "\n"
    "  char *text = (char *)string;\n"
    "\n"
    "  vprintf(text, args);\n"
    "\n"
    "  va_end(args);\n"
    "}\n"
    "void _escreverln(const char *string, ...) {\n"
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
    "int64_t _ler(char *string) {\n"
    "  char *text = (char *)string;\n"
    "  printf(\"%s \", text);\n"
    "\n"
    "  int64_t out;\n"
    "  scanf(\"%ld\", &out);\n"
    "  return out;\n"
    "}\n"
    ;

    fprintf(ctx->output, "%sint main() {\n%sreturn 0;\n}\n", 
        prelude, prog ? prog->text : ""
    ); 
}

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
%left NOT // também o SUB unário.

%parse-param {Context *ctx}

%%

programa
    :          { programa(ctx, NULL); }
    | comandos { programa(ctx, &$1); }

comandos
    : expr PONTOEVIRGULA          { comando(&$$, NULL, &$1); }
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
    : INTEIRO { $$ = $1; $$.type = TY_INTEIRO; }
    | FLOAT { $$ = $1; $$.type = TY_FLOAT; }
    | STRING { $$ = $1; $$.type = TY_STRING; }

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
    | expr                      { parametro(&$$, NULL, &$1); }
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
    : expr INTERROGACAO expr { condicao(&$$, &$1, &$3, NULL); }
    | expr INTERROGACAO expr DOIS_PONTOS expr { condicao(&$$, &$1, &$3, &$5); }

bloco
    : NOME_BLOCO { add_bloco(ctx, $1.text); } DOIS_PONTOS blocoCorpo { bloco_labels(ctx, &$$, &$1, &$4); }
    | blocoCorpo

blocoCorpo
    : INICIO_BLOCO FIM_BLOCO
    { bloco(ctx, &$$, NULL, NULL); }
    | INICIO_BLOCO expr FIM_BLOCO
    { bloco(ctx, &$$, NULL, &$2); }
    | INICIO_BLOCO comandos FIM_BLOCO
    { bloco(ctx, &$$, &$2, NULL); }
    | INICIO_BLOCO comandos expr FIM_BLOCO
    { bloco(ctx, &$$, &$2, &$3); }

return
    : RETURN NOME_BLOCO      { retorna(ctx, &$$, &$2, NULL); }
    /* | RETURN NOME_BLOCO expr { retorna(ctx, &$$, &$2, &$3);} */
    /* | RETURN                 { retorna(ctx, &$$, NULL, NULL); } */
    /* | RETURN expr            { retorna(ctx, &$$, NULL, &$2);} */

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
    fprintf(stderr,"Erro na linha %d: %s\n",yylineno,s);
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
    bool build = false;
    bool run = false;
    bool print_tokens = false;
    for (int i = 1; i < argc; i++) {
        if (argv[i][0] == '-') {
            if (strcmp(argv[i], "--tokens") == 0) {
                print_tokens = true;
            } else if (strcmp(argv[i], "--debug") == 0) {
                yydebug = 1;
            } else if (strcmp(argv[i], "--build") == 0) {
                struct stat st = {0};
                if (stat("build", &st) == -1) {
                    _mkdir("build");
                }
                output = fopen("build/out.c", "w");
                if (output == NULL) {
                    fprintf(stderr, "Arquivo de saída não encontrado\n");
                    return 5;
                }
                build = true;
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
                build = true;
                run = true;
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

    const char *build_command;
    const char *run_command;
    if (windows) {
        build_command = "gcc -w build\\out.c -o build\\out.exe";
        run_command = ".\\build\\out.exe";
    } else {
        build_command = "gcc -w build/out.c -o build/out.exe";
        run_command ="./build/out.exe";
    }

    if (build) {
        int res = system(build_command);
        if (res != 0) {
            fprintf(stderr, "Compilação falhou.");
            return 7;
        }
        if (run) {
            system(run_command);
        }
    }
}
