#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

#define int int64_t
void _escrever(int string, ...) {
    char* text = (char*) string;

    va_list args;
    va_start(args,text);

    vprintf(text, args);
    printf("\n");

    va_end(args);
}

int _ler(int string){
    char* text = (char*) string;
    printf("%s ", text);

    int out;
    scanf("%ld", &out);
    return out;
}
