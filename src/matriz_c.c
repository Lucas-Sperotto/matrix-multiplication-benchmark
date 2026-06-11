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
 *  - N: tamanho da matriz (varia de 100 até B)
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

#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <time.h>
#endif

static double now_seconds(void)
{
#ifdef _WIN32
    LARGE_INTEGER freq;
    LARGE_INTEGER counter;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&counter);
    return (double)counter.QuadPart / (double)freq.QuadPart;
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
#endif
}

static int parse_int(const char *text, const char *name, int min_value, int max_value, int *out)
{
    char *end = NULL;
    long value;

    errno = 0;
    value = strtol(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' || value < min_value || value > max_value)
    {
        fprintf(stderr, "Parametro invalido para %s: %s\n", name, text);
        return 0;
    }

    *out = (int)value;
    return 1;
}

static int *make_points(int b, int npts, int escala)
{
    const double a = 100.0;
    int *points = (int *)malloc((size_t)npts * sizeof(int));
    if (points == NULL)
    {
        return NULL;
    }

    if (escala == 1)
    {
        double step = ((double)b - a) / (double)(npts - 1);
        for (int i = 0; i < npts; i++)
        {
            points[i] = (int)(a + step * i + 0.5);
        }
    }
    else
    {
        double ratio = pow((double)b / a, 1.0 / (double)(npts - 1));
        for (int i = 0; i < npts; i++)
        {
            points[i] = (int)(a * pow(ratio, i) + 0.5);
        }
    }

    return points;
}

static void multiply(const int *mat1, const int *mat2, int *res, int n)
{
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            int sum = 0;
            for (int k = 0; k < n; k++)
            {
                sum += mat1[(size_t)i * n + k] * mat2[(size_t)k * n + j];
            }
            res[(size_t)i * n + j] = sum;
        }
    }
}

static int verify_sample(const int *res, int n)
{
    int idxs[3] = {0, n / 2, n - 1};

    for (int a = 0; a < 3; a++)
    {
        int i = idxs[a];
        for (int b = 0; b < 3; b++)
        {
            int j = idxs[b];
            if (res[(size_t)i * n + j] != i + j)
            {
                fprintf(stderr, "Erro na multiplicacao para N=%d em [%d,%d]\n", n, i, j);
                return 0;
            }
        }
    }

    return 1;
}

static int run_once(int n, double *time_alloc, double *time_calc, double *time_free)
{
    size_t n2;
    int *mat1 = NULL;
    int *mat2 = NULL;
    int *res = NULL;
    double start;
    double end;

    if ((size_t)n > SIZE_MAX / (size_t)n)
    {
        fprintf(stderr, "N muito grande: %d\n", n);
        return 0;
    }
    n2 = (size_t)n * (size_t)n;
    if (n2 > SIZE_MAX / sizeof(int))
    {
        fprintf(stderr, "Matriz muito grande para alocar: N=%d\n", n);
        return 0;
    }

    start = now_seconds();
    mat1 = (int *)malloc(n2 * sizeof(int));
    mat2 = (int *)malloc(n2 * sizeof(int));
    res = (int *)malloc(n2 * sizeof(int));
    if (mat1 == NULL || mat2 == NULL || res == NULL)
    {
        fprintf(stderr, "Falha de alocacao para N=%d\n", n);
        free(mat1);
        free(mat2);
        free(res);
        return 0;
    }

    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            mat1[(size_t)i * n + j] = i + j;
            mat2[(size_t)i * n + j] = (i == j) ? 1 : 0;
        }
    }
    end = now_seconds();
    *time_alloc += end - start;

    start = now_seconds();
    multiply(mat1, mat2, res, n);
    end = now_seconds();
    *time_calc += end - start;

    if (!verify_sample(res, n))
    {
        free(mat1);
        free(mat2);
        free(res);
        return 0;
    }

    start = now_seconds();
    free(mat1);
    free(mat2);
    free(res);
    end = now_seconds();
    *time_free += end - start;

    return 1;
}

int main(int argc, char **argv)
{
    int b;
    int npts;
    int m_count;
    int escala;
    int *ns = NULL;
    FILE *file = NULL;
    const char *out_csv;

    if (argc != 6)
    {
        fprintf(stderr, "Uso: %s <B> <Npts> <M> <Escala> <out_csv>\n", argv[0]);
        fprintf(stderr, "Exemplo: %s 4000 12 5 1 out/execucao/resultado_c.csv\n", argv[0]);
        return 1;
    }

    if (!parse_int(argv[1], "B", 100, 100000, &b) ||
        !parse_int(argv[2], "Npts", 2, 10000, &npts) ||
        !parse_int(argv[3], "M", 1, 100000, &m_count) ||
        !parse_int(argv[4], "Escala", 0, 1, &escala))
    {
        return 1;
    }

    out_csv = argv[5];
    ns = make_points(b, npts, escala);
    if (ns == NULL)
    {
        fprintf(stderr, "Erro ao gerar escala.\n");
        return 1;
    }

    file = fopen(out_csv, "w");
    if (file == NULL)
    {
        fprintf(stderr, "Erro ao abrir arquivo de saida: %s\n", out_csv);
        free(ns);
        return 1;
    }
    fprintf(file, "N,TCS,TAM,TDM\n");

    for (int n_idx = 0; n_idx < npts; n_idx++)
    {
        int n = ns[n_idx];
        double warm_alloc = 0.0;
        double warm_calc = 0.0;
        double warm_free = 0.0;
        double time_alloc = 0.0;
        double time_calc = 0.0;
        double time_free = 0.0;

        if (!run_once(n, &warm_alloc, &warm_calc, &warm_free))
        {
            fclose(file);
            free(ns);
            return 1;
        }

        for (int m = 0; m < m_count; m++)
        {
            if (!run_once(n, &time_alloc, &time_calc, &time_free))
            {
                fclose(file);
                free(ns);
                return 1;
            }
        }

        fprintf(file, "%d,%.6e,%.6e,%.6e\n",
                n,
                time_calc / (double)m_count,
                time_alloc / (double)m_count,
                time_free / (double)m_count);
        printf("Resultados para N = %d salvos.\n", n);
    }

    fclose(file);
    free(ns);
    printf("Todos os resultados foram salvos em %s.\n", out_csv);
    return 0;
}
