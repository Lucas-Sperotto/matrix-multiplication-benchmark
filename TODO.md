# TODO – Benchmark de Multiplicação de Matrizes

Guia de melhorias, correções e próximas fases. Organizado por arquivo e prioridade.
Última revisão completa: 2026-04-25. Trilha de linguagens extras preparada em 2026-08-25.

---

## Trilha `tcc-lic-thassio` — Rust, Julia e Elixir

O objetivo desta branch é preparar o contrato, os testes e o fluxo de colaboração. Os protótipos em `experiments/` ainda não são implementações aceitas. O plano detalhado está em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

Infraestrutura de contribuição:

- [x] Documentar o fork com `origin` do aluno e `upstream/tcc-lic-thassio` como base.
- [x] Definir branches e PRs separados: `feat/rust-benchmark`, `feat/julia-benchmark`, `feat/elixir-benchmark`.
- [x] Fixar o contrato `B Npts M escala out_csv` e o CSV `N,TCS,TAM,TDM`.
- [x] Adicionar diagnóstico das toolchains em `scripts/check_extra_toolchains.sh`.
- [x] Adicionar o harness isolado `scripts/test_extra_language.py`.
- [x] Preparar o validador para CSVs extras declarados no manifesto, preservando os seis CSVs principais obrigatórios.
- [x] Preparar o plotador para reconhecer Rust, Julia e Elixir quando os CSVs estiverem presentes.
- [x] Adicionar template de Pull Request com o checklist da trilha.

Implementações, obrigatoriamente nesta ordem:

- [ ] **Rust:** adaptar `experiments/matriz_rust.rs`, usar `Vec<i32>` plano, `Instant`, `drop` medido em `TDM`, warm-up e validação amostral; passar no harness.
- [ ] **Julia:** adaptar `experiments/matriz_Julia.jl`, preservar os valores lógicos com indexação 1-based, usar `time_ns()`, registrar `TDM=0.0`, fazer warm-up e passar no harness.
- [ ] **Elixir:** reescrever `experiments/matriz_multiplication.exs`, escolher acesso indexado previsível, usar `System.monotonic_time/0`, registrar `TDM=0.0`, fazer warm-up e passar no harness.

Aceite e integração:

- [ ] Promover cada arquivo de `experiments/` para `src/` somente após aceite explícito do mantenedor e repetir o harness no novo caminho.
- [ ] Depois dos três PRs, avaliar um PR separado `feat/extra-languages-integration`.
- [ ] Se aprovado, tornar as novas linguagens opcionais nos runners e registrar toolchains/saídas no manifesto.
- [ ] Confirmar o validador e os gráficos opcionais no fluxo completo depois que as implementações existirem.
- [ ] Manter C, C++, Java e Python executáveis e validáveis quando nenhuma toolchain extra estiver instalada.

---

## Revisão de código — 2026-04-25 (completa)

### Bugs corrigidos nesta revisão

- [x] **`src/matriz_python.py`** — shebang `#!/usr/bin/env python3` estava na linha 27; movido para linha 1.
      Efeito do bug: `./src/matriz_python.py` falha ao ser executado diretamente (kernel ignora shebang fora da linha 1).
- [x] **`requirements.txt`** — `pandas` e `psutil` listados como dependências mas nenhum é usado por `src/` ou `scripts/`.
      Mantido apenas `matplotlib>=3.6`. Instalar pandas (~60 MB) sem necessidade confundia usuários novos.
- [x] **`src/plot_benchmarks.py`** — título do gráfico "C vs C++" enganoso quando o plot usa `C_O3` vs `C++_O3`.
      Corrigido: o título agora reflete quais variantes estão sendo comparadas ("C -O3 vs C++ -O3").

### Bugs conhecidos — a corrigir

- [x] **`experiments/teste.py`** — `linear()` não depende mais de `Npts` global; o arquivo foi reescrito com validação antes da abertura do CSV, `time.perf_counter()` e cabeçalho `N,TCS,TAM,TDM`.
- [x] **`experiments/matriz_c_blas.c`** — `cblas_dgemm` agora recebe buffers `double *` contíguos.
- [x] **`experiments/matriz_c_blas.c`** — argumentos são validados antes de abrir o arquivo de saída.
- [x] **`experiments/matriz_c_blas.c`** — `fopen` é checado antes de qualquer `fprintf`.

### Achados gerais — qualidade e consistência

- [x] **Comentários de cabeçalho desatualizados** em todos os arquivos de `src/` diziam "N varia de 10 até 10.000".
      O mínimo real é 100 (enforced por `parse_int`). Atualizado para "N varia de 100 até B".
- [x] **`experiments/teste.py`** — arquivo experimental com múltiplos problemas; reescrito antes de qualquer promoção a `src/`:
      - `linear()` deixou de usar variável global
      - `time.time()` foi substituído por `time.perf_counter()`
      - `np.dot` e `psutil` foram removidos para evitar dependências externas nesse experimento
      - Abertura do arquivo de saída passou a ocorrer após validação dos argumentos
      - Código morto foi removido
      - Cabeçalho CSV agora é `"N,TCS,TAM,TDM"`
- [ ] **`experiments/matriz_rust.rs`** — usa `Vec<Vec<i32>>` (não contíguo), valores de N fixos e saída `.dat` fora do contrato CSV; seguir a etapa Rust de `EXTRA_LANGUAGES.md`.
- [ ] **`experiments/matriz_Julia.jl`** — usa `Dates.now()` com resolução inadequada e conversão incorreta para segundos, além de saída `.dat`; seguir a etapa Julia de `EXTRA_LANGUAGES.md`.
- [ ] **`experiments/matriz_multiplication.exs`** — referencia resultado fora de escopo, usa acesso incompatível com listas e saída `.dat`; reescrever conforme a etapa Elixir de `EXTRA_LANGUAGES.md`.
- [x] **`build/` não aparece rastreado no índice atual** (`git ls-files build` retorna vazio). Nada a desrastrear nesta revisão.
- [ ] **`out/teste/`** parece ser execução local temporária que não deveria estar no histórico. Avaliar remoção.
- [x] **`run_all.sh`** usa flags de aviso na compilação (`-Wall -Wextra`).
- [x] **`run_all.sh` e `run_all.ps1`** especificam padrão da linguagem (`-std=c11`, `-std=c++17`).
- [x] **Java usa `int[][]`** (array de arrays, não contíguo). Documentado na metodologia.
- [x] **Sem warm-up** antes de medir. Corrigido com 1 rodada não cronometrada antes do loop de M repetições.

---

## MVP publicável — status 2026-04-25

- [x] Fluxo principal: C, C++, Java, Python com contrato comum `B Npts M escala out_csv`.
- [x] CSVs com cabeçalho comum: `N,TCS,TAM,TDM`.
- [x] C/C++ geram executáveis em `build/linux/`; Java compila em `build/java/`.
- [x] `run_all.sh` com modo interativo e `--batch`.
- [x] `run_all.ps1` alinhado ao mesmo contrato no Windows.
- [x] Resultados em `out/<run_id>/`.
- [x] `run_manifest.json`, `system_info.md` e `system_info.json` gerados por execução.
- [x] `scripts/validate_run.py` valida CSVs, metadados e gráficos.
- [x] `src/plot_benchmarks.py` sem dependência de pandas, apenas matplotlib.
- [x] Shebang em `src/matriz_python.py` na linha 1.
- [x] `requirements.txt` contém apenas dependências reais (`matplotlib`).
- [x] Título do gráfico "C vs C++" reflete as variantes reais (-O3 quando disponível).
- [ ] `run_all.ps1` não foi executado neste ambiente (sem `pwsh`). Validar em Windows antes de divulgar.

Itens fora do MVP (experimentos):

- [ ] Implementar Rust, Julia e Elixir em três PRs separados e promover a `src/` somente após aceite.
- [ ] Avaliar a integração opcional dessas linguagens ao runner, manifesto, validador e gráficos em um quarto PR.
- [x] Corrigir `experiments/matriz_c_blas.c` (bugs acima) antes de adicionar ao fluxo público.
- [ ] Adicionar variante NumPy em Python para comparação justa de desempenho.

---

## 0. Padronização Geral

- [x] Colunas CSV: `N,TCS,TAM,TDM`
- [x] Python e Java registram `TDM=0.0`
- [x] Nomes de arquivo: `resultado_c.csv`, `resultado_c_O3.csv`, etc.
- [x] Contrato CLI: `<B> <Npts> <M> <escala> <out_csv>`
- [x] Validação de argumentos de entrada em todas as linguagens
- [x] Adicionar **warm-up** (1 rodada não cronometrada antes das M repetições)
- [x] Documentar metodologia: o que é TCS, TAM, TDM; por que M repetições; por que warm-up
- [x] Flags de compilação padrão: `-std=c11`, `-std=c++17`

---

## 1. `src/matriz_c.c`

**Estado atual:** bom. Alocação 1D contígua, `CLOCK_MONOTONIC`, overflow check, `verify_sample` por amostragem.

- [x] Atualizar comentário de cabeçalho: "N varia de 100 até B" (não "de 10 até 10.000")
- [x] Adicionar warm-up antes do loop de M
- [x] Adicionar `-std=c11 -Wall -Wextra` na compilação (em `run_all.sh`)
- [ ] (Opcional) Separar explicitamente inicialização de alocação no TAM para clareza metodológica

---

## 2. `src/matriz_cpp.cpp`

**Estado atual:** bom. `std::chrono::steady_clock`, `std::vector<int>` plano, tratamento de exceções.

- [x] Atualizar comentário de cabeçalho: "N varia de 100 até B"
- [x] Adicionar warm-up antes do loop de M
- [x] Adicionar `-std=c++17 -Wall -Wextra` na compilação (em `run_all.sh`)
- [ ] (Opcional) Substituir `std::vector<int>().swap(mat1)` por `mat1 = {}` — mais legível, mesmo efeito

---

## 3. `src/matriz_java.java`

**Estado atual:** bom. `System.nanoTime()`, `Locale.US`, `Files.createDirectories`, TDM=0.0 consistente.

- [x] Atualizar comentário de cabeçalho: "N varia de 100 até B"
- [x] Adicionar warm-up antes do loop de M (crítico: JIT não otimizado na primeira chamada)
- [x] Documentar que `int[][]` é array de arrays (não contíguo) — comportamento padrão Java, não bug
- [ ] (Opcional) Renomear classe para `MatrizJava` seguindo convenção Java (requer renomear arquivo)

---

## 4. `src/matriz_python.py`

**Estado atual:** bom após correção do shebang. `time.perf_counter()`, `csv.writer`, `Path`, sem dependências externas.

- [x] Shebang na linha 1
- [x] Atualizar comentário de cabeçalho: "N varia de 100 até B"
- [x] Adicionar warm-up antes do loop de M
- [ ] (Opcional) Variante com NumPy para comparação (`experiments/matriz_numpy.py`)

---

## 5. `src/plot_benchmarks.py`

**Estado atual:** funcional. Gera 4 grupos de gráficos, lida com CSVs faltantes.

- [x] Título do gráfico "C vs C++" reflete variantes reais
- [x] Adicionar flags `--logx` / `--logy` para escalas logarítmicas nos eixos
- [x] Gráfico adicional: "C e C++ sem otimização" (somente `C` e `C++`, sem `_O3`)
- [x] Aceitar lista de linguagens a excluir via argumento: `--exclude Python`

---

## 6. `run_all.sh`

**Estado atual:** bom. `set -euo pipefail`, `--batch`, validação, manifest, validação pós-execução.

- [x] Adicionar `-std=c11` e `-Wall -Wextra` nas invocações de `gcc`
- [x] Adicionar `-std=c++17` e `-Wall -Wextra` nas invocações de `g++`
- [x] O cache matplotlib em `check_python_runtime` usa `$ROOT_DIR/.cache/matplotlib`; o gerador de gráficos usa `out_dir/.matplotlib`. Unificado para `.cache/matplotlib`.

---

## 7. `scripts/validate_run.py`

**Estado atual:** sólido. Valida CSVs, cabeçalhos, tipos, metadados, PNGs.

- [x] Adicionar check de NaN/Inf nos valores float dos CSVs
- [x] Validar que N é monotonicamente não decrescente nas linhas

---

## 8. `scripts/gen_sysinfo_md.sh`

**Estado atual:** bom. Detecta WSL, captura info via PowerShell, gera `.md` e `.json`.

- [ ] Verificar compatibilidade do `date -Iseconds` em macOS (GNU vs BSD date)

---

## 9. `experiments/` — itens antes de promover ao fluxo principal

- [x] `teste.py` — corrigir bug em `linear()` (usa `Npts` global), remover código morto, trocar `time.time()` por `time.perf_counter()`, adicionar coluna TDM
- [x] `matriz_c_blas.c` — corrigir tipo das matrizes (`double *` contíguo), corrigir ordem de validação de argc/fopen
- [ ] `matriz_rust.rs` — adaptar ao contrato CLI/CSV, usar buffer plano, `Instant`, `drop` medido e `verify_sample`; validar com `scripts/test_extra_language.py`
- [ ] `matriz_Julia.jl` — adaptar ao contrato CLI/CSV, usar `time_ns()`, `TDM=0.0` e `verify_sample`; validar com o harness
- [ ] `matriz_multiplication.exs` — reescrever com acesso indexado válido, relógio monotônico, `TDM=0.0` e validação amostral; validar com o harness
- [ ] Promover os três arquivos para nomes padronizados em `src/` somente após aceite do respectivo PR

---

## 10. Organização do repositório

- [x] `build/` — confirmado sem arquivos rastreados no índice atual; nenhuma ação `git rm --cached` necessária nesta revisão
- [ ] Avaliar remoção de `out/teste/` do histórico se for execução local descartável
- [ ] (Opcional) Adicionar README em inglês (`README_en.md`) para ampliar alcance
- [ ] (Opcional) Adicionar GitHub Actions para smoke test automático em PRs

---

## 11. Checklist pré-publicação

- [ ] Clonar em pasta limpa e rodar `./run_all.sh --batch ...` sem arquivos pré-gerados
- [ ] Rodar `.\run_all.ps1` no Windows nativo
- [ ] Confirmar que `src/` contém apenas código-fonte
- [ ] Confirmar que `build/` não está no histórico git
- [ ] Confirmar que `out/<id>/` tem CSVs, gráficos, `system_info.md` e `run_manifest.json`
- [ ] Rodar `python3 scripts/validate_run.py out/<id>` com resultado "sucesso"

---

## 12. Extensões futuras

- [ ] Variante NumPy para Python
- [ ] Rust, Julia e Elixir no contrato comum, seguindo a ordem e os PRs de `EXTRA_LANGUAGES.md`
- [ ] BLAS (C/C++) no contrato comum — experimento C corrigido, ainda não integrado ao fluxo principal
- [ ] Paralelismo: OpenMP em C/C++, threads em Java
- [ ] Coluna de memória RSS em todos os benchmarks
- [ ] Análise estatística: desvio padrão, boxplot
- [ ] Relatório final automático em Markdown
- [ ] Medição de energia (RAPL, nvidia-smi)

---

✅ FIM DO TODO
