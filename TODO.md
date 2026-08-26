# TODO – Benchmark de Multiplicação de Matrizes

Guia de melhorias, correções e próximas fases da trilha `tcc-lic-thassio`.

Última revisão: **2026-08-26**.

---

## 1. Estado atual da trilha `tcc-lic-thassio`

Contrato comum adotado para todas as implementações:

```text
B Npts M escala out_csv
```

CSV comum:

```text
N,TCS,TAM,TDM
```

Infraestrutura já disponível:

- [x] Contrato CLI comum documentado.
- [x] Regra de geração de N padronizada com arredondamento metade-para-cima.
- [x] Regressão para geração da série de N.
- [x] Harness isolado `scripts/test_extra_language.py`.
- [x] Casos inválidos incluindo limites inferiores, superiores e valores negativos.
- [x] `scripts/validate_run.py` confere contagem de linhas contra `Npts`.
- [x] `scripts/validate_run.py` confere consistência da série de N entre CSVs.
- [x] Plotador preparado para reconhecer Rust, Julia e Elixir quando presentes.
- [x] Diagnóstico de toolchains extras.
- [x] Template de Pull Request da trilha.
- [x] Implementação Rust validada e promovida para `src/`.
- [x] Implementação Julia validada e promovida para `src/`.
- [x] Implementação Elixir validada, promovida para `src/` e incorporada à base.

### Pull Requests da trilha

Revisar e tratar **nesta ordem**:

- [x] **PR #9 — Rust:** aceite técnico incorporado.
- [x] **PR #10 — Julia:** aceite técnico incorporado.
- [x] **PR #11 — Elixir:** implementação incorporada.

Observação histórica:

- O PR #8 de Elixir foi fechado sem merge apenas para corrigir a ordem formal dos PRs.
- Rust e Julia já haviam sido incorporados ao histórico de `tcc-lic-thassio` antes da formalização dos PRs; por isso #9 e #10 registram aceite técnico retroativo sem reescrever histórico.

---

## 2. Prioridade imediata — antes/durante o Prompt 7

### P0/P1 de contrato e execução

- [ ] **C e C++:** criar o diretório pai de `out_csv` quando ele ainda não existir, como já fazem Java/Python/Rust/Julia/Elixir.
- [ ] Adicionar regressão no harness/testes para execução com caminho de saída em diretório pai inexistente.
- [ ] Sanitizar `--run-name`/`-RunName` nos dois runners: rejeitar caminhos absolutos, separadores, `..` e caracteres fora de `[A-Za-z0-9_.-]`; adicionar regressão de path traversal.
- [ ] Definir e testar o tratamento de espaços em branco nos argumentos numéricos, hoje divergente entre Java e C/C++.
- [ ] Avaliar uma função de arredondamento explícita em C e casos-limite de ponto flutuante; preservar a política metade-para-cima e não alterar código sem um caso reproduzível de divergência.
- [ ] Manter `validate_run.py` exigindo exatamente `Npts` linhas por CSV.
- [ ] Manter `validate_run.py` exigindo a mesma série de N em todas as implementações da execução.
- [ ] Manter teste regressivo do caso `B=101 Npts=3 escala=1` → `N=[100,101,101]`.

### Corretude do algoritmo

O harness de contrato valida CLI/CSV/tempos/série N, mas não prova sozinho que a multiplicação está matematicamente correta.

- [ ] Criar testes internos pequenos de multiplicação para C, C++, Java, Python, Rust, Julia e Elixir.
- [ ] Usar matrizes pequenas conhecidas, incluindo uma matriz que **não seja identidade**, para evitar falso negativo estrutural.
- [ ] Executar esses testes fora da janela de benchmark; eles são testes de corretude, não métricas de desempenho.
- [ ] Manter a validação amostral em nove posições durante a execução como defesa adicional.

---

## 3. Recomendações metodológicas obrigatórias

### Definir claramente o objeto da comparação

Adotar explicitamente uma formulação equivalente a:

> Comparam-se implementações funcional e algoritmicamente equivalentes de multiplicação matricial manual O(N³), preservando características fundamentais de representação e runtime de cada linguagem. Não se assume equivalência microarquitetural das estruturas de dados.

- [ ] Registrar essa definição em `METHODOLOGY.md`.
- [ ] Evitar afirmar que todas as linguagens realizam operações de memória internamente idênticas.

### Métricas TAM, TCS e TDM

- [ ] Documentar que TAM/TCS/TDM têm significado operacional diferente em runtimes com GC e estruturas imutáveis.
- [ ] Não comparar TDM de C/C++/Rust diretamente com `TDM=0.0` de Java/Python/Julia/Elixir como se medissem o mesmo mecanismo.
- [ ] Avaliar uma métrica derivada para análise global:

```text
TEXEC = TAM + TCS + TDM
```

- [ ] Se `TEXEC` for adotado, manter TAM/TCS/TDM como métricas diagnósticas e declarar as limitações de GC/JIT.

### Warm-up, JIT e GC

- [ ] Preservar pelo menos um warm-up descartado por N conforme o contrato atual.
- [ ] Verificar empiricamente, por exemplo com `java -XX:+PrintCompilation`, se um warm-up por N estabiliza o JIT; documentar a limitação ou ajustar a estratégia.
- [ ] Registrar versões e características de runtime/toolchain no manifesto.
- [ ] Fixar ou declarar versões testadas de Rust e Julia, além de registrar no manifesto as versões realmente usadas.
- [ ] Documentar diferenças de JIT entre Java, Julia e BEAM.
- [ ] Não forçar GC para fabricar uma métrica TDM em linguagens com memória gerenciada.
- [ ] Considerar aumentar M nos experimentos finais e analisar estabilidade/variância dos tempos.
- [ ] Documentar faixas práticas de `B`/`Npts`/`M` por linguagem e hardware, com estimativas ou avisos de memória e tempo para combinações inviáveis.

---

## 4. Rust — decisões a documentar

Estado: implementação aceita tecnicamente e já presente em `src/`.

- [x] `Vec<i32>` plano.
- [x] Indexação `i*N+j`.
- [x] `Instant` para temporização monotônica.
- [x] `drop` explícito em TDM.
- [x] Warm-up e M repetições.
- [x] Validação amostral fora de TCS.
- [x] `black_box` fora da janela TCS.
- [x] Acesso sem bounds-check no laço quente com invariantes de segurança documentadas.
- [ ] Registrar em `METHODOLOGY.md` que o benchmark Rust usa `unsafe/get_unchecked` no laço quente.
- [ ] Registrar em `THREATS_TO_VALIDITY.md` que essa opção aproxima o custo de acesso de C/C++, mas não representa uma implementação Rust genérica com bounds-check ativo.
- [ ] Preservar no runner exatamente a política de compilação usada na validação (`--edition=2021`, otimização e warnings como erro quando aplicável).

---

## 5. Julia — decisões antes dos experimentos finais

Estado: implementação aceita tecnicamente e já presente em `src/`.

- [x] Multiplicação manual O(N³).
- [x] Sem BLAS/`*` matricial.
- [x] `time_ns()`.
- [x] `TDM=0.0`, sem GC forçado.
- [x] Conversão correta entre índices lógicos 0-based e indexação Julia 1-based.
- [x] `@inbounds` validado também com `--check-bounds=yes`.
- [ ] **Decidir formalmente `Matrix{Int}` versus `Matrix{Int32}`.**
- [ ] Preferir `Int32` se o objetivo for aproximar a largura do elemento usada por C/C++/Java/Rust, salvo justificativa experimental em contrário.
- [ ] Se `Int` for mantido, registrar que em plataformas 64-bit normalmente representa 64 bits e altera consumo de memória/cache.
- [ ] Documentar layout column-major de Julia versus layout row-major/linear das outras implementações.
- [ ] Documentar que a ordem `i,j,k` foi mantida para preservar equivalência algorítmica, mesmo não sendo a ordem mais favorável ao layout column-major.
- [ ] Registrar a participação potencial do GC em TAM.

---

## 6. Elixir — decisões metodológicas e operacionais

Estado: implementação aceita tecnicamente, incorporada à base e presente em `src/`.

- [x] Representação escolhida após comparar listas, tuplas aninhadas, `:array` e tupla plana.
- [x] Tupla plana indexada por `i*N+j`.
- [x] Construção O(N²) por lista + `List.to_tuple/1`.
- [x] Multiplicação manual O(N³).
- [x] `System.monotonic_time/0` e `System.convert_time_unit/3`.
- [x] `TDM=0.0` sem GC forçado.
- [x] Harness completo aprovado.
- [x] Escalonamento compatível com O(N³) em teste diagnóstico.
- [x] Fazer review final e merge do PR #11 somente após #9 e #10.
- [ ] Documentar que `res` é construído durante TCS por causa da imutabilidade da linguagem.
- [ ] Documentar que TAM sofre pressão/variância de GC causada pela lista intermediária.
- [ ] Não interpretar TCS de Elixir como fase operacional idêntica ao TCS de linguagens que pré-alocam `res`.
- [ ] Definir limites experimentais práticos para B/M em Elixir antes da coleta definitiva, evitando execuções inviáveis.

---

## 7. Auditoria independente — decisões sobre achados

### Falsos positivos identificados

- [x] **Arredondamento C++:** `std::round` não usa bankers rounding; para N positivo coincide com a política metade-para-cima adotada no projeto.
- [x] **Arredondamento Java:** `Math.round(double)` é compatível com `floor(x + 0.5)` para os valores positivos do benchmark.
- [x] **Overflow do acumulador com a matriz identidade:** o resultado esperado é `i+j`; com `N <= 100000`, não há overflow de `int32` no valor calculado nas implementações atuais.

Esses itens **não devem gerar alteração de código** sem nova evidência.

### Achados reais a preservar

- [ ] C/C++ não criam automaticamente o diretório pai de `out_csv`.
- [ ] Layout de memória varia entre linguagens e deve constar nas ameaças à validade.
- [ ] JIT, GC e política de warm-up não são semanticamente idênticos entre runtimes.
- [ ] TDM não é métrica diretamente comparável entre memória manual e memória gerenciada.

### Auditoria pós-integração

- [ ] Repetir auditoria independente depois do Prompt 7.
- [ ] Exigir que o auditor registre antes da análise:
  - branch atual;
  - SHA atual;
  - `git status`;
  - lista das sete implementações realmente analisadas.
- [ ] Não aceitar conclusões baseadas em `main` quando o alvo da auditoria for `tcc-lic-thassio`.

---

## 8. Prompt 7 — integração das linguagens extras

Branch usada: `feat/extra-languages-integration` (base `tcc-lic-thassio`, com Rust/Julia/Elixir já aceitos em `src/`). Plano completo em `INTEGRATION_PLAN.md`.

Objetivos:

- [x] Integrar Rust, Julia e Elixir aos runners sem quebrar o fluxo principal.
- [x] Manter C, C++, Java e Python funcionais quando nenhuma toolchain extra estiver instalada (comportamento padrão sem flags é idêntico ao anterior; testado por smoke test).
- [x] Definir política das extras: híbrida — opcional por padrão (nunca ativa sem flag), com auto-detecção de toolchain acionada por flags explícitas (`--with-rust`/`--with-julia`/`--with-elixir`/`--with-all-extras` em `run_all.sh`; `-WithRust`/`-WithJulia`/`-WithElixir`/`-WithAllExtras` em `run_all.ps1`).
- [x] Se uma linguagem for explicitamente solicitada e a toolchain estiver ausente, abortar com erro claro (testado: `--with-rust` sem `rustc` no `PATH` aborta com "Dependencia ausente: rustc", código 1, núcleo já gerado preservado).
- [x] Registrar no manifesto **somente** linguagens realmente executadas.
- [x] Registrar versões das toolchains usadas (`tools.rustc`/`tools.julia`/`tools.elixir`).
- [x] Incluir os CSVs extras no manifesto quando executados.
- [x] Validar todos os CSVs declarados (`scripts/validate_run.py` não precisou de mudança de schema, mas expôs um bug real — ver achado abaixo).
- [x] Manter os CSVs principais obrigatórios conforme a política atual.
- [x] Plotador já incluía apenas séries presentes e válidas (`src/plot_benchmarks.py` não precisou de alteração).
- [x] Garantir que ausência de uma linguagem opcional não invalide uma execução do núcleo principal (por construção: sem a flag, a toolchain nunca é verificada).
- [x] Testar o fluxo completo com todas as toolchains disponíveis (`--with-all-extras`, 9 CSVs, 8 tools).
- [x] Testar o fluxo principal simulando ausência das toolchains extras (com e sem flags).
- [x] Atualizar README, EXECUTION, CONTRIBUTING, EXTRA_LANGUAGES e DIAGRAMS para o estado pós-integração.

### Achado real durante os smoke tests

- [x] **`scripts/validate_run.py` misturava caminhos relativos e absolutos**: `EXPECTED_CSVS` gerava caminhos relativos a partir de `run_dir`, mas `safe_manifest_output` sempre resolvia para absoluto: `path.relative_to(run_dir)` quebrava com `ValueError` para qualquer CSV que só existisse via manifesto (nunca um dos 6 nomes centrais) — ou seja, quebrava exatamente ao validar Rust/Julia/Elixir pela primeira vez em uma execução real. Nunca foi pego antes porque `scripts/test_validate_run.py` sempre reusava os 6 nomes centrais no fixture. Corrigido resolvendo `run_dir` uma única vez no início de `main()`.
- [x] **Reutilizar um `run_id` misturava resultados de execuções diferentes**: os runners agora rejeitam um diretório de saída não vazio, e o validador rejeita CSV extra presente mas ausente do manifesto.
- [x] **PowerShell ignorava códigos de saída nativos em parte do fluxo**: compilações, benchmarks, plotador e validador agora passam por `Assert-LastExitCode`.
- [x] **Manifesto das extras dependia da string de versão**: a inclusão agora depende da flag e do sucesso da execução; falha na sondagem de versão usa `N/D` sem omitir o CSV produzido.

---

## 9. Validação e testes

- [ ] Criar uma suíte de smoke test oficial do projeto.
- [ ] Manter `scripts/test_point_generation.py` como regressão do contrato de N.
- [ ] Manter `scripts/test_validate_run.py` para CSV truncado e séries N divergentes.
- [ ] Executar `git diff --check` antes de cada merge.
- [x] Executar `py_compile` nos scripts Python alterados nesta integração.
- [x] Rodar harness específico de cada linguagem antes da integração.
- [x] Rodar `validate_run.py` em execução completa depois da integração (6 CSVs no núcleo e 9 com todas as extras).
- [ ] Validar `run_all.ps1` no Windows nativo antes da publicação.
- [ ] Clonar o repositório em diretório limpo e reproduzir uma execução completa antes da coleta experimental final.
- [ ] Documentar em `EXTRA_LANGUAGES.md` que o harness testa a sobrescrita do CSV e aplica timeout de 120 segundos por subprocesso.

---

## 10. Documentação científica

Criar/atualizar:

- [ ] `METHODOLOGY.md`.
- [ ] `docs/THREATS_TO_VALIDITY.md`.
- [x] README com quick start e visão geral operacional.
- [x] `EXECUTION.md` com execução operacional e exemplos.
- [x] `CONTRIBUTING.md` com fluxo atualizado das branches.
- [x] `EXTRA_LANGUAGES.md` refletindo o estado pós-integração.

`METHODOLOGY.md` deve cobrir, no mínimo:

- [ ] objetivo do benchmark;
- [ ] variável independente N;
- [ ] variáveis dependentes TAM/TCS/TDM e eventual TEXEC;
- [ ] controles experimentais;
- [ ] geração de N e regra de arredondamento;
- [ ] warm-up e número de repetições;
- [ ] validação matemática;
- [ ] flags de compilação;
- [ ] JIT;
- [ ] GC;
- [ ] layout e tipo numérico;
- [ ] hardware e sistema operacional;
- [ ] versões das toolchains;
- [ ] limitações e ameaças à validade;
- [ ] procedimento de reprodução.

---

## 11. Portabilidade e organização

- [ ] Verificar compatibilidade de `date -Iseconds` no macOS.
- [ ] Fornecer diagnóstico das toolchains extras em PowerShell ou documentar que `scripts/check_extra_toolchains.sh` exige WSL/Git Bash.
- [ ] Normalizar a saída UTF-16/NUL de `wsl.exe --status` em `scripts/gen_sysinfo_md.sh`; hoje certos hosts WSL podem gerar surrogates inválidos e interromper o JSON.
- [ ] Confirmar que `src/` contém apenas código-fonte.
- [ ] Confirmar que `build/` não está rastreado.
- [ ] Avaliar remoção de resultados locais históricos em `out/teste/`, se ainda existirem.
- [ ] Confirmar que artefatos compilados/caches/resultados locais permanecem ignorados.
- [ ] Considerar GitHub Actions para smoke tests automáticos em PRs.
- [ ] Considerar README em inglês após estabilização do TCC.

---

## 12. Extensões futuras — fora do escopo imediato

- [ ] Variante NumPy para Python.
- [ ] BLAS em C/C++ no contrato comum.
- [ ] Paralelismo com OpenMP/threads.
- [ ] Medição de memória RSS.
- [ ] Preservar tempos brutos por repetição e gerar desvio padrão, percentis, boxplots e intervalos de confiança.
- [ ] Relatório automático em Markdown.
- [ ] Medição de energia quando houver infraestrutura adequada.
