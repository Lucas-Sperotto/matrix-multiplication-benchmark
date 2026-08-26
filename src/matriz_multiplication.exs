# Projeto: Benchmark de Multiplicação de Matrizes
# Descrição: Multiplicação de duas matrizes N x N em Elixir/Erlang padrão
#            (sem Hex, sem paralelismo, sem biblioteca de álgebra linear),
#            medindo tempo de alocação/inicialização (TAM) e cálculo (TCS).
#            TDM é sempre 0.0: BEAM gerencia memória automaticamente.
#
# Linguagem: Elixir
#
# Parâmetros (CLI): B Npts M Escala out_csv
#  - B: tamanho máximo da matriz; N varia de 100 até B
#  - Npts: número de pontos na escala (2 a 10000)
#  - M: repetições medidas para calcular a média (1 a 100000)
#  - Escala: 0=logarítmica, 1=linear
#  - out_csv: caminho do arquivo CSV de saída
#
# Representação da matriz — comparação feita antes de implementar:
#  1. Listas encadeadas: acesso a um índice arbitrário é O(N); indexar uma
#     matriz N x N como lista-de-listas via `Enum.at/2` tornaria o próprio
#     `multiply` O(N^5), não O(N^3) — mudaria a complexidade do algoritmo,
#     não apenas o estilo. Descartada para o acesso aleatório do laço quente.
#  2. Tuplas aninhadas (tupla de tuplas-linha): leitura O(1) via `elem/2`
#     (tuplas Erlang são blocos contíguos, como um array), mas `put_elem/3`
#     copia a tupla inteira a cada atualização — inicializar célula a célula
#     custaria O(N) por célula, ou seja, O(N^3) só para inicializar uma
#     matriz N x N (deveria ser O(N^2)). Descartada para inicialização.
#  3. `:array` do Erlang: apesar do nome, é uma árvore (não um bloco
#     contíguo); leitura/escrita são O(log N), não O(1). Menos comparável a
#     C/C++/Java/Python/Rust/Julia (todos O(1) por acesso) que uma tupla.
#  4. Tupla plana única de N*N elementos, indexada por `i*N+j` (o mesmo
#     esquema de indexação exigido para o Rust em EXTRA_LANGUAGES.md),
#     construída UMA VEZ a partir de uma lista (construção O(N) por
#     comprehension, sem custo de append) e congelada com
#     `List.to_tuple/1` (O(N) para converter). Dá leitura O(1) (igual às
#     demais linguagens) e construção O(N^2) total (igual às demais
#     linguagens), sem nunca mutar uma tupla já construída.
#
# Escolhida a opção 4: é a única que preserva tanto a complexidade de
# acesso O(1) quanto a complexidade de construção O(N^2)/O(N^3) das outras
# seis implementações, e usa a mesma convenção i*N+j do Rust, maximizando
# comparabilidade sem alterar o algoritmo (mesmos três laços i, j, k).
#
# Contrato completo em EXTRA_LANGUAGES.md.

defmodule ContractError do
  defexception [:message]
end

defmodule MatrizElixir do
  @min_b 100
  @max_b 100_000
  @min_npts 2
  @max_npts 10_000
  @min_m 1
  @max_m 100_000
  @min_escala 0
  @max_escala 1
  @base_a 100.0

  defp parse_int(text, name, min_value, max_value) do
    case Integer.parse(text) do
      {value, ""} when value >= min_value and value <= max_value ->
        value

      _ ->
        raise ContractError, message: "Parametro invalido para #{name}: #{text}"
    end
  end

  # Mesma regra de arredondamento usada em matriz_c.c/matriz_cpp.cpp/
  # matriz_java.java/matriz_rust.rs/src/matriz_Julia.jl e corrigida em
  # matriz_python.py: metade-para-cima via floor(x + 0.5). `i` percorre o
  # indice logico (0-based) da formula, nao um indice de estrutura.
  defp make_points(b, npts, escala) do
    if escala == 1 do
      step = (b - @base_a) / (npts - 1)
      for i <- 0..(npts - 1), do: floor(@base_a + step * i + 0.5)
    else
      ratio = :math.pow(b / @base_a, 1.0 / (npts - 1))
      for i <- 0..(npts - 1), do: floor(@base_a * :math.pow(ratio, i) + 0.5)
    end
  end

  # Tupla plana N*N, indexada i*n+j (ver comparacao no cabecalho do arquivo).
  # Construida via comprehension (O(N^2), i outer/j inner garante ordem
  # row-major) e congelada uma unica vez com List.to_tuple/1: nunca ha
  # put_elem/3 (que copiaria a estrutura inteira a cada chamada).
  defp build_matrix(n, value_fun) do
    list = for i <- 0..(n - 1), j <- 0..(n - 1), do: value_fun.(i, j)
    List.to_tuple(list)
  end

  defp dot_product(mat1, mat2, i, j, n) do
    Enum.reduce(0..(n - 1), 0, fn k, acc ->
      acc + elem(mat1, i * n + k) * elem(mat2, k * n + j)
    end)
  end

  # Multiplicacao manual O(N^3): tres lacos explicitos i, j, k (o laco k via
  # Enum.reduce dentro de dot_product), sem `Kernel.*` de matrizes, sem
  # `LinearAlgebra` (nao existe na biblioteca padrao do Elixir/Erlang de
  # qualquer forma) e sem paralelismo. `res` so passa a existir quando a
  # comprehension termina: em Elixir/BEAM nao ha estrutura mutavel para
  # "reservar espaco" antes de calcular os valores, entao alocacao e calculo
  # do resultado sao inseparaveis aqui — por isso ficam inteiramente dentro
  # de TCS, nao de TAM (unica divergencia do texto do contrato compartilhado,
  # motivada pela imutabilidade da linguagem; ver relatorio do PR).
  defp multiply(mat1, mat2, n) do
    list = for i <- 0..(n - 1), j <- 0..(n - 1), do: dot_product(mat1, mat2, i, j, n)
    List.to_tuple(list)
  end

  # `idxs` sao indices logicos 0-based (0, N/2, N-1), como no contrato.
  defp verify_sample(res, n) do
    idxs = [0, div(n, 2), n - 1]

    for i <- idxs, j <- idxs do
      expected = i + j
      actual = elem(res, i * n + j)

      if actual != expected do
        raise ContractError, message: "Erro na multiplicacao para N=#{n} em [#{i},#{j}]"
      end
    end

    :ok
  end

  defp run_once(n) do
    start_alloc = System.monotonic_time()
    mat1 = build_matrix(n, fn i, j -> i + j end)
    mat2 = build_matrix(n, fn i, j -> if i == j, do: 1, else: 0 end)

    alloc_time =
      System.convert_time_unit(System.monotonic_time() - start_alloc, :native, :nanosecond) /
        1.0e9

    start_calc = System.monotonic_time()
    res = multiply(mat1, mat2, n)

    calc_time =
      System.convert_time_unit(System.monotonic_time() - start_calc, :native, :nanosecond) / 1.0e9

    verify_sample(res, n)

    # TDM = 0.0: BEAM gerencia memoria automaticamente via GC geracional,
    # sem liberacao explicita. Nenhuma coleta e forcada em lugar nenhum do
    # arquivo (nem aqui, nem em TCS/TAM): forcar :erlang.garbage_collect/0
    # inflaria e desestabilizaria artificialmente uma metrica que deve ser
    # constante.
    {calc_time, alloc_time, 0.0}
  end

  defp run(args) do
    if length(args) != 5 do
      raise ContractError,
        message:
          "Uso: elixir matriz_multiplication.exs <B> <Npts> <M> <Escala> <out_csv>\n" <>
            "Exemplo: elixir matriz_multiplication.exs 4000 12 5 1 out/execucao/resultado_elixir.csv"
    end

    [b_text, npts_text, m_text, escala_text, out_csv] = args

    b = parse_int(b_text, "B", @min_b, @max_b)
    npts = parse_int(npts_text, "Npts", @min_npts, @max_npts)
    m_count = parse_int(m_text, "M", @min_m, @max_m)
    escala = parse_int(escala_text, "Escala", @min_escala, @max_escala)

    parent = Path.dirname(out_csv)

    if parent != "" and parent != "." do
      File.mkdir_p!(parent)
    end

    points = make_points(b, npts, escala)

    File.open!(out_csv, [:write], fn file ->
      IO.write(file, "N,TCS,TAM,TDM\n")

      Enum.each(points, fn n ->
        # Warm-up descartado: tambem aciona a compilacao JIT do BeamAsm (OTP
        # >= 24) para as funcoes deste modulo. O BeamAsm compila o modulo
        # inteiro para codigo nativo no carregamento, antes de main/1 rodar
        # qualquer laco — diferente do JIT por-metodo do Java ou da
        # especializacao por-tipo do Julia, aqui nao ha recompilacao a cada N;
        # o warm-up por N ainda remove efeitos de cache/alocador na primeira
        # chamada, mas nao existe uma segunda rodada de compilacao a evitar.
        run_once(n)

        {sum_calc, sum_alloc, sum_free} =
          Enum.reduce(1..m_count, {0.0, 0.0, 0.0}, fn _, {sc, sa, sf} ->
            {calc, alloc, free} = run_once(n)
            {sc + calc, sa + alloc, sf + free}
          end)

        m = m_count * 1.0

        line =
          :io_lib.format("~b,~.7e,~.7e,~.7e~n", [n, sum_calc / m, sum_alloc / m, sum_free / m])

        IO.write(file, line)
        IO.puts("Resultados para N = #{n} salvos.")
      end)
    end)

    IO.puts("Todos os resultados foram salvos em #{out_csv}.")
    :ok
  end

  def main(args) do
    try do
      run(args)
      System.halt(0)
    rescue
      e in ContractError ->
        IO.puts(:stderr, e.message)
        System.halt(1)

      e ->
        IO.puts(:stderr, Exception.message(e))
        System.halt(1)
    end
  end
end

MatrizElixir.main(System.argv())
