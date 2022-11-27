#pragma once

enum Type {
    TY_INTEIRO,
    TY_FLOAT,
    TY_STRING,
    TY_VOID,
};
typedef enum Type Type;

struct Expr {
    char *text;
    Type type;
    unsigned int var;
    // Usado em lista de parametros
    struct Expr *tail;
};
typedef struct Expr Expr;
