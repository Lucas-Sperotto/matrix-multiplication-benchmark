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
#include <math.h>
// #include <sys/resource.h>

void multiply(int **mat1, int **mat2, int **res, int N)
{
    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {3
            res[i][j] = 0;
            for (int k = 0; k < N; k++)
            {
                res[i][j] += mat1[i][k] * mat2[k][j];
            }
        }
    }
}

// Função para gerar pontos em escala logarítmica
int *logspace(double b, int Npts)
{
    double a = 100.0; // valor inicial fixo
    if (Npts < 2)
        return NULL;

    int *arr = malloc(Npts * sizeof(int));
    if (!arr)
        return NULL;

    double r = pow(b / a, 1.0 / (Npts - 1)); // razão geométrica
    for (int i = 0; i < Npts; i++)
    {
        arr[i] = (int)(a * pow(r, i) + 0.5); // arredonda para o inteiro mais próximo
    }

    return arr;
}

int *linear(double b, int Npts)
{
    double a = 100.0; // valor inicial fixo
    if (Npts < 2)
        return NULL;

    int *arr = malloc(Npts * sizeof(int));
    if (!arr)
        return NULL;

    double step = (b - a) / (Npts - 1); // passo linear
    for (int i = 0; i < Npts; i++)
    {
        arr[i] = (int)(a + step * i + 0.5); // arredonda para o inteiro mais próximo
    }

    return arr;
}

int main(int argc, char **argv)
{
    FILE *f;
    if (argc > 5)
        f = fopen("resultado_c_O3.csv", "w");
    else
        f = fopen("resultado_c.csv", "w");

    if (f == NULL)
    {
        printf("Erro ao abrir o arquivo!\n");
        return -1;
    }
    fprintf(f, "N,TCS,TAM,TLM\n"); //

    int M = 1;

    if (argc < 5)
    {
        printf("Uso: %s <B> <Npts> <M> <Escala>\n", argv[0]);
        printf("Exemplo: %s 4000 12 5 1\n", argv[0]);
        return -1;
    }

    int B = atoi(argv[1]);      // valor máximo
    int Npts = atoi(argv[2]);   // quantidade de pontos
    M = atoi(argv[3]);          // número de repetições
    int escala = atoi(argv[4]); // escala do grafico

    int *Ns = NULL;

    if (escala == 1)
        Ns = linear(B, Npts);
    else
        Ns = logspace(B, Npts);

    if (Ns == NULL)
    {
        printf("Erro ao gerar escala .\n");
        return 1;
    }

    // printf("B = %d\n\n", B);
    // printf("Npts = %d\n\n", Npts);
    // printf("M = %d\n\n", M);

    for (int n = 0; n < Npts; n++)
    {
        int N = Ns[n];
        double time_free = 0.0, time_alloc = 0.0, time_calc = 0.0;
        // printf("%d:\n", N);
        for (int m = 1; m <= M; m++)
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

            clock_t end_alloc = clock();
            time_alloc += ((double)(end_alloc - start_alloc)) / CLOCKS_PER_SEC;

            // Medindo o tempo de cálculo
            clock_t start_calc = clock();
            multiply(mat1, mat2, res, N);
            clock_t end_calc = clock();
            time_calc += (((double)(end_calc - start_calc)) / CLOCKS_PER_SEC);

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
            time_free += ((double)(end_free - start_free)) / CLOCKS_PER_SEC;
            // Salvando os resultados no arquivo
            // printf("%d,", N);            // valor de N
            // printf("%e,", (time_calc));  // Tempo de cálculo: %f segundos\n
            // printf("%e,", (time_alloc)); // Tempo de alocação de memória: %f segundos\n
            // printf("%e\n", (time_free)); // Tempo de liberação de memória: %f segundos

            // valor de N
            // printf("[%d]:\t%e\n", m, (((double)(end_calc - start_calc)) / CLOCKS_PER_SEC)); // Tempo de cálculo: %f segundos\n
            // printf("%e,", (time_alloc)); // Tempo de alocação de memória: %f segundos\n
            // printf("%e\n", (time_free)); // Tempo de liberação de memória: %f segundos

            // fprintf(f, "Memória usada: %ld KB\n", memory_used_kb);
        }
        // Salvando os resultados no arquivo
        fprintf(f, "%d,", N);                        // valor de N
        fprintf(f, "%e,", (time_calc / (double)M));  // Tempo de cálculo: %f segundos\n
        fprintf(f, "%e,", (time_alloc / (double)M)); // Tempo de alocação de memória: %f segundos\n
        fprintf(f, "%e\n", (time_free / (double)M)); // Tempo de liberação de memória: %f segundos
        // fprintf(f, "Memória usada: %ld KB\n", memory_used_kb);
        printf("Resultados para N = %d salvos.\n", N);
    }
    fclose(f);
    free(Ns);
    printf("Todos os resultados foram salvos no arquivo resultado_c.csv.\n");
    return 0;
}