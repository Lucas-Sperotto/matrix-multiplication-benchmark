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
#include <iomanip> // para std::scientific e std::setprecision
#include <cmath>
#include <vector>
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

std::vector<int> logspace(double b, int Npts)
{
    double a = 100.0; // valor inicial fixo
    std::vector<int> arr;

    if (Npts < 2)
        return arr; // retorna vetor vazio se Npts < 2

    arr.reserve(Npts); // otimiza alocação

    double r = std::pow(b / a, 1.0 / (Npts - 1)); // razão geométrica

    for (int i = 0; i < Npts; i++)
    {
        arr.push_back(static_cast<int>(std::round(a * std::pow(r, i))));
    }

    return arr;
}

std::vector<int> linear(double b, int Npts)
{
    double a = 100.0; // valor inicial fixo
    std::vector<int> arr;

    if (Npts < 2)
        return arr; // retorna vetor vazio se Npts < 2

    arr.reserve(Npts); // otimiza alocação

    double step = (b - a) / (Npts - 1); // passo linear
    for (int i = 0; i < Npts; i++)
    {
        arr.push_back(static_cast<int>(std::round((int)(a + step * i + 0.5)))); // arredonda para o inteiro mais próximo
    }

    return arr;
}

int main(int argc, char **argv)
{

    std::ofstream file;
    std::string filename;

    if (argc > 5)
        filename = "resultado_cpp_O3.csv";
    else
        filename = "resultado_cpp.csv";

    file.open(filename);

    if (!file.is_open())
    {
        cout << "Erro ao abrir o arquivo!" << endl;
        return -1;
    }
    file << "N,TCS,TAM,TLM" << endl;

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
    int escala = atoi(argv[4]); // número de repetições

    std::vector<int> Ns;

    if (escala == 1)
        Ns = linear(B, Npts);
    else
        Ns = logspace(B, Npts);

    if (Ns.empty())
    {
        std::cout << "Erro ao gerar escala.\n";
        return 1;
    }

    // cout << "B = " << B << endl;

    // cout << "Numero de pontos = " << Npts << endl;

    // cout << "M = " << M << endl;
    //  Configura notação científica e precisão
    file << std::scientific << std::setprecision(6);

    // Varie N automaticamente de 10 a 10000
    for (int n = 0; n < Npts; n++)
    {
        int N = Ns[n];
        double time_free = 0.0, time_alloc = 0.0, time_calc = 0.0;

        for (int m = 1; m <= M; m++)
        {

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
            time_alloc += double(end_alloc - start_alloc) / CLOCKS_PER_SEC;

            // Tempo do cálculo
            clock_t start_calc = clock();
            multiply(mat1, mat2, res, N);
            clock_t end_calc = clock();
            time_calc += double(end_calc - start_calc) / CLOCKS_PER_SEC;

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
            time_free += double(end_free - start_free) / CLOCKS_PER_SEC;

            // cout << N << ",";
            // cout << time_calc << ",";  // Tempo de cálculo segundos
            // cout << time_alloc << ","; // Tempo de alocação de memória segundos
            // cout << time_free << endl; // Tempo de liberação de memória: %f segundos
        }
        // Salvando os resultados no arquivo
        file << N << ",";
        file << (time_calc / (double)M) << ",";  // Tempo de cálculo segundos
        file << (time_alloc / (double)M) << ","; // Tempo de alocação de memória segundos
        file << (time_free / (double)M) << endl; // Tempo de liberação de memória: %f segundos
        // file << "Memória usada: " << memory_used_kb << "KB" << endl << endl;

        cout << "Resultados para N = " << N << " salvos." << endl;
    }

    file.close();
    cout << "Todos os resultados foram salvos no arquivo resultado_cpp.csv." << endl;

    return 0;
}
