/**********************************************************************
 * Projeto: Benchmark de Multiplicação de Matrizes
 * Descrição: Este código realiza a multiplicação de duas matrizes
 *            de tamanho N x N, variando automaticamente o valor de N
 *            e medindo o tempo de alocação de memória, cálculo,
 *            e liberação de memória.
 *            O código salva os resultados em um arquivo de saída.
 *
 * Linguagem: C
 *
 * Autores: Lucas Kriesel Sperotto, Marcos Adriano Silva David
 * Data: 05/09/2024
 *
 * Parâmetros:
 *  - N: tamanho da matriz (varia de 10 até 10.000)
 *
 * Saída: Arquivo de resultados contendo:
 *  - Tempo de alocação de memória
 *  - Tempo de cálculo (multiplicação das matrizes)
 *  - Tempo de liberação de memória
 *
 * Uso:
 *  - Compile e execute o código, e o arquivo de saída será gerado
 *    contendo os resultados para diferentes valores de N.
 **********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <time.h> // para medição do tempo
// #include <sys/resource.h>

void multiply(int **mat1, int **mat2, int **res, int N)
{
    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            res[i][j] = 0;
            for (int k = 0; k < N; k++)
            {
                res[i][j] += mat1[i][k] * mat2[k][j];
            }
        }
    }
}

int main()
{
    FILE *f = fopen("resultado_c.csv", "w");
    if (f == NULL)
    {
        printf("Erro ao abrir o arquivo!\n");
        return 1;
    }

    fprintf(f, "N,TCS,TAM,TLM\n"); //

    // Varie N automaticamente de 10 a 1000
    for (int N = 10; N <= 1000; N)
    {

        // Medindo o tempo de alocação de memória
        clock_t start_alloc = clock();
        int **mat1 = (int **)malloc(N * sizeof(int *));
        int **mat2 = (int **)malloc(N * sizeof(int *));
        int **res = (int **)malloc(N * sizeof(int *));

        for (int i = 0; i < N; i++)
        {
            mat1[i] = (int *)malloc(N * sizeof(int));
            mat2[i] = (int *)malloc(N * sizeof(int));
            res[i] = (int *)malloc(N * sizeof(int));
        }

        clock_t end_alloc = clock();
        double time_alloc = ((double)(end_alloc - start_alloc)) / CLOCKS_PER_SEC;

        // Inicializando as matrizes
        for (int i = 0; i < N; i++)
        {
            for (int j = 0; j < N; j++)
            {
                mat1[i][j] = i + j;
                if (i == j)
                    mat2[i][j] = 1;
                else
                {
                    mat2[i][j] = 0;
                }
            }
        }

        // Medindo o tempo de cálculo
        clock_t start_calc = clock();
        multiply(mat1, mat2, res, N);
        clock_t end_calc = clock();
        double time_calc = ((double)(end_calc - start_calc)) / CLOCKS_PER_SEC;

        // Medição do uso de memória
        // struct rusage usage;
        // getrusage(RUSAGE_SELF, &usage);
        // long memory_used_kb = usage.ru_maxrss;  // Memória usada em KB

        // Verificação do resultado
        for (int i = 0; i < N; i++)
        {
            for (int j = 0; j < N; j++)
            {
                if (res[i][j] != i + j)
                    printf("Erro na multiplicação das matrizes para N = %d!\n", N);
            }
        }

        // Medindo o tempo de liberação de memória
        clock_t start_free = clock();
        for (int i = 0; i < N; i++)
        {
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
        fprintf(f, "%d,", N);          // valor de N
        fprintf(f, "%E,", time_calc);  // Tempo de cálculo: %f segundos\n
        fprintf(f, "%E,", time_alloc); // Tempo de alocação de memória: %f segundos\n
        fprintf(f, "%E\n", time_free); // Tempo de liberação de memória: %f segundos
        // fprintf(f, "Memória usada: %ld KB\n", memory_used_kb);

        printf("Resultados para N = %d salvos.\n", N);

        // Altera o valor de N
        if (N >= 1000)
            N += 100;
        else
            N += 100;
    }
    fclose(f);
    printf("Todos os resultados foram salvos no arquivo resultado_c.csv.\n");
    return 0;
}