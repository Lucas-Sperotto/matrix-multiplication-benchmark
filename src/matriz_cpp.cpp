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


#include <chrono>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

using Clock = std::chrono::steady_clock;

static double elapsed_seconds(Clock::time_point start, Clock::time_point end)
{
    return std::chrono::duration<double>(end - start).count();
}

static int parse_int(const char *text, const std::string &name, int min_value, int max_value)
{
    std::string value_text(text);
    size_t consumed = 0;
    long value = 0;

    try
    {
        value = std::stol(value_text, &consumed, 10);
    }
    catch (const std::exception &)
    {
        throw std::invalid_argument("Parametro invalido para " + name + ": " + value_text);
    }

    if (consumed != value_text.size() || value < min_value || value > max_value)
    {
        throw std::invalid_argument("Parametro invalido para " + name + ": " + value_text);
    }

    return static_cast<int>(value);
}

static std::vector<int> make_points(int b, int npts, int escala)
{
    const double a = 100.0;
    std::vector<int> points;
    points.reserve(static_cast<size_t>(npts));

    if (escala == 1)
    {
        const double step = (static_cast<double>(b) - a) / static_cast<double>(npts - 1);
        for (int i = 0; i < npts; i++)
        {
            points.push_back(static_cast<int>(std::round(a + step * i)));
        }
    }
    else
    {
        const double ratio = std::pow(static_cast<double>(b) / a, 1.0 / static_cast<double>(npts - 1));
        for (int i = 0; i < npts; i++)
        {
            points.push_back(static_cast<int>(std::round(a * std::pow(ratio, i))));
        }
    }

    return points;
}

static void multiply(const std::vector<int> &mat1, const std::vector<int> &mat2, std::vector<int> &res, int n)
{
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            int sum = 0;
            for (int k = 0; k < n; k++)
            {
                sum += mat1[static_cast<size_t>(i) * n + k] * mat2[static_cast<size_t>(k) * n + j];
            }
            res[static_cast<size_t>(i) * n + j] = sum;
        }
    }
}

static bool verify_sample(const std::vector<int> &res, int n)
{
    const int idxs[3] = {0, n / 2, n - 1};

    for (int i : idxs)
    {
        for (int j : idxs)
        {
            if (res[static_cast<size_t>(i) * n + j] != i + j)
            {
                std::cerr << "Erro na multiplicacao para N=" << n << " em [" << i << "," << j << "]\n";
                return false;
            }
        }
    }

    return true;
}

static bool run_once(int n, double &time_alloc, double &time_calc, double &time_free)
{
    const size_t n_size = static_cast<size_t>(n);
    if (n_size > std::numeric_limits<size_t>::max() / n_size)
    {
        std::cerr << "N muito grande: " << n << "\n";
        return false;
    }
    const size_t n2 = n_size * n_size;

    auto start = Clock::now();
    std::vector<int> mat1(n2);
    std::vector<int> mat2(n2);
    std::vector<int> res(n2);

    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            mat1[static_cast<size_t>(i) * n + j] = i + j;
            mat2[static_cast<size_t>(i) * n + j] = (i == j) ? 1 : 0;
        }
    }
    auto end = Clock::now();
    time_alloc += elapsed_seconds(start, end);

    start = Clock::now();
    multiply(mat1, mat2, res, n);
    end = Clock::now();
    time_calc += elapsed_seconds(start, end);

    if (!verify_sample(res, n))
    {
        return false;
    }

    start = Clock::now();
    std::vector<int>().swap(mat1);
    std::vector<int>().swap(mat2);
    std::vector<int>().swap(res);
    end = Clock::now();
    time_free += elapsed_seconds(start, end);

    return true;
}

int main(int argc, char **argv)
{
    if (argc != 6)
    {
        std::cerr << "Uso: " << argv[0] << " <B> <Npts> <M> <Escala> <out_csv>\n";
        std::cerr << "Exemplo: " << argv[0] << " 4000 12 5 1 out/execucao/resultado_cpp.csv\n";
        return 1;
    }

    try
    {
        const int b = parse_int(argv[1], "B", 100, 100000);
        const int npts = parse_int(argv[2], "Npts", 2, 10000);
        const int m_count = parse_int(argv[3], "M", 1, 100000);
        const int escala = parse_int(argv[4], "Escala", 0, 1);
        const std::string out_csv = argv[5];

        std::ofstream file(out_csv);
        if (!file.is_open())
        {
            std::cerr << "Erro ao abrir arquivo de saida: " << out_csv << "\n";
            return 1;
        }

        file << "N,TCS,TAM,TDM\n";
        file << std::scientific << std::setprecision(6);

        for (int n : make_points(b, npts, escala))
        {
            double warm_alloc = 0.0;
            double warm_calc = 0.0;
            double warm_free = 0.0;
            double time_alloc = 0.0;
            double time_calc = 0.0;
            double time_free = 0.0;

            if (!run_once(n, warm_alloc, warm_calc, warm_free))
            {
                return 1;
            }

            for (int m = 0; m < m_count; m++)
            {
                if (!run_once(n, time_alloc, time_calc, time_free))
                {
                    return 1;
                }
            }

            file << n << ","
                 << (time_calc / static_cast<double>(m_count)) << ","
                 << (time_alloc / static_cast<double>(m_count)) << ","
                 << (time_free / static_cast<double>(m_count)) << "\n";

            std::cout << "Resultados para N = " << n << " salvos.\n";
        }

        std::cout << "Todos os resultados foram salvos em " << out_csv << ".\n";
    }
    catch (const std::exception &ex)
    {
        std::cerr << ex.what() << "\n";
        return 1;
    }

    return 0;
}
