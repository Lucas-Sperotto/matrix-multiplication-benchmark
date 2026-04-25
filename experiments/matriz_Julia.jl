#=**********************************************************************
 * Projeto: Benchmark de Multiplicação de Matrizes
 * Descrição: Este código realiza a multiplicação de duas matrizes 
 *            de tamanho N x N, variando automaticamente o valor de N 
 *            e medindo o tempo de alocação de memória, cálculo, 
 *            e liberação de memória.
 *            O código salva os resultados em um arquivo de saída.
 *
 * Linguagem: Julia
 *
 * Autores: Lucas Kriesel Sperotto, Marcos Adriano Silva David
 * Data: 26/09/2024
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
 *  - execute o código, e o arquivo de saída será gerado 
 *    contendo os resultados para diferentes valores de N.
 **********************************************************************/=#


using Printf
using LinearAlgebra
using Dates

function multiply(mat1, mat2, res, N)
    for i in 1:N
        for j in 1:N
            res[i, j] = 0
            for k in 1:N
                res[i, j] += mat1[i, k] * mat2[k, j]
            end
        end
    end
end

function benchmark_multiplication()
    open("resultado_julia.dat", "a") do f

        for N in [10, 100, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]

            # Tempo de alocação de memória
            start_alloc = now()
            mat1 = zeros(Int, N, N)
            mat2 = zeros(Int, N, N)
            res = zeros(Int, N, N)
            end_alloc = now()
            time_alloc = (end_alloc - start_alloc).value / 1e9  # Em segundos

            # Inicializando as matrizes
            for i in 1:N
                for j in 1:N
                    mat1[i, j] = i + j
                    mat2[i, j] = i == j ? 1 : 0
                end
            end

            # Tempo do cálculo
            start_calc = now()
            multiply(mat1, mat2, res, N)
            end_calc = now()
            time_calc = (end_calc - start_calc).value / 1e9  # Em segundos

            # Verificação do resultado
            for i in 1:N
                for j in 1:N
                    if res[i, j] != i + j
                        println("Erro na multiplicação das matrizes para N = $N!")
                    end
                end
            end

            # Tempo de liberação de memória
            start_free = now()
            mat1 = nothing
            mat2 = nothing
            res = nothing
            GC.gc()  # Garbage collection
            end_free = now()
            time_free = (end_free - start_free).value / 1e9  # Em segundos

            # Salvando os resultados no arquivo
            @printf(f, "N = %d\n", N)
            @printf(f, "Tempo de alocação de memória: %f segundos\n", time_alloc)
            @printf(f, "Tempo de cálculo: %f segundos\n", time_calc)
            @printf(f, "Tempo de liberação de memória: %f segundos\n\n", time_free)

            println("Resultados para N = $N salvos.")
        end
    end

    println("Todos os resultados foram salvos no arquivo resultado_julia.dat.")
end

benchmark_multiplication()
