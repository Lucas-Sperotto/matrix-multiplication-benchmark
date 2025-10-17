# ✅ TODO – Refatoração e Melhorias do Projeto de Benchmark de Matrizes

Este documento reúne todas as melhorias planejadas para o projeto, organizadas por arquivo e prioridade.  
Use como guia para refatoração, padronização, otimização e documentação.

---

## 🔹 0. Padronização Geral (Aplica a todas as linguagens)

- [ ] Padronizar nomes das colunas CSV como: `N,TCS,TAM,TDM`
- [ ] Python não mede TDM → registrar `0.0` para manter consistência
- [ ] Padronizar nomes de arquivos com/sem otimização:  
      Ex: `resultado_c.csv`, `resultado_c_O3.csv`, etc.
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
- [ ] Remover dependência de `argc` para sufixo `_O3`
- [ ] Usar macro `-DO3_BUILD` ou flag `--o3` para indicar otimização
- [ ] Reduzir verificação para **amostragem ou checksum**
- [ ] (Opcional) Modularizar código em funções auxiliares
- [ ] (Opcional) Usar paralelismo (OpenMP, std::thread) em versão futura

---

## 🔹 3. Arquivo: `matriz_python.py` ✅ PRIORIDADE ALTA

- [ ] **Corrigir bug:** função `linear()` usa `Npts` em vez de `npts`
- [ ] Trocar `time.time()` por `time.perf_counter()` (melhor resolução)
- [ ] Padronizar cabeçalho `"N,TCS,TAM,TDM"` (TDM = 0.0)
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
- [ ] Padronizar nomenclatura de arquivos `_O3` sem depender de `argc` no binário
- [ ] Adicionar opção `--venv` para criar ambiente Python isolado
- [ ] Instalar dependências Python usando `requirements.txt` ao invés de `pip install` direto
- [ ] Criar `run_manifest.json` com:
    - B, Npts, M, escala,
    - data/hora da execução,
    - hash do commit
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
- [ ] Avaliar impacto de tipos (int vs float vs double)
- [ ] Implementar paralelismo em C/C++ (OpenMP) e Java (Threads)
- [ ] Medir consumo de energia (perf, RAPL, nvidia-smi)
- [ ] Consolidar todos os resultados em um único CSV/JSON final
- [ ] Criar script de análise estatística (média, desvio, boxplot)
- [ ] Gerar relatório final automático (Markdown ou PDF)

---

✅ FIM DO TODO
