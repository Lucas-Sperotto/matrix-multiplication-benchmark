# **********************************************************************
# Projeto: Benchmark de Multiplicação de Matrizes
# Descrição: Este código realiza a multiplicação de duas matrizes 
#            de tamanho N x N, variando automaticamente o valor de N 
#            e medindo o tempo de alocação de memória e do cálculo.
#            O código salva os resultados em um arquivo de saída.
#
# Linguagem: Elixir
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

defmodule Matrix do
  def multiply(mat1, mat2, N) do
    for row <- mat1 do
      for col <- transpose(mat2) do
        Enum.zip(row, col)
        |> Enum.reduce(0, fn {x, y}, acc -> acc + x * y end)
      end
    end
  end

  def transpose(matrix) do
    List.zip(matrix) |> Enum.map(&Tuple.to_list/1)
  end
end

defmodule Main do
  def run do
    {:ok, file} = File.open("resultado_elixir.dat", [:write])

    for N <- [10, 100, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000] do  # Varie N automaticamente de 10 a 10000
      
      # Tempo de alocação de memória
      start_alloc = :os.system_time(:millisecond)
      mat1 = for i <- 0..(N-1), do: for j <- 0..(N-1), do: i + j
      mat2 = for i <- 0..(N-1), do: for j <- 0..(N-1), do: if i == j, do: 1, else: 0
      end_alloc = :os.system_time(:millisecond)
      time_alloc = (end_alloc - start_alloc) / 1000

      # Tempo de cálculo
      start_calc = :os.system_time(:millisecond)
      _res = Matrix.multiply(mat1, mat2, N)
      end_calc = :os.system_time(:millisecond)
      time_calc = (end_calc - start_calc) / 1000


      # Verificação do resultado
      for i <- 0..(N-1) do
        for j <- 0..(N-1) do
          if res[i][j] != i + j do
            IO.puts("Erro na multiplicação das matrizes para N = #{N}!")
          end
        end
      end
      # Não precisamos medir o tempo de liberação de memória em Elixir, pois a coleta de lixo é automática.

      # Salvando os resultados no arquivo
      IO.write(file, "N = #{N}\n")
      IO.write(file, "Tempo de alocação de memória: #{time_alloc} segundos\n")
      IO.write(file, "Tempo de cálculo: #{time_calc} segundos\n\n")

      IO.puts("Resultados para N = #{N} salvos.")
    end

    File.close(file)
    IO.puts("Todos os resultados foram salvos no arquivo resultado_elixir.dat.")
  end
end

Main.run()
