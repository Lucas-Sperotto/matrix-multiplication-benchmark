/**********************************************************************
 * Projeto: Benchmark de Multiplicação de Matrizes
 * Descrição: Este código realiza a multiplicação de duas matrizes
 *            de tamanho N x N, variando automaticamente o valor de N
 *            e medindo o tempo de alocação de memória, cálculo,
 *            e liberação de memória.
 *            O código salva os resultados em um arquivo de saída.
 *
 * Linguagem: C++
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

#include <iostream>
#include <fstream>
#include <ctime>
// #include <sys/resource.h>

using namespace std;

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

    ofstream file("resultado_cpp.csv");
    if (!file.is_open())
    {
        cout << "Erro ao abrir o arquivo!" << endl;
        return 1;
    }
    file << "N,TCS,TAM,TLM" << endl;

    for (int N : {10, 100, 500, 1000, 1500, 2000, 2500, 3000})
    {
        { // Varie N automaticamente de 10 a 10000

            // Tempo de alocação de memória
            clock_t start_alloc = clock();
            int **mat1 = new int *[N];
            int **mat2 = new int *[N];
            int **res = new int *[N];

            for (int i = 0; i < N; i++)
            {
                mat1[i] = new int[N];
                mat2[i] = new int[N];
                res[i] = new int[N];
            }
            clock_t end_alloc = clock();
            double time_alloc = double(end_alloc - start_alloc) / CLOCKS_PER_SEC;

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

            // Tempo do cálculo
            clock_t start_calc = clock();
            multiply(mat1, mat2, res, N);
            clock_t end_calc = clock();
            double time_calc = double(end_calc - start_calc) / CLOCKS_PER_SEC;

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
                        cout << "Erro na multiplicação das matrizes para N = " << N << "!\n";
                }
            }

            // Tempo de liberação de memória
            clock_t start_free = clock();
            for (int i = 0; i < N; i++)
            {
                delete[] mat1[i];
                delete[] mat2[i];
                delete[] res[i];
            }
            delete[] mat1;
            delete[] mat2;
            delete[] res;
            clock_t end_free = clock();
            double time_free = double(end_free - start_free) / CLOCKS_PER_SEC;

            // Salvando os resultados no arquivo
            file << N << ",";
            file << time_calc << ",";  // Tempo de cálculo segundos
            file << time_alloc << ","; // Tempo de alocação de memória segundos
            file << time_free << endl; // Tempo de liberação de memória: %f segundos
            // file << "Memória usada: " << memory_used_kb << "KB" << endl << endl;

            cout << "Resultados para N = " << N << " salvos." << endl;
        }

        file.close();
        cout << "Todos os resultados foram salvos no arquivo resultado_cpp.csv." << endl;

        return 0;
    }
