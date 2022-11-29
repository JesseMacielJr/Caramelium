#pragma once

/// Os tipos das expressões durante a compilacão.
enum Type
{
    /// Um valor inteiro
    TY_INTEIRO,
    /// Um valor ponto flutuante
    TY_FLOAT,
    /// Uma string constante.
    TY_STRING,
    /// Tipo para expressões que retornar um valor vazio, tipo blocos
    /// terminados em ';', ou um condicional sem 'else'.
    TY_VOID,
    /// Tipo para expressões de desivo de fluxo, como '<-' e '->'. Como essas
    /// operações fazem um desvio, o seu valor é compatível com qualquer outro.
    TY_DIVERGE,
};
typedef enum Type Type;

/// O tipo que o Bison retorna em cada regra.
struct Expr
{
    /// String condendo a tradução dessa expressão para código em C.
    char *text;

    /// O tipo dessa expressão.
    Type type;

    /// O número da variável que contém essa expressão no código em C.
    ///
    /// Durante a compilação, o valor de algumas expressões precisam ser
    /// primeiros atribuidos a uma variável, para depois serem passados para as
    /// próximas expressões. O nome dessas variáveis tem o formato "x<var>".
    ///
    /// Por exemplo a expressão `1 ? { escrever("olá"); 2 } : 3` é traduzido
    /// para:
    ///
    /// int x0;
    /// if (1) {
    ///     printf("olá");
    ///     x0 = 2;
    /// } else {
    ///     x0 = 3;
    /// }
    ///
    /// Nesse caso, `var` teria o valor `0`.
    unsigned int var;

    /// Usado em lista de parametros, aponta para a expressão anterior a essa.
    struct Expr *tail;
};
typedef struct Expr Expr;
