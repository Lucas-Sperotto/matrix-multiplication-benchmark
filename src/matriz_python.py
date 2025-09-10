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
import psutil
import sys


def multiply(mat1, mat2, N):
    res = [[0] * N for _ in range(N)]
    for i in range(N):
        for j in range(N):
            for k in range(N):
                res[i][j] += mat1[i][k] * mat2[k][j]
    return res

# Abrir o arquivo para salvar os resultados
with open("resultado_python.csv", "w") as f:

    f.write(f"N,TCS,TAM\n")

    M = 1  # valor padrão

    if len(sys.argv) == 2:  # se passou 1 argumento além do nome do script
        M = int(sys.argv[1])  # converte string para inteiro
    
    print("M:", M)

    for N in [10, 100, 500, 1000]:  # Varie N automaticamente de 10 a 10000

        time_alloc = 0.0
        time_calc = 0.0

        for m in range(1, M + 1):
        # Medir o tempo de alocação de memória
            start_alloc = time.time()
            mat1 = [[i + j for j in range(N)] for i in range(N)]
            mat2 = [[1 if i == j else 0 for j in range(N)] for i in range(N)]
            end_alloc = time.time()
            time_alloc += end_alloc - start_alloc

            # Medir a quantidade de memória usada
            process = psutil.Process()
            memory_info = process.memory_info().rss / 1024  # Convert to KB

            # Medir o tempo de cálculo
            start_calc = time.time()
            res = multiply(mat1, mat2, N)
            end_calc = time.time()
            time_calc += end_calc - start_calc
            
            # Verificação do resultado
            for i in range(N):
                for j in range(N):
                    if res[i][j] != i + j:
                        print(f"Erro na multiplicação das matrizes para N = {N}!")
            
            # Em Python, não precisamos medir o tempo de liberação de memória, pois o garbage collector cuida disso.
            print(f"{N}")
            print(f"{time_calc:.6e}")
            print(f"{time_alloc:.6e}\n")

        # Salvando os resultados no arquivo
        f.write(f"{N},")
        f.write(f"{(time_calc/M):.6e},")
        f.write(f"{(time_alloc/M):.6e}\n")        
        #f.write(f"Memória usada: {memory_info} KB\n")
        print(f"Resultados para N = {N} salvos.")

print("Todos os resultados foram salvos no arquivo resultado_python.csv.")
