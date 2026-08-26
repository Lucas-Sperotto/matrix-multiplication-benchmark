# Aceite técnico — Benchmark Rust

Data: 2026-08-26
Branch de origem: `feat/rust-benchmark`
Branch de destino: `tcc-lic-thassio`

## Contexto

A implementação Rust foi desenvolvida e validada antes da formalização do Pull Request. O commit da implementação (`bc6343992f1a9d568d880779a15bda756e5f9876`) já se tornou ancestral de `tcc-lic-thassio` durante a sequência de trabalho Rust → Julia → Elixir. Por esse motivo, o GitHub não permite abrir retroativamente um PR contendo novamente o diff original da implementação.

Este documento registra o aceite técnico da etapa Rust sem reescrever histórico ou reverter a branch de integração.

## Implementação aceita

- contrato CLI `B Npts M escala out_csv`;
- CSV `N,TCS,TAM,TDM`;
- geração de N com arredondamento metade-para-cima;
- `Vec<i32>` plano indexado por `i*N+j`;
- multiplicação manual O(N³), sem crates numéricas;
- `std::time::Instant` para temporização monotônica;
- warm-up por N e M repetições medidas;
- validação amostral em nove posições fora de TCS;
- `drop` explícito para TDM;
- checagem de overflow de dimensões e alocação falível;
- `black_box` fora da janela TCS para manter o resultado observável;
- promoção da implementação validada para `src/`.

## Validação realizada

- `rustfmt --check`;
- `rustc --edition=2021 -C opt-level=3 -D warnings`;
- `scripts/test_extra_language.py`;
- testes manuais do contrato e sobrescrita de CSV;
- caso regressivo `B=101 Npts=3 escala=1`, com `N=[100,101,101]`;
- comparação com C/Python para a série de N;
- `git diff --check`.

## Decisões metodológicas

O laço cúbico utiliza acesso sem bounds-check por meio de `get_unchecked`/`get_unchecked_mut`, com invariantes de segurança documentadas. Essa decisão reduz um custo específico do runtime Rust que, nos testes realizados, alterava significativamente TCS. Portanto, os resultados devem ser descritos como correspondentes a uma implementação Rust otimizada com acesso não verificado no laço quente, e não como desempenho genérico de qualquer implementação Rust segura.

## Pendências para a integração/metodologia

- registrar `unsafe/get_unchecked` em `METHODOLOGY.md` e nas ameaças à validade;
- preservar no runner as mesmas flags de compilação usadas na validação;
- manter o harness como gate da implementação;
- documentar diferenças de layout, runtime e gerenciamento de memória nas comparações cruzadas;
- não interpretar TAM/TCS/TDM como fases microarquiteturalmente idênticas entre todas as linguagens.

## Resultado do aceite

A implementação Rust é considerada apta para seguir à fase de integração dos runners, manifesto, validação e gráficos, condicionada ao tratamento documental das diferenças metodológicas acima.
