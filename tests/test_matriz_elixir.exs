# Teste de corretude (nao de desempenho) para src/matriz_multiplication.exs.
#
# A variavel de ambiente MATRIZ_ELIXIR_SKIP_MAIN precisa estar definida
# ANTES de Code.require_file/1, pois a guarda de main/1 e' avaliada
# imediatamente ao carregar o arquivo (nao dentro de uma funcao). Reusa
# MatrizElixir.build_matrix/2 e MatrizElixir.multiply/3 (publicas, ver
# src/matriz_multiplication.exs) com um caso conhecido nao identidade,
# fora da janela de benchmark.
#
# Executar:
#   elixir tests/test_matriz_elixir.exs

System.put_env("MATRIZ_ELIXIR_SKIP_MAIN", "1")

Code.require_file(Path.join([__DIR__, "..", "src", "matriz_multiplication.exs"]))

defmodule TestMatrizElixir do
  def run do
    # A = [[1,2],[3,4]], B = [[5,6],[7,8]]
    a = {{1, 2}, {3, 4}}
    b = {{5, 6}, {7, 8}}

    mat1 = MatrizElixir.build_matrix(2, fn i, j -> a |> elem(i) |> elem(j) end)
    mat2 = MatrizElixir.build_matrix(2, fn i, j -> b |> elem(i) |> elem(j) end)

    res = MatrizElixir.multiply(mat1, mat2, 2)
    expected = {19, 22, 43, 50}

    if res == expected do
      IO.puts("OK: matriz_multiplication.exs multiply/3 caso nao identidade 2x2")
      System.halt(0)
    else
      IO.puts(:stderr, "FALHA: res=#{inspect(res)}, esperado=#{inspect(expected)}")
      System.halt(1)
    end
  end
end

TestMatrizElixir.run()
