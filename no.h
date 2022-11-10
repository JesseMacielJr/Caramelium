#ifndef _NO_H_
#define _NO_H_

struct No {
  int token;
  double val;
  char nome[256];
  struct No *esq, *dir, *prox, *prox1, *prox2, *prox3;
};

typedef struct No No;

#endif
