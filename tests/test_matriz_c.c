/**********************************************************************
 * Teste de corretude (nao de desempenho) para src/matriz_c.c.
 *
 * O benchmark principal usa a matriz identidade como segundo operando,
 * o que nao distingue uma multiplicacao real de uma copia da primeira
 * matriz (ver docs/METHODOLOGY.md, "Validacao matematica"). Este teste chama
 * a mesma funcao multiply() de producao com um caso conhecido e NAO
 * identidade, fora de qualquer janela de benchmark.
 *
 * `#define main matriz_c_main` renomeia a funcao main() de matriz_c.c
 * antes de incluir o arquivo, evitando duplicidade de simbolo com o
 * main() deste teste, sem duplicar nem alterar o codigo de producao.
 * Compilar e executar separadamente do build do runner:
 *   gcc -std=c11 -Wall -Wextra -Wno-unused-function \
 *       tests/test_matriz_c.c -o build/test_matriz_c -lm
 *   ./build/test_matriz_c
 **********************************************************************/

/* Nao incluir <stdio.h> (ou qualquer header de sistema) antes de
 * "../src/matriz_c.c": esse arquivo define _POSIX_C_SOURCE antes do
 * primeiro header de sistema, exigido pela glibc para expor
 * clock_gettime/CLOCK_MONOTONIC sob -std=c11. Incluir <stdio.h> aqui
 * primeiro travaria as macros de feature sem essa extensao. */
#define main matriz_c_main
#include "../src/matriz_c.c"
#undef main

int main(void)
{
    /* A = [[1,2],[3,4]], B = [[5,6],[7,8]] (row-major, flat i*n+j). */
    int mat1[4] = {1, 2, 3, 4};
    int mat2[4] = {5, 6, 7, 8};
    int res[4] = {0, 0, 0, 0};
    int expected[4] = {19, 22, 43, 50};

    multiply(mat1, mat2, res, 2);

    for (int i = 0; i < 4; i++)
    {
        if (res[i] != expected[i])
        {
            fprintf(stderr, "FALHA: res[%d]=%d, esperado=%d\n", i, res[i], expected[i]);
            return 1;
        }
    }

    printf("OK: matriz_c multiply() caso nao identidade 2x2\n");
    return 0;
}
