#!/usr/bin/env julia
#=**********************************************************************
 * Projeto: Benchmark de Multiplicação de Matrizes
 * Descrição: Multiplicação de duas matrizes N x N em Julia puro (apenas
 *            biblioteca padrão), medindo tempo de alocação/inicialização
 *            (TAM) e cálculo (TCS). TDM é sempre 0.0: Julia usa coleta de
 *            lixo automática, sem liberação explícita.
 *
 * Linguagem: Julia
 *
 * Autores: Lucas Kriesel Sperotto, Thassio Artur Grisolia Vaz e Silva
 * Data: 26/08/2026
 *
 * Parâmetros (CLI): B Npts M Escala out_csv
 *  - B: tamanho máximo da matriz; N varia de 100 até B
 *  - Npts: número de pontos na escala (2 a 10000)
 *  - M: repetições medidas para calcular a média (1 a 100000)
 *  - Escala: 0=logarítmica, 1=linear
 *  - out_csv: caminho do arquivo CSV de saída
 *
 * Contrato completo em docs/EXTRA_LANGUAGES.md.
 **********************************************************************=#

using Printf

const MIN_B = 100
const MAX_B = 100_000
const MIN_NPTS = 2
const MAX_NPTS = 10_000
const MIN_M = 1
const MAX_M = 100_000
const MIN_ESCALA = 0
const MAX_ESCALA = 1
const BASE_A = 100.0

struct ContractError <: Exception
    message::String
end

Base.showerror(io::IO, e::ContractError) = print(io, e.message)

function parse_int(text::AbstractString, name::AbstractString, min_value::Int, max_value::Int)::Int
    value = tryparse(Int, text)
    if value === nothing || value < min_value || value > max_value
        throw(ContractError("Parametro invalido para $name: $text"))
    end
    return value
end

# Mesma regra de arredondamento usada em matriz_c.c/matriz_cpp.cpp/matriz_java.java/
# matriz_rust.rs e corrigida em matriz_python.py: metade-para-cima via floor(x + 0.5).
# `i` percorre o indice logico (0-based) da formula, nao um indice de array.
function make_points(b::Int, npts::Int, escala::Int)::Vector{Int}
    points = Vector{Int}(undef, npts)
    if escala == 1
        step = (Float64(b) - BASE_A) / (npts - 1)
        for i in 0:(npts - 1)
            points[i + 1] = floor(Int, BASE_A + step * i + 0.5)
        end
    else
        ratio = (Float64(b) / BASE_A)^(1.0 / (npts - 1))
        for i in 0:(npts - 1)
            points[i + 1] = floor(Int, BASE_A * ratio^i + 0.5)
        end
    end
    return points
end

# Multiplicacao manual O(N^3), tres lacos, sem `*` de matrizes, sem
# LinearAlgebra.mul! e sem BLAS. `@inbounds` remove a checagem de limites do
# laco quente: os indices i, j, k sempre percorrem 1:n e mat1/mat2/res sao
# sempre matrizes n x n (alocadas com essa mesma dimensao em run_once), entao
# os acessos sao seguros por construcao. Sem isso, a checagem de limites do
# Julia custaria uma fracao substancial de TCS sem equivalente no C/C++/Rust
# (ver M1 na revisao de codigo do Rust, medido empiricamente em ~40%).
#
# Elementos em Int32 (32 bits), igual a C/C++/Java/Rust: `acc` e' declarado
# explicitamente como Int32(0), nao como o literal `0` (que Julia infere como
# Int nativo, 64 bits nas plataformas 64-bit). Sem essa anotacao, `acc` seria
# Int e cada `mat1[i,k]*mat2[k,j]` (Int32) seria promovido implicitamente para
# a largura nativa na soma, reintroduzindo essa largura pela porta dos fundos
# mesmo com mat1/mat2/res em Int32. Indices i, j, k e n permanecem Int (nao
# ha motivo para estreitar contadores/dimensoes).
function multiply!(res::Matrix{Int32}, mat1::Matrix{Int32}, mat2::Matrix{Int32}, n::Int)
    @inbounds for i in 1:n
        for j in 1:n
            acc = Int32(0)
            for k in 1:n
                acc += mat1[i, k] * mat2[k, j]
            end
            res[i, j] = acc
        end
    end
    return nothing
end

# `idxs` sao indices logicos 0-based (0, N/2, N-1), como no contrato, do tipo
# Int (indices nao sao estreitados para Int32). O acesso ao array Julia
# (1-based) usa `idx + 1`; o valor esperado usa os indices logicos
# diretamente, sem deslocamento, igual as demais linguagens. A comparacao
# `actual != expected` mistura Int32 (actual) e Int (expected) sem problema:
# Julia promove apenas para a comparacao, sem afetar o tipo armazenado.
function verify_sample(res::Matrix{Int32}, n::Int)
    idxs = (0, n ÷ 2, n - 1)
    for i in idxs
        for j in idxs
            expected = i + j
            actual = res[i + 1, j + 1]
            if actual != expected
                throw(ContractError("Erro na multiplicacao para N=$n em [$i,$j]"))
            end
        end
    end
    return nothing
end

struct Times
    calc::Float64
    alloc::Float64
    free::Float64
end

function run_once(n::Int)::Times
    start_alloc = time_ns()
    # `undef` para mat1/mat2: cada elemento e sobrescrito uma unica vez no
    # laco abaixo, sem zerar antes (evita a dupla escrita identificada como
    # achado M2 na revisao do Rust). `res` nasce zerado com `zeros`, exigido
    # pelo contrato ("TAM: alocacao e inicializacao... do resultado"); e
    # reescrito por completo depois, na janela de TCS, por multiply!.
    # Elementos em Int32; conversoes explicitas na inicializacao evitam
    # depender da conversao implicita de setindex! e deixam o tipo visivel.
    mat1 = Matrix{Int32}(undef, n, n)
    mat2 = Matrix{Int32}(undef, n, n)
    res = zeros(Int32, n, n)
    @inbounds for i in 1:n
        for j in 1:n
            mat1[i, j] = Int32((i - 1) + (j - 1))
            mat2[i, j] = i == j ? Int32(1) : Int32(0)
        end
    end
    alloc_time = (time_ns() - start_alloc) / 1.0e9

    start_calc = time_ns()
    multiply!(res, mat1, mat2, n)
    calc_time = (time_ns() - start_calc) / 1.0e9

    verify_sample(res, n)

    # TDM = 0.0: Julia gerencia memoria automaticamente via GC, sem liberacao
    # explicita. Nao ha coleta forcada (GC.gc()) em lugar nenhum: forcar uma
    # coleta sincrona aqui inflaria e desestabilizaria artificialmente uma
    # metrica que deve ser constante.
    return Times(calc_time, alloc_time, 0.0)
end

function run(args::Vector{String})
    if length(args) != 5
        throw(ContractError(
            "Uso: julia matriz_Julia.jl <B> <Npts> <M> <Escala> <out_csv>\n" *
            "Exemplo: julia matriz_Julia.jl 4000 12 5 1 out/execucao/resultado_julia.csv",
        ))
    end

    b = parse_int(args[1], "B", MIN_B, MAX_B)
    npts = parse_int(args[2], "Npts", MIN_NPTS, MAX_NPTS)
    m_count = parse_int(args[3], "M", MIN_M, MAX_M)
    escala = parse_int(args[4], "Escala", MIN_ESCALA, MAX_ESCALA)
    out_csv = args[5]

    parent = dirname(out_csv)
    if !isempty(parent)
        mkpath(parent)
    end

    points = make_points(b, npts, escala)

    open(out_csv, "w") do file
        println(file, "N,TCS,TAM,TDM")
        for n in points
            run_once(n) # warm-up descartado; tambem aciona a compilacao JIT
            # de run_once/multiply!/verify_sample para o tipo Int, reutilizada
            # sem custo adicional pelos demais N (Julia especializa por
            # assinatura de tipo, nao por valor).

            sum_calc = 0.0
            sum_alloc = 0.0
            sum_free = 0.0
            for _ in 1:m_count
                times = run_once(n)
                sum_calc += times.calc
                sum_alloc += times.alloc
                sum_free += times.free
            end

            @printf(file, "%d,%.6e,%.6e,%.6e\n", n, sum_calc / m_count, sum_alloc / m_count, sum_free / m_count)
            println("Resultados para N = $n salvos.")
        end
    end

    println("Todos os resultados foram salvos em $out_csv.")
    return nothing
end

function main()
    try
        run(ARGS)
    catch e
        if e isa ContractError
            println(stderr, e.message)
        else
            println(stderr, sprint(showerror, e))
        end
        exit(1)
    end
    exit(0)
end

# Guarda padrao do Julia: so dispara main() quando este arquivo e' executado
# diretamente (`julia matriz_Julia.jl ...`), nao quando e' apenas incluido via
# `include(...)` por outro script (ex.: tests/test_matriz_julia.jl, que reusa
# multiply!/verify_sample sem acionar a CLI). Nao altera o comportamento de
# nenhuma invocacao real do benchmark.
if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
