#!/usr/bin/env julia
# Teste de corretude (nao de desempenho) para src/matriz_Julia.jl.
#
# `include()` carrega o arquivo de producao no escopo Main sem disparar
# main(): a guarda `if abspath(PROGRAM_FILE) == abspath(@__FILE__)` em
# matriz_Julia.jl compara o script de topo (este arquivo) com o proprio
# arquivo incluido, que sao diferentes aqui. Reusa multiply!() com um
# caso conhecido nao identidade, fora da janela de benchmark.
#
# Executar (com e sem bounds-check, conforme Tarefa 1 do plano de
# estabilizacao — @inbounds no laco quente de producao so e valido se o
# resultado permanecer correto mesmo com a checagem de limites ligada):
#   julia tests/test_matriz_julia.jl
#   julia --check-bounds=yes tests/test_matriz_julia.jl

include(joinpath(@__DIR__, "..", "src", "matriz_Julia.jl"))

function test_multiply_non_identity()
    # A = [[1,2],[3,4]], B = [[5,6],[7,8]] (Int32, como em producao).
    mat1 = Int32[1 2; 3 4]
    mat2 = Int32[5 6; 7 8]
    res = zeros(Int32, 2, 2)
    expected = Int32[19 22; 43 50]

    multiply!(res, mat1, mat2, 2)

    if res != expected
        println(stderr, "FALHA: res=$res, esperado=$expected")
        exit(1)
    end

    println("OK: matriz_Julia multiply! caso nao identidade 2x2")
end

test_multiply_non_identity()
