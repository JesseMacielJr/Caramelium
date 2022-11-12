#pragma once

struct Expr {
    char* text;
    unsigned int var;
    // Usado em lista de parametros
    struct Expr* tail;
};
typedef struct Expr Expr;
