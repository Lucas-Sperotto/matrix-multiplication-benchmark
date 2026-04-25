# ✅ TODO – Refatoração e Melhorias do Projeto de Benchmark de Matrizes

Este documento reúne todas as melhorias planejadas para o projeto, organizadas por arquivo e prioridade.
Use como guia para refatoração, padronização, otimização e documentação.

---

## ✅ MVP publicável implementado — revisão de 2026-04-25

- [x] Fluxo principal limitado a C, C++, Java e Python.
- [x] Benchmarks principais aceitam contrato comum: `B Npts M escala out_csv`.
- [x] CSVs novos usam cabeçalho comum: `N,TCS,TAM,TDM`.
- [x] C/C++ geram executáveis em `build/linux/`; Java compila em `build/java/`.
- [x] `run_all.sh` possui modo interativo e modo `--batch`.
- [x] `run_all.ps1` foi alinhado ao mesmo contrato no Windows.
- [x] Resultados são escritos direto em `out/<run_id>/`.
- [x] `run_manifest.json`, `system_info.md` e `system_info.json` são gerados por execução.
- [x] `scripts/validate_run.py` valida CSVs, metadados e gráficos.
- [x] `src/gen_sysinfo_md.sh` foi movido para `scripts/gen_sysinfo_md.sh`.
- [x] Fontes experimentais fora do MVP foram movidas para `experiments/`.
- [x] Binários gerados foram removidos da raiz e de `src/`.
- [x] `.gitignore` foi revisado para ignorar `build/`, caches e execuções locais temporárias sem ignorar `out/` inteiro.
- [x] `README.md`, `EXECUTION.md` e `CONTRIBUTING.md` foram atualizados para o fluxo MVP.

### Nova verificação antes dos commits — 2026-04-25

- [x] `git diff --check` passou sem erros de whitespace.
- [x] `bash -n run_all.sh` passou.
- [x] `bash -n scripts/gen_sysinfo_md.sh` passou.
- [x] `python3 -m py_compile src/matriz_python.py src/plot_benchmarks.py scripts/validate_run.py` passou.
- [x] `gcc src/matriz_c.c -o build/linux/matriz_c_check -lm` passou.
- [x] `g++ src/matriz_cpp.cpp -o build/linux/matriz_cpp_check` passou.
- [x] `javac -d build/java src/matriz_java.java` passou.
- [x] Smoke completo passou: `./run_all.sh --batch --run-name mvp_smoke_100 --B 100 --Npts 2 --M 1 --escala 1`.
- [x] `python3 scripts/validate_run.py out/mvp_smoke_100` passou.
- [x] `python3 src/plot_benchmarks.py out/mvp_smoke_100` passou.
- [x] Não há `resultado_*.csv`, `matriz_c`, `matriz_cpp` ou `.class` fora de `build/`.
- [x] `src/` contém apenas o fluxo principal: C, C++, Java, Python e plot.
- [ ] `run_all.ps1` não foi executado neste ambiente porque não há `pwsh`/`powershell` disponível.

Itens que continuam fora do MVP:

- [ ] Integrar Rust, Julia e Elixir ao contrato comum.
- [ ] Corrigir `matriz_c_blas.c` antes de adicioná-lo ao fluxo público.
- [ ] Adicionar NumPy, paralelismo, energia, estatística avançada e relatório automático.

---

## 🔴 Avaliação geral do repositório — revisão de 2026-04-25

Objetivo desta rodada: preparar o projeto para divulgação pública, reprodução por terceiros e sincronização de resultados dentro de `out/`, mantendo `src/` apenas com código-fonte e evitando binários espalhados pela raiz ou dentro de `src/`.

### Achados objetivos

- [ ] Remover binários gerados da árvore versionada/visível:
      `matriz_c` e `matriz_cpp` aparecem na raiz como executáveis ELF;
      `src/matriz_c_blas` também é um executável ELF dentro de `src/`.
- [ ] Definir política de versionamento para `out/`:
      manter resultados aceitos/publicáveis em `out/<id_da_execucao>/`, mas separar execuções locais/testes temporários para evitar poluir o histórico.
- [ ] Padronizar `out/<id_da_execucao>/` como destino direto de CSVs, gráficos, `system_info.md` e futuro `run_manifest.json`; evitar gerar `resultado_*.csv` na raiz para depois mover.
- [ ] Corrigir divergência entre documentação e código:
      a documentação ainda cita `MatrixMultiplication.java` e arquivos `.dat`, mas o código atual usa `src/matriz_java.java` e CSVs como `resultado_java.csv`.
- [ ] Corrigir contrato dos CSVs entre linguagens:
      C/C++ escrevem `TLM`, o plot remapeia para `TDM`, Java/Python não escrevem `TDM`, e Rust/Julia/Elixir ainda usam formatos `.dat`.
- [ ] Criar `requirements.txt` ou `pyproject.toml` para dependências Python (`pandas`, `matplotlib`, `psutil`, opcionalmente `numpy`), pois o ambiente atual falhou ao gerar gráficos por falta/instalação incompleta de `pandas`.
- [ ] Evitar instalação automática com `sudo apt` dentro de `run_all.sh` no fluxo principal; para divulgação pública, preferir checagem clara + instrução de instalação ou flag explícita `--install-deps`.
- [ ] Revisar `.gitignore`: hoje ignora binários sem extensão de forma muito ampla (`**/[!.]*`), o que pode esconder arquivos válidos; ao mesmo tempo `.vscode/` já está rastreado apesar de estar no `.gitignore`.
- [ ] Definir se `bin/` será usado para executáveis finais ou wrappers. Recomendação: compilar em `build/` e reservar `bin/` apenas para comandos estáveis/distribuíveis, se necessário.
- [ ] Manter `src/` apenas com código-fonte. Scripts auxiliares de execução/coleta podem ficar em `scripts/` se a organização crescer.

### Verificações feitas nesta revisão

- [x] `bash -n run_all.sh` passou.
- [x] `bash -n scripts/gen_sysinfo_md.sh` passou.
- [x] `python3 -m py_compile src/matriz_python.py src/plot_benchmarks.py scripts/validate_run.py` passou.
- [x] Compilação leve de `src/matriz_c.c`, `src/matriz_cpp.cpp` e `src/matriz_java.java` para `build/` passou.
- [x] Execução mínima de C, C++, Java e Python com `B=100`, `Npts=2`, `M=1`, `escala=1` passou em `out/mvp_smoke_100`.
- [x] `src/plot_benchmarks.py` foi refeito sem dependência obrigatória de `pandas`, mantendo `matplotlib`.
- [ ] `experiments/matriz_c_blas.c` compila, mas com warnings graves: `cblas_dgemm` espera `double *` contíguo e o código passa `int **`.
- [ ] Rust não foi verificado porque `rustc` não está instalado neste ambiente.

### Decisões recomendadas antes de divulgar

- [ ] Estrutura-alvo:

```text
.
├─ src/                  # apenas implementações-fonte dos benchmarks
├─ scripts/              # shell/PowerShell/utilitários, se separados da raiz
├─ build/                # artefatos de compilação ignorados pelo Git
├─ experiments/          # implementações fora do fluxo publicável
├─ bin/                  # opcional: wrappers estáveis ou executáveis publicados
├─ out/                  # resultados sincronizáveis por execução
├─ docs/                 # documentação mais longa, se necessário
└─ README.md
```

- [ ] Convenção para contribuições em `out/`:
      `out/<autor_ou_id>-<maquina>-<os>-<B>-<data>/`.
- [ ] Cada pasta em `out/` deve conter, no mínimo:
      `resultado_*.csv`, `system_info.md`, `run_manifest.json` e gráficos gerados.
- [ ] `run_manifest.json` deve registrar: parâmetros (`B`, `Npts`, `M`, escala), linguagens executadas, versões dos compiladores/interpretes, flags de compilação, data/hora, sistema operacional e hash do commit.
- [ ] Criar um comando de validação pré-PR, por exemplo `./scripts/validate_run.sh out/<id>`, para conferir nomes, colunas CSV e presença de manifesto.

---

## 🔹 0. Padronização Geral (Aplica a todas as linguagens)

- [ ] Padronizar nomes das colunas CSV como: `N,TCS,TAM,TDM`
- [ ] Python não mede TDM → registrar `0.0` para manter consistência
- [ ] Java não mede desalocação manual → registrar `TDM=0.0` ou `NA` conforme contrato definido
- [ ] Trocar `TLM` por `TDM` em C, C++ e qualquer variante BLAS
- [ ] Padronizar nomes de arquivos com/sem otimização:
      Ex: `resultado_c.csv`, `resultado_c_O3.csv`, etc.
- [ ] Definir contrato único de CLI para todas as linguagens:
      `<B> <Npts> <M> <escala> <out_dir> [--variant nome]`
- [ ] Validar argumentos de entrada (`B >= 100`, `Npts >= 2`, `M >= 1`, escala em `{0,1}`) antes de executar benchmarks pesados
- [ ] Adicionar execução de **warm-up** (1 rodada não cronometrada)
- [ ] (Opcional) Fixar **semente aleatória** (se houver geração de dados)
- [ ] Adicionar coluna de **memória (RSS)** em todas as linguagens ou remover completamente psutil
- [ ] Verificação do resultado: usar **amostragem** ou **checksum simples**, não percorrer toda a matriz
- [ ] Documentar M (número de repetições) em cada execução ou em manifesto
- [ ] (Opcional) Registrar número de threads / afinidade (consistência entre execuções)

---

## 🔹 1. Arquivo: `matriz_c.c`

- [ ] Substituir alocação `int**` por **buffer contíguo (uma malloc só)**
- [ ] Implementar macro ou função de indexação: `A[i*N + j]`
- [ ] Trocar `clock()` por `clock_gettime(CLOCK_MONOTONIC)` para tempo de parede
- [ ] Ajustar cabeçalho CSV para `"N,TCS,TAM,TDM"`
- [ ] Receber caminho de saída por argumento e escrever diretamente em `out/<execucao>/resultado_c.csv`
- [ ] Remover lógica `if (argc > 5)` para detectar `_O3`
- [ ] Usar macro de compilação `-DO3_BUILD` ou flag explícita para indicar O3
- [ ] Reduzir verificação do resultado para **amostragem**
- [ ] Garantir chamada de `free()` para todos os buffers
- [ ] Opcional: separar funções (alocação, multiplicação, temporização, verificação) para legibilidade

---

## 🔹 2. Arquivo: `matriz_cpp.cpp`

- [ ] Substituir `new[]/delete[]` por `std::vector<int>` ou `std::unique_ptr<int[]>`
- [ ] Usar `<chrono>` (`std::chrono::steady_clock`) em vez de `clock()`
- [ ] Padronizar cabeçalho `"N,TCS,TAM,TDM"`
- [ ] Receber caminho de saída por argumento e escrever diretamente em `out/<execucao>/resultado_cpp.csv`
- [ ] Remover dependência de `argc` para sufixo `_O3`
- [ ] Usar macro `-DO3_BUILD` ou flag `--o3` para indicar otimização
- [ ] Reduzir verificação para **amostragem ou checksum**
- [ ] (Opcional) Modularizar código em funções auxiliares
- [ ] (Opcional) Usar paralelismo (OpenMP, std::thread) em versão futura

---

## 🔹 3. Arquivo: `matriz_python.py` ✅ PRIORIDADE ALTA

- [ ] **Finalizar correção:** função `linear()` ainda usa `range(Npts)` em vez de `range(npts)`, ficando dependente de variável global
- [ ] Trocar `time.time()` por `time.perf_counter()` (melhor resolução)
- [ ] Padronizar cabeçalho `"N,TCS,TAM,TDM"` (TDM = 0.0)
- [ ] Receber caminho de saída por argumento e escrever diretamente em `out/<execucao>/resultado_python.csv`
- [ ] Decidir uso de `psutil`:
    - [ ] Remover completamente (evitar dependência)
    - [ ] OU registrar memória no CSV (`MEM_KB`)
- [ ] (Opcional) Criar variante com NumPy (`--numpy`)
- [ ] (Opcional) Parametrizar B, npts, M via `argparse`
- [ ] (Opcional) Melhorar verificação do resultado com amostragem

---

## 🔹 4. Arquivo: `plot_benchmarks.py`

- [ ] Ajustar `detect_N_column()` para usar sempre `.lower()` nos nomes de coluna
- [ ] Remover necessidade de remapear `"TLM"` para `"TDM"` (se arquivos forem padronizados)
- [ ] Adicionar validação explícita de dependências e erro didático quando `pandas`/`matplotlib` não estiverem instalados corretamente
- [ ] Definir `MPLCONFIGDIR` em diretório gravável (`out/<execucao>/.matplotlib` ou `.cache/matplotlib`) para evitar warning de cache/config em ambientes restritos
- [ ] Adicionar **filtro genérico de exclusão** de linguagens ou versões (ex: “todas menos Python e sem O3”)
- [ ] Adicionar flags `--logx` e `--logy` para escalas logarítmicas
- [ ] Adicionar grid leve nos gráficos para melhor leitura
- [ ] Criar gráficos extras:
    - [ ] “Todas as linguagens menos Python e C/C++ sem O3”
    - [ ] (Opcional) Gráficos separados para memória (TAM/TDM)
- [ ] Garantir nomes de arquivos de saída consistentes com alias dos grupos comparados

---

## 🔹 5. Arquivo: `run_all.sh`

- [ ] Criar modo `--batch` (sem interação) e manter modo interativo atual
- [ ] Usar `pushd/popd` para garantir execução sempre na raiz do projeto
- [ ] Criar `build/` automaticamente e compilar C/C++ nele, por exemplo `build/linux/matriz_c` e `build/linux/matriz_cpp`
- [ ] Remover geração de executáveis na raiz (`./matriz_c`, `./matriz_cpp`)
- [ ] Compilar Java com `javac -d build/java src/matriz_java.java` e executar com `java -cp build/java matriz_java`
- [ ] Fazer cada linguagem escrever direto em `out/<RUN_NAME>/`, sem arquivos temporários na raiz e sem `mv resultado_*.csv`
- [ ] Padronizar nomenclatura de arquivos `_O3` sem depender de `argc` no binário
- [ ] Adicionar opção `--venv` para criar ambiente Python isolado
- [ ] Instalar dependências Python usando `requirements.txt` ao invés de `pip install` direto
- [ ] Substituir instalação automática via `sudo apt` por mensagens de pré-requisito ou por uma flag explícita `--install-deps`
- [ ] Criar `run_manifest.json` com:
    - B, Npts, M, escala,
    - data/hora da execução,
    - hash do commit
- [ ] Registrar versões de `gcc`, `g++`, `java`, `javac`, `python`, pacotes Python e flags de compilação no manifesto
- [ ] (Opcional) Copiar todos os resultados e gráficos para pasta com timestamp
- [ ] (Opcional) Permitir passar parâmetros via linha de comando (sem `read`)

---

## 🔹 6. Arquivo: `gen_sysinfo_md.sh`

- [ ] Adicionar detecção de GPU (NVIDIA / AMD / via `lspci` ou `nvidia-smi`)
- [ ] Exportar informações também em **JSON** (`system_info.json`) além do `.md`
- [ ] Garantir consistência de formato entre Linux, WSL e Windows
- [ ] (Opcional) Adicionar informações adicionais:
    - Número de núcleos e threads
    - Tamanho de cache L1/L2/L3
    - Frequência da CPU
- [ ] (Opcional) Usar comandos mais robustos para coletar dados em diferentes distros

---

## 🔹 7. Organização e Documentação

- [ ] Criar `README.md` mais detalhado:
    - Descrição do projeto
    - Objetivo dos benchmarks
    - Como compilar e executar cada linguagem
    - Como rodar `run_all.sh`
    - Estrutura do repositório
- [ ] Atualizar `EXECUTION.md` para refletir nomes reais: `src/matriz_java.java`, CSVs, `out/<RUN_NAME>/` e futura pasta `build/`
- [ ] Atualizar `CONTRIBUTING.md` com a convenção de `out/<id_da_execucao>/` e checklist mínimo para aceitar resultados
- [ ] Adicionar seção: **Metodologia de benchmark**
    - Explicar TCS, TAM, TDM
    - Justificar warm-up e repetições (M)
- [ ] Criar `CONTRIBUTING.md` com padrão de commits e branches
- [ ] Adicionar `.gitignore` completo (binários, CSVs, venv, etc.)
- [ ] Adicionar `LICENSE` (MIT ou GPL ou outra)
- [ ] (Opcional) Adicionar **diagramas ou imagens** no README
- [ ] (Opcional) Traduzir README para inglês (README_en.md)

---

## 🔹 8. Extensões Futuras (Opcional, mas recomendadas)

- [ ] Implementar versão Python com NumPy para comparação justa
- [ ] Integrar Rust, Julia e Elixir ao mesmo contrato de CLI/CSV antes de divulgá-las como suportadas
- [ ] Corrigir `experiments/matriz_c_blas.c` antes de adicioná-lo ao fluxo público, usando buffers `double *` contíguos compatíveis com BLAS
- [ ] Avaliar impacto de tipos (int vs float vs double)
- [ ] Implementar paralelismo em C/C++ (OpenMP) e Java (Threads)
- [ ] Medir consumo de energia (perf, RAPL, nvidia-smi)
- [ ] Consolidar todos os resultados em um único CSV/JSON final
- [ ] Criar script de análise estatística (média, desvio, boxplot)
- [ ] Gerar relatório final automático (Markdown ou PDF)

---

## 🔹 9. Estrutura de diretórios, `bin/`, `build/` e `src/`

- [ ] Remover da raiz os executáveis gerados localmente (`matriz_c`, `matriz_cpp`) e garantir que continuem ignorados pelo Git.
- [x] Remover `src/matriz_c_blas` do versionamento por ser binário; manter apenas `experiments/matriz_c_blas.c`.
- [ ] Criar e documentar `build/` como destino padrão de compilação local.
- [ ] Decidir papel de `bin/`:
    - [ ] Opção recomendada: `bin/` vazio ou contendo apenas wrappers estáveis, como `bin/run-benchmark`.
    - [ ] Evitar versionar executáveis compilados em `bin/` porque variam por sistema operacional e arquitetura.
- [ ] Revisar `.gitignore` para ignorar `build/`, binários compilados, caches Python e execuções temporárias, sem esconder arquivos-fonte sem extensão.
- [ ] Avaliar remoção de `.vscode/` do versionamento ou manter apenas configurações realmente portáveis.
- [ ] Se `out/` deve ser sincronizado por colaboradores, não ignorar `out/` inteiro; em vez disso, documentar quais subpastas são aceitas e quais são locais/temporárias.

---

## 🔹 10. Checklist mínimo antes de publicação

- [ ] Clonar em pasta limpa e rodar o fluxo completo sem depender de arquivos gerados previamente.
- [ ] Rodar `./run_all.sh --batch ...` em Linux/WSL e `.\run_all.ps1` no Windows.
- [ ] Confirmar que nada é criado na raiz exceto arquivos explicitamente versionados.
- [ ] Confirmar que `src/` contém apenas código-fonte.
- [ ] Confirmar que `build/` contém artefatos de compilação e é ignorado pelo Git.
- [ ] Confirmar que `out/<id>/` contém todos os CSVs, gráficos, `system_info.md` e `run_manifest.json`.
- [ ] Rodar validador de CSVs: colunas, tipos numéricos, nomes esperados e ausência de linhas vazias.
- [ ] Rodar gerador de gráficos em ambiente limpo com dependências instaladas por `requirements.txt`.
- [ ] Atualizar README com comando rápido de reprodução e exemplo de PR de resultados.

---

✅ FIM DO TODO
