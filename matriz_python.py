# **********************************************************************
# Projeto: Benchmark de Multiplicação de Matrizes
# Descrição: Este código realiza a multiplicação de duas matrizes 
#            de tamanho N x N, variando automaticamente o valor de N 
#            e medindo o tempo de alocação de memória e do cálculo.
#            O código salva os resultados em um arquivo de saída.
#
# Linguagem: Python
#
# Autores: Lucas Kriesel Sperotto, Marcos Adriano Silva David
# Data: 05/09/2024
#
# Parâmetros:
#  - N: tamanho da matriz (varia de 10 até 10.000)
#
# Saída: Arquivo de resultados contendo:
#  - Tempo de alocação de memória
#  - Tempo de cálculo (multiplicação das matrizes)
#
# Uso:
#  - Execute o código, e o arquivo de saída será gerado contendo os 
#    resultados para diferentes valores de N.
# **********************************************************************

import time

def multiply(mat1, mat2, N):
    res = [[0] * N for _ in range(N)]
    for i in range(N):
        for j in range(N):
            for k in range(N):
                res[i][j] += mat1[i][k] * mat2[k][j]
    return res

# Abrir o arquivo para salvar os resultados
with open("resultado_python.dat", "w") as f:

    for N in [10, 100, 1000, 10000]:  # Varie N automaticamente de 10 a 10000
        
        # Medir o tempo de alocação de memória
        start_alloc = time.time()
        mat1 = [[i + j for j in range(N)] for i in range(N)]
        mat2 = [[i - j for j in range(N)] for i in range(N)]
        end_alloc = time.time()
        time_alloc = end_alloc - start_alloc

        # Medir o tempo de cálculo
        start_calc = time.time()
        res = multiply(mat1, mat2, N)
        end_calc = time.time()
        time_calc = end_calc - start_calc

        # Em Python, não precisamos medir o tempo de liberação de memória, pois o garbage collector cuida disso.

        # Salvando os resultados no arquivo
        f.write(f"N = {N}\n")
        f.write(f"Tempo de alocação de memória: {time_alloc} segundos\n")
        f.write(f"Tempo de cálculo: {time_calc} segundos\n\n")

        print(f"Resultados para N = {N} salvos.")

print("Todos os resultados foram salvos no arquivo resultado_python.dat.")
