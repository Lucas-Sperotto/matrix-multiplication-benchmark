# Aceite técnico — Benchmark Julia

Data: 2026-08-26
Branch de origem: `feat/julia-benchmark`
Branch de destino: `tcc-lic-thassio`

## Contexto

A implementação Julia foi desenvolvida e validada após Rust. O commit principal (`62ddf2515867864842ab3fec7546c313b977a2eb`) já havia sido sincronizado com `tcc-lic-thassio` antes da formalização do Pull Request. O GitHub, portanto, não permite recriar retroativamente o diff original sem reescrever histórico.

Este documento registra o aceite técnico da etapa Julia de forma auditável, sem alterar o histórico já consolidado.

## Implementação aceita

- contrato CLI `B Npts M escala out_csv`;
- CSV `N,TCS,TAM,TDM`;
- geração de pontos N com arredondamento metade-para-cima;
- multiplicação manual O(N³), sem BLAS ou multiplicação matricial pronta;
- `Matrix` nativo e indexação Julia 1-based mapeada para os índices lógicos 0-based do experimento;
- temporização com `time_ns()`;
- warm-up por N e M repetições;
- validação amostral em nove posições fora de TCS;
- `TDM=0.0`, sem GC forçado;
- `@inbounds` no laço quente, com validação adicional usando `--check-bounds=yes`;
- promoção da implementação validada para `src/`.

## Validação realizada

- execução manual `144 3 1 1`;
- `scripts/test_extra_language.py` completo;
- repetição do harness com `julia --check-bounds=yes`;
- caso regressivo `B=101 Npts=3 escala=1` com `N=[100,101,101]`;
- comparação da série N com C/Python;
- análise de JIT/especialização, bounds-check, layout de memória e GC;
- `git diff --check`.

## Decisões metodológicas

Julia utiliza armazenamento column-major. A ordem de laços `i,j,k` foi mantida para preservar a equivalência algorítmica com as demais linguagens, mesmo não sendo a ordem mais favorável à localidade de cache do layout nativo Julia.

O uso de `@inbounds` foi mantido após verificação explícita dos acessos. O GC automático pode participar significativamente de TAM sob pressão de alocação, e esse custo não deve ser interpretado como equivalente estrito ao custo de alocação manual de C/C++/Rust.

A escolha do tipo elementar deve ser explicitamente registrada antes dos experimentos finais. Em plataformas 64-bit, `Int` normalmente possui 64 bits, enquanto C/C++/Java/Rust usam elementos de 32 bits nas implementações atuais. Deve-se avaliar `Matrix{Int32}` ou justificar a manutenção de `Matrix{Int}` e tratar seu impacto em memória/cache como ameaça à validade.

## Pendências para a integração/metodologia

- verificar e decidir formalmente `Int` versus `Int32` antes da execução experimental final;
- documentar layout column-major e ordem de laços;
- registrar o efeito de GC em TAM;
- preservar no manifesto a versão de Julia usada;
- manter o harness comum como gate;
- documentar diferenças de JIT, GC, tipo numérico e layout nas ameaças à validade.

## Resultado do aceite

A implementação Julia é considerada apta para a fase de integração, condicionada à decisão explícita sobre largura do tipo elementar e ao registro das diferenças metodológicas acima.
