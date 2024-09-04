#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void multiply(int **mat1, int **mat2, int **res, int N) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            res[i][j] = 0;
            for (int k = 0; k < N; k++) {
                res[i][j] += mat1[i][k] * mat2[k][j];
            }
        }
    }
}

int main() {
    FILE *f = fopen("resultado_c.dat", "w");
    if (f == NULL) {
        printf("Erro ao abrir o arquivo!\n");
        return 1;
    }

    for (int N = 10; N <= 10000; N *= 10) {  // Varie N automaticamente de 10 a 10000

        // Medindo o tempo de alocação de memória
        clock_t start_alloc = clock();
        int **mat1 = (int **)malloc(N * sizeof(int *));
        int **mat2 = (int **)malloc(N * sizeof(int *));
        int **res = (int **)malloc(N * sizeof(int *));
        
        for (int i = 0; i < N; i++) {
            mat1[i] = (int *)malloc(N * sizeof(int));
            mat2[i] = (int *)malloc(N * sizeof(int));
            res[i] = (int *)malloc(N * sizeof(int));
        }
        clock_t end_alloc = clock();
        double time_alloc = ((double)(end_alloc - start_alloc)) / CLOCKS_PER_SEC;

        // Inicializando as matrizes
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                mat1[i][j] = i + j;
                mat2[i][j] = i - j;
            }
        }

        // Medindo o tempo de cálculo
        clock_t start_calc = clock();
        multiply(mat1, mat2, res, N);
        clock_t end_calc = clock();
        double time_calc = ((double)(end_calc - start_calc)) / CLOCKS_PER_SEC;

        // Medindo o tempo de liberação de memória
        clock_t start_free = clock();
        for (int i = 0; i < N; i++) {
            free(mat1[i]);
            free(mat2[i]);
            free(res[i]);
        }
      
        free(mat1);
        free(mat2);
        free(res);
        clock_t end_free = clock();
        double time_free = ((double)(end_free - start_free)) / CLOCKS_PER_SEC;

        // Salvando os resultados no arquivo
        fprintf(f, "N = %d\n", N);
        fprintf(f, "Tempo de alocação de memória: %f segundos\n", time_alloc);
        fprintf(f, "Tempo de cálculo: %f segundos\n", time_calc);
        fprintf(f, "Tempo de liberação de memória: %f segundos\n\n", time_free);

        printf("Resultados para N = %d salvos.\n", N);
    }

    fclose(f);
    printf("Todos os resultados foram salvos no arquivo resultado_c.dat.\n");
    return 0;
}
